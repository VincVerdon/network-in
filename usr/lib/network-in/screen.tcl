#!/usr/bin/env wish
####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
#version 20250302
set version(network-in) 2.0-beta9

# Démarrage de Network-in!
################################################################################
################################################################################

encoding system utf-8

wm withdraw .

# on determine le repertoire de demarrage
#set rep [info nameofexecutable]
set rep [file dirname [file normalize [info script]]]

# on définit le répertoire temporaire
set rep_tmp /tmp/network-in

# on source le fichier de config général et personnel s'il existe
source /etc/network-in.cfg
if {[file exists $::rep_conf/network-in.cfg]} {
  source $::rep_conf/network-in.cfg
}

# on source les differents modules
source [file join $rep xml_structure.tcl]

# Démarrage affichage Xephyr
toplevel .x
wm attributes .x -zoomed true
update
set size [winfo geometry .x]
#wm geometry .x 1600x900
frame .x.f -container 1
pack .x.f -fill both -expand 1
update
exec Xephyr -parent [scan [winfo id .x.f] %x] -listen tcp -listen local -screen 1600x900 -resizeable $::screen &
#after 1000
update
#exec xfwm4 --display $::screen &

