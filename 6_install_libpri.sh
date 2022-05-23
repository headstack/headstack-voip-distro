#!/bin/bash

### Variables
SRC_DIR=/root/src/

### Install libpri
cd $SRC_DIR && tar -xzf libpri-1.6.0.tar.gz
cd $SRC_DIR/libpri* && make && make install
