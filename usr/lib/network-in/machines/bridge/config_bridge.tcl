####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de config de la bridge nat
####################################################################
# Version 20250128

# Interface de configuration de base de la machine
################################################################################
proc interface_bridge {id} {
  
	destroy .br$id
	toplevel .br$id
	maj_nom_bridge $id
	wm protocol .br$id WM_DELETE_WINDOW {#}
	wm iconphoto .br$id -default im_bridge
    wm resizable .br$id 0 0
	
	label .br$id.ico -image im_bridge
	pack .br$id.ico
  
	labelframe .br$id.f -text [::msgcat::mc "Configuration"]
	pack .br$id.f -fill both -expand 1
	#button .br$id.f.1 -text [::msgcat::mc "Bridge interface name"]  -command "fenetre_config_nom_tap_bridge $id" -width 20
	#pack .br$id.f.1 -fill x
	button .br$id.f.2 -text [::msgcat::mc "Host side IP configuration"]  -command "fenetre_config_ip_bridge $id" -width 20
	pack .br$id.f.2 -fill x
	button .br$id.f.3 -text [::msgcat::mc "Name"] -command "fenetre_config_nom_bridge $id"
	pack .br$id.f.3 -fill x
    
    # boutons
    button .br$id.arret -compound left -text [::msgcat::mc "Switch off"] -image im_eteindre -relief flat -command "arrete_bridge $id"
    pack .br$id.arret -anchor w
	
}


# Fait passer la fenêtre de la bridge en avant-plan
################################################################################
proc raise_bridge {id} {
	if [winfo exists .br$id] {
		raise .br$id
	}
}


# Fait disparaître la fenêtre de la bridge
################################################################################
proc hide_bridge {id} {
	if [winfo exists .br$id] {
		lower .br$id
	}
}


# Renommage du bridge
################################################################################
proc applique_change_nom_bridge {id} {
    
    if {$::obj($id,nom) == {}} {
        set ::obj($id,nom) $id
    } else  {
        set ::obj($id,nom) $::tmp($id,nom)
    }
    # mise à jour dans l'interface du bridge
    maj_nom_bridge $id
    
}


# Mise à jour du nom du bridge dans l'interface
################################################################################
proc maj_nom_bridge {id} {
    
    wm title .br$id $::obj($id,nom)
    # on régénère le dessin de l'objet
    dessine_objet $id
    
}


# Fenetre de config du nom
################################################################################
proc fenetre_config_nom_bridge {id} {
  
    if [winfo exists .brnom$id] {
        raise .brnom$id
        return
    }
    
  set ::tmp($id,nom) $::obj($id,nom)
    
  toplevel .brnom$id
  wm title .brnom$id [::msgcat::mc "Name configuration"]
  wm transient .brnom$id .br$id
  positionne_fenetre .brnom$id .br$id
  
  label .brnom$id.ico -image im_config
  pack .brnom$id.ico
  
  # zone de saisie
  labelframe .brnom$id.f
  pack .brnom$id.f -fill both -expand 1
  label .brnom$id.f.l -text "[::msgcat::mc "Name"] : "
  pack .brnom$id.f.l -side left
  entry .brnom$id.f.e -background white -textvariable ::tmp($id,nom)
  pack .brnom$id.f.e -fill x -side left -expand 1
  
  # boutons
  frame .brnom$id.fb
  pack .brnom$id.fb
  button .brnom$id.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "applique_change_nom_bridge $id ; destroy .brnom$id"
  pack .brnom$id.fb.v -side left
  button .brnom$id.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command "destroy .brnom$id" -relief flat
  pack .brnom$id.fb.a -side left
    
}

# Fenetre de config du nom de l'interface TAP du bridge
################################################################################
proc fenetre_config_nom_tap_bridge {id} {
	
    if [winfo exists .brnom$id] {
        raise .brnom$id
        return
    }
    
    set ::tmp($id,nom_tap) $::obj($id,nom_tap)
    
	toplevel .brnom$id
	wm title .brnom$id [::msgcat::mc "Interface configuration"]
	wm transient .brnom$id .br$id
    positionne_fenetre .brnom$id .br$id
    
	label .brnom$id.ico -image im_config
	pack .brnom$id.ico
	
	# zone de saisie
	labelframe .brnom$id.f
	pack .brnom$id.f -fill both -expand 1
	label .brnom$id.f.l -text "[::msgcat::mc "Interface name"] : "
	pack .brnom$id.f.l -side left
	entry .brnom$id.f.e -background white -textvariable ::tmp($id,tap)
	pack .brnom$id.f.e -fill x -side left -expand 1
	
	# boutons
	frame .brnom$id.fb
	pack .brnom$id.fb
	button .brnom$id.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "change_nom_tap_bridge $id ; destroy .brnom$id"
	pack .brnom$id.fb.v -side left
	button .brnom$id.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command "destroy .brnom$id" -relief flat
	pack .brnom$id.fb.a -side left
}


################################################################################
proc change_nom_tap_bridge {id} {
	set ::obj($id,nom_tap) $::tmp($id,nom_tap)
	# mise à jour dans l'interface du bridge
	maj_nom_bridge $id
	# on régénère le dessin de l'objet
	dessine_objet $id
}


# Fenetre de config de l'adresse
################################################################################
proc fenetre_config_ip_bridge {id} {
    
    if [winfo exists .brip$id] {
        raise .brip$id
        return
    }
    
    set ::tmp($id,ip) $::obj($id,ip_tap)
    set ::tmp($id,netmask) $::obj($id,netmask_tap)
    set ::tmp($id,gateway) $::obj($id,gateway_tap)
    set ::tmp($id,conf_tap) $::obj($id,conf_tap)

    toplevel .brip$id
    wm title .brip$id [::msgcat::mc "Host side IP configuration"]
    wm transient .brip$id .br$id
    positionne_fenetre .brip$id .br$id

    label .brip$id.ico -image im_config
    pack .brip$id.ico

    # Activation de l'interface
    labelframe .brip$id.f2 -text [::msgcat::mc "Generalities"]
    pack .brip$id.f2 -fill both -expand 1
    label .brip$id.f2.l -text [::msgcat::mc "Type : ethernet"]
    grid .brip$id.f2.l -row 1 -column 1 -sticky e
    label .brip$id.f2.l1 -text "[::msgcat::mc "Name"] : $::obj($id,nom_tap)"
    grid .brip$id.f2.l1 -row 1 -column 0 -sticky w
    
    # Zone de choix du type de config
    labelframe .brip$id.f0 -text [::msgcat::mc "Configuration method"]
    pack .brip$id.f0 -fill both -expand 1
    
    ttk::radiobutton .brip$id.f0.r1 -text "[::msgcat::mc "Managed by the host system"]" \
    -value {host} -variable ::tmp($id,conf_tap) -command  "desactive_interface_conf_ip $id"
    grid .brip$id.f0.r1 -row 0 -column 0 -sticky w
    ttk::radiobutton .brip$id.f0.r2 -text "[::msgcat::mc "DHCP configuration"]" \
    -value {dhcp} -variable ::tmp($id,conf_tap) -command "desactive_interface_conf_ip $id"
    #grid .brip$id.f0.r2 -row 1 -column 0 -sticky w
    ttk::radiobutton .brip$id.f0.r3 -text "[::msgcat::mc "Static configuration"]" \
    -value {static} -variable ::tmp($id,conf_tap) -command  "active_interface_conf_ip $id"
    grid .brip$id.f0.r3 -row 2 -column 0 -sticky w
    
    # zone de saisie
    labelframe .brip$id.f -text [::msgcat::mc "Parameters"]
    pack .brip$id.f -fill both -expand 1
    label .brip$id.f.l1 -text "[::msgcat::mc "IP address"] : "
    entry .brip$id.f.e1 -background white -width 16 -textvariable ::tmp($id,ip)
    label .brip$id.f.l2 -text "[::msgcat::mc "Network mask"] : "
    entry .brip$id.f.e2 -background white -width 16 -textvariable ::tmp($id,netmask)
    label .brip$id.f.l3 -text "[::msgcat::mc "Gateway address"] : "
    entry .brip$id.f.e3 -background white -width 16 -textvariable ::tmp($id,gateway)
    grid .brip$id.f.l1 -row 1 -column 0 -sticky e
    grid .brip$id.f.e1 -row 1 -column 1 -sticky w
    grid .brip$id.f.l2 -row 2 -column 0 -sticky e
    grid .brip$id.f.e2 -row 2 -column 1 -sticky w
    grid .brip$id.f.l3 -row 3 -column 0 -sticky e
    grid .brip$id.f.e3 -row 3 -column 1 -sticky w
    
    # boutons
    frame .brip$id.fb
    pack .brip$id.fb
    button .brip$id.fb.a -compound left -text [::msgcat::mc "Abort"] -relief flat -image im_annuler -command "destroy .brip$id"
    pack .brip$id.fb.a -side right
    button .brip$id.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "ch_ip_bridge $id"
    pack .brip$id.fb.v -side right
    
    if {$::tmp($id,conf_tap) != "static"} {
        desactive_interface_conf_ip $id
    }
}


# Désactivation de la conf IP dans l'interface
################################################################################
proc desactive_interface_conf_ip {id} {

    .brip$id.f.e1 configure -state readonly
    .brip$id.f.e2 configure -state readonly
    .brip$id.f.e3 configure -state readonly
}


# Activation de la conf IP dans l'interface
################################################################################
proc active_interface_conf_ip {id} {

    .brip$id.f.e1 configure -state normal
    .brip$id.f.e2 configure -state normal
    .brip$id.f.e3 configure -state normal
}


# Application des choix de conf IP saisis dans l'interface
################################################################################
proc ch_ip_bridge {id} {

    if {$::obj($id,conf_tap) == {static} && ($::tmp($id,ip) == {} || $::tmp($id,netmask) == {})} {
        tk_messageBox -parent .brip$id -title [::msgcat::mc "Error"] -icon error \
        -message [::msgcat::mc "You must choose  an IP address and a mask"]
    } else {
        applique_config_bridge $id
    }
    destroy .brip$id
    
}


################################################################################
proc applique_config_bridge {id} {
  
    set ::obj($id,conf_tap) $::tmp($id,conf_tap)
    set ::obj($id,ip_tap) $::tmp($id,ip)
    set ::obj($id,netmask_tap) $::tmp($id,netmask)
    set ::obj($id,gateway_tap) $::tmp($id,gateway)
	
    # on applique les changements : arrêt et redémarrage de l'interface TAP
    exec_config_bridge $id stop
    exec_config_bridge $id start
    
	unset ::tmp($id,ip)
	unset ::tmp($id,netmask)
    unset ::tmp($id,gateway)
    
    maj_infos_connexion_bridge $id
    
}

# Exécution du script de configuration TAP côté hôte
################################################################################
proc exec_config_bridge {id action} {
    
    if {$action != "start"} {
        catch {exec sudo $::rep/bin/conf_bridge $id $::obj($id,nom_tap) stop}
    } else {
        switch $::obj($id,conf_tap) {
            {host} {
                catch {exec sudo $::rep/bin/conf_bridge $id $::obj($id,nom_tap) host $::obj($id,mac_tap)}
            }
            {static} {
            	catch {exec sudo $::rep/bin/conf_bridge $id $::obj($id,nom_tap) static $::obj($id,mac_tap) $::obj($id,ip_tap) $::obj($id,netmask_tap) $::obj($id,gateway_tap)}
            }
            {dhcp} {
                catch {exec sudo $::rep/bin/conf_bridge $id $::obj($id,nom_tap) dhcp $::obj($id,mac_tap) &}
            }
        }
    }
    
}

# Mise à jour des étiquettes d'état de l'interface ethernet du TAP
################################################################################
proc maj_infos_connexion_bridge_anc {id} {
	
	set liaison $::obj($id,eth0)
	
    if {$::obj($id,ip_tap) != {} && $::obj($id,netmask_tap) != {}} {
        set ::tmp($id,etat_tap) "$::obj($id,ip_tap)/[calcul_mask_dec2cidr $::obj($id,netmask_tap)]"
    } else {
        set ::tmp($id,etat_tap) {}
    }
	
	maj_infos_connexion $liaison
	
}


# Mise à jour des étiquettes d'état de l'interface ethernet du TAP
################################################################################
proc maj_infos_connexion_bridge {id} {
	
	set liaison $::obj($id,eth0)
	set infos [get_interface_ip $::obj($id,nom_tap)]
	set ip [lindex $infos 0]
	if { $ip  != {}} {
		set ::tmp($id,etat_tap) "$ip/[lindex $infos 1]"
	} else {
		set ::tmp($id,etat_tap) {}
	}
	
	maj_infos_connexion $liaison
	
}

# Démarrage du bridge
################################################################################
proc demarre_bridge {id} {
	
	puts ">>>>Démarrage BRIDGE $id"
    
	# Configuration de l'interface réseau
    exec_config_bridge $id start
    
	#Affichage interface
    interface_bridge $id
    
    # l'objet est déclaré actif désormais
	set ::tmp($id,etat) 1
	affiche_objet_on $id
    
	# activation du câble réseau
	demarre_connexion $::obj($id,eth0)
    
	#Mise à jour affichage sur les étiquettes de câbles
	set ::tmp($id,etat_eth0) {}
	set ::tmp($id,etat_tap) {}
    maj_infos_connexion_bridge $id
	
}


# Arrêt du bridge
################################################################################
proc arrete_bridge {id} {
    
    destroy .br$id
    destroy .brnom$id
    destroy .brip$id

    # on débranche le câble de connexion
	set id_liaison $::obj($id,eth0)
	arrete_connexion $id_liaison
    
    #Déconfiguration de l'interface TAP
    exec_config_bridge $id stop
	
    # l'objet est déclaré inactif désormais
	set ::tmp($id,etat) 0
	affiche_objet_off $id
    maj_infos_connexion_bridge $id
	puts ">>>>BRIDGE $id arrêté"
	
}
