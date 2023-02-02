variable "aws_region" {
  type        = string
  default     = "eu-west-2"
  description = "Sets the aws region"
}

#variable "access_key" {
  #default = "AKIARQYDZHD2JKSTN7DA"
#}

#variable "secret_key" {
  #default = "SpfrC3k9EuQg5PRWfy/2lk11f/vEgZDDlgrMszdu"
#}


variable "cidr_block" {
  description = "cidr block for the VPC ID"
  default     = "10.0.0.0/16"
  type        = string
}


variable "domain_name" {
  default     = "khessie.live"
  type        = string
  description = "My Domain name"
}
