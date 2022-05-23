#!/bin/sh
#
# Text Color Variables http://misc.flogisoft.com/bash/tip_colors_and_formatting
tcLtG="\033[00;37m"              # LIGHT GRAY
tcDkG="\033[01;30m"              # DARK GRAY
tcLtR="\033[01;31m"              # LIGHT RED
tcLtGRN="\033[01;32m"            # LIGHT GREEN
tcLtBL="\033[01;34m"             # LIGHT BLUE
tcLtP="\033[01;35m"              # LIGHT PURPLE
tcLtC="\033[01;36m"              # LIGHT CYAN
tcW="\033[01;37m"                # WHITE
tcRESET="\033[0m"                # DROP ALL COLORS
tcORANGE="\033[38;5;209m"        # ORANGE
#

# Time of day
HOUR=$(date +"%H")
if [ $HOUR -lt 12  -a $HOUR -ge 0 ]; then TIME="morning"
elif [ $HOUR -lt 17 -a $HOUR -ge 12 ]; then TIME="day"
else TIME="evening"
fi
#

# System uptime
uptime=`cat /proc/uptime | cut -f1 -d.`
upDays=$((uptime/60/60/24))
upHours=$((uptime/60/60%24))
upMins=$((uptime/60%60))
#

# System + Memory
SYS_LOADS=`cat /proc/loadavg | awk '{print $1}'`
MEMORY_USED=`free -b | grep Mem | awk '{print $3/$2 * 100.0}'`
SWAP_USED=`free -b | grep Swap | awk '{print $3/$2 * 100.0}'`
NUM_PROCS=`ps aux | wc -l`
IPADDRESS=`hostname --all-ip-addresses`
RELEASE=`cat /etc/centos-release`
#

# Check syntax in graph Users
USERS=$(users | wc -w)
if [ $USERS = 1 ]; then USERCOUNT="user"
else USERCOUNT="users"
fi
#

# Check Asterisk status
ASTERISK=$(asterisk -rx "core show version" 2>/dev/null | cut -c 1-8)
if [ "$ASTERISK" = "Asterisk" ]; then ASTRUN=$tcLtC"Running"
else ASTRUN=$tcLtR"Not Running"
fi
#

# Check FreePBX status
FPBX=$(systemctl status freepbx.service | grep "Active:" | awk '{print $2}')
if [ "$FPBX" = "active" ]; then FPBXRUN=$tcLtC"Running"
else FPBXRUN=$tcLtR"Not Running"
fi
#

# Check MariaDB status
MDB=$(systemctl status mariadb.service | grep "Active:" | awk '{print $2}')
if [ "$MDB" = "active" ]; then MDBRUN=$tcLtC"Running"
else MDBRUN=$tcLtR"Not Running"
fi
#

# Check DAHDI status
DAHDI=$(systemctl status dahdi.service | grep "Active:" | awk '{print $2}')
if [ "$DAHDI" = "active" ]; then DAHDIRUN=$tcLtC"Running"
else DAHDIRUN=$tcLtR"Not Running"
fi
#

# Check Apache status
HTTPD=$(systemctl status httpd.service | grep "Active:" | awk '{print $2}')
if [ "$HTTPD" = "active" ]; then HTTPDRUN=$tcLtC"Running"
else HTTPDRUN=$tcLtR"Not Running"
fi
#

# Check OpenVPN status
OVPN=$(systemctl status openvpn@server.service | grep "Active:" | awk '{print $2}')
if [ "$OVPN" = "active" ]; then OVPNRUN=$tcLtC"Running"
else OVPNRUN=$tcLtR"Not Running"
fi
#

# Check Iptables status
IPT=$(systemctl status iptables.service | grep "Active:" | awk '{print $2}')
if [ "$IPT" = "active" ]; then IPTRUN=$tcLtC"Running"
else IPTRUN=$tcLtR"Not Running"
fi
#

# Check IPset status
IPS=$(systemctl status ipset.service | grep "Active:" | awk '{print $2}')
if [ "$IPS" = "active" ]; then IPSRUN=$tcLtC"Running"
else IPSRUN=$tcLtR"Not Running"
fi
#

# Check fail2ban status
F2B=$(systemctl status fail2ban.service | grep "Active:" | awk '{print $2}')
if [ "$F2B" = "active" ]; then F2BRUN=$tcLtC"Running"
else F2BRUN=$tcLtR"Not Running"
fi
#

# Check postfix status
PSX=$(systemctl status postfix.service | grep "Active:" | awk '{print $2}')
if [ "$PSX" = "active" ]; then PSXRUN=$tcLtC"Running"
else PSXRUN=$tcLtR"Not Running"
fi
#

# OUTPUT
echo -e $tcDkG "==============================================================="
echo -e $tcLtG "$tcLtC>_ HeadStack Ltd.                                 Good $TIME!"
echo -e $tcDkG "==============================================================="
echo -e $tcLtG " - Hostname      :$tcW `hostname -f`"
echo -e $tcLtG " - IP Address    :$tcW $IPADDRESS"
echo -e $tcLtG " - Release       :$tcW $RELEASE"
echo -e $tcLtG " - Kernel        : `uname -a | awk '{print $1" "$3" "$12}'`"
echo -e $tcLtG " - Users         : Currently $USERS $USERCOUNT logged on"
echo -e $tcLtG " - Server Time   : `date`"
echo -e $tcLtG " - System load   : $SYS_LOADS / $NUM_PROCS processes running"
echo -e $tcLtG " - Memory used   : $MEMORY_USED %"
echo -e $tcLtG " - Swap used     : $SWAP_USED %"
echo -e $tcLtG " - Asterisk      : $ASTRUN"
echo -e $tcLtG " - FreePBX       : $FPBXRUN"
echo -e $tcLtG " - DAHDI         : $DAHDIRUN"
echo -e $tcLtG " - MariaDB       : $MDBRUN"
echo -e $tcLtG " - Apache        : $HTTPDRUN"
echo -e $tcLtG " - Postfix       : $PSXRUN"
echo -e $tcLtG " - OpenVPN       : $OVPNRUN"
echo -e $tcLtG " - IPtables      : $IPTRUN"
echo -e $tcLtG " - IPset         : $IPSRUN"
echo -e $tcLtG " - Fail2Ban      : $F2BRUN"
echo -e $tcLtG " - System uptime : $upDays days $upHours hours $upMins minutes"
echo -e $tcDkG "==============================================================="
echo -e $tcLtG "$tcW Tech Supp contacts:"
echo -e $tcLtG " website: https://headstack.ru"
echo -e $tcLtG " e-mail:  team@headstack.ru"
echo -e $tcLtG " phone:   +79856635077"
echo -e $tcRESET ""
#
