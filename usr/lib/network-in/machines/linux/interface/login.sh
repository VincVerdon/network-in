#!/bin/bash
#Version 20250612

trap '#' SIGINT
trap '#' SIGKILL
trap '#' SIGTERM

VERSION=$(grep 'set version(equipment)' /var/networkin/interface/interface.tcl | sed -E 's/^.*version\(equipment\).+\{(.*)\}/\1/')
while true
do
    echo "Network-In simulator : Welcome ! (Equipment version : $VERSION)"
    echo
    login
    echo
    clear
done

