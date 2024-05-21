####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Fonctions gestion réseau ordinateur et routeur
####################################################################
# Version 20231230

# Ecriture du nom dans /etc/hostname
################################################################################
proc changer_nom_machine {nom} {
	# Mise à jour hostname
	exec echo $nom > /etc/hostname
	exec hostname $nom
	
	# On met à jour le nom dans le fichier hosts
	exec sed -i s/$::nom_machine/$nom/ /etc/hosts
	
	# On sauvegarde le nouveau nom
	set ::nom_machine $nom
	
	# Affichage
	wm title . "$nom"
}

# Changement de la configuration IP
################################################################################
proc changer_ip_machine {} {
	
	# arret des interfaces
	catch {exec systemctl stop networking.service &}
	
	# mise à jour du fichier interfaces
	set f [open /etc/network/interfaces w]
	puts $f "#Automatic configuration by Network-In interface"
	puts $f ""
	# config de l'interface loopback
	puts $f "#Interface lo"
	puts $f "auto lo"
	puts $f "iface lo inet loopback"
	# config des ethernet
	for {set i 0} {$i < $::tmp(nb_eth)} {incr i} {
		set interface eth$i
		set address [lindex $::tmp($interface) 1]
		set mode [lindex $::tmp($interface) 0]
		set etat  [lindex $::tmp($interface) 4]
		if {$mode == {static} && $address != {}} {
			puts $f ""
			puts $f "#Interface $interface"
			if {$etat == {1}} {
				puts $f "auto $interface"
			}
			puts $f "iface $interface inet static"
			set address [lindex $::tmp($interface) 1]
			set netmask [lindex $::tmp($interface) 2]
			set gateway [lindex $::tmp($interface) 3]
			puts $f "address $address"
			puts $f "netmask $netmask"
			if {$gateway != {}} {
				puts $f "gateway $gateway"
			}
		}
		if {$mode == {dhcp}} {
			puts $f ""
			puts $f "#Interface $interface"
			if {$etat == {1}} {
				puts $f "auto $interface"
			}
			puts $f "iface $interface inet dhcp"
		}
	}
	close $f
	
	# redémarrage des interfaces réseau
	catch {exec systemctl start networking.service &}
	
}

# Lit le fichier d'échange des interfaces et complète les données dans $tmp
# $tmp(nb_eth) et $nb(nb_wlan) et les ip dans $tmp(eth0)... $tmp(wlan1)...
################################################################################
proc lire_interfaces {} {
	set ::tmp(nb_eth) 0
	set ::tmp(nb_wlan) 0
	
	set l_int [lire_fichier_echange interfaces]
	foreach {type nb} $l_int {
		set ::tmp(nb_$type) $nb
		for  {set i 0} {$i < $::tmp(nb_$type)} {incr i} {
			# lecture de la config ip des interfaces
			set ::tmp($type$i) [lire_interface $type$i]
		}
	}
}

# Fenetre de config du nom
################################################################################
proc fenetre_config_nom {} {
	
	destroy .cfg2
	toplevel .cfg2
	wm title .cfg2  [::msgcat::mc "Name configuration"]
	wm transient .cfg2 .
	positionne_fenetre .cfg2
	
	label .cfg2.ico -image img_config
	pack .cfg2.ico
	
	# zone de saisie
	labelframe .cfg2.f
	pack .cfg2.f -fill both -expand 1
	label .cfg2.f.l -text "[::msgcat::mc "Name"] :"
	pack .cfg2.f.l -side left
	entry .cfg2.f.e -background white
	pack .cfg2.f.e -fill x -side left -expand 1
	.cfg2.f.e insert end [lire_nom_machine]
	
	# boutons
	frame .cfg2.fb
	pack .cfg2.fb
	button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
		set ::tmp(nom) [.cfg2.f.e get]
		if {$::tmp(nom) == {}} {
			tk_messageBox -title [::msgcat::mc "Error"] -icon error -message [::msgcat::mc "You must choose a name"]
		} else  {
			changer_nom_machine $::tmp(nom)
			destroy .cfg2
		}
	}
	pack .cfg2.fb.v -side left
	button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
	pack .cfg2.fb.a -side left
}

# lecture du fichier hostname
################################################################################
proc lire_nom_machine {} {
	return [exec cat /etc/hostname]
}

# lecture du fichier interfaces
################################################################################
proc lire_interface {interface} {
	
	set mode {static}
	set etat 0
	set address {}
	set netmask {}
	set gateway {}
	
	set f [open /etc/network/interfaces r]
	
	# recherche de l'interface
	while {![eof $f]} {
		gets $f ligne
		if {[lindex $ligne 0] == "auto" && [lindex $ligne 1] == $interface} {
			set etat 1
		} elseif {[lindex $ligne 0]  == "iface" && [lindex $ligne 1] == $interface} {
			break
		} else  {
			set ligne {}
		}
	}
	if {$ligne == {}} {
		return [list $mode $address $netmask $gateway $etat]
	}
	
	# si dhcp, alors on a finit de lire le fichier et on sort
	set mode [lindex $ligne 3]
	if {$mode == "dhcp"} {
		close $f
		return [list $mode $address $netmask $gateway $etat ]
	}
	
	# recherche des autres paramètres
	while {![eof $f]} {
		gets $f ligne
		switch [lindex $ligne 0] {
			{iface} {
				# on tombe sur la config d'une autre interface. On sort !
				break
			}
			{address} {set address [lindex $ligne 1]}
			{netmask} {set netmask [lindex $ligne 1]}
			{gateway} {set gateway [lindex $ligne 1]}
		}
	}
	close $f
	return [list $mode $address $netmask $gateway $etat]
}

