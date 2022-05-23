#!/bin/bash

# Do some manipulations for delivery mail from server
sed -i 's/inet_protocols = all/inet_protocols = ipv4/' /etc/postfix/main.cf
sed -i 's/#myhostname = host.domain.tld/myhostname = headstack.localhost.localdomain/' /etc/postfix/main.cf
sed -i 's/#myorigin = $myhostname/myorigin = headstack.localhost.localdomain/' /etc/postfix/main.cf
sed -i 's/mydestination = $myhostname, localhost.$mydomain, localhost/mydestination = $myhostname, headstack.localdomain, headstack, localhost.localdomain, localhost/' /etc/postfix/main.cf

# Read config
postmap /etc/postfix/main.cf

# Start postfix
/usr/sbin/postfix start

# Enable service to startup
systemctl disable postfix
systemctl enable postfix
