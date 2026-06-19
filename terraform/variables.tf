variable "instance_type" {
  type = string
  description = "instance type"
}

variable "keypair" {
  type = string
  description = "jumpbox keypair"
}

variable "vpc_id" {
  type = string
  description = "jumpbox vpc"
}

variable "jumpbox_cidr" {
  type = string
  description = "cidr of the jumpbox subnet"
}
