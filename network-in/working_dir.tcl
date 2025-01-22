#!/usr/bin/env tclsh
####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
#version 20231013


# Démarrage de Network-in!
################################################################################
################################################################################

# on determine le repertoire de demarrage
set rep [file dirname [file normalize [info script]]]

# on source le fichier de config
source /etc/network-in.cfg
if {[file exists ~/.network-in.cfg]} {
  source ~/.network-in.cfg
}

puts [file normalize $rep_proj]
exit
