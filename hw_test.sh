#!/usr/bin/env bash

proc_pid1=$(ls -d /proc/+([0-9]) | sort --field-separator="/" -k 3 -g)
echo $proc_pid1
