data "aws_ami" "al2023" {
  most_recent = true

  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_instance" "jumpbox" {
  instance_type = var.instance_type
  ami = data.aws_ami.al2023.id
  key_name = var.keypair
  subnet_id = aws_subnet.jumpbox_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.login_from_here.id]
  iam_instance_profile = aws_iam_instance_profile.this.name

  user_data = <<-EOF
              #! /bin/bash
              dnf update -y
              dnf install -y ansible
              ansible-pull -U ${var.userdata_playbook_url} -i localhost ${var.userdata_playbook_path}
              EOF

  tags = {
    Name = "Jumpbox"
    "${var.jumpbox_tag}" = "1"
  }
}

resource "aws_security_group" "login_from_here" {
  name        = "login-from-here"
  description = "Security group that restricts inbound traffic to my IP"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.login_from_here.id
  description       = "Allow SSH from my current public IP"
  
  cidr_ipv4   = "${chomp(data.http.my_public_ip.response_body)}/32"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow-traffic-out" {
  security_group_id = aws_security_group.login_from_here.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_subnet" "jumpbox_subnet" {
  vpc_id = var.vpc_id
  cidr_block = var.jumpbox_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "jumpbox_subnet_igw" {
  vpc_id = var.vpc_id
}

resource "aws_route_table" "jumpbox_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jumpbox_subnet_igw.id
  }
}

resource "aws_route_table_association" "igw_assoc" {
  subnet_id = aws_subnet.jumpbox_subnet.id
  route_table_id = aws_route_table.jumpbox_rt.id
}

resource "aws_iam_role" "this" {
  name = "jumpbox_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "jumpbox-instance-profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_policy" "this" {
  name = "jumpbox-policy"
  path = "/"
  description = "Policy for the Jumpbox to access resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

