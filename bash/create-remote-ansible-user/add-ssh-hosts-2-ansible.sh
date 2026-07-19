#!/usr/bin/env bash

# pulls from local ssh config, adds remote vm to ansible inventory
add_ssh_hosts_2_ansible() {
	awk '/^Host /{print $2}' /${HOME}/.ssh/config | while read -r ip; do 
		grep -qxF "$ip" /${HOME}/ansible/hosts.txt 2>/dev/null || echo "$ip" >> /${HOME}/ansible/hosts.txt
	done
}
