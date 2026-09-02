# template-tf-modules

---
## Repository Structure & Details (Auto-generated)

### Scopo
Modulo Client VPN Endpoint AWS.

### Cartelle
- `main.tf`: definizione risorse.
- `examples/`: esempi di utilizzo.

### Script
Nessuno.

### Workflow
- `documentation.yaml`: generazione documentazione.

Terraform module to create a Client VPN enpoint inside your VPC


## Usage

```hcl
module "vpn" {
  source                     = "git::https://github.com/pagopa/terraform-aws-client-vpn-endpoint.git"
  endpoint_name              = "vpn"
  endpoint_client_cidr_block = "10.100.0.0/22"
  endpoint_subnets           = [module.vpc.private_subnets[0]] # Attach VPN to single subnet. Reduce cost
  endpoint_vpc_id            = module.vpc.vpc_id
  tls_subject_common_name    = "vpn.sandbox.pagopa.it"
  saml_provider_arn          = aws_iam_saml_provider.vpn.arn
  self_service_portal        = "enabled"

  authorization_rules = {}

  authorization_rules_all_groups = {
    full_access_private_subnet_0 = module.vpc.private_subnets_cidr_blocks[0]
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0   |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_ec2_client_vpn_authorization_rule.sso_to_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule) | resource |
| [aws_ec2_client_vpn_authorization_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule) | resource |
| [aws_ec2_client_vpn_authorization_rule.this_all_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule) | resource |
| [aws_ec2_client_vpn_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |
| [aws_ec2_client_vpn_network_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource |
| [aws_ec2_client_vpn_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_route) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_routes"></a> [additional\_routes](#input\_additional\_routes) | A map where the key is a subnet ID of endpoint subnet for network association and value is a cidr to where traffic should be routed from that subnet. Useful in cases if you need to route beyond the VPC subnet, for instance peered VPC | `map(string)` | `{}` | no |
| <a name="input_authorization_rules"></a> [authorization\_rules](#input\_authorization\_rules) | Map containing authorization rule configuration. rule\_name = "target\_network\_cidr, access\_group\_id" . | `map(string)` | `{}` | no |
| <a name="input_authorization_rules_all_groups"></a> [authorization\_rules\_all\_groups](#input\_authorization\_rules\_all\_groups) | Map containing authorization rule configuration with authorize\_all\_groups=true. rule\_name = "target\_network\_cidr" . | `map(string)` | `{}` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | The ARN of ACM certigicate to use for the VPN server config. | `string` | `null` | no |
| <a name="input_client_root_certificate_arn"></a> [client\_root\_certificate\_arn](#input\_client\_root\_certificate\_arn) | The ARN of the ACM Client Certificate for enabling mutual authentication (certificate-authentication) | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_name_prefix"></a> [cloudwatch\_log\_group\_name\_prefix](#input\_cloudwatch\_log\_group\_name\_prefix) | Specifies the name prefix of CloudWatch Log Group for VPC flow logs. | `string` | `"/aws/client-vpn-endpoint/"` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days you want to retain log events in the specified log group for VPN connection logs. | `number` | `30` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | DNS servers to be used for DNS resolution. A Client VPN endpoint can have up to two DNS servers. If no DNS server is specified, the DNS address of the connecting device is used. Conflict with `use_vpc_internal_dns` | `list(string)` | `[]` | no |
| <a name="input_enable_split_tunnel"></a> [enable\_split\_tunnel](#input\_enable\_split\_tunnel) | Whether split-tunnel is enabled on VPN endpoint | `bool` | `true` | no |
| <a name="input_endpoint_client_cidr_block"></a> [endpoint\_client\_cidr\_block](#input\_endpoint\_client\_cidr\_block) | The IPv4 address range, in CIDR notation, from which to assign client IP addresses. The address range cannot overlap with the local CIDR of the VPC in which the associated subnet is located, or the routes that you add manually. The address range cannot be changed after the Client VPN endpoint has been created. The CIDR block should be /22 or greater. | `string` | `"10.100.100.0/24"` | no |
| <a name="input_endpoint_name"></a> [endpoint\_name](#input\_endpoint\_name) | Name to be used on the Client VPN Endpoint | `string` | n/a | yes |
| <a name="input_endpoint_subnets"></a> [endpoint\_subnets](#input\_endpoint\_subnets) | List of IDs of endpoint subnets for network association | `list(string)` | n/a | yes |
| <a name="input_endpoint_vpc_id"></a> [endpoint\_vpc\_id](#input\_endpoint\_vpc\_id) | VPC where the VPN will be connected. | `string` | n/a | yes |
| <a name="input_saml_provider_arn"></a> [saml\_provider\_arn](#input\_saml\_provider\_arn) | The ARN of the IAM SAML identity provider. | `string` | `null` | no |
| <a name="input_self_service_portal"></a> [self\_service\_portal](#input\_self\_service\_portal) | Whether the Client VPN self-service portal is enabled. | `string` | `"disabled"` | no |
| <a name="input_self_service_saml_provider_arn"></a> [self\_service\_saml\_provider\_arn](#input\_self\_service\_saml\_provider\_arn) | The ARN of a separate IAM SAML identity provider for the Client VPN self-service portal. Leave null to use saml\_provider\_arn. Changing this value replaces the Client VPN endpoint. | `string` | `null` | no |
| <a name="input_tls_subject_common_name"></a> [tls\_subject\_common\_name](#input\_tls\_subject\_common\_name) | The common\_name for subject for which a certificate is being requested. RFC5280. Not used if certificate\_arn provided. | `string` | `null` | no |
| <a name="input_tls_validity_period_hours"></a> [tls\_validity\_period\_hours](#input\_tls\_validity\_period\_hours) | Specifies the number of hours after initial issuing that the certificate will become invalid.  Not used if certificate\_arn provided. | `number` | `47400` | no |
| <a name="input_transport_protocol"></a> [transport\_protocol](#input\_transport\_protocol) | The transport protocol to be used by the VPN session. | `string` | `"udp"` | no |
| <a name="input_use_vpc_internal_dns"></a> [use\_vpc\_internal\_dns](#input\_use\_vpc\_internal\_dns) | Use VPC Internal DNS as is DNS servers | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_ec2_client_vpn_endpoint"></a> [aws\_ec2\_client\_vpn\_endpoint](#output\_aws\_ec2\_client\_vpn\_endpoint) | n/a |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | n/a |
<!-- END_TF_DOCS -->
