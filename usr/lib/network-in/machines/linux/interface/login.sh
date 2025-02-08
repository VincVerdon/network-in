#!/bin/bash
#Version 20250208

trap '#' SIGINT
trap '#' SIGKILL
trap '#' SIGTERM

VERSION=$(grep 'set version(equipment)' /var/networkin/interface/interface.tcl | sed -E 's/^.*version\(equipment\).+\{(.*)\}/\1/')

while true
do
    echo "Network-In simulator : Welcome ! (Equipment version : $VERSION)"
    read RIEN
    
    login
done

