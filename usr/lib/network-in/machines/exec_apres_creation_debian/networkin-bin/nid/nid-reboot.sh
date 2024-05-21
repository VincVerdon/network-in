#!/bin/sh
# doit etre execute au redemarrage de la machine
# V. Verdon
REP_NETW=/var/networkin

echo "redemarrage en cours" > $REP_NETW/com/reboot
rm -f $REP_NETW/com/on

exit 0
