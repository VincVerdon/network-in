####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de config de la passerelle nat
####################################################################
# Version 20250427
set ::version(vbox) 1.0

# Interface de configuration de base de la machine
################################################################################
proc fenetre_config_vbox {id} {
	
	destroy .vbox$id
	toplevel .vbox$id
	wm title .vbox$id [get_vbox_current_name $id]
	wm protocol .vbox$id WM_DELETE_WINDOW "supprime_fenetre_config_vbox $id"
	wm transient .vbox$id .main
	#wm iconphoto .vbox$id -default im_virtualbox
	wm resizable .vbox$id 0 0
	#positionne_fenetre .vbox$id
	
	label .vbox$id.ico -image im_virtualbox
	pack .vbox$id.ico
	
	labelframe .vbox$id.f -text [::msgcat::mc "Configuration"]
	pack .vbox$id.f -fill both -expand 1
	button .vbox$id.f.1 -text [::msgcat::mc "Name"]  -command "fenetre_config_nom_vbox $id" -width 20
	pack .vbox$id.f.1 -fill x
	button .vbox$id.f.2 -text [::msgcat::mc "VM selection"]  -command "fenetre_select_vbox $id" -width 20
	pack .vbox$id.f.2 -fill x
	button .vbox$id.f.3 -text [::msgcat::mc "Connected interface"] -command "fenetre_select_interf_vbox $id"
	pack .vbox$id.f.3 -fill x
	if {! $::tmp($id,is_present)} {
		.vbox$id.f.3 configure -state disabled
	}
	button .vbox$id.f.4 -text [::msgcat::mc "About"] -command "a_propos $::version(vbox) .vbox$id"
	pack .vbox$id.f.4 -fill x
	# boutons
	frame .vbox$id.fb
	pack .vbox$id.fb
	ttk::button .vbox$id.fb.a -compound left -text [::msgcat::mc "Close"] -image im_annuler -command "supprime_fenetre_config_vbox $id"
	pack .vbox$id.fb.a -side left
	
}


################################################################################
proc supprime_fenetre_config_vbox {id} {
	destroy .vbox$id
	destroy .vbox2$id
	destroy .vbox3$id
}


# Fait passer la fenêtre de la passerelle en avant-plan
################################################################################
proc show_vbox {id} {
	if [winfo exists .vbox$id] {
		raise .vbox$id
	}
}


# Fait disparaître la fenêtre de la passerelle
################################################################################
proc hide_vbox {} {
	if [winfo exists .vbox$id] {
		lower .vbox$id
		wm withdraw .vbox$id
	}
}

# Interface de configuration de base de la machine
################################################################################
proc fenetre_select_vbox {id} {
  
	destroy .vbox2$id
	toplevel .vbox2$id
	wm title .vbox2$id [::msgcat::mc "VM selection"]
	wm transient .vbox2$id .vbox$id
	positionne_fenetre .vbox2$id .vbox$id
	
	label .vbox2$id.ico -image im_config
	pack .vbox2$id.ico
	
	# zone de saisie
	labelframe .vbox2$id.f
	pack .vbox2$id.f -fill both -expand 1
	label .vbox2$id.f.l -text "[::msgcat::mc "Actual VM ID"] : "
	pack .vbox2$id.f.l -side left
	label .vbox2$id.f.e -background white -text $::obj($id,vbox_id)
	pack .vbox2$id.f.e -fill x -side left -expand 1
	
	# zone d'affichage des VM virtualbox existantes
	labelframe .vbox2$id.fvm -text [::msgcat::mc "VMs list"]
	pack .vbox2$id.fvm -fill both -expand 1
	ttk::treeview .vbox2$id.fvm.t -columns {nom id} -show headings -yscroll ".vbox2$id.fvm.sv set"
	pack .vbox2$id.fvm.t -side left -fill both -expand 1
	scrollbar .vbox2$id.fvm.sv -orient vertical -command ".vbox2$id.fvm.t yview"
	pack .vbox2$id.fvm.sv -side left -fill y
	.vbox2$id.fvm.t heading nom -text [::msgcat::mc "Name"]
	.vbox2$id.fvm.t heading id -text [::msgcat::mc "ID"]
	# insertion des données sur les VMs
	set liste [get_vms_list]
	foreach vm $liste {
			set item [.vbox2$id.fvm.t insert {} end -values [list [lindex $vm 0] [lindex $vm 1]]]
		if {$::obj($id,vbox_id) == [lindex $vm 1]} {
			.vbox2$id.fvm.t selection set $item
		}
	}
	
	bind .vbox2$id.fvm.t <ButtonPress-1> ".vbox2$id.fb.v configure -state normal"
	
	# boutons
	frame .vbox2$id.fb
	pack .vbox2$id.fb
	ttk::button .vbox2$id.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command "save_vbox_conf $id" -state disabled
	pack .vbox2$id.fb.v -side left
	ttk::button .vbox2$id.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command "destroy .vbox2$id"
	pack .vbox2$id.fb.a -side left
	
}


#Validation de la conf
###################################################################################
proc save_vbox_conf {id} {
	set vbox_id [.vbox2$id.fvm.t selection]
	set vbox_id [lindex [.vbox2$id.fvm.t item $vbox_id -values] 1]
	destroy .vbox2$id
	set ::tmp($id,is_present) 1
	.vbox$id.f.3 configure -state normal
	if {$vbox_id != $::obj($id,vbox_id)} {
		set ::obj($id,vbox_id) $vbox_id
		maj_affichage_nom_vbox $id
		fenetre_select_interf_vbox $id
	}
}


# Retourne la liste des VMs Virtualbox existant sur le système
###################################################################################
proc get_vms_list {} {
	
	set vms {}
	set res [exec vboxmanage list vms]
	foreach {name id} $res {
		lappend vms [list $name $id]
	}
	return $vms
	
}


# Vérifie le nom d'une VM à partir de son id
###################################################################################
proc get_vbox_name {id} {
	
	set ret {}
	if {$::tmp(vbox_found)} {
    	set liste [get_vms_list]
    	foreach m $liste {
    			if {[lindex $m 1] == $::obj($id,vbox_id)} {
    				set ret [lindex $m 0]
    			}
    	}
	}
	return $ret
	
}


# Retourne le nom de vbox à afficher (soit le nom d'équipement soit le nom de VM suivant les choix et la config)
###################################################################################
proc get_vbox_current_name {id} {
	
	set ret $::obj($id,nom)
	if {$::tmp($id,is_present) && $::obj($id,name_from_vbox)} {
		set ret [get_vbox_name $id]
	}
	return $ret
	
}


# Retourne la liste des interfaces réseaux avec leur MAC et true si dédiée à Network-in
###################################################################################
proc get_vbox_interfaces {id} {
	set liste_interf {}
	set infos [exec vboxmanage showvminfo $::obj($id,vbox_id)]
	set infos [split $infos \n]
	set long [llength $infos] 
	for {set i 0} {$i < $long} {incr i} {
		set ligne [lindex $infos $i]
		if {[regexp -expanded {NIC.([0-9])} $ligne res nic]} {
			if {[regexp -expanded {NIC.*MAC:.*([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2})([0-9A-Z]{2}),} $ligne res mac1 mac2 mac3 mac4 mac5 mac6]} {
				set mac [string tolower "$mac1:$mac2:$mac3:$mac4:$mac5:$mac6"]
				set interf($nic,mac) $mac
				set connected 0
				if {[regexp -expanded {NIC.*MAC:.*VDE.*/vde/(m[0-9]+)} $ligne res n_vde]} {
					if {$n_vde == $id} {
						set connected 1
					}
				}
				lappend liste_interf $nic $mac $connected
			}
  	}
	}
	return $liste_interf
}


# Retourne un booleen indiquant si Virtualbox est installé sur l'hôte
###################################################################################
proc is_vbox_software_installed {} {
	set ret 1
	if {[catch {exec which vboxmanage}]}  {
		set ret 0
	}
	return $ret
}


# Fenêtre permettant de modifier le nom du matériel
# et de le faire éventuellement correspondre au nom VirtualBox
###################################################################################
proc fenetre_config_nom_vbox {id} {
	
    if [winfo exists .vbox2$id] {
        raise .vbox2$id
        return
    }
    
    set ::tmp(nom) $::obj($id,nom)
    
	toplevel .vbox2$id
	wm title .vbox2$id [::msgcat::mc "Name configuration"]
	wm transient .vbox2$id .vbox$id
	positionne_fenetre .vbox2$id .vbox$id
	
	label .vbox2$id.ico -image im_config
	pack .vbox2$id.ico
	
	# zone de saisie
	labelframe .vbox2$id.f
	pack .vbox2$id.f -fill both -expand 1
	
	ttk::checkbutton .vbox2$id.f.ck -text [::msgcat::mc "Use VM name"] -onvalue true -offvalue false -variable ::obj($id,name_from_vbox) -command "bind_name_to_vbox_name $id"	
	grid .vbox2$id.f.ck  -row 0 -column 0 -sticky w
	
	label .vbox2$id.f.l -text "[::msgcat::mc "Name"] : "
	grid .vbox2$id.f.l -row 1 -column 0 -sticky w
	entry .vbox2$id.f.e -background white -textvariable ::tmp(nom)
	grid .vbox2$id.f.e -row 1 -column 1 -sticky w
	bind_name_to_vbox_name $id
	
	#Si aucune VM Virtualbox n'est attachée à cet équipement on désactive ce bouton
	if {! $::tmp($id,is_present)} {
		if {$::obj($id,name_from_vbox)} {
			#On décoche d'abord le bouton
			.vbox2$id.f.ck invoke
		}
		.vbox2$id.f.ck configure -state disabled
	}
	
	# boutons
	frame .vbox2$id.fb
	pack .vbox2$id.fb
	button .vbox2$id.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "
		change_nom_vbox $id
		destroy .vbox2$id
	"
	
	pack .vbox2$id.fb.v -side left
	button .vbox2$id.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command "destroy .vbox2$id" -relief flat
	pack .vbox2$id.fb.a -side left
}

# Fenêtre permettant de modifier le nom du matériel
# et de le faire éventuellement correspondre au nom VirtualBox
###################################################################################
proc fenetre_select_interf_vbox {id} {
	
	destroy .vbox2$id
	toplevel .vbox2$id
	wm title .vbox2$id [::msgcat::mc "Connected interface"]
	wm transient .vbox2$id .vbox$id
	positionne_fenetre .vbox2$id .vbox$id
	
	label .vbox2$id.ico -image im_config
	pack .vbox2$id.ico
	
	label .vbox2$id.l -text [::msgcat::mc "Choose the interface of VirtualBox VM to bind to Network-In simulator"]
	pack .vbox2$id.l
	
	# zone de saisie
	labelframe .vbox2$id.f -text [::msgcat::mc "Interfaces list"]
	pack .vbox2$id.f -fill both -expand 1
	
	set liste [get_vbox_interfaces $id]
	set ::tmp($id,interf_selected) $::obj($id,vbox_interf)
	foreach {nic mac connected} $liste {
		ttk::radiobutton .vbox2$id.f.$nic -text "[::msgcat::mc "Interface"] $nic" -value $nic \
		-variable ::tmp($id,interf_selected)
		if {$::obj($id,vbox_interf) == $nic} {
			set ::tmp($id,interf_selected) $nic
		}
		pack .vbox2$id.f.$nic
	}
	
	# boutons
	frame .vbox2$id.fb
	pack .vbox2$id.fb
	button .vbox2$id.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat \
	-command "change_vbox_interf $id"
	
	pack .vbox2$id.fb.v -side left
	button .vbox2$id.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler \
	-command "destroy .vbox2$id" -relief flat
	pack .vbox2$id.fb.a -side left
}

################################################################################
proc change_vbox_interf {id} {
	set ::obj($id,vbox_interf) $::tmp($id,interf_selected)
	destroy .vbox2$id
}


################################################################################
proc bind_name_to_vbox_name {id} {
	if {$::obj($id,name_from_vbox)} {
		.vbox2$id.f.e configure -state disabled
		} else {
			.vbox2$id.f.e configure -state normal
	}
}


# Met à jour le nom de l'équipement
################################################################################
proc change_nom_vbox {id} {
	set ::obj($id,nom) $::tmp(nom)
	maj_affichage_nom_vbox $id
}


# Met à jour l'affichage du nom
################################################################################
proc maj_affichage_nom_vbox {id} {
	# mise à jour dans l'interface de la VM
	wm title .vbox$id [get_vbox_current_name $id]
	# on régénère le dessin de l'objet
	dessine_objet $id
}


# Démarrage de la VM VirtualBox
################################################################################
proc demarre_virtualbox {id} {
	
	if {$::tmp(vbox_found) && $::tmp($id,is_present)} {
    	puts ">>>>STARTING VM Virtualbox $id"
    	
    	set famille $::obj($id,famille)
    	set type $::obj($id,type)
    	
    	# l'objet est déclaré actif désormais
    	set ::tmp($id,etat) 1
    	affiche_objet_on $id
    	
    	set ::tmp($id,etat_eth0) {}
    	
    	# Création de l'interface et du switch bridge
    	exec $::rep/bin/conf_virtualbox $id $::obj($id,vbox_id) start $::obj($id,vbox_interf)
    	
    	# activation du câble réseau
    	set id_liaison $::obj($id,eth0)
    	if {$id_liaison != {}} {
    		demarre_connexion $id_liaison
    	}
	}
	
}


# Arrêt soft de la VM VirtualBox
################################################################################
proc arrete_virtualbox {id} {
	catch {exec $::rep/bin/conf_virtualbox $id $::obj($id,vbox_id) stop}
	# l'objet est déclaré inactif désormais
	set ::tmp($id,etat) 0
	affiche_objet_off $id
	puts ">>>>VM Virtualbox $id STOPPED"
}

# Arrêt hard de la VM VirtualBox
################################################################################
proc force_arrete_virtualbox {id} {
	puts ">>>>Arrêt forcé VM Virtualbox $id"
	catch {exec $::rep/bin/conf_virtualbox $id $::obj($id,vbox_id) force}
	# l'objet est déclaré inactif désormais
	set ::tmp($id,etat) 0
	affiche_objet_off $id
	puts ">>>>VM Virtualbox $id arrêtée"
}

