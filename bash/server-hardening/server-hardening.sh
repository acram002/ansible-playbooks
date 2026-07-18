#!/usr/bin/env bash

read -s -p "enter pw" $pw
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
