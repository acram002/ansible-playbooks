#!/usr/bin/env bash

# runs local script as sudo to remote system

# user input
read -p "Enter username: " user
read -p "Enter ip: " ip
read -p "Enter script file path: " script

# may need checks: sudo installed, supplied user not root
ssh -t "$user@$ip" "sudo $script"

# may need -o StrictHostKeyChecking=no
