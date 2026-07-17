#!/usr/bin/env bash

# make this & below test-ssh fxn, also can do ! ssh, 1 if, then print success after if no exit
test_ansible_ssh_sudo() {
	echo "checking ssh key login for '${ansible_user}'"
	if ssh -i "$key_path" -o BatchMode=yes -o ConnectTimeout=5 \
			"${ansible_user}@${remote_host}" "echo Connection successful"; then
		echo ""
		echo "all done. add this to your ansible repo"
		echo ""
		echo "${remote_host} ansible_user=${ansible_user} ansible_ssh_private_key_file=${key_path}"
		echo ""
	else
		echo "error: could not connect as '${ansible_user}' using new key" >&2
		exit 1
	fi

	# test pw-less sudo
	echo "testing pw-less sudo as '${ansible_user}'"
	if ! ssh -i "$key_path" -o BatchMode=yes -o ConnectTimeout=5 \
			"${ansible_user}@${remote_host}" "sudo -n true" >&/dev/null; then
		echo "error: pw-less sudo failed for ${ansible_user}' aborting b/f hardening sshd" >&2
		exit 1
	fi
	echo "success: pw-less sudo works"
}
