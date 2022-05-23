#!/bin/bash

### Variables
SRC_DIR=/root/src/

### Install libedit
cd $SRC_DIR && tar -xzf libedit-20190324-3.1.tar.gz
cd $SRC_DIR/libedit-* && ./configure && make && make install && cd $SRC_DIR
