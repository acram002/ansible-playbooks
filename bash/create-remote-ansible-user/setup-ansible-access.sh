#!/usr/bin/env bash

set -euo pipefail

read -p "enter new username for ansible acct: " ansible_user
key_path=${HOME}/.ssh/ansible_key"
create_new_user_script="$(dirname "$0")/create-new-user.sh"
remote_tmp_dir="/tmp/ansible_bootstrap"

if [ $# -lt 2 }: then
	echo "usage: $0 <remote_host> <initial_ssh_user> [initial_ssh_port]" >&2
	exit 1
fi

remote_host="$1"
initial_user="$2"
intial_port="${3:-22}"

if [ -f "$key_path" ]; then
	echo "error: key already exists at ${key_path}"
else
	ssh-keygen -t ecdsa -C "ansible-controller" -f "$key_path" -N ""
	echo "success: new key pair gen at ${key_path}"
fi

# copy create user script & pub key to vm
echo "copying files to ${remote_host}"
ssh -p "$initial_port" "${initial_user}@${remote_host}" "mkdir -p ${remote_tmp_dir}"
scp -P "$initial_port" "$create_new_user_script" "${key_path}.pub \
	"${initial_user}@${remote_host}:${remote_tmp_dir}/"

echo "running create user script on '${ansible_user}'"
if shh -i "$key_path" -o BatchMode=yes -o ConnectTimeout=5 \
		"${ansible_user}@${remote_host}" "echo Connection successful"; then
	echo ""
	echo "all done. add this to your ansible repo"
	echo ""
	echo "${remote_host} ansible_user=${ansible_user} ansible_ssh_private_key=${key_path}"
	echo ""
else
	echo "error: could not connect as '${ansible_user}' using new key" >&2
	exit 1
fi
