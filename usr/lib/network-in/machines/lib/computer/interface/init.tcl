#!/usr/bin/env wish
####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20260414
# Bureau version ordinateur

encoding system utf-8

# on determine le repertoire de demarrage
set rep [info nameofexecutable]
set rep [file dirname [file normalize [info script]]]
# et le rep de communication
set rep_com $rep/../com

# on source le fichier de config
source [file join $rep interface.cfg]
set font(name) [list $font(name)]

# chargement du catalogue de messages
package require msgcat 1.3
# on force la langue à utiliser (appelée "en" dans tous les cas !)
::msgcat::mclocale en
if {[file exists $rep/dict.actu]} {
  set f [open $rep/dict.actu r]
  set l [read $f]
  ::msgcat::::mcmset en $l
  close $f
}

# on source les differents modules
source [file join $rep lib_images.tcl]
source [file join $rep lib_interface.tcl]
source [file join $rep interface.tcl]

# on initialise quelques variables
set ::nom_machine [exec hostname]
set ::window_id {}
set ::display [lire_fichier_echange display]
set ::ip_hote [lire_fichier_echange ip_hote]
set ::display_hote [lire_fichier_echange display_hote]

# démarrage de l'interface
fenetre_principale
