#!/bin/bash
### BEGIN INIT INFO
# Provides:          nid
# Required-Start:
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Demarrage du daemon network-in
# Description: Demarrage du daemon de communication avec network-in
### END INIT INFO
# Démarrage et arrêt du daemon de network-in!
# V. Verdon
# Version 20241229
REP_NETW=/var/networkin
PID=/var/run/nid
PID_INTERFACE=/var/run/nid_interface

case "$1" in
    start)	#creation du répertoire REP_NETW et montage pour communication avec le simulateur
        if [ -e $REP_NETW ]
        then
            umount $REP_NETW
        else
            mkdir $REP_NETW
        fi
            mount -n -t hostfs none  $REP_NETW
            $REP_NETW/nid/nid-main &
	;;
    stop)
        kill $(cat $PID)
        rm $PID
        kill $(cat $PID_INTERFACE)
        rm $PID_INTERFACE
    ;;
    *)
        echo "Usage: nid {start|stop}"
        exit 2
    ;;
esac
exit 0
