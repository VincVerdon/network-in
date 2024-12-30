####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de configuration réseau
####################################################################
# Version 20241229
# Ce module a besoin des libs réseau
source [file join $::rep lib_reseau.tcl]

# Interface de configuration de base de la machine
################################################################################
proc config_reseau {} {
  
  destroy .cfg
  toplevel .cfg
  wm title .cfg  [::msgcat::mc "Network configuration"]
  positionne_fenetre .cfg
	
  label .cfg.ico -image img_config
  pack .cfg.ico
  
  labelframe .cfg.f -text [::msgcat::mc "Network configuration"]
  pack .cfg.f -fill both -expand 1
  button .cfg.f.1 -text [::msgcat::mc "IP configuration"] -command {config_interfaces} -width 20
  pack .cfg.f.1 -fill x
  
  button .cfg.f.2 -text [::msgcat::mc "DNS"] -command {fenetre_config_client_dns}
  pack .cfg.f.2 -fill x
  
  button .cfg.f.3 -text [::msgcat::mc "Name"] -command {fenetre_config_nom}
  pack .cfg.f.3 -fill x
  
  button .cfg.q -compound left -text [::msgcat::mc "Close"] -image img_annuler -command {destroy .cfg} -relief flat
  pack .cfg.q
	
  update
  winid_maj [winid_parent [winfo id .cfg]]
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

# fenetre de config du DNS
################################################################################
proc fenetre_config_client_dns {} {
  
  # lecture de la config ip pour savoir si on est en dhcp (alors DNS en lecture seule)
  set ip [lire_interfaces]
  if {[string first dhcp [array get ::tmp eth*]]  != {-1} || [string first dhcp [array get ::tmp wlan*]]  != {-1}} {
    set mode dhcp
  } else  {
    set mode static
  }
  # lecture de la config DNS
  set resolv [lire_dns_machine]
  
  set ::tmp(domaine) [lindex $resolv 0]
  set ::tmp(dns1) [lindex $resolv 1]
  set ::tmp(dns2) [lindex $resolv 2]
  set ::tmp(dns3) [lindex $resolv 3]
  
  destroy .cfg2
  toplevel .cfg2
  wm title .cfg2 [::msgcat::mc "DNS Configuration"]
  wm transient .cfg2 .cfg
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config
  pack .cfg2.ico
  
  if {$mode == {dhcp}} {
    label .cfg2.l -text [::msgcat::mc "DHCP : automatic DNS configuration"]
    pack .cfg2.l
  }
  
  # zone de saisie
  labelframe .cfg2.f
  pack .cfg2.f -fill both -expand 1
  label .cfg2.f.l -text "[::msgcat::mc "Domain"] : "
  entry .cfg2.f.e -background white -width 16 -textvariable ::tmp(domaine)
  label .cfg2.f.l1 -text "[::msgcat::mc "Address of server"] n°1 : "
  entry .cfg2.f.e1 -background white -width 16 -textvariable ::tmp(dns1)
  label .cfg2.f.l2 -text "[::msgcat::mc "Address of server"] n°2 : "
  entry .cfg2.f.e2 -background white -width 16 -textvariable ::tmp(dns2)
  label .cfg2.f.l3 -text "[::msgcat::mc "Address of server"] n°3 : "
  entry .cfg2.f.e3 -background white -width 16 -textvariable ::tmp(dns3)
  grid .cfg2.f.l -row 0 -column 0 -sticky e
  grid .cfg2.f.e -row 0 -column 1 -sticky w
  grid .cfg2.f.l1 -row 1 -column 0 -sticky e
  grid .cfg2.f.e1 -row 1 -column 1 -sticky w
  grid .cfg2.f.l2 -row 2 -column 0 -sticky e
  grid .cfg2.f.e2 -row 2 -column 1 -sticky w
  grid .cfg2.f.l3 -row 3 -column 0 -sticky e
  grid .cfg2.f.e3 -row 3 -column 1 -sticky w
  if {$mode == {dhcp}} {
    .cfg2.f.e configure -state readonly
    .cfg2.f.e1 configure -state readonly
    .cfg2.f.e2 configure -state readonly
    .cfg2.f.e3 configure -state readonly
  }
  
  # boutons
  frame .cfg2.fb
  pack .cfg2.fb
  if {$mode == {static}} {
    button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
      changer_dns_machine $::tmp(domaine) $::tmp(dns1) $::tmp(dns2) $::tmp(dns3)
      destroy .cfg2
    }
    pack .cfg2.fb.v -side left
  }
  button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
  pack .cfg2.fb.a -side left
}

################################################################################
proc config_interfaces {} {
  
  # lecture de toutes les interfaces
  lire_interfaces
  
  # si on a une seule interface, on n'a pas le choix !
  if {[expr $::tmp(nb_eth) + $::tmp(nb_wlan)] <= {1}} {
    if {$::tmp(nb_eth) == {1}} {
      fenetre_config_ip eth0
    } else  {
      fenetre_config_ip wlan0
    }
  } else  {
    fenetre_choix_interface
  }
}

################################################################################
proc fenetre_choix_interface {} {
  
  set nb_eth $::tmp(nb_eth)
  set nb_wlan $::tmp(nb_wlan)
  
  destroy .cfg2
  toplevel .cfg2
  wm transient .cfg2 .cfg
  wm title .cfg2 [::msgcat::mc "IP configuration"]
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config
  pack .cfg2.ico
  
  if {$nb_eth > 0} {
    labelframe .cfg2.f1 -text [::msgcat::mc "Ethernet interfaces"]
    pack .cfg2.f1 -fill both -expand 1
    for  {set i 0} {$i < $nb_eth} {incr i} {
      button .cfg2.f1.$i -text eth$i -command "fenetre_config_ip eth$i"
      pack .cfg2.f1.$i -fill x
    }
  }
  if {$nb_wlan > 0} {
    labelframe .cfg2.f2 -text [::msgcat::mc "Wifi interfaces"]
    pack .cfg2.f2 -fill both -expand 1
    for  {set i 0} {$i < $nb_wlan} {incr i} {
      button .cfg2.f2.$i -text wlan$i -command "fenetre_config_ip wlan$i"
      pack .cfg2.f2.$i -fill x
    }
  }
  
  button .cfg2.v -compound left -text [::msgcat::mc "Close"] -image img_annuler -relief flat -command {destroy .cfg2}
  pack .cfg2.v
}

# Fenetre de config de l'adresse
################################################################################
proc fenetre_config_ip {interf} {
  
  set ::tmp(interface) $interf
  set ::tmp(mode) [lindex $::tmp($interf) 0]
  set ::tmp(etat) [lindex $::tmp($interf) 4]
  
  if {$::tmp(mode) == {static}} {
    set ::tmp(ip) [lindex $::tmp($interf) 1]
    set ::tmp(netmask) [lindex $::tmp($interf) 2]
    set ::tmp(gateway) [lindex $::tmp($interf) 3]
    set ::tmp(sauve_ip) $::tmp(ip)
    set ::tmp(sauve_netmask) $::tmp(netmask)
    set ::tmp(sauve_gateway) $::tmp(gateway)
    set ::tmp(sauve_etat) $::tmp(etat)
  } else  {
    set res [lire_ifconfig $interf]
    set ::tmp(ip) [lindex $res 0]
    set ::tmp(netmask) [lindex $res 1]
    set ::tmp(gateway) [lindex $res 2]
    set ::tmp(sauve_ip) {}
    set ::tmp(sauve_netmask) {}
    set ::tmp(sauve_gateway) {}
    if {$::tmp(ip) != {}} {
      set ::tmp(sauve_etat) 1
    } else  {
      set ::tmp(sauve_etat) 0
    }
  }
  
  destroy .cfg3
  toplevel .cfg3
  wm title .cfg3  [::msgcat::mc "IP configuration"]
  if {[winfo exists .cfg2]} {
    wm transient .cfg3 .cfg2
  } else  {
    wm transient .cfg3 .cfg
  }
  positionne_fenetre .cfg3
  
  label .cfg3.ico -image img_config
  pack .cfg3.ico
  
  # Activation de l'interface
  labelframe .cfg3.f2 -text [::msgcat::mc "Generalities"]
  pack .cfg3.f2 -fill both -expand 1
  label .cfg3.f2.l -text [::msgcat::mc "Type : ethernet"]
  label .cfg3.f2.l1 -text "[::msgcat::mc "Name"] : $interf"
  checkbutton .cfg3.f2.c -text [::msgcat::mc "Active interface"] -variable ::tmp(etat)
  grid .cfg3.f2.l1 -row 1 -column 0 -sticky w
  grid .cfg3.f2.l -row 1 -column 1 -sticky e
  grid .cfg3.f2.c -row 3 -column 0 -sticky w
  
  # Choix du type de config
  labelframe .cfg3.f0 -text [::msgcat::mc "Configuration method"]
  pack .cfg3.f0 -fill both -expand 1
  
  # zone de saisie
  labelframe .cfg3.f -text [::msgcat::mc "Parameters"]
  pack .cfg3.f -fill both -expand 1
  label .cfg3.f.l1 -text "[::msgcat::mc "IP address"] : "
  entry .cfg3.f.e1 -background white -width 16 -textvariable ::tmp(ip)
  label .cfg3.f.l2 -text "[::msgcat::mc "Network mask"] : "
  entry .cfg3.f.e2 -background white -width 16 -textvariable ::tmp(netmask)
  label .cfg3.f.l3 -text "[::msgcat::mc "Gateway address"] : "
  entry .cfg3.f.e3 -background white -width 16 -textvariable ::tmp(gateway)
  grid .cfg3.f.l1 -row 1 -column 0 -sticky e
  grid .cfg3.f.e1 -row 1 -column 1 -sticky w
  grid .cfg3.f.l2 -row 2 -column 0 -sticky e
  grid .cfg3.f.e2 -row 2 -column 1 -sticky w
  grid .cfg3.f.l3 -row 3 -column 0 -sticky e
  grid .cfg3.f.e3 -row 3 -column 1 -sticky w
  
  # Choix du type de config... Suite
  radiobutton .cfg3.f0.1 -text [::msgcat::mc "Static"]  -variable ::tmp(mode) -value static -command {
    .cfg3.f.e1 configure -state normal
    .cfg3.f.e2 configure -state normal
    .cfg3.f.e3 configure -state normal
    set ::tmp(ip) $::tmp(sauve_ip)
    set ::tmp(netmask) $::tmp(sauve_netmask)
    set ::tmp(gateway) $::tmp(sauve_gateway)
    pack .cfg3.fb.v -side right
  }
  pack .cfg3.f0.1 -side left
  radiobutton .cfg3.f0.2 -text [::msgcat::mc "Dynamic"] -variable ::tmp(mode) -value dhcp -command {
    set ::tmp(sauve_ip) $::tmp(ip)
    set ::tmp(sauve_netmask) $::tmp(netmask)
    set ::tmp(sauve_gateway) $::tmp(gateway)
    set ::tmp(ip) {}
    set ::tmp(netmask) {}
    set ::tmp(gateway) {}
    .cfg3.f.e1 configure -state readonly
    .cfg3.f.e2 configure -state readonly
    .cfg3.f.e3 configure -state readonly
  }
  pack .cfg3.f0.2 -side left
  
  # boutons
  frame .cfg3.fb
  pack .cfg3.fb
  button .cfg3.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg3} -relief flat
  pack .cfg3.fb.a -side right
  button .cfg3.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command "
  ch_ip $interf
  "
  
  # prise en compte du mode
  set ::tmp(etat_config_ip) 0
  if { $::tmp(mode) == "static"} {
    .cfg3.f.e1 configure -state normal
    .cfg3.f.e2 configure -state normal
    .cfg3.f.e3 configure -state normal
    pack .cfg3.fb.v -side right
  } else  {
    .cfg3.f.e1 configure -state readonly
    .cfg3.f.e2 configure -state readonly
    .cfg3.f.e3 configure -state readonly
  }
  
}

# Application des choix de conf IP saisis dans l'interface
################################################################################
proc ch_ip {interf} {
  
  if {$::tmp(mode) == {static}} {
    if {$::tmp(ip) == {} || $::tmp(netmask) == {}} {
      if {$::tmp(etat)} {
        tk_messageBox -parent .cfg3 -title [::msgcat::mc "Error"] -icon error -message [::msgcat::mc "You must choose  an IP address and a mask"]
        return
      }
    }
  }
  set ::tmp($interf) [list $::tmp(mode) $::tmp(ip) $::tmp(netmask) $::tmp(gateway) $::tmp(etat)]
  changer_ip_machine
  destroy .cfg3
}
