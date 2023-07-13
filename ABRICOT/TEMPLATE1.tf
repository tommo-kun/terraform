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
resource "aws_vpc" "ABRICOT-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "ABRICOT-VPC"
        }
}
resource "aws_subnet" "ABRICOT-SUBNET1" {
        vpc_id = "${aws_vpc.ABRICOT-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "ABRICOT-SUBNET1"
	}
}
resource "aws_subnet" "ABRICOT-SUBNET2" {
        vpc_id = "${aws_vpc.ABRICOT-VPC.id}"
        cidr_block = "10.0.2.0/24"
        tags = {
                Name = "ABRICOT-SUBNET2"
        }
}
resource "aws_internet_gateway" "ABRICOT-IGW" {
}
resource "aws_internet_gateway_attachment" "ABRICOT-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.ABRICOT-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.ABRICOT-IGW.id}"
}
resource "aws_route" "ABRICOT-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.ABRICOT-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.ABRICOT-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.ABRICOT-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "ABRICOT-ROUTE1" {
  vpc_id = "${aws_vpc.ABRICOT-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ABRICOT-IGW.id}"
  }
  tags = {
    Name = "ABRICOT-ROUTE1"
  }
}
resource "aws_route_table" "ABRICOT-ROUTE2" {
  vpc_id = "${aws_vpc.ABRICOT-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ABRICOT-NAT-GTW.id}"
  }
  tags = {
    Name = "ABRICOT-ROUTE2"
  }
}
resource "aws_route_table_association" "ABRICOT-RTB-ASSOC" {
  route_table_id = "${aws_route_table.ABRICOT-ROUTE2.id}"
  subnet_id = "${aws_subnet.ABRICOT-SUBNET2.id}"
}
resource "aws_eip" "ABRICOT-EIP" {
}
resource "aws_nat_gateway" "ABRICOT-NAT-GTW" {
  allocation_id = "${aws_eip.ABRICOT-EIP.id}"
  subnet_id     = "${aws_subnet.ABRICOT-SUBNET1.id}"
  tags = {
    Name = "ABRICOT-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.ABRICOT-IGW]
}
resource "aws_security_group" "ABRICOT-SG1" {
        name = "ABRICOT-SG1"
        description = "ABRICOT-SG1"
        vpc_id = "${aws_vpc.ABRICOT-VPC.id}"
        ingress {
                description = "ABRICOT-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "ABRICOT-SG1-ALLOW-SSH"
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
                Name = "ABRICOT-SG1"
        }
}
resource "aws_security_group" "ABRICOT-SG2" {
        name = "ABRICOT-SG2"
        description = "ABRICOT-SG2"
        vpc_id = "${aws_vpc.ABRICOT-VPC.id}"
        ingress {
                description = "ABRICOT-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.ABRICOT-SG1.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.ABRICOT-SG1.id}"]
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
                Name = "ABRICOT-SG2"
        }
}
resource "aws_instance" "ABRICOT-INSTANCE1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.ABRICOT-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.ABRICOT-SG1.id}"]
        tags = {
                Name = "ABRICOT-INSTANCE1"
        }
        user_data = "${templatefile("conf.tpl", { WEB_IP = "${aws_instance.ABRICOT-INSTANCE2.private_ip}" })}"
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "ABRICOT-INSTANCE2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.ABRICOT-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.ABRICOT-SG2.id}"]
        tags = {
                Name = "ABRICOT-INSTANCE2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ip2"
        }
}
