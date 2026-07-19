#!/usr/bin/env bash

check_sshd_config(){
if
	change_sshd_config()
else
	echo "ssh config secure"
fi
}

set_fw() {

echo "fw set, only allow port 22 for ansible control node"
}

config_updates() {
apt_update()

# config unattend sec updates
echo "system updated, automatic security updates config"
}

basic_hardening() {
# install & config Fail2Ban for brute-force ssh

echo "Fail2Ban installed and config for ssh attacks"
}

server_config() {
# set correct timezonel; ntp?
# set hostname

echo "correct time and hostname set"
}

check_svc_mgmt() {
# test systemctl services, start/stop, enable at boot

echo "systemctl svcs working and configured"
}

sec_checklist() {

echo "all tests passed. linux server hardeninig complete"
}


read -s -p "enter pw" $pw
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
