#!/bin/bash

### Edit /etc/php.ini
# Max upload filesize:
sed -i 's/^\(upload_max_filesize = \).*/\1256M/' /etc/php.ini
# Time:
sed -i 's/\(date.timezone =\).*/\1 Europe\/Moscow/' /etc/php.ini
# Memory limit:
sed -i 's/^\(memory_limit\).*/\1 = 256M/' /etc/php.ini
# Post max filesize:
sed -i 's/\(^post_max_size = \).*/\1256M/' /etc/php.ini
#!#

### Edit /etc/httpd/conf/httpd.conf
# User and group for startup httpd:
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
# Add FQDN for sucsessfully resolve
#sed -i 's/^#\(ServerName\).*/\1 headstack:80/' /etc/httpd/conf/httpd.conf
# Override's httpd allow:
sed -i 's/\(AllowOverride\).*/\1 All/' /etc/httpd/conf/httpd.conf
#!#

### Make tmp dir for cetrs
mkdir ~/certs && cd ~/certs

### Generating private key on 2048 bit
openssl genrsa -out ca.key 2048

### Generating request on cert CSR
openssl req -new -key ca.key -out ca.csr -subj "/C=RU/ST=MO/L=Moscow/O=HeadStack/OU=VoIP Department/CN=headstack.local/CN=headstack/emailAddress=r.ponkrashov@headstack.ru"

### Generating self-signed key
openssl x509 -req -days 1461 -in ca.csr -signkey ca.key -out ca.crt

### Mooving certs to target folder
mv ca.crt /etc/pki/tls/certs
mv ca.key /etc/pki/tls/private/ca.key
mv ca.csr /etc/pki/tls/private/ca.csr

### Remove tmp dir for cetrs
rm -rf ~/certs

### Configure redirect HTTP -> HTTPS
cat <<'EOF123' >> /etc/httpd/conf.d/fpbxadm.conf
<VirtualHost *:443>
    ServerName site.ru
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/ca.crt
    SSLCertificateKeyFile /etc/pki/tls/private/ca.key
</VirtualHost>

#<VirtualHost *:80>
#    ServerName site.ru
#    RewriteEngine On
#    RewriteCond %{HTTPS} off
#    RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
#</VirtualHost>
EOF123

cat <<'EOF123' >> /var/www/html/.htaccess

RewriteCond %{SERVER_PORT} ^80$
RewriteRule ^.*$ https://%{SERVER_NAME}%{REQUEST_URI} [R=301,L]
EOF123

### Start like a demon httpd
/usr/sbin/httpd -k start

### Enable for systemd
systemctl enable httpd
