variable "vpc_id" {
  description = "The ID of the existing VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the existing subnets"
  type        = list(string)
}

variable "route_table_id" {
  description = "The ID of the existing route table"
  type        = string
}

variable "internet_gateway_id" {
  description = "The ID of the existing internet gateway"
  type        = string
}