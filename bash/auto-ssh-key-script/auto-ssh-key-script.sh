#!/usr/bin/env bash

# get ip
read -p "Enter remote ip: " ip
read -p "Enter remote ip username (ex:root): " remoteUser
read -s -p "Enter remote pw: " remotePw
echo
read -p "Enter local file path for key (ex:/root/.ssh/id_<keyName>): " keyPath 

# function to create key
create_key() {
	# might include 0>&- for overwrite prompt if key already exists
	ssh-keygen -t ecdsa -f $keyPath -q -N ""
}

copy_key() {
	echo "Processing $ip..."

	# check server reachable by ssh
	if ! timeout 5 bash -c "echo > /dev/tcp/$ip/22" &>/dev/null; then
		echo "Error: Server $remoteUser@$ip is unreachable."
		return 1
	fi

	# check key not in authorized_keys file
#	if ssh "$remoteUser@$ip" "grep -Fxq \"$(<\"

	if command -v ssh-copy-id &> /dev/null; then
		if sshpass -p "$remotePw" ssh-copy-id -i "$keyPath" "$remoteUser@$ip"; then
			echo "Public key copied to $ip for $remoteUser"
		else
			echo "Error: Failed to copy public key to $ip for $remoteUser"
			return 2
		fi
	else
		echo "use manual method"
# write up manual method

	fi 
}

change_remote_config() {
sshpass -p "$remotePw" ssh -t "$remoteUser@$ip" /bin/bash << EOF
echo "$remotePw" | sudo -S sh -c 'printf "PubKeyAuthentication yes\nPasswordAuthentication no\n" >> /etc/ssh/sshd_config'
echo "$remotePw" | sudo -S systemctl restart sshd
EOF
}

change_local_config() {
	configDir=$(dirname "$keyPath")
	cat >> "$configDir/config" << EOF
Host $ip
	User $remoteUser
	IdentityFile $keyPath
	IdentitiesOnly yes
EOF

}

#create_n_copy_key() {
#	create_key
#	copy_key
#}
create_key
echo "key created"
copy_key
echo "key copied"
change_remote_config
echo "remote config changed"
change_local_config
echo "local config changed"
echo "now try ssh <ip>"
