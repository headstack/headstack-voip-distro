# .bashrc

# Aliases

# Basic
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Extended
alias n='nano'
alias s='sngrep'
alias myip='wget -qO- icanhazip.com'
alias he='/usr/local/sbin/dynmotd.sh'
alias ifc='ifconfig'
alias hi='history'
alias his='history'
alias reb='reboot'
alias shut='shutdown -h now'
alias show='ls -lattr'
alias showp='ps aux'

# Firewall stack (IPtables Fail2Ban IPset)
alias fwconfigure='vi ~/fw_iptables.sh'
alias fwconfig='vi ~/fw_iptables.sh'
alias fwconf='vi ~/fw_iptables.sh'
alias fwco='vi ~/fw_iptables.sh'
alias fwshow='iptables -L -nv'
alias fwsh='iptables -L -nv'
alias fwinit='~/fw_iptables.sh'
alias fwin='~/fw_iptables.sh'
alias fwstart='systemctl start iptables.service fail2ban.service ipset.service'
alias fwsta='systemctl start iptables.service fail2ban.service ipset.service'
alias fwstop='systemctl stop iptables.service fail2ban.service ipset.service'
alias fwsto='systemctl stop iptables.service fail2ban.service ipset.service'
alias fwrestart='systemctl restart iptables.service fail2ban.service ipset.service'
alias fwres='systemctl restart iptables.service fail2ban.service ipset.service'
alias fwenable='systemctl enable iptables.service fail2ban.service ipset.service'
alias fwena='systemctl enable iptables.service fail2ban.service ipset.service'
alias fwdisable='systemctl disable iptables.service fail2ban.service ipset.service'
alias fwdis='systemctl disable iptables.service fail2ban.service ipset.service'

# Systemctl aliases
alias sc='systemctl'
alias scss='systemctl status'
alias scssd='systemctl status -l'
alias scre='systemctl restart'
alias scst='systemctl start'
alias scsp='systemctl stop'
alias scen='systemctl enable'
alias scdi='systemctl disable'

# Asterisk
alias a='asterisk -rvvvvv'
alias ra='asterisk -rx'
alias ch='asterisk -rx "core show channels verbose"'
alias csu='asterisk -rx "core show uptime"'
alias ssp='asterisk -rx "sip show peers"'
alias ssr='asterisk -rx "sip show registry"'
alias isp='asterisk -rx "iax2 show peers"'
alias isr='asterisk -rx "iax2 show registry"'
alias dapps='asterisk -rx "core show applications"'
alias dfuns='asterisk -rx "core show functions"'
alias dreload='asterisk -rx "dialplan reload"'
alias p='asterisk -rx "sip show peers"'
alias pp='asterisk -rx "sip show peers" | fgrep -i $1'
alias r='asterisk -rx "sip show registry"'
alias u='asterisk -rx "core show calls uptime"'

# Bash history
export HISTSIZE=10000
export HISTTIMEFORMAT="%h %d %H:%M:%S "
PROMPT_COMMAND='history -a'
export HISTIGNORE="ls:ll:history:w:htop"

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
