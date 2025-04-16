####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de config de la passerelle nat
####################################################################
# Version 20250414
set ::version(nat) 2.0

# Interface de configuration de base de la machine
################################################################################
proc interface_passerelle {id} {
  
  toplevel .passe -screen $::screen
  maj_nom_passerelle $id
  wm protocol .passe WM_DELETE_WINDOW {hide_passerelle}
  wm iconphoto .passe -default im_nat
  wm resizable .passe 0 0
  
  label .passe.ico -image im_nat
  pack .passe.ico
  
  labelframe .passe.f -text [::msgcat::mc "Configuration"]
  pack .passe.f -fill both -expand 1
  button .passe.f.1 -text [::msgcat::mc "IP configuration"]  -command "fenetre_config_ip_passerelle $id" -width 20
  pack .passe.f.1 -fill x
  button .passe.f.3 -text [::msgcat::mc "Name"] -command "fenetre_config_nom_passerelle $id"
  pack .passe.f.3 -fill x
	button .passe.f.4 -text [::msgcat::mc "About"] -command "a_propos $::version(nat) .passe"
	pack .passe.f.4 -fill x
  
	# boutons
	button .passe.arret -compound left -text [::msgcat::mc "Switch off"] -image im_eteindre -relief flat -command "arrete_passerelle $id"
	pack .passe.arret -anchor w
	
}


# Fait passer la fenêtre de la passerelle en avant-plan
################################################################################
proc raise_passerelle {} {
	if [winfo exists .passe] {
		wm deiconify .passe
		raise .passe
	}
}

# Fait disparaître la fenêtre de la passerelle
################################################################################
proc hide_passerelle {} {
	if [winfo exists .passe] {
		#lower .passe
		wm withdraw .passe
	}
}


################################################################################
proc change_nom_passerelle {id} {
    
  set ::obj($id,nom) $::tmp($id,nom)
  # mise à jour dans l'interface de la passerelle
  maj_nom_passerelle $id
  # on régénère le dessin de l'objet
  dessine_objet $id
    
}


################################################################################
proc maj_nom_passerelle {id} {
    
  if {$::obj($id,nom) == {}} {
    wm title .passe $id
  } else  {
    wm title .passe $::obj($id,nom)
  }
    
}


# Fenetre de config du nom
################################################################################
proc fenetre_config_nom_passerelle {id} {
  
    if [winfo exists .passe2] {
        raise .passe2
        return
    }
    
    set ::tmp($id,nom) $::obj($id,nom)
    
  toplevel .passe2 -screen $::screen
  wm title .passe2 [::msgcat::mc "Name configuration"]
  wm transient .passe2 .passe
  positionne_fenetre .passe2 .passe
  
  label .passe2.ico -image im_config
  pack .passe2.ico
  
  # zone de saisie
  labelframe .passe2.f
  pack .passe2.f -fill both -expand 1
  label .passe2.f.l -text "[::msgcat::mc "Name"] : "
  pack .passe2.f.l -side left
  entry .passe2.f.e -background white -textvariable ::tmp($id,nom)
  pack .passe2.f.e -fill x -side left -expand 1
  
  # boutons
  frame .passe2.fb
  pack .passe2.fb
  button .passe2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "change_nom_passerelle $id ; destroy .passe2"
  pack .passe2.fb.v -side left
  button .passe2.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .passe2} -relief flat
  pack .passe2.fb.a -side left
}


# Fenetre de config de l'adresse
################################################################################
proc fenetre_config_ip_passerelle {id} {
    
  if [winfo exists .passe3] {
      raise .passe3
      return
  }
    
  set ::tmp($id,ip) $::obj($id,ip_eth0)
  set ::tmp($id,netmask)  $::obj($id,netmask_eth0)
  set ::tmp($id,ip_anc) $::obj($id,ip_eth0)
  set ::tmp($id,netmask_anc)  $::obj($id,netmask_eth0)
  
  toplevel .passe3 -screen $::screen
  wm title .passe3 [::msgcat::mc "IP configuration"]
  wm transient .passe3 .passe
  positionne_fenetre .passe3 .passe
  
  label .passe3.ico -image im_config
  pack .passe3.ico
  
  # Activation de l'interface
  labelframe .passe3.f2 -text [::msgcat::mc "Generalities"]
  pack .passe3.f2 -fill both -expand 1
  label .passe3.f2.l0 -text [::msgcat::mc "Type : ethernet"]
  grid .passe3.f2.l0 -row 1 -column 2 -sticky w
  label .passe3.f2.l1 -text "Nom : eth0"
  grid .passe3.f2.l1 -row 1 -column 0 -sticky w
	
  # zone de saisie
  labelframe .passe3.f -text [::msgcat::mc "Parameters"]
  pack .passe3.f -fill both -expand 1
  label .passe3.f.l1 -text "[::msgcat::mc "IP address"] : "
  entry .passe3.f.e1 -background white -width 16 -textvariable ::tmp($id,ip)
  label .passe3.f.l2 -text "[::msgcat::mc "Network mask"] : "
  entry .passe3.f.e2 -background white -width 16 -textvariable ::tmp($id,netmask)
  grid .passe3.f.l1 -row 1 -column 0 -sticky e
  grid .passe3.f.e1 -row 1 -column 1 -sticky w
  grid .passe3.f.l2 -row 2 -column 0 -sticky e
  grid .passe3.f.e2 -row 2 -column 1 -sticky w
  
  # boutons
  frame .passe3.fb
  pack .passe3.fb
  button .passe3.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .passe3} -relief flat
  pack .passe3.fb.a -side right
  button .passe3.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -relief flat -command "applique_config_ip_passerelle $id ; destroy .passe3"
  pack .passe3.fb.v -side right
  
}


################################################################################
proc applique_config_ip_passerelle {id} {
  
  set ::obj($id,ip_eth0) $::tmp($id,ip)
  set ::obj($id,netmask_eth0) $::tmp($id,netmask)
  set ::tmp($id,etat_eth0) "$::obj($id,ip_eth0)/[calcul_mask_dec2cidr $::obj($id,netmask_eth0)]"
	
  # on applique les changements : redémarrage de l'interface réseau
	if {$::tmp($id,etat)} {
        exec_config_passerelle $id $::tmp($id,ip_anc) $::tmp($id,netmask_anc) stop
        exec_config_passerelle $id $::obj($id,ip_eth0) $::obj($id,netmask_eth0) start
        #on met à jour l'affichage les infos sur l'IP si elles sont affichées actuellement
        set id_liaison $::obj($id,eth0)
        if {$id_liaison != "" && $::tmp($id_liaison,infos_connexion)} {
            maj_infos_connexion $id_liaison
        }
	}
	unset ::tmp($id,ip)
	unset ::tmp($id,ip_anc)
	unset ::tmp($id,netmask)
	unset ::tmp($id,netmask_anc)
	
}


################################################################################
proc exec_config_passerelle {id ip masque action} {

  set masque [calcul_mask_cidr2dec $masque]
  catch {exec sudo $::rep/bin/conf_gateway $ip $masque $action}
	
  #Mise à jour étiquettes infos
  set id_liaison $::obj($id,eth0)
  maj_infos_connexion $id_liaison
	
}


# Démarrage de la passerelle
################################################################################
proc demarre_passerelle {id} {
	
	puts ">>>>STARTING PASSERELLE $id"
	
	set famille $::obj($id,famille)
	set type $::obj($id,type)
	
	# Conf actuelle de l'interface pour affichage
	if {$::obj($id,ip_eth0) != "" && $::obj($id,netmask_eth0) != ""} {
		set ::tmp($id,etat_eth0) "$::obj($id,ip_eth0)/[calcul_mask_dec2cidr $::obj($id,netmask_eth0)]"
	} else {
		set ::tmp($id,etat_eth0) ""
	}
	
	# Configuration de l'interface réseau
	exec_config_passerelle $id $::obj($id,ip_eth0) $::obj($id,netmask_eth0) start
	
	# l'objet est déclaré actif désormais
	set ::tmp($id,etat) 1
	affiche_objet_on $id
	
	# activation du câble réseau
	set id_liaison $::obj($id,eth0)
	if {$id_liaison != {}} {
		demarre_connexion $id_liaison
	}
	maj_infos_connexion $id_liaison
	
	#Affichage interface
	interface_passerelle $id
}

# Arrêt de la passerelle
################################################################################
proc arrete_passerelle {id} {
	
	destroy .passe
	destroy .passe2
	destroy .passe3
	
	# on débranche le câble
	set id_liaison $::obj($id,eth0)
	set ::tmp($id,etat_eth0) {}
	arrete_connexion $id_liaison
	
	# l'objet est déclaré inactif désormais
	set ::tmp($id,etat) 0
	affiche_objet_off $id
	
	# Déconfiguration de l'interface NAT
	exec_config_passerelle $id $::obj($id,ip_eth0) $::obj($id,netmask_eth0) stop
	
	puts ">>>>PASSERELLE $id STOPPED"
	
}
