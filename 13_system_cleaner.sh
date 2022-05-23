#!/bin/bash

# Get ip
IPADDR=`wget -qO- icanhazip.com`
PROV=`curl -s https://www.whoismyisp.org | grep -oP -m1 '(?<=isp">).*(?=</p)'`
GEO=`wget -qO- https://ipvigilante.com/$IPADDR | sed 's/",/",\n/g'`

# Get date
STAMP=`date '+%Y.%m.%d_%H:%M:%S'`
DA=`date '+%Y.%m.%d'`
TI=`date '+%H:%M:%S'`

# Entering in inst dir
cd /root/

# Make dir and mooving logs in prepared dir
mkdir -p /root/anaconda/post_logs/
mv /root/nch-post.log /root/ch-post.log /root/0_prep_inst_source.log /root/anaconda/post_logs/
mv /root/init/logs/* /root/anaconda/post_logs/

# Delete init dir
rm -rf /root/init/

# Entering src dir
cd /root/src/

# Moving some needed sources in /usr/src/
cp /root/src/asterisk-16-current.tar.gz /usr/src/
cp /root/src/dahdi-linux-complete-2.10.0+2.10.0.tar.gz /usr/src/
cp -r /root/src/asterisk-16.9.0 /usr/src/
cp -r /root/src/dahdi-linux-complete-2.10.0+2.10.0 /usr/src/

# Remove src dir
rm -rf /root/src/

#Touch datestamp
touch /root/anaconda/datetimestamp_$STAMP

# Pack logs
cd /root/
zip anaconda_logs_$IPADDR.zip /root/anaconda/* /root/anaconda/post_logs/*

# Sent logs to email
echo -e "HeadStack Distro has been installed.\nSending logs in attachement.\n\nInstall date: $DA\n\nInstall time: $TI\n\nFrom ip: $IPADDR\n\nInternet provider: $PROV\n\nAdvanced information: $GEO" | mail -s "[HeadStack] Distro has been installed from: $IPADDR" -a /root/anaconda_logs*.zip r.ponkrashov@headstack.ru

# Last clear
rm -f /root/anaconda_logs*.zip
rm -rf /root/anaconda/
