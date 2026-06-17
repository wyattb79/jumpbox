variable "instance_type" {
  type = string
  description = "instance type"
}

variable "keypair" {
  type = string
  description = "jumpbox keypair"
}

variable "vpc" {
  type = string
  description = "jumpbox vpc"
}

variable "subnet" {
  type = string
  description = "jumpbox subnet"
}
