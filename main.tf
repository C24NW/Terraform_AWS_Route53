#Create Provider
provider "aws" {
  region = "us-west-1"
}

#Create VPC
resource "aws_vpc" "vpc_1" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_1"
  }
}

#Set Availability Zone
data "aws_availability_zones" "available_zones" {}

#Create subnet
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.vpc_1.id
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.igw_1]

  tags = {
    Name = "vpc_1 az_1 subnet_1"
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "igw_1"
  }
}

#Create public route table
resource "aws_route_table" "route_table_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }

  tags = {
    Name = "route_table_1"
  }
}

#Associate route table with subnet
resource "aws_route_table_association" "route_table_association_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table_1.id
}

#Create security group for EC2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_vpc.vpc_1.id

  #Rule in security group that allows incoming traffic
  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.102/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2 security group"
  }
}

#Configure Route 53 zone
resource "aws_route53_zone" "zone_1" {
  name = "exampledomain.com"
  vpc {
    vpc_id = aws_vpc.vpc_1.id
  }
}

#Create DNS resource record for first instance
resource "aws_route53_record" "record_1" {
  zone_id = aws_route53_zone.zone_1.id
  name    = "first.exampledomain.com"
  type    = "A"
  ttl     = 300
  records = [aws_instance.instance_1.private_ip]
}

#Create DNS resource record for second instance
resource "aws_route53_record" "record_2" {
  zone_id = aws_route53_zone.zone_1.id
  name    = "second.exampledomain.com"
  type    = "A"
  ttl     = 300
  records = [aws_instance.instance_2.private_ip]
}

#Create EC2 instances
resource "aws_instance" "instance_1" {
  ami                    = "ami-0953e68f68effeb5d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "us_west_1"
  subnet_id              = aws_subnet.subnet_1.id
  user_data              = file("instance_1_web.sh")
  tags = {
    Name = "Instance 1"
  }
}

resource "aws_instance" "instance_2" {
  ami                    = "ami-0953e68f68effeb5d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "us_west_1"
  subnet_id              = aws_subnet.subnet_1.id
  user_data              = file("instance_2_web.sh")
  tags = {
    Name = "Instance 2"
  }
}

resource "aws_eip" "eip_1" {
  instance   = aws_instance.instance_1.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw_1]
}

resource "aws_eip" "eip_2" {
  instance   = aws_instance.instance_2.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw_1]
}

#Print the EC2's public IPv4 address
output "public_ipv4_address_instance_1" {
  value = aws_eip.eip_1.public_ip
}

output "public_ipv4_address_instance_2" {
  value = aws_eip.eip_2.public_ip
}

