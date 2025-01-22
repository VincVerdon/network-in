#!/usr/bin/env wish
####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
#version 20250107
set version(network-in) 2.0-beta4

# Démarrage de Network-in!
################################################################################
################################################################################

encoding system utf-8

# on determine le repertoire de demarrage
#set rep [info nameofexecutable]
set rep [file dirname [file normalize [info script]]]

# on définit le répertoire temporaire
set rep_tmp /tmp/network-in

# on initialise quelques variables
set ::tmp(id1) {}
set ::tmp(id2) {}

# on source le fichier de config général et personnel s'il existe
source /etc/network-in.cfg
if {[file exists $::rep_conf/network-in.cfg]} {
  source $::rep_conf/network-in.cfg
}

#Création du rep de projet s'il n'existe pas
if ![file exists $::rep_proj] {
	file mkdir $::rep_proj
}

#Création des rep de config et de stockage d'images disque s'il n'existent pas
if ![file exists $::rep_conf/disks] {
	file mkdir $::rep_conf/disks
	file mkdir $::rep_conf/kernels
}
if ![file exists $::rep_conf/kernels] {
	file mkdir $::rep_conf/kernels
}

# définition de la première ip de communication utilisable
set decoup [split $::ip_hote .]
set ::tmp(reseau) "[lindex $decoup 0].[lindex $decoup 1].[lindex $decoup 2]"
set ::tmp(n_ip_com) [lindex $decoup 3]
unset decoup

# on permet la connexion des machines UML sur notre serveur X
for  {set i 2} {$i <=20} {incr i} {
  exec xhost inet:$::tmp(reseau).$i
}

# on arrete tous les switchs vde restés actifs
catch {exec killall vde_switch}

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

# définition du message boite A propos
set ::apropos "[::msgcat::mc "Network-In! is a network simulator"]
V. Verdon Corp! - $::version(network-in)
https://network-in.vverdon.fr
"

# on source les differents modules
source [file join $rep xml_structure.tcl]
source [file join $rep interface.tcl]
source [file join $rep interface_composants.tcl]
source [file join $rep init_composants.tcl]
source [file join $rep traitement.tcl]
source [file join $rep machines passerelle config_passerelle.tcl]
source [file join $rep machines virtualbox config_virtualbox.tcl]
source [file join $rep machines bridge config_bridge.tcl]

lappend auto_path $::rep/ScidLightTheme
package require ttk-themes
# styles possibles : clam alt default classic
ttk::style theme use scidblue
#ttk::style configure TRadiobutton -color  {green}
ttk::style configure TButton -relief flat
#Les boutons répondent à la touche Entrée en plus de la touche espace
bind TButton <Key-Return> { 
	%W invoke
}
bind Button <Key-Return> { 
	%W invoke
}

#On vérifie si Virtualbox est installé
set ::tmp(vbox_found) [is_vbox_software_installed]

#Construction fenetre appli
creer_images_interface
creer_fontes_interface
fenetre_principale

if {[file exists $::rep_proj/datas/structure.xml]} {
	# restauration du projet en cours
    restaurer_projet
	if {$argc != 0} {
		#Cas où un nom de fichier est passé au démarrage
		dialogue_ouvrir_projet [lindex $argv 0]
	}
} else {
	# pas de projet en cours
	init_projet
	if {$argc != 0} {
		#Cas où un nom de fichier est passé au démarrage
		desarchiver_projet [lindex $argv 0]
	}
}
