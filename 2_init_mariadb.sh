#!/bin/bash

# Install MariaDB ODBC connector
echo -e "Installation MariaDB ODBC connector in progress..."
cd /root/src/
mkdir odbc_package
mv mariadb-connector-odbc-3.1.7-ga-rhel7-x86_64.tar.gz odbc_package/
cd odbc_package/
tar -xf mariadb-connector-odbc-3.1.7-ga-rhel7-x86_64.tar.gz
install lib64/libmaodbc.so /usr/lib64/
install -d /usr/lib64/mariadb/
install -d /usr/lib64/mariadb/plugin/
install lib64/mariadb/plugin/auth_gssapi_client.so /usr/lib64/mariadb/plugin/
install lib64/mariadb/plugin/caching_sha2_password.so /usr/lib64/mariadb/plugin/
install lib64/mariadb/plugin/client_ed25519.so /usr/lib64/mariadb/plugin/
install lib64/mariadb/plugin/dialog.so /usr/lib64/mariadb/plugin/
install lib64/mariadb/plugin/mysql_clear_password.so /usr/lib64/mariadb/plugin/
install lib64/mariadb/plugin/sha256_password.so /usr/lib64/mariadb/plugin/
echo -e "\n"

# Rewrite config odbcinst.ini
echo -e "Rewrite odbcinst.ini config file in progress..."
echo -e "\n"

cat <<'EOF123' > /etc/odbcinst.ini
# Example driver definitions

# Driver from the postgresql-odbc package
# Setup from the unixODBC package
[PostgreSQL]
Description     = ODBC for PostgreSQL
Driver          = /usr/lib/psqlodbcw.so
Setup           = /usr/lib/libodbcpsqlS.so
Driver64        = /usr/lib64/psqlodbcw.so
Setup64         = /usr/lib64/libodbcpsqlS.so
FileUsage       = 1


# Driver from the mysql-connector-odbc package
# Setup from the unixODBC package
[MySQL]
Description     = ODBC for MariaDB
#Driver         = /usr/lib/libmaodbc.so
#Setup          = /usr/lib/libodbcmyS.so
Driver64        = /usr/lib64/libmaodbc.so
Setup64         = /usr/lib64/libodbcmyS.so
FileUsage       = 1
UsageCount      = 1
EOF123

# Start MariaDB Server
echo -e "MariaDB Server start in progress..."
echo -e "\n"
/usr/bin/mariadbd-safe --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib64/mysql/plugin --user=mysql --log-error=/var/lib/mysql/mariadb.err --pid-file=mariadb.pid --socket=/var/lib/mysql/mysql.sock --nowatch
