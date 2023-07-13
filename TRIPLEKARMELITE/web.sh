#!/bin/bash
yum update
yum install -y httpd git
systemctl enable --now httpd
cat /etc/hostname > /var/www/html/index.html
exit
