#!/bin/bash

### Variables
SRC_DIR=/root/src/

### Install dahdi
cd $SRC_DIR && tar -xzf dahdi-linux-complete-2.10.0+2.10.0.tar.gz
cd $SRC_DIR/dahdi* && make all && make install && make config && ldconfig
sed -i 's/^\(w.*\)/#\1/; s/^\(x.*\)/#\1/' /etc/dahdi/modules
chkconfig dahdi on
