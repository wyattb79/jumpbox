data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-*"]
  }

  owners = ["099720109477"] # Canonical
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_instance" "jumpbox" {
  instance_type = var.instance_type
  ami = data.aws_ami.ubuntu.id
  key_name = var.keypair
}

resource "aws_security_group" "login_from_here" {
  name        = "login-from-here"
  description = "Security group that restricts inbound traffic to my IP"
  vpc_id      = "vpc-12345678" # Replace with your VPC ID
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.login_from_here.id
  description       = "Allow SSH from my current public IP"
  
  cidr_ipv4   = "${chomp(data.http.my_public_ip.response_body)}/32"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}
