#!/usr/bin/env bash

# creates ansible user acct on remote vm

set -euo pipefail

# read -p "enter username for new user: " username

# checks if running under uid 0, which is root (sudo runs as root)
if [ "$(id -u)" -ne 0 ]; then
	echo "error: script must be run as root (use sudo)" >&2
	exit 1
fi

# checks that called with exactly 2 arguments (sudo /*.sh username /path/key.pub)
if [ $# -ne 2 ]; then
	echo "usage: $0 username /path/key.pub" >&2
	exit 1
fi

# installs sudo if not found, allows new user to be added to sudoers
if ! command -v sudo &>/dev/null; then
	echo "notice: sudo not found, installing"
	apt-get update -qq
	apt-get install -y sudo
fi

username="$1"
PUBKEY_PATH="$2"
SUDOERS_FILE="/etc/sudoers.d/${username}"

# PUBKEY_PATH="$1"

# checks that pubkey path is a valid file
if [ ! -f "$PUBKEY_PATH" ]; then
	echo "error: pub key file '$PUBKEY_PATH' not found" >&2
	exit 1
fi

# checks if user exists, adds user
if id "$username" &>/dev/null; then
	echo "error: user '$username' already exists" >&2
	exit 1
else
	if adduser --disabled-password --gecos "" "$username"; then
		echo "success: user '$username' created"
	else
		echo "error: failed to create $username" >&2
		exit 1
	fi
fi

USER_HOME=$(eval echo "~${username}")
SSH_DIR="${USER_HOME}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

mkdir -p "$SSH_DIR"

# install ssh pub key
if [ -f "$AUTH_KEYS" ] && grep -qF "$(cat "$PUBKEY_PATH")" "$AUTH_KEYS"; then
	echo "warning:: pub key already present in authorized_keys"
else
	cat "$PUBKEY_PATH" >> "$AUTH_KEYS"
	echo "success: pub key added to ${AUTH_KEYS}"
fi

# fix permissions
chown -R "${username}:${username}" "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$AUTH_KEYS"
echo "success: permissions set on ${SSH_DIR}"

# pw-less sudo for ansible
echo "${username} ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"

# visudo to check sudoers
if visudo -cf "$SUDOERS_FILE"; then
	echo "success: pw-less sudo config for $username"
else
	echo "error: invalid sudoers syntax" >&2
	rm -f "$SUDOERS_FILE"
	exit 1
fi

# cleanup?
# ...

echo ""
echo "fin. from ansible server: "
echo " ssh -i /path/ansible_key ${username}@<remote-vm-ip>"
