#!/usr/bin/env wish
####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
#version 20260728
set version(network-in) 2.1.0

# Démarrage de Network-in!
################################################################################
################################################################################
puts "Starting user program network-in.tcl"

encoding system utf-8

wm withdraw .

# On determine le repertoire de demarrage
set rep [file dirname [file normalize [info script]]]

# On définit le répertoire temporaire
set rep_tmp /tmp/network-in

# Valeur de l'orientation par défaut de la fenêtre principale
set ::orientation horizontal

# On source le fichier de config général
source /etc/network-in.cfg

# Création des rep de config et de stockage d'images disque perso s'ils n'existent pas
if ![file exists $::rep_conf/disks] {
	file mkdir $::rep_conf/disks
} else {
	# Mise à jour des mtime des disques système si nécessaire
	# Utile si lecture d'une maquette importée (contrôle mtime par linux.uml au démarrage VM)
	puts [exec $rep/bin/set_disks_mtime $::rep_conf/disks]
}
if ![file exists $::rep_conf/kernels] {
	file mkdir $::rep_conf/kernels
} else {
	 # Mise à jour des mtime des disques modules si nécessaire
	 # Utile si lecture d'une maquette importée (contrôle mtime par linux.uml au démarrage VM)
	 puts [exec $rep/bin/set_disks_mtime $::rep_conf/kernels]
 }

# Prise en compte fichier de conf personnel s'il existe
if {[file exists $::rep_conf/network-in.cfg]} {
  source $::rep_conf/network-in.cfg
} else {
	set f [open $::rep_conf/network-in.cfg w]
	puts $f "#Insert here your own configuration parameters"
	puts $f "#This overrides /etc/network-in.cfg parameters"
	close $f
}
set font(xterm) [list $font(xterm)]

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
package require msgcat
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
# Définition des exe vde4networkin (vde2)
set rep_vde $rep/vde4networkin
set ::vde(switch) $rep_vde/vde_switch
set ::vde(mswitch) $rep_vde/vde_switch
set ::vde(term) $rep_vde/vdeterm
set ::vde(dpipe) $rep_vde/dpipe
set ::vde(plug) $rep_vde/vde_plug
unset rep_vde

# Définition exe st
set ::exe_st $rep/bin/st

# on source les differents modules
source [file join $rep xml_structure.tcl]
source [file join $rep interface.tcl]
source [file join $rep interface_composants.tcl]
source [file join $rep init_composants.tcl]
source [file join $rep traitement.tcl]
source [file join $rep capture.tcl]
source [file join $rep machines nat nat.tcl]
source [file join $rep machines virtualbox virtualbox.tcl]
source [file join $rep machines bridge bridge.tcl]
source [file join $rep machines mswitch mswitch.tcl]

# Package fsdialog pour amélioration des boites de gestion des fichiers (remplacement tk_getOpenFile et tk_SaveFile)
lappend auto_path $::rep/fsdialog
package require fsdialog

# Prise en compte des thèmes
lappend auto_path $::rep/ScidLightTheme
package require ttk-themes
ttk::style theme use scidblue
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

#On définit si l'utilisateur a l'autorisation de faire des captures
#Si non, on utilisera le compte générique networkin-cap
#if {![has_capture_rights]} {
#	set capture(exe) "sudo -u networkin-cap $capture(exe)"
#}

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

puts "network-in.tcl started"
