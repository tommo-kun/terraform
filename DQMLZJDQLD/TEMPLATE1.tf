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
resource "aws_vpc" "DQMLZJDQLD-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "DQMLZJDQLD-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "DQMLZJDQLD-PUB-SUBNET" {
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "DQMLZJDQLD-PUB-SUBNET"
	}
}
resource "aws_subnet" "DQMLZJDQLD-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "DQMLZJDQLD-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "DQMLZJDQLD-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "DQMLZJDQLD-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "DQMLZJDQLD-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "DQMLZJDQLD-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "DQMLZJDQLD-IGW" {
}
resource "aws_internet_gateway_attachment" "DQMLZJDQLD-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.DQMLZJDQLD-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "DQMLZJDQLD-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.DQMLZJDQLD-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.DQMLZJDQLD-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.DQMLZJDQLD-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "DQMLZJDQLD-ROUTE-PUB" {
  vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.DQMLZJDQLD-IGW.id}"
  }
  tags = {
    Name = "DQMLZJDQLD-ROUTE1"
  }
}
resource "aws_route_table" "DQMLZJDQLD-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.DQMLZJDQLD-NAT-GTW.id}"
  }
  tags = {
    Name = "DQMLZJDQLD-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "DQMLZJDQLD-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.DQMLZJDQLD-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.DQMLZJDQLD-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "DQMLZJDQLD-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.DQMLZJDQLD-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.DQMLZJDQLD-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "DQMLZJDQLD-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.DQMLZJDQLD-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.DQMLZJDQLD-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "DQMLZJDQLD-EIP" {
}
resource "aws_nat_gateway" "DQMLZJDQLD-NAT-GTW" {
  allocation_id = "${aws_eip.DQMLZJDQLD-EIP.id}"
  subnet_id     = "${aws_subnet.DQMLZJDQLD-PUB-SUBNET.id}"
  tags = {
    Name = "DQMLZJDQLD-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.DQMLZJDQLD-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "DQMLZJDQLD-SG-ADMIN" {
        name = "DQMLZJDQLD-SG-ADMIN"
        description = "DQMLZJDQLD-SG-ADMIN"
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        ingress {
                description = "DQMLZJDQLD-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "DQMLZJDQLD-SG-ADMIN"
        }
}

resource "aws_security_group" "DQMLZJDQLD-SG-REVERSE" {
        name = "DQMLZJDQLD-SG1"
        description = "DQMLZJDQLD-SG-REVERSE"
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        ingress {
                description = "DQMLZJDQLD-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "DQMLZJDQLD-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.DQMLZJDQLD-SG-ADMIN.id}"]
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
                Name = "DQMLZJDQLD-SG-REVERSE"
        }
}
resource "aws_security_group" "DQMLZJDQLD-SG-PRIV-WEB" {
        name = "DQMLZJDQLD-SG-PRIV-WEB"
        description = "DQMLZJDQLD-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.DQMLZJDQLD-VPC.id}"
        ingress {
                description = "DQMLZJDQLD-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.DQMLZJDQLD-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.DQMLZJDQLD-SG-ADMIN.id}"]
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
                Name = "DQMLZJDQLD-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "PUB_KEY_PRIV"
}


# INSTANCES
resource "aws_instance" "DQMLZJDQLD-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.DQMLZJDQLD-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.DQMLZJDQLD-SG-ADMIN.id}"]
        tags = {
                Name = "DQMLZJDQLD-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "DQMLZJDQLD-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.DQMLZJDQLD-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.DQMLZJDQLD-SG-REVERSE.id}"]
        tags = {
                Name = "DQMLZJDQLD-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "DQMLZJDQLD-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.DQMLZJDQLD-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.DQMLZJDQLD-SG-PRIV-WEB.id}"]
        tags = {
                Name = "DQMLZJDQLD-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "DQMLZJDQLD-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.DQMLZJDQLD-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.DQMLZJDQLD-SG-PRIV-WEB.id}"]
        tags = {
                Name = "DQMLZJDQLD-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "DQMLZJDQLD-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.DQMLZJDQLD-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.DQMLZJDQLD-SG-PRIV-WEB.id}"]
        tags = {
                Name = "DQMLZJDQLD-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


