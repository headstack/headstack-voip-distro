#!/bin/sh

#
# Восстановление сохраненных правил iptables по таймауту
#
TIMEOUT=120
(
        sleep $TIMEOUT
        systemctl stop iptables.service
        systemctl start iptables.service
) &
TIMEOUT_PID=$!
disown -h

### Скрипт конфигурации iptables ###

IPTABLES=/sbin/iptables
IP6TABLES=/sbin/ip6tables
IPSET=/usr/sbin/ipset

#
# Сетевые интерфейсы и диапазоны ip-адресов
# (обычно не нужно)
#
#LAN_IFACE=eth0
#LAN_NET=192.168.50.0/24
#PHONES_IFACE=vlan10
#INET_IFACE=eth1

#
# Установка политик по умолчанию
#
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT

#
# Очищаем предыдущие записи
#
$IPTABLES -F
$IP6TABLES -F
$IPTABLES -F -t nat
$IPTABLES -F -t raw
$IPTABLES -X HEADSTACK 2>/dev/null
$IPTABLES -X OPENVPN 2>/dev/null
$IPTABLES -X PHONES 2>/dev/null
$IPTABLES -X ADMIN 2>/dev/null
$IPTABLES -X SIP 2>/dev/null
$IPTABLES -X IAX2 2>/dev/null
$IPTABLES -X BLACKLIST 2>/dev/null
$IPTABLES -X f2b-SSH 2>/dev/null
$IPTABLES -X f2b-OPENVPN 2>/dev/null
$IPTABLES -X f2b-FREEPBX 2>/dev/null
$IPTABLES -X f2b-ASTERISK 2>/dev/null
#$IPTABLES -X f2b-BADBOTS 2>/dev/null
#$IPTABLES -X LAN 2>/dev/null
$IPSET -F
$IPSET -X


#
# Черный список подсетей (содержимое в конце скрипта для читабельности)
#
$IPSET -N blacklisted_nets hash:net

#
# OPENVPN
#
$IPTABLES -N OPENVPN
$IPTABLES -A OPENVPN -s 0.0.0.0/0 -j ACCEPT
$IPTABLES -A OPENVPN -j RETURN

#
# HEADSTACK
#
$IPTABLES -N HEADSTACK
#$IPTABLES -A HEADSTACK -s 192.168.88.0/24 -j ACCEPT
$IPTABLES -A HEADSTACK -s 79.111.14.12/32 -j ACCEPT
$IPTABLES -A HEADSTACK -s 10.10.100.0/24 -j ACCEPT
$IPTABLES -A HEADSTACK -j RETURN

#
# Сюда заносим подсети из которых можно админить АТС (SSH и HTTP)
#
$IPTABLES -N ADMIN
$IPTABLES -A ADMIN -j HEADSTACK
# Административная подсеть клиента
#$IPTABLES -A ADMIN -i eth0 -s 192.168.88.0/24 -j ACCEPT
$IPTABLES -A ADMIN -j RETURN

#
# HIGH AVAILABILLITY
#
$IPTABLES -N HIGHAVAIL
$IPTABLES -A HIGHAVAIL -j HEADSTACK
#$IPTABLES -A HIGHAVAIL -s 192.168.88.0/24 -j ACCEPT

#
# Подсети телефонов
#
$IPTABLES -N PHONES
#$IPTABLES -A PHONES -i eth0 -s 192.168.88.0/24 -j ACCEPT
$IPTABLES -A PHONES -j HEADSTACK
$IPTABLES -A PHONES -j RETURN

#
# Сюда заносим подсети из которых можно подключаться по SIP
#
$IPTABLES -N SIP
# Телефоны
$IPTABLES -A SIP -j PHONES
# Провайдер
$IPTABLES -A SIP -s 195.34.37.37 -j ACCEPT #MTS_TEST
$IPTABLES -A SIP -j RETURN

#
# Сюда заносим подсети из которых можно подключаться по IAX2
#
$IPTABLES -N IAX2
# АТС клиента
#$IPTABLES -A IAX2 -s 192.168.88.162 -j ACCEPT
$IPTABLES -A IAX2 -j HEADSTACK
$IPTABLES -A IAX2 -j RETURN

#
# Подсеть клиентских машин
# (нужно, если клиент хочет использовать FOP2 или вешать NTP/DNS/еще что-нибудь на АТС, т.е. редко)
#
#$IPTABLES -N LAN
#$IPTABLES -A LAN -i $LAN_IFACE -s $LAN_NET -j ACCEPT
#$IPTABLES -A LAN -j RETURN

#
# Цепочка INPUT
#
# Allow "ping -s 777" from anywhere
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -m length --length 805 -j ACCEPT
# Защита от спуфинга
$IPTABLES -A INPUT -p tcp -m state --state NEW --tcp-flags SYN,ACK SYN,ACK -j REJECT --reject-with tcp-reset
# Защита от попытки открыть входящее соединение TCP не через SYN
$IPTABLES -A INPUT -p tcp -m state --state NEW ! --syn -j DROP

# Разрешаем RELATED, ESTABLISHED
$IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# Запрещаем INVALID
$IPTABLES -A INPUT -m state --state INVALID -j DROP

# Черный список подсетей
$IPTABLES -A INPUT -m set --match-set blacklisted_nets src -j DROP

# Разрешаем локальный интерфейс
$IPTABLES -A INPUT -i lo -j ACCEPT

# Закрываемся от кривого icmp
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -j ADMIN

# Разрешаем сервисные порты для доступа только из сервисных сетей
#$IPTABLES -A INPUT -p tcp --dport 41413 -j OPENVPN                     # OpenVPN
$IPTABLES -A INPUT -p tcp --dport 22 -j ADMIN                           # SSH
$IPTABLES -A INPUT -p tcp --dport 80 -j ADMIN                           # HTTP
$IPTABLES -A INPUT -p tcp --dport 443 -j ADMIN                          # HTTPS
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -j SIP              # ping от провайдеров и SIP-девайсов
$IPTABLES -A INPUT -p udp --dport 5060 -j SIP                           # SIP
$IPTABLES -A INPUT -p tcp --dport 5060 -j SIP                           # SIP TCP
$IPTABLES -A INPUT -p tcp --dport 5061 -j SIP                           # SIP TLS
$IPTABLES -A INPUT -p udp --dport 5160 -j SIP                           # PJSIP
$IPTABLES -A INPUT -p tcp --dport 5160 -j SIP                           # PJSIP TCP
$IPTABLES -A INPUT -p tcp --dport 5161 -j SIP                           # PJSIP TLS
$IPTABLES -A INPUT -p udp --dport 36600:39999 -j SIP                    # RTP
$IPTABLES -A INPUT -p udp --dport 4569 -j IAX2                          # IAX2
#$IPTABLES -A INPUT -p udp --dport 69 -j PHONES                         # TFTP provisioning
#$IPTABLES -A INPUT -p tcp --dport 8969 -j PHONES                       # HTTP provisioning
$IPTABLES -A INPUT -p udp --dport 123 -j PHONES                         # NTP для телефонов (обычно нужно)
$IPTABLES -A INPUT -p tcp --dport 80 -j PHONES                          # HTTP (XML-службы для телефонов, FOP2 и т.д.)
#$IPTABLES -A INPUT -p tcp --dport 4445 -j PHONES                       # FOP2 (раскомментировать, если нужно FOP2)
#$IPTABLES -A INPUT -p udp --dport 123 -j LAN                           # NTP
#$IPTABLES -A INPUT -p udp --dport 53 -j LAN                            # DNS
#$IPTABLES -A INPUT -p udp --dport 8088 -j ADMIN                        # раскомментировать, если нужно общаться с ARI (обычно для интеграций с CRM)
#$IPTABLES -A INPUT -p tcp --dport 8088 -j ADMIN                        # раскомментировать, если нужно общаться с ARI (обычно для интеграций с CRM)
#$IPTABLES -A INPUT -p udp --dport 4443 -j ADMIN                        # раскомментировать, если нужно 1C MIKO
#$IPTABLES -A INPUT -p tcp --dport 4443 -j ADMIN                        # раскомментировать, если нужно 1C MIKO

# High Availabillity Services
#$IPTABLES -A INPUT -p tcp --dport 2224 -j HIGHAVAIL                    # раскомментировать для pcsd
#$IPTABLES -A INPUT -p tcp --dport 3121 -j HIGHAVAIL                    # раскомментировать для crmd
#$IPTABLES -A INPUT -p tcp --dport 5403 -j HIGHAVAIL                    # раскомментировать для corosync-qnetd (quorum)
#$IPTABLES -A INPUT -p udp --dport 5404 -j HIGHAVAIL                    # раскомментировать для corosync multicast udp
#$IPTABLES -A INPUT -p udp --dport 5405 -j HIGHAVAIL                    # раскомментировать для corosync service
#$IPTABLES -A INPUT -p tcp --dport 873 -j HIGHAVAIL                     # раскомментировать для Rsync синхронизации
#$IPTABLES -A INPUT -p tcp --dport 3306 -j HIGHAVAIL                    # раскомментировать для MariaDB синхронизации
#$IPTABLES -A INPUT -p udp --dport 5060 -j HIGHAVAIL                    # раскомментировать для пинга Asterisk
#$IPTABLES -A INPUT -p tcp --dport 21064 -j HIGHAVAIL                   # раскомментировать, если в кластере исп. ресурсы требующие DLM (clvm или GFS2)
#$IPTABLES -A INPUT -p udp --dport 9929 -j HIGHAVAIL                    # раскомментировать для многосайтового кластера
#$IPTABLES -A INPUT -p tcp --dport 9929 -j HIGHAVAIL                    # раскомментировать для многосайтового кластера
#$IPTABLES -A INPUT -p tcp --dport 7410 -j HIGHAVAIL                    # раскомментировать, если используется fence_kdump
#$IPTABLES -A INPUT -p udp --dport 7410 -j HIGHAVAIL                    # раскомментировать, если используется fence_kdump

# Разрешение DHCP-сервера при необходимости. Указать интерфейс, откуда будет трафик
#$IPTABLES -A INPUT -i eth0 -p udp --dport 68 -j ACCEPT

# Разрешение главных типов протокола ICMP
$IPTABLES -A INPUT -p icmp --icmp-type fragmentation-needed -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/sec -j ACCEPT

#
# цепочка FORWARD
# (редко)
#
#$IPTABLES -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
#$IPTABLES -A FORWARD -m state --state INVALID -j DROP
#$IPTABLES -A FORWARD -i $LAN_IFACE -o $INET_IFACE -s $LAN_NET -j ACCEPT

$IPTABLES -t raw -A PREROUTING -p dccp -j NOTRACK
$IPTABLES -t raw -A OUTPUT -p dccp -j NOTRACK

#
# цепочка PREROUTING в таблице NAT
#
#$IPTABLES -t nat -A PREROUTING -p tcp -i eth+ --dport 80 -j REDIRECT --to-ports 443

#
# цепочка POSTROUTING в таблице NAT
# (редко)
#
#$IPTABLES -t nat -A POSTROUTING -o $INET_IFACE -j MASQUERADE

#
# цепочка OUTPUT (для параноиков)
#
#$IPTABLES -A OUTPUT -s 127.0.0.1 -j ACCEPT
#$IPTABLES -A OUTPUT -s 10.10.155.1 -j ACCEPT
#$IPTABLES -A OUTPUT -s 192.168.50.162 -j ACCEPT
#$IPTABLES -P OUTPUT DROP

$IPTABLES -P INPUT DROP

#
# P.S. директивы для этого блока DROP всех таблиц закомментированы,
# т.к. в противном случае при каждом применении скрипта, дропается
# ip6tables и fwconsole пытается обратиться к Asterisk на порт 5038
# по tcp6, а для всех таблиц ip6tables устанавливается политика DROP,
# что препятствует обращениям, хотя до применения скрипта
# fwconsole выполняет обращение по tcp4 на порт 5038.
# Причина этому в том, что в дистрибутиве на момент тестирования
# не был отключен протокол IPv6. В данный момент отключена поддержка
# протокола ipv6 на уровне ядра. Также стоит сказать, что для ip6tables
# выше применяется Flush, таким образом, стирая все правила, если они
# добавлялись ранее, а стандартным действием для ip6tables - stop, disable, mask.
#
#
# Скидываем весь IP6, вдруг он включен
#
#$IP6TABLES -P INPUT DROP 2>/dev/null
#$IP6TABLES -P FORWARD DROP 2>/dev/null
#$IP6TABLES -P OUTPUT DROP 2>/dev/null
service ip6tables save >/dev/null 2>&1
systemctl stop ip6tables.service
systemctl disable ip6tables.service
systemctl mask ip6tables.service
#systemctl enable ip6tables.service

#
# Здесь же стоит предусмотреть, что может быть активен Firewalld, который
# будет помехой для работы скрипта. Таким образом, он отключается как и
# ip6tables.
#
systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl mask firewalld.service

#
# Черный список подсетей
#
$IPSET -A blacklisted_nets 1.0.0.0/8
$IPSET -A blacklisted_nets 7.0.0.0/8
$IPSET -A blacklisted_nets 14.0.0.0/8
$IPSET -A blacklisted_nets 23.0.0.0/8
$IPSET -A blacklisted_nets 24.0.0.0/8
$IPSET -A blacklisted_nets 27.0.0.0/8
$IPSET -A blacklisted_nets 35.0.0.0/8
$IPSET -A blacklisted_nets 36.0.0.0/8
$IPSET -A blacklisted_nets 39.0.0.0/8
$IPSET -A blacklisted_nets 40.0.0.0/8
$IPSET -A blacklisted_nets 41.0.0.0/8
$IPSET -A blacklisted_nets 42.0.0.0/8
$IPSET -A blacklisted_nets 43.0.0.0/8
$IPSET -A blacklisted_nets 45.0.0.0/8
$IPSET -A blacklisted_nets 47.0.0.0/8
$IPSET -A blacklisted_nets 49.0.0.0/8
$IPSET -A blacklisted_nets 50.0.0.0/8
$IPSET -A blacklisted_nets 54.0.0.0/8
$IPSET -A blacklisted_nets 58.0.0.0/8
$IPSET -A blacklisted_nets 59.0.0.0/8
$IPSET -A blacklisted_nets 60.0.0.0/8
$IPSET -A blacklisted_nets 61.0.0.0/8
$IPSET -A blacklisted_nets 63.0.0.0/8
$IPSET -A blacklisted_nets 64.0.0.0/8
$IPSET -A blacklisted_nets 65.0.0.0/8
$IPSET -A blacklisted_nets 66.0.0.0/8
$IPSET -A blacklisted_nets 67.0.0.0/8
$IPSET -A blacklisted_nets 68.0.0.0/8
$IPSET -A blacklisted_nets 69.0.0.0/8
$IPSET -A blacklisted_nets 70.0.0.0/8
$IPSET -A blacklisted_nets 71.0.0.0/8
$IPSET -A blacklisted_nets 72.0.0.0/8
$IPSET -A blacklisted_nets 73.0.0.0/8
$IPSET -A blacklisted_nets 74.0.0.0/8
$IPSET -A blacklisted_nets 75.0.0.0/8
$IPSET -A blacklisted_nets 76.0.0.0/8
$IPSET -A blacklisted_nets 96.0.0.0/8
$IPSET -A blacklisted_nets 97.0.0.0/8
$IPSET -A blacklisted_nets 98.0.0.0/8
$IPSET -A blacklisted_nets 99.0.0.0/8
$IPSET -A blacklisted_nets 100.0.0.0/8
$IPSET -A blacklisted_nets 101.0.0.0/8
$IPSET -A blacklisted_nets 102.0.0.0/8
$IPSET -A blacklisted_nets 103.0.0.0/8
$IPSET -A blacklisted_nets 104.0.0.0/8
$IPSET -A blacklisted_nets 105.0.0.0/8
$IPSET -A blacklisted_nets 106.0.0.0/8
$IPSET -A blacklisted_nets 107.0.0.0/8
$IPSET -A blacklisted_nets 108.0.0.0/8
$IPSET -A blacklisted_nets 110.0.0.0/8
$IPSET -A blacklisted_nets 111.0.0.0/8
$IPSET -A blacklisted_nets 112.0.0.0/8
$IPSET -A blacklisted_nets 113.0.0.0/8
$IPSET -A blacklisted_nets 114.0.0.0/8
$IPSET -A blacklisted_nets 115.0.0.0/8
$IPSET -A blacklisted_nets 116.0.0.0/8
$IPSET -A blacklisted_nets 117.0.0.0/8
$IPSET -A blacklisted_nets 118.0.0.0/8
$IPSET -A blacklisted_nets 119.0.0.0/8
$IPSET -A blacklisted_nets 120.0.0.0/8
$IPSET -A blacklisted_nets 121.0.0.0/8
$IPSET -A blacklisted_nets 122.0.0.0/8
$IPSET -A blacklisted_nets 123.0.0.0/8
$IPSET -A blacklisted_nets 124.0.0.0/8
$IPSET -A blacklisted_nets 125.0.0.0/8
$IPSET -A blacklisted_nets 126.0.0.0/8
$IPSET -A blacklisted_nets 128.0.0.0/8
$IPSET -A blacklisted_nets 129.0.0.0/8
$IPSET -A blacklisted_nets 130.0.0.0/8
$IPSET -A blacklisted_nets 131.0.0.0/8
$IPSET -A blacklisted_nets 132.0.0.0/8
$IPSET -A blacklisted_nets 133.0.0.0/8
$IPSET -A blacklisted_nets 134.0.0.0/8
$IPSET -A blacklisted_nets 135.0.0.0/8
$IPSET -A blacklisted_nets 136.0.0.0/8
$IPSET -A blacklisted_nets 137.0.0.0/8
$IPSET -A blacklisted_nets 138.0.0.0/8
$IPSET -A blacklisted_nets 139.0.0.0/8
$IPSET -A blacklisted_nets 140.0.0.0/8
$IPSET -A blacklisted_nets 142.0.0.0/8
$IPSET -A blacklisted_nets 143.0.0.0/8
$IPSET -A blacklisted_nets 144.0.0.0/8
$IPSET -A blacklisted_nets 146.0.0.0/8
$IPSET -A blacklisted_nets 147.0.0.0/8
$IPSET -A blacklisted_nets 148.0.0.0/8
$IPSET -A blacklisted_nets 149.0.0.0/8
$IPSET -A blacklisted_nets 150.0.0.0/8
$IPSET -A blacklisted_nets 152.0.0.0/8
$IPSET -A blacklisted_nets 153.0.0.0/8
$IPSET -A blacklisted_nets 154.0.0.0/8
$IPSET -A blacklisted_nets 155.0.0.0/8
$IPSET -A blacklisted_nets 156.0.0.0/8
$IPSET -A blacklisted_nets 157.0.0.0/8
$IPSET -A blacklisted_nets 158.0.0.0/8
$IPSET -A blacklisted_nets 159.0.0.0/8
$IPSET -A blacklisted_nets 160.0.0.0/8
$IPSET -A blacklisted_nets 161.0.0.0/8
$IPSET -A blacklisted_nets 162.0.0.0/8
$IPSET -A blacklisted_nets 163.0.0.0/8
$IPSET -A blacklisted_nets 164.0.0.0/8
$IPSET -A blacklisted_nets 165.0.0.0/8
$IPSET -A blacklisted_nets 166.0.0.0/8
$IPSET -A blacklisted_nets 167.0.0.0/8
$IPSET -A blacklisted_nets 168.0.0.0/8
$IPSET -A blacklisted_nets 169.0.0.0/8
$IPSET -A blacklisted_nets 170.0.0.0/8
$IPSET -A blacklisted_nets 171.0.0.0/8
$IPSET -A blacklisted_nets 173.0.0.0/8
$IPSET -A blacklisted_nets 174.0.0.0/8
$IPSET -A blacklisted_nets 175.0.0.0/8
$IPSET -A blacklisted_nets 177.0.0.0/8
$IPSET -A blacklisted_nets 179.0.0.0/8
$IPSET -A blacklisted_nets 180.0.0.0/8
$IPSET -A blacklisted_nets 181.0.0.0/8
$IPSET -A blacklisted_nets 182.0.0.0/8
$IPSET -A blacklisted_nets 183.0.0.0/8
$IPSET -A blacklisted_nets 184.0.0.0/8
$IPSET -A blacklisted_nets 186.0.0.0/8
$IPSET -A blacklisted_nets 187.0.0.0/8
$IPSET -A blacklisted_nets 189.0.0.0/8
$IPSET -A blacklisted_nets 190.0.0.0/8
$IPSET -A blacklisted_nets 191.0.0.0/8
$IPSET -A blacklisted_nets 196.0.0.0/8
$IPSET -A blacklisted_nets 197.0.0.0/8
$IPSET -A blacklisted_nets 198.0.0.0/8
$IPSET -A blacklisted_nets 199.0.0.0/8
$IPSET -A blacklisted_nets 200.0.0.0/8
$IPSET -A blacklisted_nets 201.0.0.0/8
$IPSET -A blacklisted_nets 202.0.0.0/8
$IPSET -A blacklisted_nets 203.0.0.0/8
$IPSET -A blacklisted_nets 204.0.0.0/8
$IPSET -A blacklisted_nets 205.0.0.0/8
$IPSET -A blacklisted_nets 206.0.0.0/8
$IPSET -A blacklisted_nets 207.0.0.0/8
$IPSET -A blacklisted_nets 208.0.0.0/8
$IPSET -A blacklisted_nets 209.0.0.0/8
$IPSET -A blacklisted_nets 210.0.0.0/8
$IPSET -A blacklisted_nets 211.0.0.0/8
$IPSET -A blacklisted_nets 216.0.0.0/8
$IPSET -A blacklisted_nets 218.0.0.0/8
$IPSET -A blacklisted_nets 219.0.0.0/8
$IPSET -A blacklisted_nets 220.0.0.0/8
$IPSET -A blacklisted_nets 221.0.0.0/8
$IPSET -A blacklisted_nets 222.0.0.0/8
$IPSET -A blacklisted_nets 223.0.0.0/8

KEY=""
while [ ! "$KEY" == "y" ]; do
        echo -e "Убедитесь, что можете подключиться по SSH, и нажмите 'y'\nПравила iptables будут восстановлены через $TIMEOUT секунд"
        read -n 1 -s KEY
        KEY="$(echo $KEY | tr Y y)"
done

exec 2>/dev/null
kill -s TERM $TIMEOUT_PID
service iptables save
service ipset save
systemctl enable iptables.service
systemctl enable ipset.service
systemctl enable fail2ban.service
systemctl restart fail2ban.service
