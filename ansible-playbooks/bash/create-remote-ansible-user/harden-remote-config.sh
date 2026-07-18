#!/usr/bin/env bash

# hardens remote vm sshd_config
harden_remote_config() {
	echo "hardening sshd_config on ${remote_host}"
	ssh -i "$key_path" -o BatchMode=yes "${ansible_user}@${remote_host}" bash << 'EOF'
set -euo pipefail

set_sshd_config() {
	local key="$1"
	local value="$2"
	local file="$3"

	if grep -qE "^\s*#?\s*${key}\b" "$file";then
		sudo sed -i -E "s|^\s*#?\s*${key}\s+.*|${key} ${value}|" "$file"
	else
		echo "${key} ${value}" | sudo tee -a "$file" > /dev/null
	fi
}

# make this a loop or sumting
set_sshd_config "PubkeyAuthentication" "yes" /etc/ssh/sshd_config
set_sshd_config "PasswordAuthentication" "no" /etc/ssh/sshd_config
set_sshd_config "PermitRootLogin" "no" /etc/ssh/sshd_config

sudo sshd -t

sudo systemctl restart ssh

EOF
	echo "success: sshd_config hardened on ${remote_host}"
}
