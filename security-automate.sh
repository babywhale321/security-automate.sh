#!/bin/bash

#!!!!!!!!!!!!!!intended to be changed pass this line!!!!!!!!!!!!!!!!!

#SSHD [ OPTIONAL ]
#usertoallow="admin" # [ OPTIONAL ]
#iptoallow="192.168.1.1" # [ OPTIONAL ]
#ssh_pbkey="PubkeyAuthentication yes" # [ OPTIONAL ]
#ssh_passwdauth="PasswordAuthentication yes" # [ OPTIONAL ] 
ssh_port="Port 22"
ssh_permitroot="PermitRootLogin no"
ssh_kbd="KbdInteractiveAuthentication no"
ssh_pam="UsePAM yes"
ssh_x11="X11Forwarding yes"

#/etc/login.defs
umasknum="027"
minrounds="SHA_CRYPT_MIN_ROUNDS 10000"
maxrounds="SHA_CRYPT_MAX_ROUNDS 20000"

#FAIL2BAN SSHD
enabled="true"
findtime="48h"
bantime="48h"
maxretry="3"

#UFW
#example = ufw_command="ufw allow 22 && ufw limit 80 && ufw allow 443"
ufw_command="ufw allow 22"

#!!!!!!!!!!!!!!NOT intended to be changed pass this line!!!!!!!!!!!!!!!!!

#copy default configs to exsisting configs
cp defaults/sshd_config /etc/ssh/sshd_config
cp defaults/login.defs /etc/login.defs

#file variables
sshconfignew="sshd_config_new"
sshconfig="sshd_config"
cd /etc/ssh

#removing lines containing patterns from default file
grep -v "Port" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "PermitRootLogin" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "KbdInteractiveAuthentication" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "UsePAM" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "X11Forwarding" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "AllowUsers" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "$iptoallow" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "PubkeyAuthentication" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig
grep -v "PasswordAuthentication" $sshconfig > $sshconfignew && mv $sshconfignew $sshconfig

#append new values to sshd_config
echo $ssh_port >> $sshconfig
echo $ssh_permitroot >> $sshconfig
echo $ssh_kbd >> $sshconfig
echo $ssh_pam >> $sshconfig
echo $ssh_x11 >> $sshconfig
echo $ssh_pbkey >> $sshconfig
echo $ssh_passwdauth >> $sshconfig

#cleaning up
rm $sshconfignew

#OPTIONAL usertoallow or iptoallow variables
if [ -z "$usertoallow" ]
then
      echo "optional part of script has been skipped"
else
    if [ -z "$iptoallow" ]    
    then
        echo AllowUsers=$usertoallow >> /etc/ssh/sshd_config
    else
        echo AllowUsers=$usertoallow@$iptoallow >> /etc/ssh/sshd_config
    fi
fi

#/etc/login.defs
sed "s/022/$umasknum/" /etc/login.defs > /etc/login.defs.new
echo $minrounds >> /etc/login.defs.new
echo $maxrounds >> /etc/login.defs.new
cp /etc/login.defs.new /etc/login.defs && rm /etc/login.defs.new

#install fail2ban then delete default or exsisting config from this script
fail2banconfig="sshd.conf"
apt install fail2ban -y && cd /etc/fail2ban/jail.d/ && rm defaults-debian.conf || rm $fail2banconfig

#add variables to config
echo "[sshd]" >> $fail2banconfig
echo enabled=$enabled >> $fail2banconfig
echo findtime=$findtime >> $fail2banconfig
echo bantime=$bantime >> $fail2banconfig
echo maxretry=$maxretry >> $fail2banconfig

#ufw add rules then reload / enable rules
apt install ufw -y
eval "$ufw_command"
echo "y" | ufw reload
echo "y" | ufw enable

#enable services then restart services
systemctl enable fail2ban
systemctl restart ssh fail2ban
