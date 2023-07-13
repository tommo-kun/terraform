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
resource "aws_vpc" "INSTAGRAM-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "INSTAGRAM-VPC"
        }
}

# SUBNETS
resource "aws_subnet" "INSTAGRAM-PUB-SUBNET" {
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "INSTAGRAM-PUB-SUBNET"
	}
}
resource "aws_subnet" "INSTAGRAM-PRIV-SUBNET1" {
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone_id = "euw3-az1"
	tags = {
                Name = "INSTAGRAM-PRIV-SUBNET1"
        }
}
resource "aws_subnet" "INSTAGRAM-PRIV-SUBNET2" {
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        cidr_block = "10.0.3.0/24"
	availability_zone_id = "euw3-az2"
        tags = {
                Name = "INSTAGRAM-PRIV-SUBNET2"
        }
}
resource "aws_subnet" "INSTAGRAM-PRIV-SUBNET3" {
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone_id = "euw3-az3"
	tags = {
                Name = "INSTAGRAM-PRIV-SUBNET3"
        }
}

# Internet GTW 
resource "aws_internet_gateway" "INSTAGRAM-IGW" {
}
resource "aws_internet_gateway_attachment" "INSTAGRAM-IGW-ATTACHMENT" {
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.INSTAGRAM-IGW.id}"
}

# ROUTE TABLES
resource "aws_route" "INSTAGRAM-ROUTE-DEFAULT" {
        route_table_id = "${aws_vpc.INSTAGRAM-VPC.main_route_table_id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.INSTAGRAM-IGW.id}"
        depends_on = [
                aws_internet_gateway_attachment.INSTAGRAM-IGW-ATTACHMENT
        ]
}
resource "aws_route_table" "INSTAGRAM-ROUTE-PUB" {
  vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.INSTAGRAM-IGW.id}"
  }
  tags = {
    Name = "INSTAGRAM-ROUTE1"
  }
}
resource "aws_route_table" "INSTAGRAM-ROUTE-PRIV" {
  vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.INSTAGRAM-NAT-GTW.id}"
  }
  tags = {
    Name = "INSTAGRAM-ROUTE-PRIV"
  }
}
resource "aws_route_table_association" "INSTAGRAM-RTB-ASSOC1" {
  route_table_id = "${aws_route_table.INSTAGRAM-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.INSTAGRAM-PRIV-SUBNET1.id}"
}
resource "aws_route_table_association" "INSTAGRAM-RTB-ASSOC2" {
  route_table_id = "${aws_route_table.INSTAGRAM-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.INSTAGRAM-PRIV-SUBNET2.id}"
}
resource "aws_route_table_association" "INSTAGRAM-RTB-ASSOC3" {
  route_table_id = "${aws_route_table.INSTAGRAM-ROUTE-PRIV.id}"
  subnet_id = "${aws_subnet.INSTAGRAM-PRIV-SUBNET3.id}"
}


# NAT GTW
resource "aws_eip" "INSTAGRAM-EIP" {
}
resource "aws_nat_gateway" "INSTAGRAM-NAT-GTW" {
  allocation_id = "${aws_eip.INSTAGRAM-EIP.id}"
  subnet_id     = "${aws_subnet.INSTAGRAM-PUB-SUBNET.id}"
  tags = {
    Name = "INSTAGRAM-NAT-GTW"
  }
    depends_on = [aws_internet_gateway.INSTAGRAM-IGW]
}

# SECURITY GROUPS
resource "aws_security_group" "INSTAGRAM-SG-ADMIN" {
        name = "INSTAGRAM-SG-ADMIN"
        description = "INSTAGRAM-SG-ADMIN"
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        ingress {
                description = "INSTAGRAM-SG1-ALLOW-SSH-FROM-EXT"
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
                Name = "INSTAGRAM-SG-ADMIN"
        }
}

resource "aws_security_group" "INSTAGRAM-SG-REVERSE" {
        name = "INSTAGRAM-SG1"
        description = "INSTAGRAM-SG-REVERSE"
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        ingress {
                description = "INSTAGRAM-SG-ALLOW-WEB"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                ipv6_cidr_blocks = []
        }
	ingress {
                description = "INSTAGRAM-SG-REVERSE-ALLOW-SSH-FROM-ADMIN"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.INSTAGRAM-SG-ADMIN.id}"]
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
                Name = "INSTAGRAM-SG-REVERSE"
        }
}
resource "aws_security_group" "INSTAGRAM-SG-PRIV-WEB" {
        name = "INSTAGRAM-SG-PRIV-WEB"
        description = "INSTAGRAM-SG-PRIV-WEB"
        vpc_id = "${aws_vpc.INSTAGRAM-VPC.id}"
        ingress {
                description = "INSTAGRAM-SG-ALLOW-WEB-TO-REVERSE"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = ["${aws_security_group.INSTAGRAM-SG-REVERSE.id}"]
		ipv6_cidr_blocks = []
        }
	ingress {
		description = "ALLOW-SSH-FROM-ADMIN-TO-PRIV"	
		from_port = 22
                to_port = 22
                protocol = "tcp"
                security_groups = ["${aws_security_group.INSTAGRAM-SG-ADMIN.id}"]
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
                Name = "INSTAGRAM-SG-PRIV-WEB"
        }
}
# SSH KEY FOR PRIV INSTANCES
resource "aws_key_pair" "KEY-PRIV-TO-PUB" {
  key_name   = "KEY-PRIV-TO-PUB"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvuWRTsoth8L52Bag+0iBXZhKBkkVi7fyHOaffc0bhb0jRTHXUrfDz82wuP/bMoK1ihtX+du+jm2L3xh5/h+cvGSBv1rhrJJLg3W7IcRd14aR665C/PdMp0FtI0eF+Ghnu/uxBTeJtXugOdSMN11kyWVvMK8Vqk3jDj1+Rhhf/k+DdtIC6+/RQAQw5YkI2ROP3VoKYirKpwkG1cnc+0lv6d3DGun8S1NnOo9NduEMt5oTHQKRHKlMbSETTWLfxaR4Gq63mvNOOI+HgYh7MEXHRvSMp+zA0l2shlGXIUfJKoh2Krajq2rAChFUY4oIGC7sPAfpSHzsxQSOwbADJrM6vQRCVFFGlZbVdNDk8k5+5v3iQX3id9//foc2NKEZx6lvo6mSr2unygA9U2PqeGM+yMaOVlgcb7mvEZSGeWXsXqTm9uc3O7C5/5bXyuPs8nMwQHHHnwjq+jTQwEpDNY/4zHEzcvd+rBxLwsI88H4ebyDX5s0teXPd3JyGxx4WHEaM= jenkins@server"
}


# INSTANCES
resource "aws_instance" "INSTAGRAM-INSTANCE-ADMIN" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.INSTAGRAM-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "TSIEUDAT-KEYSSH"
        security_groups = ["${aws_security_group.INSTAGRAM-SG-ADMIN.id}"]
        tags = {
                Name = "INSTAGRAM-INSTANCE-ADMIN"
        }
	provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}
resource "aws_instance" "INSTAGRAM-INSTANCE-REVERSE" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.INSTAGRAM-PUB-SUBNET.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = true
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.INSTAGRAM-SG-REVERSE.id}"]
        tags = {
                Name = "INSTAGRAM-INSTANCE-REVERSE"
        }
        provisioner "local-exec" {
                command = "echo ${self.public_ip} > public_ip1"
        }
}

resource "aws_instance" "INSTAGRAM-INSTANCE-PRIV1" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.INSTAGRAM-PRIV-SUBNET1.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.INSTAGRAM-SG-PRIV-WEB.id}"]
        tags = {
                Name = "INSTAGRAM-INSTANCE-PRIV1"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv1"
        }
}
resource "aws_instance" "INSTAGRAM-INSTANCE-PRIV2" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.INSTAGRAM-PRIV-SUBNET2.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.INSTAGRAM-SG-PRIV-WEB.id}"]
        tags = {
                Name = "INSTAGRAM-INSTANCE-PRIV2"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv2"
        }
}
resource "aws_instance" "INSTAGRAM-INSTANCE-PRIV3" {
        ami = "ami-0f61de2873e29e866"
        subnet_id = "${aws_subnet.INSTAGRAM-PRIV-SUBNET3.id}"
        instance_type = "t2.micro"
        associate_public_ip_address = false
        key_name = "${aws_key_pair.KEY-PRIV-TO-PUB.key_name}"
        security_groups = ["${aws_security_group.INSTAGRAM-SG-PRIV-WEB.id}"]
        tags = {
                Name = "INSTAGRAM-INSTANCE-PRIV3"
        }
        user_data = "${file("web.sh")}"
        provisioner "local-exec" {
                command = "echo ${self.private_ip} > private_ippriv3"
        }
}


