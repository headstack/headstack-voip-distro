#!/bin/bash

### Prepare directory in a installed system # ------------------------------------------------------------------------------------------
mkdir -p /mnt/sysimage/root/init/logs/
mkdir -p /mnt/sysimage/root/src/
mkdir -p /mnt/sysimage/usr/libexec/ipset/ /mnt/sysimage/etc/ipset/
# ------------------------------------------------------------------------------------------

### Move configs # ------------------------------------------------------------------------------------------

#Move prepared bashrc
cat /run/install/repo/init_scripts/configs/.bashrc > /mnt/sysimage/root/.bashrc

#Move ssh pre-authenticaion banner
cp /run/install/repo/init_scripts/configs/issue.net /mnt/sysimage/etc/

#Move firewall script
cp /run/install/repo/init_scripts/syscripts/fw_iptables.sh /mnt/sysimage/root/

#Move HeadStack motd script
cp /run/install/repo/init_scripts/syscripts/dynmotd.sh /mnt/sysimage/usr/local/sbin/

#Move ipset configs
cp /run/install/repo/init_scripts/configs/ipset.service /mnt/sysimage/usr/lib/systemd/system/
cp /run/install/repo/init_scripts/configs/ipset.start-stop /mnt/sysimage/usr/libexec/ipset/
cp /run/install/repo/init_scripts/configs/ipset /mnt/sysimage/etc/ipset/

#Move FreePBX configs
cp /run/install/repo/init_scripts/configs/freepbx.service /mnt/sysimage/etc/systemd/system/

#Move init scripts
cp /run/install/repo/init_scripts/services/* /mnt/sysimage/root/init/

#Move fail2ban configs
yes | cp /run/install/repo/init_scripts/configs/fail2ban_extras/jail.local /mnt/sysimage/etc/fail2ban/
yes | cp /run/install/repo/init_scripts/configs/fail2ban_extras/freepbx-auth.conf /mnt/sysimage/etc/fail2ban/filter.d/
yes | cp /run/install/repo/init_scripts/configs/fail2ban_extras/asterisk.conf /mnt/sysimage/etc/fail2ban/filter.d/
yes | cp /run/install/repo/init_scripts/configs/fail2ban_extras/openvpn.conf /mnt/sysimage/etc/fail2ban/filter.d/

#Move mdb script
cp /run/install/repo/init_scripts/syscripts/mdb /mnt/sysimage/usr/bin/

#Move sendEmail script
cp /run/install/repo/init_scripts/syscripts/sendEmail.pl /mnt/sysimage/usr/local/bin/

#Move delete_old_rec.sh to cron
cp /run/install/repo/init_scripts/syscripts/delete_old_rec.sh /mnt/sysimage/etc/cron.weekly/

#Move ha agents to target dir
cp /run/install/repo/sources/ha_ext/* /mnt/sysimage/usr/lib/ocf/resource.d/heartbeat/

# ------------------------------------------------------------------------------------------

### Move pkgs # ------------------------------------------------------------------------------------------

#MariaDB-connector-ODBC
cp /run/install/repo/sources/mariadb-connector-odbc-3.1.7-ga-rhel7-x86_64.tar.gz /mnt/sysimage/root/src/

#Asterisk
cp /run/install/repo/sources/asterisk-16-current.tar.gz /mnt/sysimage/root/src/
cp -r /run/install/repo/sources/mp3/ /mnt/sysimage/root/src/

#Dahdi
cp /run/install/repo/sources/dahdi-linux-complete-2.10.0+2.10.0.tar.gz /mnt/sysimage/root/src/

#FreePBX
cp /run/install/repo/sources/freepbx-15.0-latest.tgz /mnt/sysimage/root/src/
cp /run/install/repo/sources/freepbx_extras.tar.gz /mnt/sysimage/root/src/
cp /run/install/repo/sources/clear_modules.tar.gz /mnt/sysimage/root/src/
cp /run/install/repo/sources/moh.tar.gz /mnt/sysimage/root/src/

#Asterisk libs
cp /run/install/repo/sources/libedit-20190324-3.1.tar.gz /mnt/sysimage/root/src/
cp /run/install/repo/sources/libpri-1.6.0.tar.gz /mnt/sysimage/root/src/
cp /run/install/repo/sources/sipsak-0.9.7.tar.gz /mnt/sysimage/root/src/
cp /run/install/repo/sources/jansson-2.12.tar.bz2 /mnt/sysimage/tmp/
cp /run/install/repo/sources/pjproject-2.9.tar.bz2 /mnt/sysimage/tmp/
# ------------------------------------------------------------------------------------------
