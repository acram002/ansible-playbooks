#!/usr/bin/env bash

# change local config
set_local_ssh_config(){
	local configDir
	configDir=$(dirname "$key_path")
	local configFile="${configDir}/config"

	if grep -q "^Host ${remote_host}\$" "$configFile" 2>/dev/null; then
		echo "notice: config entry for ${remote_host} already exists"
	else
		cat >> "$configFile" << EOF

Host ${remote_host}
	User ${ansible_user}
	IdentityFile ${key_path}
	IdentitiesOnly yes
EOF
	echo "success: added ${remote_host} to ${configFile}"
	fi
}
