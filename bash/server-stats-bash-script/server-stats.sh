#!/bin/bash

echo "=== CPU Usage ==="
top -bn1 | grep "%Cpu(s)" | awk '{totalCpu="Total CPU usage: "($2+$4+$6)"%";print totalCpu}'

echo "=== Memory Usage ==="
free -m | awk '/Mem:/ {
    used=$3; total=$2; free=$4;
    printf "Total: %d MB\nUsed: %d MB (%.2f%%)\nFree: %d MB (%.2f%%)\n", total, used, used/total*100, free, free/total*100
}'

echo "\n=== Disk Usage ==="
df -h / | awk 'NR==2 {
    printf "Total: %s\nUsed: %s\nFree: %s\n", $2, $3, $4
}'

echo "\n=== Top 5 Processes by CPU Usage ==="
ps -eo pid,comm,%cpu,%mem, --sort=-%cpu | head -n 6

echo "\n=== Top 5 Processes by Memory Usage ==="
ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6
