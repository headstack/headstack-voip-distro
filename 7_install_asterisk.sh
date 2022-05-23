#!/bin/bash

### Variables
SRC_DIR=/root/src/

### Add asterisk user
useradd -m asterisk

### Install asterisk
cd $SRC_DIR && tar -xzvf asterisk-16-current.tar.gz && cd $SRC_DIR/asterisk-16.* && \
cp -r /root/src/mp3/ /root/src/asterisk-16.9.0/addons/ && sed -i -e '/#include "asterisk.h"/i#define ASTMM_LIBC ASTMM_REDIRECT' /root/src/asterisk-16.9.0/addons/mp3/interface.c && \
./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled --with-crypto --with-ssl=ssl --with-srtp && \
make menuselect.makeopts && menuselect/menuselect --disable-category MENUSELECT_CORE_SOUNDS --disable-category MENUSELECT_EXTRA_SOUNDS --disable-category MENUSELECT_MOH \
--disable chan_skinny --disable chan_unistim --disable app_getcpeid --disable res_config_mysql --disable app_mysql --disable cdr_mysql \
--enable chan_ooh323 --enable format_mp3  \
--enable app_meetme --enable app_saycounted --enable app_statsd --enable app_macro --enable app_skel --enable app_ivrdemo \
--enable cdr_syslog \
--enable res_ari_mailboxes --enable res_mwi_external --enable res_mwi_external_ami --enable res_stasis_mailbox --enable res_chan_stats \
--enable res_corosync --enable res_endpoint_stats \
--enable res_pktccops --enable res_remb_modifier --enable res_snmp --enable res_snmp --enable res_statsd \
--enable conf_bridge_binaural_hrir_importer && \
 make && make install && make config && ldconfig && make samples

### Moving samples in some dir
mkdir /etc/asterisk/conf_samples
cp /etc/asterisk/* /etc/asterisk/conf_samples/

### Change news in configs for FPBX
cat <<'EOF123' > /etc/asterisk/asterisk.conf
[directories](!)
astetcdir => /etc/asterisk
astmoddir => /usr/lib64/asterisk/modules
astvarlibdir => /var/lib/asterisk
astdbdir => /var/lib/asterisk
astkeydir => /var/lib/asterisk
astdatadir => /var/lib/asterisk
astagidir => /var/lib/asterisk/agi-bin
astspooldir => /var/spool/asterisk
astrundir => /var/run/asterisk
astlogdir => /var/log/asterisk
astsbindir => /usr/sbin

[options]
transmit_silence_during_record = yes
languageprefix=yes
execincludes=yes
dontwarn=yes
runuser = asterisk
rungroup = asterisk

[files]
astctlpermissions = 0660
astctlowner = root
astctlgroup = apache
astctl = asterisk.ctl
EOF123

cat <<'EOF123' > /etc/asterisk/cdr.conf
[general]
enable=yes
unanswered = yes
congestion = yes
EOF123

### Removing some files
rm -f /etc/asterisk/cdr_beanstalkd.conf /etc/asterisk/cdr_custom.conf /etc/asterisk/cdr_manager.conf /etc/asterisk/cdr_mysql.conf /etc/asterisk/cdr_odbc.conf /etc/asterisk/cdr_pgsql.conf /etc/asterisk/cdr_sqlite3_custom.conf /etc/asterisk/cdr_syslog.conf /etc/asterisk/cdr_tds.conf

rm -f /etc/odbc.ini

### Remove Asterisk from autoload
systemctl disable asterisk

### Change permissions for asterisk user
chown -R asterisk.asterisk /var/www/html
chown -R asterisk.asterisk /var/lib/php/session
chown -R root.asterisk /var/lib/php/wsdlcache
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/{lib,log,spool,run}/asterisk
chown -R asterisk.asterisk /usr/{lib,lib64}/asterisk
chown -R asterisk:asterisk /var/spool/mqueue/
