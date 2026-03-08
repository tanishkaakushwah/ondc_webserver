#!/bin/bash

apt update -y
apt install nginx -y

systemctl start nginx
systemctl enable nginx

echo "ONDC DevOps Assignment Running Successfully 🚀 | By Tanishka - DevOps Engineer" > /var/www/html/index.html