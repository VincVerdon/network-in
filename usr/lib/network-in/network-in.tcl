#!/usr/bin/env wish
####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
#version 20251022
set version(network-in) 2.0

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

#Valeur de l'orientation par défaut de la fenêtre principale
set ::orientation horizontal

# on source le fichier de config général et personnel s'il existe
source /etc/network-in.cfg
if {[file exists $::rep_conf/network-in.cfg]} {
  source $::rep_conf/network-in.cfg
} else {
	set f [open $::rep_conf/network-in.cfg w]
	puts $f "#Insert here your own parameters configuration"
	puts $f "#This overrides /etc/network-in.cfg parameters"
	close $f
}

#Création des rep de config et de stockage d'images disque s'il n'existent pas
if ![file exists $::rep_conf/disks] {
	file mkdir $::rep_conf/disks
	file mkdir $::rep_conf/kernels
}
if ![file exists $::rep_conf/kernels] {
	file mkdir $::rep_conf/kernels
}

# Rep courant initial
set ::tmp(current_dir) $::rep_home

# définition de la première ip de communication utilisable
set decoup [split $::ip_hote .]
set ::tmp(reseau) "[lindex $decoup 0].[lindex $decoup 1].[lindex $decoup 2]"
set ::tmp(n_ip_com) [lindex $decoup 3]
unset decoup
# on permet la connexion des machines UML sur notre serveur X
# Indispensable pour copier/coller entre hôte et machines
for  {set i 2} {$i <=20} {incr i} {
  exec xhost inet:$::tmp(reseau).$i
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
source [file join $rep machines nat config_passerelle.tcl]
source [file join $rep machines virtualbox config_virtualbox.tcl]
source [file join $rep machines bridge config_bridge.tcl]

# Prise en compte des thèmes
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

# Package fsdialog pour amélioration des boites de gestion des fichiers (remplacement tk_getOpenFile et tk_SaveFile)
lappend auto_path $::rep/fsdialog
package require fsdialog

#On vérifie si Virtualbox est installé
set ::tmp(vbox_found) [is_vbox_software_installed]

#Construction fenetre appli
creer_images_interface
creer_fontes_interface
fenetre_principale

#Démarrage du scan du presse papier pour envoi aux machines du simulateur
set ::tmp(clip) ""
boucle_maj_clipboard

# restauration du projet en cours
if {[file exists $::rep_proj/structure.xml]} {
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

