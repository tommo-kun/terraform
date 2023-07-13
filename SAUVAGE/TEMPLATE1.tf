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
resource "aws_vpc" "SAUVAGE-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "SAUVAGE-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "SAUVAGE-PUB-SUBNET" {
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "SAUVAGE-PUB-SUBNET"
	}
}
resource "aws_subnet" "SAUVAGE-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "SAUVAGE-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "SAUVAGE-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "SAUVAGE-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "SAUVAGE-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "SAUVAGE-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "SAUVAGE-IGW" {
}
resource "aws_internet_gateway_attachment" "SAUVAGE-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.SAUVAGE-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "SAUVAGE-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.SAUVAGE-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.SAUVAGE-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.SAUVAGE-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "SAUVAGE-ROUTE-PUB" {
  vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.SAUVAGE-IGW.id}"
  }
  tags = {
    Name = "SAUVAGE-ROUTE1"
  }
}
resource "aws_route_table" "SAUVAGE-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.SAUVAGE-NAT-GTW.id}"
  }
  tags = {
    Name = "SAUVAGE-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "SAUVAGE-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.SAUVAGE-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.SAUVAGE-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "SAUVAGE-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.SAUVAGE-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.SAUVAGE-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "SAUVAGE-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.SAUVAGE-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.SAUVAGE-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "SAUVAGE-EIP" {
}
resource "aws_nat_gateway" "SAUVAGE-NAT-GTW" {
  allocation_id = "${aws_eip.SAUVAGE-EIP.id}"
  subnet_id     = "${aws_subnet.SAUVAGE-PUB-SUBNET.id}"
  tags = {
    Name = "SAUVAGE-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.SAUVAGE-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "SAUVAGE-SG-ADMIN" {
        name = "SAUVAGE-SG-ADMIN"
        description = "SAUVAGE-SG-ADMIN"
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        ingress {
                description = "SAUVAGE-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "SAUVAGE-SG-ADMIN"
        }
}

resource "aws_security_group" "SAUVAGE-SG-REVERSE" {
        name = "SAUVAGE-SG1"
        description = "SAUVAGE-SG-REVERSE"
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        ingress {
                description = "SAUVAGE-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "SAUVAGE-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.SAUVAGE-SG-ADMIN.id}"]
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
                Name = "SAUVAGE-SG-REVERSE"
        }
}
resource "aws_security_group" "SAUVAGE-SG-PRIV-WEB" {
        name = "SAUVAGE-SG-PRIV-WEB"
        description = "SAUVAGE-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.SAUVAGE-VPC.id}"
        ingress {
                description = "SAUVAGE-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.SAUVAGE-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.SAUVAGE-SG-ADMIN.id}"]
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
                Name = "SAUVAGE-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "PUB_KEY_PRIV"
}


# INSTANCES
resource "aws_instance" "SAUVAGE-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.SAUVAGE-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.SAUVAGE-SG-ADMIN.id}"]
        tags = {
                Name = "SAUVAGE-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "SAUVAGE-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.SAUVAGE-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.SAUVAGE-SG-REVERSE.id}"]
        tags = {
                Name = "SAUVAGE-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "SAUVAGE-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.SAUVAGE-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.SAUVAGE-SG-PRIV-WEB.id}"]
        tags = {
                Name = "SAUVAGE-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "SAUVAGE-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.SAUVAGE-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.SAUVAGE-SG-PRIV-WEB.id}"]
        tags = {
                Name = "SAUVAGE-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "SAUVAGE-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.SAUVAGE-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.SAUVAGE-SG-PRIV-WEB.id}"]
        tags = {
                Name = "SAUVAGE-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


