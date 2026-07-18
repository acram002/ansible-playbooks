#!/usr/bin/env bash

awk '/^Host /{print $2}' /root/.ssh/config | while read -r ip; do 
	grep -qxF "$ip" /github/ansible/hosts.txt 2>/dev/null || echo "$ip" >> /github/ansible/hosts.txt
done
