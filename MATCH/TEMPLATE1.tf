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
resource "aws_vpc" "MATCH-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "MATCH-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "MATCH-PUB-SUBNET" {
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "MATCH-PUB-SUBNET"
	}
}
resource "aws_subnet" "MATCH-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "MATCH-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "MATCH-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "MATCH-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "MATCH-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "MATCH-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "MATCH-IGW" {
}
resource "aws_internet_gateway_attachment" "MATCH-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.MATCH-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "MATCH-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.MATCH-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.MATCH-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.MATCH-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "MATCH-ROUTE-PUB" {
  vpc_id = "${aws_vpc.MATCH-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.MATCH-IGW.id}"
  }
  tags = {
    Name = "MATCH-ROUTE1"
  }
}
resource "aws_route_table" "MATCH-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.MATCH-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.MATCH-NAT-GTW.id}"
  }
  tags = {
    Name = "MATCH-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "MATCH-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.MATCH-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.MATCH-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "MATCH-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.MATCH-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.MATCH-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "MATCH-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.MATCH-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.MATCH-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "MATCH-EIP" {
}
resource "aws_nat_gateway" "MATCH-NAT-GTW" {
  allocation_id = "${aws_eip.MATCH-EIP.id}"
  subnet_id     = "${aws_subnet.MATCH-PUB-SUBNET.id}"
  tags = {
    Name = "MATCH-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.MATCH-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "MATCH-SG-ADMIN" {
        name = "MATCH-SG-ADMIN"
        description = "MATCH-SG-ADMIN"
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        ingress {
                description = "MATCH-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "MATCH-SG-ADMIN"
        }
}

resource "aws_security_group" "MATCH-SG-REVERSE" {
        name = "MATCH-SG1"
        description = "MATCH-SG-REVERSE"
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        ingress {
                description = "MATCH-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "MATCH-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.MATCH-SG-ADMIN.id}"]
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
                Name = "MATCH-SG-REVERSE"
        }
}
resource "aws_security_group" "MATCH-SG-PRIV-WEB" {
        name = "MATCH-SG-PRIV-WEB"
        description = "MATCH-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.MATCH-VPC.id}"
        ingress {
                description = "MATCH-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.MATCH-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.MATCH-SG-ADMIN.id}"]
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
                Name = "MATCH-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEkLUpSB9d/T0kqsLtG5fojLqCM7baG06rnY5DzXHjOnZKaaYnq1NpAFUKe+MilK1rKf7WxZvp9xavBL/EuXNr+EqA7FEK6uWhKtPUbpiYbtDLIjOaMLORcxWMzkgzIO/4KH7PgzKmlvFeZ78JprmljgIYGR8Dc3SGbKfCMOcLzL81RqU6QOZCIeUeVtc9kY2S7cQte1jJL81sHZ8Aiz2vdFWv5SSAbqEyDOMU3HBBRHzc1Xr6oGIxL5tG+v7LTosqy+uziHrLL5N60hnq74Irk3ilOKtwuwWD7SFb2NwId1LG3HwjxRJmlKboluYzyAt4lFEa/EJ5QM3JcNp4zcTLfMKad8+5hU+H1cVwj/60NCwZ4r7R12HcCKjv+uNcgnhVvSQFAwOJSvBk+UmyzP7nA8LliZxL9yz5OI2tXAZUGhTNkUNJNp1sHky31YHS46gu25DBUjL4YYuYGQ3tCfgHDHtquxF0yLajeLyynrcKIgHD/xSWxfTk9DAgvnn2KIM= jenkins@server"
}


# INSTANCES
resource "aws_instance" "MATCH-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.MATCH-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.MATCH-SG-ADMIN.id}"]
        tags = {
                Name = "MATCH-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "MATCH-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.MATCH-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.MATCH-SG-REVERSE.id}"]
        tags = {
                Name = "MATCH-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip22"
        }
}

resource "aws_instance" "MATCH-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.MATCH-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.MATCH-SG-PRIV-WEB.id}"]
        tags = {
                Name = "MATCH-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "MATCH-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.MATCH-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.MATCH-SG-PRIV-WEB.id}"]
        tags = {
                Name = "MATCH-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "MATCH-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.MATCH-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.MATCH-SG-PRIV-WEB.id}"]
        tags = {
                Name = "MATCH-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


