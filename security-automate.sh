#!/bin/bash

#!!!!!!!!!!!!!!intended to be changed pass this line!!!!!!!!!!!!!!!!!

#SSHD [ OPTIONAL ]
#usertoallow="admin" # [ OPTIONAL ]
#iptoallow="192.168.1.1" # [ OPTIONAL ]
#ssh_pbkey="PubkeyAuthentication yes" # [ OPTIONAL ]
#ssh_passwdauth="PasswordAuthentication yes" # [ OPTIONAL ] 
ssh_include="Include /etc/ssh/sshd_config.d/*.conf"
ssh_port="Port 22"
ssh_permitroot="PermitRootLogin no"
ssh_kbd="KbdInteractiveAuthentication no"
ssh_pam="UsePAM yes"
ssh_x11="X11Forwarding yes"
ssh_motd="PrintMotd no"
ssh_env="AcceptEnv LANG LC_*"
ssh_sub="Subsystem sftp /usr/lib/openssh/sftp-server"
ssh_configbackup="sshd_config_backup" #backup up file name from sshd_config

#FAIL2BAN SSHD
enabled="true"
findtime="48h"
bantime="48h"
maxretry="3"
fail2banconfig="sshd.conf"

#UFW
#example = ufw_command="ufw limit 22 ; ufw deny 80 ; ufw allow 443"
ufw_command="ufw limit 22"


#!!!!!!!!!!!!!!NOT intended to be changed pass this line!!!!!!!!!!!!!!!!!


#ssh variables added to new config file
ssh_config="sshd_config_new" #new config file name to replace sshd_config
cd /etc/ssh && cp sshd_config $ssh_configbackup && touch $ssh_config || rm $ssh_config
echo $ssh_include >> $ssh_config
echo $ssh_port >> $ssh_config
echo $ssh_permitroot >> $ssh_config
echo $ssh_kbd >> $ssh_config
echo $ssh_pam >> $ssh_config
echo $ssh_x11 >> $ssh_config
echo $ssh_motd >> $ssh_config
echo $ssh_env >> $ssh_config
echo $ssh_sub >> $ssh_config
echo $ssh_pbkey >> $ssh_config
echo $ssh_passwdauth >> $ssh_config
mv $ssh_config sshd_config

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


#install fail2ban then delete default or exsisting config from this script
apt install fail2ban -y && cd /etc/fail2ban/jail.d/ && rm defaults-debian.conf || rm $fail2banconfig
#add variables to config
echo "[sshd]" >> $fail2banconfig
echo enabled=$enabled >> $fail2banconfig
echo findtime=$findtime >> $fail2banconfig
echo bantime=$bantime >> $fail2banconfig
echo maxretry=$maxretry >> $fail2banconfig

#ufw add rules then enable rules
apt install ufw
$ufw_command
ufw enable
ufw reload

#enable services then restart services
systemctl enable fail2ban
systemctl restart ssh fail2ban
