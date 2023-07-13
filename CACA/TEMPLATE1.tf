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
resource "aws_vpc" "CACA-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "CACA-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "CACA-PUB-SUBNET" {
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "CACA-PUB-SUBNET"
	}
}
resource "aws_subnet" "CACA-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "CACA-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "CACA-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "CACA-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "CACA-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "CACA-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "CACA-IGW" {
}
resource "aws_internet_gateway_attachment" "CACA-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.CACA-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "CACA-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.CACA-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.CACA-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.CACA-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "CACA-ROUTE-PUB" {
  vpc_id = "${aws_vpc.CACA-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.CACA-IGW.id}"
  }
  tags = {
    Name = "CACA-ROUTE1"
  }
}
resource "aws_route_table" "CACA-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.CACA-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.CACA-NAT-GTW.id}"
  }
  tags = {
    Name = "CACA-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "CACA-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.CACA-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.CACA-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "CACA-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.CACA-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.CACA-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "CACA-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.CACA-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.CACA-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "CACA-EIP" {
}
resource "aws_nat_gateway" "CACA-NAT-GTW" {
  allocation_id = "${aws_eip.CACA-EIP.id}"
  subnet_id     = "${aws_subnet.CACA-PUB-SUBNET.id}"
  tags = {
    Name = "CACA-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.CACA-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "CACA-SG-ADMIN" {
        name = "CACA-SG-ADMIN"
        description = "CACA-SG-ADMIN"
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        ingress {
                description = "CACA-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "CACA-SG-ADMIN"
        }
}

resource "aws_security_group" "CACA-SG-REVERSE" {
        name = "CACA-SG1"
        description = "CACA-SG-REVERSE"
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        ingress {
                description = "CACA-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "CACA-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.CACA-SG-ADMIN.id}"]
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
                Name = "CACA-SG-REVERSE"
        }
}
resource "aws_security_group" "CACA-SG-PRIV-WEB" {
        name = "CACA-SG-PRIV-WEB"
        description = "CACA-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.CACA-VPC.id}"
        ingress {
                description = "CACA-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.CACA-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.CACA-SG-ADMIN.id}"]
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
                Name = "CACA-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "PUB_KEY_PRIV"
}


# INSTANCES
resource "aws_instance" "CACA-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.CACA-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.CACA-SG-ADMIN.id}"]
        tags = {
                Name = "CACA-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "CACA-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.CACA-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.CACA-SG-REVERSE.id}"]
        tags = {
                Name = "CACA-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "CACA-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.CACA-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.CACA-SG-PRIV-WEB.id}"]
        tags = {
                Name = "CACA-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "CACA-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.CACA-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.CACA-SG-PRIV-WEB.id}"]
        tags = {
                Name = "CACA-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "CACA-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.CACA-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.CACA-SG-PRIV-WEB.id}"]
        tags = {
                Name = "CACA-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


