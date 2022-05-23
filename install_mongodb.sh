#!/bin/bash

#Unpack this bullshit
cd /root/src/
tar -xf mongodb-linux-x86_64-rhel70-4.2.5.tgz

#Move binaries to %PATH
mv /root/src/mongodb-linux-x86_64-rhel70-4.2.5/bin/* /usr/local/bin/

#Creating directories
mkdir -p /var/log/mongodb
mkdir -p /var/lib/mongo

#Chowning directories
chown asterisk.asterisk /var/log/mongodb
chown asterisk.asterisk /var/lib/mongo

#Start
/usr/local/bin/mongod --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork
sleep 1

#Enable from start
systemctl enable mongod
