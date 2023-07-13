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
resource "aws_vpc" "LEBARCEBIEN-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "LEBARCEBIEN-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "LEBARCEBIEN-PUB-SUBNET" {
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "LEBARCEBIEN-PUB-SUBNET"
	}
}
resource "aws_subnet" "LEBARCEBIEN-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "LEBARCEBIEN-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "LEBARCEBIEN-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "LEBARCEBIEN-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "LEBARCEBIEN-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "LEBARCEBIEN-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "LEBARCEBIEN-IGW" {
}
resource "aws_internet_gateway_attachment" "LEBARCEBIEN-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.LEBARCEBIEN-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "LEBARCEBIEN-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.LEBARCEBIEN-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.LEBARCEBIEN-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.LEBARCEBIEN-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "LEBARCEBIEN-ROUTE-PUB" {
  vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.LEBARCEBIEN-IGW.id}"
  }
  tags = {
    Name = "LEBARCEBIEN-ROUTE1"
  }
}
resource "aws_route_table" "LEBARCEBIEN-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.LEBARCEBIEN-NAT-GTW.id}"
  }
  tags = {
    Name = "LEBARCEBIEN-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "LEBARCEBIEN-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.LEBARCEBIEN-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.LEBARCEBIEN-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "LEBARCEBIEN-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.LEBARCEBIEN-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.LEBARCEBIEN-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "LEBARCEBIEN-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.LEBARCEBIEN-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.LEBARCEBIEN-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "LEBARCEBIEN-EIP" {
}
resource "aws_nat_gateway" "LEBARCEBIEN-NAT-GTW" {
  allocation_id = "${aws_eip.LEBARCEBIEN-EIP.id}"
  subnet_id     = "${aws_subnet.LEBARCEBIEN-PUB-SUBNET.id}"
  tags = {
    Name = "LEBARCEBIEN-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.LEBARCEBIEN-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "LEBARCEBIEN-SG-ADMIN" {
        name = "LEBARCEBIEN-SG-ADMIN"
        description = "LEBARCEBIEN-SG-ADMIN"
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        ingress {
                description = "LEBARCEBIEN-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "LEBARCEBIEN-SG-ADMIN"
        }
}

resource "aws_security_group" "LEBARCEBIEN-SG-REVERSE" {
        name = "LEBARCEBIEN-SG1"
        description = "LEBARCEBIEN-SG-REVERSE"
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        ingress {
                description = "LEBARCEBIEN-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "LEBARCEBIEN-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.LEBARCEBIEN-SG-ADMIN.id}"]
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
                Name = "LEBARCEBIEN-SG-REVERSE"
        }
}
resource "aws_security_group" "LEBARCEBIEN-SG-PRIV-WEB" {
        name = "LEBARCEBIEN-SG-PRIV-WEB"
        description = "LEBARCEBIEN-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.LEBARCEBIEN-VPC.id}"
        ingress {
                description = "LEBARCEBIEN-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.LEBARCEBIEN-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.LEBARCEBIEN-SG-ADMIN.id}"]
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
                Name = "LEBARCEBIEN-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwIJbgD97aQy1+4qByVp3UIS6oTJhdLtTIopouh4l0BL1X7bqD3RGGIy0L/CQcvDauN5KwBvCD+XOuarZ3E0tZfBjydbKOxlAqLFzjeH8KmqSZh02D0hvrzIdDMtIQp+tc1BsKvYD4bS7st/NuHb9ZT0dH2wJIu80k8UjCrQiP2sC+U4VRGJmItntVH+TalhK4eMS5QDAQbkXbgc5QiiPhKv6v9G+52NR5/uhZe5x7YE/b7O6c7QVti2WHuN4ZPLV+kE1jpJVentoS8U3quaAYSBoshF6dHqqqNLI1Bndl80qwZcu7mAqMw1nG6+EzAfi45xuhtHzAkmqkl/TTapho8QXg3iyBQ8wLFJcB4BCnNUd+xUlQoC0+uN4Xz2USzEJ2pyB/2ues0mUowogozROHnitp+828mf+egARvVRfW+D1C1cACyeVs++5DjVprYMm/KbowhNOPItxJOods1r+vi7/1LWe9B2Bn1jIGRRpVwfTmRE8N8D6HiStzrmE2PjU= jenkins@server"
}


# INSTANCES
resource "aws_instance" "LEBARCEBIEN-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.LEBARCEBIEN-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.LEBARCEBIEN-SG-ADMIN.id}"]
        tags = {
                Name = "LEBARCEBIEN-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "LEBARCEBIEN-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.LEBARCEBIEN-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.LEBARCEBIEN-SG-REVERSE.id}"]
        tags = {
                Name = "LEBARCEBIEN-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "LEBARCEBIEN-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.LEBARCEBIEN-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.LEBARCEBIEN-SG-PRIV-WEB.id}"]
        tags = {
                Name = "LEBARCEBIEN-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "LEBARCEBIEN-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.LEBARCEBIEN-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.LEBARCEBIEN-SG-PRIV-WEB.id}"]
        tags = {
                Name = "LEBARCEBIEN-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "LEBARCEBIEN-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.LEBARCEBIEN-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.LEBARCEBIEN-SG-PRIV-WEB.id}"]
        tags = {
                Name = "LEBARCEBIEN-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


