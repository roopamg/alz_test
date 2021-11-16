terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "${var.region}"
}

# Create VPC
resource "aws_vpc" "test_vpc" {
  cidr_block = "${var.cidr_vpc}"
  tags = {
    Name = "${var.provider_name}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "${var.igw_name}"
  }
}

# Create custom route table
resource "aws_route_table" "test_route_table" {
  vpc_id = aws_vpc.test_vpc.id

  route {
      cidr_block = "${var.cidr_rt}"
      gateway_id = aws_internet_gateway.test_igw.id
    }

  route {
      ipv6_cidr_block = "${var.ipv6_cidr_rt}"
      gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name = "${var.rt_name}"
  }
}

# Create Subnet
resource "aws_subnet" "test_subnet" {
  vpc_id     =  aws_vpc.test_vpc.id
  cidr_block = "${var.cidr_subnet}"
  availability_zone = "${var.subnet_az}"
  tags = {
    Name = "${var.subnet_name}"
  }
}

# Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.test_route_table.id
}

# Create security group to allow port 21,80,443
resource "aws_security_group" "test_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.test_vpc.id

  ingress = [
    {
      description      = "HTTP"
      from_port        = 79
      to_port          = 79
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]  
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
    },
  {
      description      = "HTTPS"
      from_port        = 442
      to_port          = 442
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]  
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false      
  },

    {
      description      = "SSH"
      from_port        = 21
      to_port          = 21
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]  
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false      
    }
  ]


  egress = [
    {
      description      = "for all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]


  tags = {
    Name = "${var.sg_name}"
  }
}

# Create a network interface with an ip in the subnet that was created in step 3
resource "aws_network_interface" "test_ni" {
  subnet_id       = aws_subnet.test_subnet.id
  private_ips     = ["9.0.1.50"]
  security_groups = [aws_security_group.test_sg.id]

  tags = {
      Name = "${var.ni_name}"
  }
}

# Assign an elastic IP to the network interface created in step 6
resource "aws_eip" "test_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.test_ni.id
  associate_with_private_ip = "9.0.1.50"
  depends_on                = [aws_internet_gateway.test_igw]

  tags = {
      Name = "${var.eip_name}"
  }
}

output "server_public_ip" {
  value = aws_eip.test_eip.public_ip
}
