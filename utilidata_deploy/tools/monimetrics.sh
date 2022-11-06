#!/bin/bash

# On the lake placid prototypes, this script is occasionaly started manually by running:
# tmux new ./monimetrics.sh

while true; do
	echo $( uptime; cat /sys/devices/pwm-fan/cur_pwm /sys/devices/virtual/thermal/thermal_zone[0-3]/temp /sys/devices/system/cpu/cpu[0-3]/cpufreq/scaling_cur_freq )
	sleep 1
done | tee -a log_monimetrics

