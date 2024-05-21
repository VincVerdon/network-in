#!/usr/bin/env wish
####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
#version du fichier 20170214

wm withdraw .

encoding system utf-8

# on determine le repertoire de demarrage
set rep [info nameofexecutable]
set rep [file dirname [file normalize [info script]]]

# on définit le répertoire temporaire
set rep_tmp /tmp/network-in

# on source le fichier de config
source /etc/network-in.cfg
if {[file exists ~/.network-in.cfg]} {
  source ~/.network-in.cfg
}

# Prise en compte de la langue souhaitée
if {$::lang == {auto}} {
  set lang [string range $env(LANG) 0 1]
}
if {![file exists $::rep/lang/dict.$::lang]} {
  # choix de l'anglais par défaut
  set ::lang en
}
package require msgcat 1.3
::msgcat::mclocale $::lang
set f [open $::rep/lang/dict.$::lang r]
set l [read $f]
close $f
::msgcat::::mcmset $::lang $l
unset f l

set message $argv
tk_messageBox -icon error -title [::msgcat::mc "Network-In!"] -message [::msgcat::mc $message]
exit

