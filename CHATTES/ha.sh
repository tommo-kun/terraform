#!/bin/bash
yum update
yum install -y haproxy	 
systemctl enable --now haproxy
exit
