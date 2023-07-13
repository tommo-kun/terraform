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
resource "aws_vpc" "TRIPLEKARMELITE-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "TRIPLEKARMELITE-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "TRIPLEKARMELITE-PUB-SUBNET" {
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "TRIPLEKARMELITE-PUB-SUBNET"
	}
}
resource "aws_subnet" "TRIPLEKARMELITE-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "TRIPLEKARMELITE-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "TRIPLEKARMELITE-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "TRIPLEKARMELITE-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "TRIPLEKARMELITE-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "TRIPLEKARMELITE-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "TRIPLEKARMELITE-IGW" {
}
resource "aws_internet_gateway_attachment" "TRIPLEKARMELITE-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.TRIPLEKARMELITE-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "TRIPLEKARMELITE-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.TRIPLEKARMELITE-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.TRIPLEKARMELITE-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.TRIPLEKARMELITE-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "TRIPLEKARMELITE-ROUTE-PUB" {
  vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.TRIPLEKARMELITE-IGW.id}"
  }
  tags = {
    Name = "TRIPLEKARMELITE-ROUTE1"
  }
}
resource "aws_route_table" "TRIPLEKARMELITE-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.TRIPLEKARMELITE-NAT-GTW.id}"
  }
  tags = {
    Name = "TRIPLEKARMELITE-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "TRIPLEKARMELITE-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.TRIPLEKARMELITE-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.TRIPLEKARMELITE-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "TRIPLEKARMELITE-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.TRIPLEKARMELITE-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.TRIPLEKARMELITE-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "TRIPLEKARMELITE-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.TRIPLEKARMELITE-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.TRIPLEKARMELITE-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "TRIPLEKARMELITE-EIP" {
}
resource "aws_nat_gateway" "TRIPLEKARMELITE-NAT-GTW" {
  allocation_id = "${aws_eip.TRIPLEKARMELITE-EIP.id}"
  subnet_id     = "${aws_subnet.TRIPLEKARMELITE-PUB-SUBNET.id}"
  tags = {
    Name = "TRIPLEKARMELITE-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.TRIPLEKARMELITE-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "TRIPLEKARMELITE-SG-ADMIN" {
        name = "TRIPLEKARMELITE-SG-ADMIN"
        description = "TRIPLEKARMELITE-SG-ADMIN"
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        ingress {
                description = "TRIPLEKARMELITE-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "TRIPLEKARMELITE-SG-ADMIN"
        }
}

resource "aws_security_group" "TRIPLEKARMELITE-SG-REVERSE" {
        name = "TRIPLEKARMELITE-SG1"
        description = "TRIPLEKARMELITE-SG-REVERSE"
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        ingress {
                description = "TRIPLEKARMELITE-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "TRIPLEKARMELITE-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-ADMIN.id}"]
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
                Name = "TRIPLEKARMELITE-SG-REVERSE"
        }
}
resource "aws_security_group" "TRIPLEKARMELITE-SG-PRIV-WEB" {
        name = "TRIPLEKARMELITE-SG-PRIV-WEB"
        description = "TRIPLEKARMELITE-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.TRIPLEKARMELITE-VPC.id}"
        ingress {
                description = "TRIPLEKARMELITE-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-ADMIN.id}"]
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
                Name = "TRIPLEKARMELITE-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7hg9LMLBIMqBZuVZxRqdRQT07tJZahTnoHp5xnBKyrBN3OxCQDlc4KwxndBNJ0UUAJfj/8sFg5A1t315aBuytL+rOpD1J+ixm9nxCnbBYP8O+s3g45uKcaFyqc8BCThiUbtZTZ6urd2Klio9CtmEExLbZXP8mGT89Cqt8En2Nf/ma1jXykifVH72vmmmeLqrIvV1KmB1XSgyJdLmiCXAjVhfA91PSWrge150RpQ5jfDsc8JxTV9rydnk+XBEiwAPIGilcfbxKww46m1JsJ7CNcYPx7QNqwkiR6KP+LNBiz8burKgbDCgh8ptMFNdKGyFT4EqIDJYSWLCXImjOFa12xNb5066e3Uwx9ceZqH3VZX2SZelMRQiS+8kRDd5bA46pRsztXjekYvrSKg2YZtghTEOS+aiGE4WWtGrNUfzwdShdpMtuJLwmu8GfonafH2CoTUs0dclrB/k4Ru+aH0nf2Ir3EqAOHwmJ5Sdn1IUOsATqmxJRe9/mmjrd7qufYwc= jenkins@server"
}


# INSTANCES
resource "aws_instance" "TRIPLEKARMELITE-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.TRIPLEKARMELITE-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-ADMIN.id}"]
        tags = {
                Name = "TRIPLEKARMELITE-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "TRIPLEKARMELITE-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.TRIPLEKARMELITE-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-REVERSE.id}"]
        tags = {
                Name = "TRIPLEKARMELITE-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "TRIPLEKARMELITE-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.TRIPLEKARMELITE-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-PRIV-WEB.id}"]
        tags = {
                Name = "TRIPLEKARMELITE-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "TRIPLEKARMELITE-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.TRIPLEKARMELITE-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-PRIV-WEB.id}"]
        tags = {
                Name = "TRIPLEKARMELITE-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "TRIPLEKARMELITE-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.TRIPLEKARMELITE-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.TRIPLEKARMELITE-SG-PRIV-WEB.id}"]
        tags = {
                Name = "TRIPLEKARMELITE-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


