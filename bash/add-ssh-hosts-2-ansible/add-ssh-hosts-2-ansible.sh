#!/usr/bin/env bash

awk '/^Host /{print $2}' /${HOME}/.ssh/config | while read -r ip; do 
	grep -qxF "$ip" /${HOME}/ansible/hosts.txt 2>/dev/null || echo "$ip" >> /${HOME}/ansible/hosts.txt
done
