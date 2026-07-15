#!/usr/bin/env bash
awk '/^Host /{print $2}' /root/.ssh/config >> /github/ansible/hosts.txt
