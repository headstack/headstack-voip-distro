#!/bin/bash

### Variables
SRC_DIR=/root/src/

### Prepare for installation

### Prepare Music On Hold
tar -C /var/lib/asterisk/ -xzf $SRC_DIR/moh.tar.gz

### Unpack FreePBX
cd $SRC_DIR && tar -xf freepbx-15.0-latest.tgz

### Unpack FreePBX modules in installdir FPBX
tar -xzf /root/src/clear_modules.tar.gz
yes | cp -r /root/src/modules/* /root/src/freepbx/amp_conf/htdocs/admin/modules/

### Unpack extra files for nice installation of the FreePBX
tar -C /var/www/ -xzf /root/src/freepbx_extras.tar.gz

### Chowning directories
chown -R asterisk.asterisk /var/www/html/
chown -R asterisk.asterisk /root/src/freepbx/
chown -R asterisk.asterisk /var/lib/asterisk/

### And now we got to configure some options on installation PHP scripts and disabling updates
cd $SRC_DIR/freepbx
sed -i 's|https://mirror\.freepbx\.org|http://127.0.0.1|' ./installlib/installer.class.php
sed -i 's|http://mirror\.freepbx\.org|http://127.0.0.1|' ./upgrades/2.10.0rc1/migration.php
sed -i 's|http://mirror1\.freepbx\.org,http://mirror2\.freepbx\.org|http://127.0.0.1|' ./upgrades/2.10.0rc1/migration.php

### Installation
cd $SRC_DIR/freepbx
./start_asterisk start
./install -n

### After installation we need to unpack copy tarball's with sound files in tmp dir and unpack it on ru directory. Later we populating database and all done to be work
mkdir /var/lib/asterisk/sounds/ru
cp /var/www/html/sounds/asterisk-core-sounds-ru-ulaw-1.5.tar.gz /var/lib/asterisk/sounds/tmp/
cp /var/www/html/sounds/asterisk-core-sounds-ru-g722-1.5.tar.gz /var/lib/asterisk/sounds/tmp/
cp /var/www/html/sounds/freepbx-module-sounds-ru-ulaw-1.5.0.tar.gz /var/lib/asterisk/sounds/tmp/
cp /var/www/html/sounds/freepbx-module-sounds-ru-g722-1.5.0.tar.gz /var/lib/asterisk/sounds/tmp/
tar -C /var/lib/asterisk/sounds/ru/ -xzf /var/www/html/sounds/asterisk-core-sounds-ru-ulaw-1.5.tar.gz
tar -C /var/lib/asterisk/sounds/ru/ -xzf /var/www/html/sounds/asterisk-core-sounds-ru-g722-1.5.tar.gz
tar -C /var/lib/asterisk/sounds/ru/ -xzf /var/www/html/sounds/freepbx-module-sounds-ru-ulaw-1.5.0.tar.gz
tar -C /var/lib/asterisk/sounds/ru/ -xzf /var/www/html/sounds/freepbx-module-sounds-ru-g722-1.5.0.tar.gz

### Here we move HeadStack Brand images in needed directory for FreePBX interface is be so beautiful. And we need to clean little bit.
mv /var/www/images/* /var/www/html/admin/images/
rm -rf /var/www/images/

### Reload FreePBX settings
fwconsole reload

### Enable freepbx.service in systemd
systemctl enable freepbx.service
