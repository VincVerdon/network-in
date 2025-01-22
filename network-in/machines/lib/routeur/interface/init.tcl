#!/usr/bin/env wish
####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Interface routeur
# Version 20240101

encoding system utf-8

# on determine le repertoire de demarrage
set rep [info nameofexecutable]
set rep [file dirname [file normalize [info script]]]
# et le rep de communication
set rep_com $rep/../com
# et le rep de config du routage
set rep_conf $rep/../routage

# on initialise quelques variables
set ::nom_machine [exec hostname]
set ::window_id {}

# on source le fichier de config
source [file join $rep interface.cfg]

# on force la langue à utiliser (appelée "en" dans tous les cas !)
::msgcat::mclocale en
if {[file exists $::rep/dict.actu]} {
  set f [open $::rep/dict.actu r]
  set l [read $f]
  ::msgcat::::mcmset en $l
  close $f
}

# on source les differents modules
source [file join $rep lib_images.tcl]
source [file join $rep lib_interface.tcl]
source [file join $rep interface.tcl]
source [file join $rep config_reseau.tcl]

# démarrage de l'interface
fenetre_principale


