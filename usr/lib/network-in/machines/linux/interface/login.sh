#!/bin/bash

trap '#' SIGINT
trap '#' SIGKILL
trap '#' SIGTERM

while true
do
    echo 'Network-In simulator : Welcome !'
    read RIEN
    
    login
done

