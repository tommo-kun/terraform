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
resource "aws_vpc" "BANANE-VPC" {
        cidr_block = "10.0.0.0/24"
        tags = {
                Name = "BANANE-VPC"
        }
}
resource "aws_subnet" "BANANE-SUBNET1" {
        vpc_id = "${aws_vpc.BANANE-VPC.id}"
        cidr_block = "10.0.0.0/24"
        tags = {
                Name = "BANANE-SUBNET1"
        }
}
resource "aws_internet_gateway" "BANANE-IGW" {
}
resource "aws_internet_gateway_attachment" "BANANE-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.BANANE-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.BANANE-IGW.id}"
}
resource "aws_route" "BANANE-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.BANANE-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.BANANE-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.BANANE-IGW-ATTACHMENT
        ]
}
resource "aws_security_group" "BANANE-SG" {
        name = "BANANE-SG"
        description = "BANANE-SG"
        vpc_id = "${aws_vpc.BANANE-VPC.id}"
        ingress {
                description = "BANANE-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
        ingress {
                description = "BANANE-SG-ALLOW-SSH"
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
                Name = "BANANE-SG"
        }
}
resource "aws_instance" "BANANE-INSTANCE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.BANANE-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.BANANE-SG.id}"]
        tags = {
                Name = "BANANE-INSTANCE"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip"
        }
}
