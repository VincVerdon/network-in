#!/bin/bash
#Version 20251028

trap '#' SIGINT
trap '#' SIGKILL
trap '#' SIGTERM

while true
do
    login
    clear
done

