terraform {
        required_providers {
                aws = {
                        source  = "hashicorp/aws"
                }
        }
}
provider "aws" {
        region = "eu-west-3"
}

# VPC
resource "aws_vpc" "PROUT-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "PROUT-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "PROUT-PUB-SUBNET" {
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "PROUT-PUB-SUBNET"
	}
}
resource "aws_subnet" "PROUT-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "PROUT-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "PROUT-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "PROUT-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "PROUT-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "PROUT-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "PROUT-IGW" {
}
resource "aws_internet_gateway_attachment" "PROUT-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.PROUT-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "PROUT-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.PROUT-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.PROUT-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.PROUT-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "PROUT-ROUTE-PUB" {
  vpc_id = "${aws_vpc.PROUT-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.PROUT-IGW.id}"
  }
  tags = {
    Name = "PROUT-ROUTE1"
  }
}
resource "aws_route_table" "PROUT-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.PROUT-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.PROUT-NAT-GTW.id}"
  }
  tags = {
    Name = "PROUT-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "PROUT-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.PROUT-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.PROUT-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "PROUT-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.PROUT-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.PROUT-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "PROUT-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.PROUT-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.PROUT-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "PROUT-EIP" {
}
resource "aws_nat_gateway" "PROUT-NAT-GTW" {
  allocation_id = "${aws_eip.PROUT-EIP.id}"
  subnet_id     = "${aws_subnet.PROUT-PUB-SUBNET.id}"
  tags = {
    Name = "PROUT-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.PROUT-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "PROUT-SG-ADMIN" {
        name = "PROUT-SG-ADMIN"
        description = "PROUT-SG-ADMIN"
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        ingress {
                description = "PROUT-SG1-ALLOW-SSH-FROM-EXT"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
        egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
        tags = {
                Name = "PROUT-SG-ADMIN"
        }
}

resource "aws_security_group" "PROUT-SG-REVERSE" {
        name = "PROUT-SG1"
        description = "PROUT-SG-REVERSE"
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        ingress {
                description = "PROUT-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "PROUT-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.PROUT-SG-ADMIN.id}"]
		ipv6_cidr_blocks = []
        }
        egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
        tags = {
                Name = "PROUT-SG-REVERSE"
        }
}
resource "aws_security_group" "PROUT-SG-PRIV-WEB" {
        name = "PROUT-SG-PRIV-WEB"
        description = "PROUT-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.PROUT-VPC.id}"
        ingress {
                description = "PROUT-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.PROUT-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.PROUT-SG-ADMIN.id}"]
		ipv6_cidr_blocks = []
        }
        egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
        tags = {
                Name = "PROUT-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "PUB_KEY_PRIV"
}


# INSTANCES
resource "aws_instance" "PROUT-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.PROUT-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.PROUT-SG-ADMIN.id}"]
        tags = {
                Name = "PROUT-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "PROUT-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.PROUT-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.PROUT-SG-REVERSE.id}"]
        tags = {
                Name = "PROUT-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "PROUT-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.PROUT-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.PROUT-SG-PRIV-WEB.id}"]
        tags = {
                Name = "PROUT-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "PROUT-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.PROUT-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.PROUT-SG-PRIV-WEB.id}"]
        tags = {
                Name = "PROUT-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "PROUT-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.PROUT-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.PROUT-SG-PRIV-WEB.id}"]
        tags = {
                Name = "PROUT-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


