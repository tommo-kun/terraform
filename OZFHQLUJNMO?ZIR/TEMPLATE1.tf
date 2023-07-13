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
resource "aws_vpc" "OZFHQLUJNMO?ZIR-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "OZFHQLUJNMO?ZIR-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "OZFHQLUJNMO?ZIR-PUB-SUBNET" {
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "OZFHQLUJNMO?ZIR-PUB-SUBNET"
	}
}
resource "aws_subnet" "OZFHQLUJNMO?ZIR-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "OZFHQLUJNMO?ZIR-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "OZFHQLUJNMO?ZIR-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "OZFHQLUJNMO?ZIR-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "OZFHQLUJNMO?ZIR-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "OZFHQLUJNMO?ZIR-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "OZFHQLUJNMO?ZIR-IGW" {
}
resource "aws_internet_gateway_attachment" "OZFHQLUJNMO?ZIR-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.OZFHQLUJNMO?ZIR-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "OZFHQLUJNMO?ZIR-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.OZFHQLUJNMO?ZIR-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.OZFHQLUJNMO?ZIR-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "OZFHQLUJNMO?ZIR-ROUTE-PUB" {
  vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.OZFHQLUJNMO?ZIR-IGW.id}"
  }
  tags = {
    Name = "OZFHQLUJNMO?ZIR-ROUTE1"
  }
}
resource "aws_route_table" "OZFHQLUJNMO?ZIR-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.OZFHQLUJNMO?ZIR-NAT-GTW.id}"
  }
  tags = {
    Name = "OZFHQLUJNMO?ZIR-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "OZFHQLUJNMO?ZIR-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.OZFHQLUJNMO?ZIR-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "OZFHQLUJNMO?ZIR-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.OZFHQLUJNMO?ZIR-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "OZFHQLUJNMO?ZIR-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.OZFHQLUJNMO?ZIR-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "OZFHQLUJNMO?ZIR-EIP" {
}
resource "aws_nat_gateway" "OZFHQLUJNMO?ZIR-NAT-GTW" {
  allocation_id = "${aws_eip.OZFHQLUJNMO?ZIR-EIP.id}"
  subnet_id     = "${aws_subnet.OZFHQLUJNMO?ZIR-PUB-SUBNET.id}"
  tags = {
    Name = "OZFHQLUJNMO?ZIR-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.OZFHQLUJNMO?ZIR-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "OZFHQLUJNMO?ZIR-SG-ADMIN" {
        name = "OZFHQLUJNMO?ZIR-SG-ADMIN"
        description = "OZFHQLUJNMO?ZIR-SG-ADMIN"
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        ingress {
                description = "OZFHQLUJNMO?ZIR-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "OZFHQLUJNMO?ZIR-SG-ADMIN"
        }
}

resource "aws_security_group" "OZFHQLUJNMO?ZIR-SG-REVERSE" {
        name = "OZFHQLUJNMO?ZIR-SG1"
        description = "OZFHQLUJNMO?ZIR-SG-REVERSE"
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        ingress {
                description = "OZFHQLUJNMO?ZIR-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "OZFHQLUJNMO?ZIR-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-ADMIN.id}"]
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
                Name = "OZFHQLUJNMO?ZIR-SG-REVERSE"
        }
}
resource "aws_security_group" "OZFHQLUJNMO?ZIR-SG-PRIV-WEB" {
        name = "OZFHQLUJNMO?ZIR-SG-PRIV-WEB"
        description = "OZFHQLUJNMO?ZIR-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.OZFHQLUJNMO?ZIR-VPC.id}"
        ingress {
                description = "OZFHQLUJNMO?ZIR-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-ADMIN.id}"]
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
                Name = "OZFHQLUJNMO?ZIR-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "PUB_KEY_PRIV"
}


# INSTANCES
resource "aws_instance" "OZFHQLUJNMO?ZIR-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-ADMIN.id}"]
        tags = {
                Name = "OZFHQLUJNMO?ZIR-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "OZFHQLUJNMO?ZIR-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-REVERSE.id}"]
        tags = {
                Name = "OZFHQLUJNMO?ZIR-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "OZFHQLUJNMO?ZIR-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-PRIV-WEB.id}"]
        tags = {
                Name = "OZFHQLUJNMO?ZIR-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "OZFHQLUJNMO?ZIR-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-PRIV-WEB.id}"]
        tags = {
                Name = "OZFHQLUJNMO?ZIR-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "OZFHQLUJNMO?ZIR-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.OZFHQLUJNMO?ZIR-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "KEY-PRIV-TO-PUB"
        security_groups = ["${aws_security_group.OZFHQLUJNMO?ZIR-SG-PRIV-WEB.id}"]
        tags = {
                Name = "OZFHQLUJNMO?ZIR-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


