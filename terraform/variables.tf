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

variable "userdata_playbook_url" {
  type = string
  description = "url of an ansible playbook to setup the jumpbox"
}

variable "userdata_playbook_path" {
  type = string
  description = "path into the url where the main playbook exists"
}
