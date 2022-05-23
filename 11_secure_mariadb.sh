#!/bin/bash

#Secure MariaDB Server after installation all production services

echo -e "Securing MariaDB Server in progress..."
printf "\n n\n y\n lance1\n lance1\n y\n y\n y\n y\n" | /usr/bin/mysql_secure_installation
sleep 3
systemctl enable mariadb
