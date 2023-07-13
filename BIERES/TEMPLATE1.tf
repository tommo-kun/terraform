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
resource "aws_vpc" "BIERES-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "BIERES-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "BIERES-PUB-SUBNET" {
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "BIERES-PUB-SUBNET"
	}
}
resource "aws_subnet" "BIERES-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "BIERES-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "BIERES-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "BIERES-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "BIERES-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "BIERES-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "BIERES-IGW" {
}
resource "aws_internet_gateway_attachment" "BIERES-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.BIERES-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "BIERES-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.BIERES-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.BIERES-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.BIERES-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "BIERES-ROUTE-PUB" {
  vpc_id = "${aws_vpc.BIERES-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.BIERES-IGW.id}"
  }
  tags = {
    Name = "BIERES-ROUTE1"
  }
}
resource "aws_route_table" "BIERES-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.BIERES-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.BIERES-NAT-GTW.id}"
  }
  tags = {
    Name = "BIERES-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "BIERES-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.BIERES-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.BIERES-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "BIERES-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.BIERES-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.BIERES-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "BIERES-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.BIERES-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.BIERES-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "BIERES-EIP" {
}
resource "aws_nat_gateway" "BIERES-NAT-GTW" {
  allocation_id = "${aws_eip.BIERES-EIP.id}"
  subnet_id     = "${aws_subnet.BIERES-PUB-SUBNET.id}"
  tags = {
    Name = "BIERES-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.BIERES-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "BIERES-SG-ADMIN" {
        name = "BIERES-SG-ADMIN"
        description = "BIERES-SG-ADMIN"
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        ingress {
                description = "BIERES-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "BIERES-SG-ADMIN"
        }
}

resource "aws_security_group" "BIERES-SG-REVERSE" {
        name = "BIERES-SG1"
        description = "BIERES-SG-REVERSE"
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        ingress {
                description = "BIERES-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "BIERES-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.BIERES-SG-ADMIN.id}"]
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
                Name = "BIERES-SG-REVERSE"
        }
}
resource "aws_security_group" "BIERES-SG-PRIV-WEB" {
        name = "BIERES-SG-PRIV-WEB"
        description = "BIERES-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.BIERES-VPC.id}"
        ingress {
                description = "BIERES-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.BIERES-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.BIERES-SG-ADMIN.id}"]
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
                Name = "BIERES-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "PUB_KEY_PRIV"
}


# INSTANCES
resource "aws_instance" "BIERES-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.BIERES-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.BIERES-SG-ADMIN.id}"]
        tags = {
                Name = "BIERES-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "BIERES-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.BIERES-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.BIERES-SG-REVERSE.id}"]
        tags = {
                Name = "BIERES-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "BIERES-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.BIERES-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.BIERES-SG-PRIV-WEB.id}"]
        tags = {
                Name = "BIERES-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "BIERES-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.BIERES-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.BIERES-SG-PRIV-WEB.id}"]
        tags = {
                Name = "BIERES-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "BIERES-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.BIERES-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.BIERES-SG-PRIV-WEB.id}"]
        tags = {
                Name = "BIERES-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


