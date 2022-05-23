#!/bin/bash

### Disabling ipv6 on hot for all interfaces before system not be rebooted. In kickstart ipv6 disabled in bootloader append options
sysctl net.ipv6.conf.all.disable_ipv6=1
sysctl net.ipv6.conf.default.disable_ipv6=1

### Add Example of static network iface configuration
touch /etc/sysconfig/network-scripts/example_ifcfg_static
cat <<'EOF123' > /etc/sysconfig/network-scripts/example_ifcfg_static
#Uncomment this if needed static configuration
#To get the UUID of a network card, run uuidgen <netface>
#ONBOOT="yes"
#IPV6INIT="no"
#TYPE="Ethernet"
#DEVICE=""
#BOOTPROTO="none"
#DNS1=""
#IPADDR=""
#NETMASK=""
#GATEWAY=""
#UUID=""
#HWADDR=""
#DEFROUTE="yes"
EOF123

### Prepare SSH for nicelly job
#Make directory for authorized keys
mkdir -p /root/.ssh
#Write pub keys in file
cat <<'EOF123' > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlTzvd1IpKdlpXO9yd48dt+UiNMochSK61iCBAyxRfeNWBkfgqvfGC4BgXJotBVe+ZOE4xhTl7SZ2ZjHOJ8/jlwr8tuBAAY8owVy1I8A51jsOS7w6huCBglc5eY40eJ6x3u1bX45BoJLLa8x5KZKsYdsKsD5XiXWoIdjMa4bd5u5PdxN1v1H53/eZlzI2AQuPJnLiWroZieXMC43qopHuRhyeLyNMovb0ZxaieMmtHdgiETuIuT3TqomS222Z4ks6PBmJFOPLxfMAFbBgGpnmwrGtTgfx5RtnMZ8PSS1Vx8MOR6GxNwdfGLytgDLy7ZwuZihgWwnNsEaaVVOrQWugTQ== r.ponkrashov@headstack.ru
EOF123
#Edit sshd_config
sed -i 's/^#\(PubkeyAuthentication yes\).*/\1/' /etc/ssh/sshd_config
sed -i 's/\(^GSSAPIAuthentication\).*/\1 no/' /etc/ssh/sshd_config
sed -i 's/^#\(GSSAPIStrictAcceptorCheck\).*/\1 no/' /etc/ssh/sshd_config
sed -i 's/\(^X11Forwarding\).*/\1 no/' /etc/ssh/sshd_config
sed -i 's/^#\(UseDNS\).*/\1 no/' /etc/ssh/sshd_config
sed -i 's/^#\(PrintMotd\).*/\1 no/' /etc/ssh/sshd_config
sed -i 's/\(^# no default banner path\)/# Pre-authentication banner/' /etc/ssh/sshd_config
sed -i 's/^#\(Banner\).*/\1 \/etc\/issue.net/' /etc/ssh/sshd_config

### Prepare bashrc for normally saving history and adding aliases for system
source /root/.bashrc

### Configuring /etc/hosts for nicelly job mailq command and fast load FPBX dashboard
#sed -i 's/\(localhost\)/headstack headstack.localdomain headstack.localhost.localdomain \1/' /etc/hosts

### Configuring /etc/profile to run HeadStack motd
echo -e "\n# HeadStack Message Of The Day\n/usr/local/sbin/dynmotd.sh" >> /etc/profile

### Configuring IPset
chmod 755 /usr/lib/systemd/system/ipset.service /usr/libexec/ipset/ipset.start-stop
