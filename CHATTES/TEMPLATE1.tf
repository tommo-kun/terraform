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
resource "aws_vpc" "CHATTES-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "CHATTES-VPC"
        }
}
resource "aws_subnet" "CHATTES-SUBNET1" {
        vpc_id = "${aws_vpc.CHATTES-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "CHATTES-SUBNET1"
	}
}
resource "aws_subnet" "CHATTES-SUBNET2" {
        vpc_id = "${aws_vpc.CHATTES-VPC.id}"
        cidr_block = "10.0.2.0/24"
        tags = {
                Name = "CHATTES-SUBNET2"
        }
}
resource "aws_internet_gateway" "CHATTES-IGW" {
}
resource "aws_internet_gateway_attachment" "CHATTES-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.CHATTES-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.CHATTES-IGW.id}"
}
resource "aws_route" "CHATTES-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.CHATTES-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.CHATTES-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.CHATTES-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "CHATTES-ROUTE1" {
  vpc_id = "${aws_vpc.CHATTES-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.CHATTES-IGW.id}"
  }
  tags = {
    Name = "CHATTES-ROUTE1"
  }
}
resource "aws_route_table" "CHATTES-ROUTE2" {
  vpc_id = "${aws_vpc.CHATTES-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.CHATTES-NAT-GTW.id}"
  }
  tags = {
    Name = "CHATTES-ROUTE2"
  }
}
resource "aws_route_table_association" "CHATTES-RTB-ASSOC" {
  route_table_id = "${aws_route_table.CHATTES-ROUTE2.id}"
  subnet_id = "${aws_subnet.CHATTES-SUBNET2.id}"
}
resource "aws_eip" "CHATTES-EIP" {
}
resource "aws_nat_gateway" "CHATTES-NAT-GTW" {
  allocation_id = "${aws_eip.CHATTES-EIP.id}"
  subnet_id     = "${aws_subnet.CHATTES-SUBNET1.id}"
  tags = {
    Name = "CHATTES-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.CHATTES-IGW]
}
resource "aws_security_group" "CHATTES-SG1" {
        name = "CHATTES-SG1"
        description = "CHATTES-SG1"
        vpc_id = "${aws_vpc.CHATTES-VPC.id}"
        ingress {
                description = "CHATTES-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "CHATTES-SG1-ALLOW-SSH"
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
                Name = "CHATTES-SG1"
        }
}
resource "aws_security_group" "CHATTES-SG2" {
        name = "CHATTES-SG2"
        description = "CHATTES-SG2"
        vpc_id = "${aws_vpc.CHATTES-VPC.id}"
        ingress {
                description = "CHATTES-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.CHATTES-SG1.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.CHATTES-SG1.id}"]
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
                Name = "CHATTES-SG2"
        }
}
resource "aws_instance" "CHATTES-INSTANCE1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.CHATTES-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.CHATTES-SG1.id}"]
        tags = {
                Name = "CHATTES-INSTANCE1"
        }
        user_data = "${templatefile("conf.tpl", { WEB_IP = "${aws_instance.CHATTES-INSTANCE2.private_ip}" })}"
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "CHATTES-INSTANCE2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.CHATTES-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.CHATTES-SG2.id}"]
        tags = {
                Name = "CHATTES-INSTANCE2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ip2"
        }
}
