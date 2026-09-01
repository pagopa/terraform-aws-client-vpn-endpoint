resource "tls_private_key" "this" {
  count     = var.certificate_arn == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  count           = var.certificate_arn == null ? 1 : 0
  private_key_pem = tls_private_key.this[0].private_key_pem
  subject {
    common_name = var.tls_subject_common_name
  }
  validity_period_hours = var.tls_validity_period_hours
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "ipsec_end_system",
    "ipsec_tunnel",
    "any_extended",
    "cert_signing"
  ]
}

resource "aws_acm_certificate" "this" {
  count            = var.certificate_arn == null ? 1 : 0
  private_key      = tls_private_key.this[0].private_key_pem
  certificate_body = tls_self_signed_cert.this[0].cert_pem
  tags = {
    Name = var.tls_subject_common_name
  }
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "this" {
  name              = join("", [var.cloudwatch_log_group_name_prefix, var.endpoint_name])
  retention_in_days = var.cloudwatch_log_group_retention_in_days
}

resource "aws_cloudwatch_log_stream" "this" {
  log_group_name = aws_cloudwatch_log_group.this.name
  name           = "connection-log"
}

data "aws_vpc" "this" {
  id = var.endpoint_vpc_id
}

resource "aws_security_group" "this" {
  name        = format("client-vpn-endpoint-%s", var.endpoint_name)
  description = "Egress All. Used for other groups where VPN access is required. "
  vpc_id      = var.endpoint_vpc_id

  # VPN clients connect from arbitrary public addresses
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "Client VPN tunnel from any client public IP"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow all outbound traffic from the VPN endpoint"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = var.endpoint_name
  vpc_id                 = var.endpoint_vpc_id
  server_certificate_arn = var.certificate_arn != null ? var.certificate_arn : aws_acm_certificate.this[0].arn
  client_cidr_block      = var.endpoint_client_cidr_block
  split_tunnel           = var.enable_split_tunnel
  transport_protocol     = var.transport_protocol
  dns_servers            = var.use_vpc_internal_dns ? [cidrhost(data.aws_vpc.this.cidr_block, 2)] : var.dns_servers
  security_group_ids     = [aws_security_group.this.id]
  self_service_portal    = var.self_service_portal

  dynamic "authentication_options" {
    for_each = var.saml_provider_arn == null ? [] : [true]
    content {
      type              = "federated-authentication"
      saml_provider_arn = var.saml_provider_arn
    }
  }

  dynamic "authentication_options" {
    for_each = var.client_root_certificate_arn == null ? [] : [true]
    content {
      type                       = "certificate-authentication"
      root_certificate_chain_arn = var.client_root_certificate_arn
    }
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.this.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.this.name
  }

  tags = {
    Name = var.endpoint_name
  }
}

resource "aws_ec2_client_vpn_network_association" "this" {
  count                  = length(var.endpoint_subnets)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = element(var.endpoint_subnets, count.index)
}

resource "aws_ec2_client_vpn_authorization_rule" "sso_to_dns" {
  count                  = var.use_vpc_internal_dns ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = "${cidrhost(data.aws_vpc.this.cidr_block, 2)}/32"
  authorize_all_groups   = true
  description            = "Authorization for ${var.endpoint_name} to DNS"
}

resource "aws_ec2_client_vpn_authorization_rule" "this" {
  for_each               = var.authorization_rules
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = split(",", each.value)[0]
  access_group_id        = split(",", each.value)[1]
  description            = "Rule name: ${each.key}"
}

resource "aws_ec2_client_vpn_authorization_rule" "this_all_groups" {
  for_each               = var.authorization_rules_all_groups
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = each.value
  authorize_all_groups   = true
  description            = "Rule name: ${each.key}"
}

resource "aws_ec2_client_vpn_route" "this" {
  for_each               = var.additional_routes
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = each.value
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.this[each.key].subnet_id
  description            = "From ${each.key} to ${each.value}"
}