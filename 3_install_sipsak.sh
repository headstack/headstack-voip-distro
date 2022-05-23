#!/bin/bash

### Variables
SRC_DIR=/root/src/

### Install sipsak
cd $SRC_DIR && tar -xzf sipsak-0.9.7.tar.gz
cd $SRC_DIR/sipsak-* && ./configure && make && make install
