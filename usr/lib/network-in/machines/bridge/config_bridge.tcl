####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de config de la bridge nat
####################################################################
# Version 20240504

# Interface de configuration de base de la machine
################################################################################
proc fenetre_config_bridge {id} {
  
	destroy .bridge
  toplevel .bridge
  maj_nom_bridge $id
  wm protocol .bridge WM_DELETE_WINDOW {supprime_fenetre_config_bridge}
  wm iconphoto .bridge -default im_bridge
  
  label .bridge.ico -image im_bridge
  pack .bridge.ico
  
  labelframe .bridge.f -text [::msgcat::mc "Configuration"]
  pack .bridge.f -fill both -expand 1
  button .bridge.f.1 -text [::msgcat::mc "Bridge interface name"]  -command "fenetre_config_nom_tap_bridge $id" -width 20
  pack .bridge.f.1 -fill x
	button .bridge.f.2 -text [::msgcat::mc "Bridge IP configuration"]  -command "fenetre_config_ip_bridge $id" -width 20
	pack .bridge.f.2 -fill x
  button .bridge.f.3 -text [::msgcat::mc "Name"] -command "fenetre_config_nom_bridge $id"
  pack .bridge.f.3 -fill x
  
	# boutons
	frame .bridge.fb
	pack .bridge.fb
	ttk::button .bridge.fb.a -compound left -text [::msgcat::mc "Close"] -image im_annuler -command {supprime_fenetre_config_bridge}
	pack .bridge.fb.a -side left
	
}

################################################################################
proc supprime_fenetre_config_bridge {} {
	destroy .bridge
	destroy .bridge2
	destroy .bridge3
}

# Fait passer la fenêtre de la bridge en avant-plan
################################################################################
proc raise_bridge {} {
	if [winfo exists .bridge] {
		raise .bridge
	}
}

# Fait disparaître la fenêtre de la bridge
################################################################################
proc hide_bridge {} {
	if [winfo exists .bridge] {
		lower .bridge
	}
}


################################################################################
proc change_nom_bridge {id} {
  set ::obj($id,nom) $::tmp(nom)
  # mise à jour dans l'interface du bridge
  maj_nom_bridge $id
  # on régénère le dessin de l'objet
  dessine_objet $id
}


################################################################################
proc maj_nom_bridge {id} {
  if {$::obj($id,nom) == {}} {
    wm title .bridge [::msgcat::mc "unnamed"]
  } else  {
    wm title .bridge $::obj($id,nom)
  }
}


# Fenetre de config du nom
################################################################################
proc fenetre_config_nom_bridge {id} {
  
  destroy .bridge2
  toplevel .bridge2
  wm title .bridge2 [::msgcat::mc "Name configuration"]
  wm transient .bridge2 .bridge
  
  label .bridge2.ico -image im_config
  pack .bridge2.ico
  
  # zone de saisie
  labelframe .bridge2.f
  pack .bridge2.f -fill both -expand 1
  label .bridge2.f.l -text "[::msgcat::mc "Name"] : "
  pack .bridge2.f.l -side left
  entry .bridge2.f.e -background white -textvariable ::tmp(nom)
  set ::tmp(nom) $::obj($id,nom)
  pack .bridge2.f.e -fill x -side left -expand 1
  
  # boutons
  frame .bridge2.fb
  pack .bridge2.fb
  button .bridge2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "
    change_nom_bridge $id
    destroy .bridge2
  "
  pack .bridge2.fb.v -side left
  button .bridge2.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .bridge2} -relief flat
  pack .bridge2.fb.a -side left
}

# Fenetre de config du nom de l'interface TAP du bridge
################################################################################
proc fenetre_config_nom_tap_bridge {id} {
	
	destroy .bridge2
	toplevel .bridge2
	wm title .bridge2 [::msgcat::mc "Interface configuration"]
	wm transient .bridge2 .bridge
	
	label .bridge2.ico -image im_config
	pack .bridge2.ico
	
	# zone de saisie
	labelframe .bridge2.f
	pack .bridge2.f -fill both -expand 1
	label .bridge2.f.l -text "[::msgcat::mc "Interface name"] : "
	pack .bridge2.f.l -side left
	entry .bridge2.f.e -background white -textvariable ::tmp(tap)
	set ::tmp(tap) $::obj($id,tap)
	pack .bridge2.f.e -fill x -side left -expand 1
	
	# boutons
	frame .bridge2.fb
	pack .bridge2.fb
	button .bridge2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "
		change_nom_tap_bridge $id
		destroy .bridge2
	"
	pack .bridge2.fb.v -side left
	button .bridge2.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .bridge2} -relief flat
	pack .bridge2.fb.a -side left
}


################################################################################
proc change_nom_tap_bridge {id} {
	set ::obj($id,tap) $::tmp(tap)
	# mise à jour dans l'interface du bridge
	maj_nom_bridge $id
	# on régénère le dessin de l'objet
	dessine_objet $id
}


# Fenetre de config de l'adresse
################################################################################
proc fenetre_config_ip_bridge {id} {
  
  set ::tmp(ip) $::obj($id,ip_eth0)
  set ::tmp(netmask)  $::obj($id,netmask_eth0)
	set ::tmp(ip_anc) $::obj($id,ip_eth0)
	set ::tmp(netmask_anc)  $::obj($id,netmask_eth0)
  
  destroy .bridge3
  toplevel .bridge3
  wm title .bridge3 [::msgcat::mc "IP configuration"]
  if {[winfo exists .bridge2]} {
    wm transient .bridge3 .bridge2
  } else  {
    wm transient .bridge3 .bridge
  }
  
  label .bridge3.ico -image im_config
  pack .bridge3.ico
  
  # Activation de l'interface
  labelframe .bridge3.f2 -text [::msgcat::mc "Generalities"]
  pack .bridge3.f2 -fill both -expand 1
  label .bridge3.f2.l0 -text [::msgcat::mc "Type : ethernet"]
	grid .bridge3.f2.l0 -row 1 -column 2 -sticky w
  label .bridge3.f2.l1 -text "Nom : $::obj($id,tap)"
	grid .bridge3.f2.l1 -row 1 -column 0 -sticky w
	
  # zone de saisie
  labelframe .bridge3.f -text [::msgcat::mc "Parameters"]
  pack .bridge3.f -fill both -expand 1
  label .bridge3.f.l1 -text "[::msgcat::mc "IP address"] : "
  entry .bridge3.f.e1 -background white -width 16 -textvariable ::tmp(ip)
  label .bridge3.f.l2 -text "[::msgcat::mc "Network mask"] : "
  entry .bridge3.f.e2 -background white -width 16 -textvariable ::tmp(netmask)
  grid .bridge3.f.l1 -row 1 -column 0 -sticky e
  grid .bridge3.f.e1 -row 1 -column 1 -sticky w
  grid .bridge3.f.l2 -row 2 -column 0 -sticky e
  grid .bridge3.f.e2 -row 2 -column 1 -sticky w
  
  # boutons
  frame .bridge3.fb
  pack .bridge3.fb
  button .bridge3.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .bridge3} -relief flat
  pack .bridge3.fb.a -side right
  button .bridge3.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "applique_config_bridge $id ; destroy .bridge3"
  pack .bridge3.fb.v -side right
  
}

################################################################################
proc applique_config_bridge {id} {
  
  set ::obj($id,ip_eth0) $::tmp(ip)
  set ::obj($id,netmask_eth0) $::tmp(netmask)
	#set ::tmp($id,etat_eth0) "$::obj($id,ip_eth0)/[calcul_cidr $::obj($id,netmask_eth0)]"
	
  # on applique les changements : redémarrage des règles du parefeu
	exec_config_bridge $id $::tmp(ip_anc) $::tmp(netmask_anc) stop
  exec_config_bridge $id $::obj($id,ip_eth0) $::obj($id,netmask_eth0) start
	
	#on met à jour l'affichage les infos sur l'IP si elles sont affichées actuellement
	set id_liaison $::obj($id,eth0)
	if {$id_liaison != "" && $::tmp($id_liaison,infos_connexion)} {
		maj_infos_connexion $id_liaison
	}
	
	unset ::tmp(ip)
	unset ::tmp(ip_anc)
	unset ::tmp(netmask)
	unset ::tmp(netmask_anc)
}

################################################################################
proc exec_config_bridge {id ip masque action} {
  
  catch {exec sudo $::rep/bin/conf_bridge $ip $masque $action}
	
	#Mise à jour étiquettes infos
	set id_liaison $::obj($id,eth0)
	maj_infos_connexion $id_liaison
	
}


# Démarrage de la bridge
################################################################################
proc demarre_bridge {id} {
	
	puts ">>>>Démarrage BRIDGE $id"
	
	set famille $::obj($id,famille)
	set type $::obj($id,type)
	
	# Conf actuelle de l'interface pour affichage
	if {$::obj($id,ip_eth0) != "" && $::obj($id,netmask_eth0) != ""} {
		set ::tmp($id,etat_eth0) "$::obj($id,ip_eth0)/[calcul_cidr $::obj($id,netmask_eth0)]"
	} else {
		set ::tmp($id,etat_eth0) ""
	}
	
	# Configuration de l'interface réseau
	catch {exec sudo $::rep/bin/conf_bridge $id $::obj($id,tap) start $::obj($id,ip_eth0) $::obj($id,netmask_eth0)}
	
	# l'objet est déclaré actif désormais
	set ::tmp($id,etat) 1
	affiche_objet_on $id
	
	# activation du câble réseau
	set id_liaison $::obj($id,eth0)
	if {$id_liaison != {}} {
		demarre_connexion $id_liaison
	}
	maj_infos_connexion $id_liaison
}


# Arrêt du bridge
################################################################################
proc arrete_bridge_0 {id} {
	
	# on débranche le câble
	set id_liaison $::obj($id,eth0)
	set ::tmp($id,etat_eth0) {}
	arrete_connexion $id_liaison
	
	# l'objet est déclaré inactif désormais
	set ::tmp($id,etat) 0
	affiche_objet_off $id
	
	# Déconfiguration de l'interface réseau
	exec_config_bridge $id $::obj($id,ip_eth0) $::obj($id,netmask_eth0) stop
	
	puts ">>>>BRIDGE $id arrêté"
	
}

################################################################################
proc arrete_bridge {id} {
	
	catch {exec sudo $::rep/bin/conf_bridge $id $::obj($id,tap) stop} 
	# l'objet est déclaré inactif désormais
	set ::tmp($id,etat) 0
	affiche_objet_off $id
	puts ">>>>BRIDGE $id arrêté"
	
}
