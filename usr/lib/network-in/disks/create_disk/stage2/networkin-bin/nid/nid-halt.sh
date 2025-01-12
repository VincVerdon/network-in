#!/bin/sh
# doit etre execute a l'arret de la machine
# V. Verdon
# Version 20241229
REP_NETW=/var/networkin

echo "Arret en cours" > $REP_NETW/com/halt
rm -f $REP_NETW/com/on

exit 0
