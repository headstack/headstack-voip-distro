#!/bin/bash
### Configure logrotate format
cat <<'EOF123' >> /etc/asterisk/logger_general_custom.conf
dateformat=%F %T
appendhostname=no
queue_log=yes
rotatestrategy=timestamp
EOF123

### Configure asterisk logfiles
cat <<'EOF123' >> /etc/asterisk/logger_logfiles_custom.conf
console => error,notice,warning,dtmf,fax
full => debug,error,notice,verbose,warning,fax,dtmf
security => error,notice,warning,security
EOF123

### Configure log rotation in system
touch /etc/logrotate.d/asterisk
cat <<'EOF123' >> /etc/logrotate.d/asterisk
/var/log/asterisk/messages
/var/log/asterisk/debug
/var/log/asterisk/error
/var/log/asterisk/backup.log
/var/log/asterisk/core-fastagi_err.log
/var/log/asterisk/core-fastagi_out.log
/var/log/asterisk/h323_log
/var/log/asterisk/ucp_err.log
/var/log/asterisk/ucp_out.log
/var/log/asterisk/console {
        su asterisk asterisk
        daily
        missingok
        rotate 15
        notifempty
        compress
        sharedscripts
        create 0640 asterisk asterisk
        postrotate
        /usr/sbin/fwconsole chown
        /usr/sbin/fwconsole reload
        endscript
}
/var/log/asterisk/security
/var/log/asterisk/full {
        su asterisk asterisk
        daily
        missingok
        rotate 40
        notifempty
        compress
        sharedscripts
        create 0640 asterisk asterisk
        postrotate
        /usr/sbin/fwconsole chown
        /usr/sbin/fwconsole reload
        endscript
}
/var/log/asterisk/freepbx.log
/var/log/asterisk/freepbx_security.log
/var/log/asterisk/queue_log {
        su asterisk asterisk
        daily
        missingok
        rotate 30
        notifempty
        compress
        sharedscripts
        create 0640 asterisk asterisk
        postrotate
        /usr/sbin/fwconsole chown
        /usr/sbin/fwconsole reload
        endscript
}
EOF123

### Write aliases in config
cat <<'EOF123' > /etc/asterisk/cli_aliases.conf
[general]
template = basic_aliases

[basic_aliases]
ch=core show channels verbose
chc=core show channels concise
csu=core show uptime
ssp=sip show peers
ssr=sip show registry
ssd=sip set debug
rsd=rtp set debug
isp=iax2 show peers
isr=iax2 show registry
dapp=core show application
dapps=core show applications
dfun=core show function
dfuns=core show functions
dreload=dialplan reload
p=sip show peers
pp=sip show peer
r=sip show registry
u=core show calls uptime
EOF123

#Enable module for asterisk aliases
sed -i '/noload = res_clialiases.so/d' /etc/asterisk/modules.conf
sed -i '/^$/d' /etc/asterisk/modules.conf
echo 'load = res_clialiases.so' >> /etc/asterisk/modules.conf

fwconsole chown
fwconsole reload
