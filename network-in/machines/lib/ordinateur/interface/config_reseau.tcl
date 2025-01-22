####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de configuration réseau
####################################################################
# Version 20250102
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

	if [winfo exists .cfgnom] {
        raise .cfgnom
        return
    }
    
	toplevel .cfgnom
	wm title .cfgnom  [::msgcat::mc "Name configuration"]
	wm transient .cfgnom .cfg
	positionne_fenetre .cfgnom .cfg
	
	label .cfgnom.ico -image img_config
	pack .cfgnom.ico
	
	# zone de saisie
	labelframe .cfgnom.f
	pack .cfgnom.f -fill both -expand 1
	label .cfgnom.f.l -text "[::msgcat::mc "Name"] :"
	pack .cfgnom.f.l -side left
	entry .cfgnom.f.e -background white
	pack .cfgnom.f.e -fill x -side left -expand 1
	.cfgnom.f.e insert end [lire_nom_machine]
	
	# boutons
	frame .cfgnom.fb
	pack .cfgnom.fb
	button .cfgnom.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
		set ::tmp(nom) [.cfgnom.f.e get]
		if {$::tmp(nom) == {}} {
			tk_messageBox -title [::msgcat::mc "Error"] -icon error -message [::msgcat::mc "You must choose a name"]
		} else  {
			changer_nom_machine $::tmp(nom)
			destroy .cfgnom
		}
	}
	pack .cfgnom.fb.v -side left
	button .cfgnom.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfgnom} -relief flat
	pack .cfgnom.fb.a -side left
}

# fenetre de config du DNS
################################################################################
proc fenetre_config_client_dns {} {

    if [winfo exists .cfgdns] {
        raise .cfgdns
        return
    }

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
    
    toplevel .cfgdns
    wm title .cfgdns [::msgcat::mc "DNS Configuration"]
    wm transient .cfgdns .cfg
    positionne_fenetre .cfgdns .cfg

    label .cfgdns.ico -image img_config
    pack .cfgdns.ico

    if {$mode == {dhcp}} {
        label .cfgdns.l -text [::msgcat::mc "DHCP : automatic DNS configuration"]
        pack .cfgdns.l
    }

    # zone de saisie
    labelframe .cfgdns.f
    pack .cfgdns.f -fill both -expand 1
    label .cfgdns.f.l -text "[::msgcat::mc "Domain"] : "
    entry .cfgdns.f.e -background white -width 16 -textvariable ::tmp(domaine)
    label .cfgdns.f.l1 -text "[::msgcat::mc "Address of server"] n°1 : "
    entry .cfgdns.f.e1 -background white -width 16 -textvariable ::tmp(dns1)
    label .cfgdns.f.l2 -text "[::msgcat::mc "Address of server"] n°2 : "
    entry .cfgdns.f.e2 -background white -width 16 -textvariable ::tmp(dns2)
    label .cfgdns.f.l3 -text "[::msgcat::mc "Address of server"] n°3 : "
    entry .cfgdns.f.e3 -background white -width 16 -textvariable ::tmp(dns3)
    grid .cfgdns.f.l -row 0 -column 0 -sticky e
    grid .cfgdns.f.e -row 0 -column 1 -sticky w
    grid .cfgdns.f.l1 -row 1 -column 0 -sticky e
    grid .cfgdns.f.e1 -row 1 -column 1 -sticky w
    grid .cfgdns.f.l2 -row 2 -column 0 -sticky e
    grid .cfgdns.f.e2 -row 2 -column 1 -sticky w
    grid .cfgdns.f.l3 -row 3 -column 0 -sticky e
    grid .cfgdns.f.e3 -row 3 -column 1 -sticky w
    if {$mode == {dhcp}} {
        .cfgdns.f.e configure -state readonly
        .cfgdns.f.e1 configure -state readonly
        .cfgdns.f.e2 configure -state readonly
        .cfgdns.f.e3 configure -state readonly
    }

    # boutons
    frame .cfgdns.fb
    pack .cfgdns.fb
    if {$mode == {static}} {
        button .cfgdns.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
            changer_dns_machine $::tmp(domaine) $::tmp(dns1) $::tmp(dns2) $::tmp(dns3)
            destroy .cfgdns
        }
        pack .cfgdns.fb.v -side left
    }
    button .cfgdns.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfgdns} -relief flat
    pack .cfgdns.fb.a -side left
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
    
    if [winfo exists .cfgci] {
        raise .cfgci
        return
    }

    # lecture de toutes les interfaces
    lire_interfaces

    set nb_eth $::tmp(nb_eth)
    set nb_wlan $::tmp(nb_wlan)

    toplevel .cfgci
    wm transient .cfgci .cfg
    wm title .cfgci [::msgcat::mc "IP configuration"]
    positionne_fenetre .cfgci .cfg

    label .cfgci.ico -image img_config
    pack .cfgci.ico

    if {$nb_eth > 0} {
        labelframe .cfgci.f1 -text [::msgcat::mc "Ethernet interfaces"]
        pack .cfgci.f1 -fill both -expand 1
        for  {set i 0} {$i < $nb_eth} {incr i} {
            button .cfgci.f1.$i -text eth$i -command "fenetre_config_ip eth$i"
            pack .cfgci.f1.$i -fill x
        }
    }
    if {$nb_wlan > 0} {
        labelframe .cfgci.f2 -text [::msgcat::mc "Wifi interfaces"]
        pack .cfgci.f2 -fill both -expand 1
        for  {set i 0} {$i < $nb_wlan} {incr i} {
            button .cfgci.f2.$i -text wlan$i -command "fenetre_config_ip wlan$i"
            pack .cfgci.f2.$i -fill x
        }
    }

    button .cfgci.v -compound left -text [::msgcat::mc "Close"] -image img_annuler -relief flat -command {destroy .cfgci}
    pack .cfgci.v
  
}


# Fenetre de config de l'adresse
################################################################################
proc fenetre_config_ip {interf} {

    if [winfo exists .cfgcip] {
        raise .cfgcip
        return
    }
    
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

    toplevel .cfgcip
    wm title .cfgcip [::msgcat::mc "IP configuration"]
    wm transient .cfgcip .cfg
    if {[winfo exists .cfgci]} {
        positionne_fenetre .cfgcip .cfgci
        wm withdraw .cfgci
    } else  {
        positionne_fenetre .cfgcip .cfg
    }

    label .cfgcip.ico -image img_config
    pack .cfgcip.ico

    # Activation de l'interface
    labelframe .cfgcip.f2 -text [::msgcat::mc "Generalities"]
    pack .cfgcip.f2 -fill both -expand 1
    label .cfgcip.f2.l -text [::msgcat::mc "Type : ethernet"]
    label .cfgcip.f2.l1 -text "[::msgcat::mc "Name"] : $interf"
    checkbutton .cfgcip.f2.c -text [::msgcat::mc "Active interface"] -variable ::tmp(etat)
    grid .cfgcip.f2.l1 -row 1 -column 0 -sticky w
    grid .cfgcip.f2.l -row 1 -column 1 -sticky e
    grid .cfgcip.f2.c -row 3 -column 0 -sticky w

    # Choix du type de config
    labelframe .cfgcip.f0 -text [::msgcat::mc "Configuration method"]
    pack .cfgcip.f0 -fill both -expand 1

    # zone de saisie
    labelframe .cfgcip.f -text [::msgcat::mc "Parameters"]
    pack .cfgcip.f -fill both -expand 1
    label .cfgcip.f.l1 -text "[::msgcat::mc "IP address"] : "
    entry .cfgcip.f.e1 -background white -width 16 -textvariable ::tmp(ip)
    label .cfgcip.f.l2 -text "[::msgcat::mc "Network mask"] : "
    entry .cfgcip.f.e2 -background white -width 16 -textvariable ::tmp(netmask)
    label .cfgcip.f.l3 -text "[::msgcat::mc "Gateway address"] : "
    entry .cfgcip.f.e3 -background white -width 16 -textvariable ::tmp(gateway)
    grid .cfgcip.f.l1 -row 1 -column 0 -sticky e
    grid .cfgcip.f.e1 -row 1 -column 1 -sticky w
    grid .cfgcip.f.l2 -row 2 -column 0 -sticky e
    grid .cfgcip.f.e2 -row 2 -column 1 -sticky w
    grid .cfgcip.f.l3 -row 3 -column 0 -sticky e
    grid .cfgcip.f.e3 -row 3 -column 1 -sticky w

    # Choix du type de config... Suite
    radiobutton .cfgcip.f0.1 -text [::msgcat::mc "Static"]  -variable ::tmp(mode) -value static -command {
        .cfgcip.f.e1 configure -state normal
        .cfgcip.f.e2 configure -state normal
        .cfgcip.f.e3 configure -state normal
        set ::tmp(ip) $::tmp(sauve_ip)
        set ::tmp(netmask) $::tmp(sauve_netmask)
        set ::tmp(gateway) $::tmp(sauve_gateway)
        pack .cfgcip.fb.v -side right
    }
    pack .cfgcip.f0.1 -side left
    radiobutton .cfgcip.f0.2 -text [::msgcat::mc "Dynamic"] -variable ::tmp(mode) -value dhcp -command {
        set ::tmp(sauve_ip) $::tmp(ip)
        set ::tmp(sauve_netmask) $::tmp(netmask)
        set ::tmp(sauve_gateway) $::tmp(gateway)
        set ::tmp(ip) {}
        set ::tmp(netmask) {}
        set ::tmp(gateway) {}
        .cfgcip.f.e1 configure -state readonly
        .cfgcip.f.e2 configure -state readonly
        .cfgcip.f.e3 configure -state readonly
    }
    pack .cfgcip.f0.2 -side left

    # boutons
    frame .cfgcip.fb
    pack .cfgcip.fb
    button .cfgcip.fb.a -compound left -text [::msgcat::mc "Abort"] -relief flat -image img_annuler -command {
        destroy .cfgcip
        if {[winfo exists .cfgci]} {
            wm deiconify .cfgci
        }
    }
    pack .cfgcip.fb.a -side right
    button .cfgcip.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command "ch_ip $interf"

    # prise en compte du mode
    set ::tmp(etat_config_ip) 0
    if { $::tmp(mode) == "static"} {
        .cfgcip.f.e1 configure -state normal
        .cfgcip.f.e2 configure -state normal
        .cfgcip.f.e3 configure -state normal
        pack .cfgcip.fb.v -side right
    } else  {
        .cfgcip.f.e1 configure -state readonly
        .cfgcip.f.e2 configure -state readonly
        .cfgcip.f.e3 configure -state readonly
    }

}

# Application des choix de conf IP saisis dans l'interface
################################################################################
proc ch_ip {interf} {

    if {$::tmp(mode) == {static}} {
        if {$::tmp(ip) == {} || $::tmp(netmask) == {}} {
            if {$::tmp(etat)} {
                tk_messageBox -parent .cfgcip -title [::msgcat::mc "Error"] -icon error -message [::msgcat::mc "You must choose  an IP address and a mask"]
                return
            }
        }
    }
    set ::tmp($interf) [list $::tmp(mode) $::tmp(ip) $::tmp(netmask) $::tmp(gateway) $::tmp(etat)]
    changer_ip_machine
    destroy .cfgcip
    if {[winfo exists .cfgci]} {
        wm deiconify .cfgci
    }
    
}
