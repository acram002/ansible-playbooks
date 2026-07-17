#!/usr/bin/env bash

# --- to run: /script.sh <remote_host> <initial_ssh_user> [initial_ssh_port] ---

set -euo pipefail

read -p "enter new username for ansible acct: " ansible_user
key_path="${HOME}/.ssh/ansible_key"
create_new_user_script="$(dirname "$0")/create-remote-ansible-user.sh"
remote_tmp_dir="/tmp/ansible_bootstrap"

if [ $# -lt 2 ]; then
	echo "usage: $0 <remote_host> <initial_ssh_user> [initial_ssh_port]" >&2
	exit 1
fi

remote_host="$1"
initial_user="$2"
initial_port="${3:-22}"

# creates ssh key
if [ -f "$key_path" ]; then
	echo "error: key already exists at ${key_path}"
else
	ssh-keygen -t ecdsa -C "ansible-controller" -f "$key_path" -N ""
	echo "success: new key pair gen at ${key_path}"
fi

# copy create user script & pub key to vm
echo "copying files to ${remote_host}"
ssh -p "$initial_port" "${initial_user}@${remote_host}" "mkdir -p ${remote_tmp_dir}"
scp -P "$initial_port" "$create_new_user_script" "${key_path}.pub" \
	"${initial_user}@${remote_host}:${remote_tmp_dir}/"

# run create user script on vm
new_user_script_name="$(basename "$create_new_user_script")"
echo "running create-remote-ansible-user.sh on ${remote_host}"
ssh -p "$initial_port" -t "${initial_user}@${remote_host}" \
	"chmod +x ${remote_tmp_dir}/${new_user_script_name} && \
	${remote_tmp_dir}/${new_user_script_name} ${ansible_user} ${remote_tmp_dir}/ansible_key.pub"

# call fxn
source "$(dirname "$0")/test-ansible-ssh-sudo.sh"
test_ansible_ssh_sudo

# call fxn
source "$(dirname "$0")/harden-remote-config.sh"
harden_remote_config

# call fxn
source "$(dirname "$0")/set-local-ssh-config.sh"
set_local_ssh_config
