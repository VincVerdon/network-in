####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface routeur
####################################################################
# Version 20250107

# Création de l'interface de configuration principale
################################################################################
proc fenetre_principale {} {

    set nom [exec hostname]
    wm title . $nom
    wm protocol . WM_DELETE_WINDOW {#}
    wm iconphoto . -default img_icone
	wm resizable . 0 0
    #ecrire_fichier_echange window_id [winfo id .]
    
    label .ico -image img_icone
    pack .ico

    #frame .f -background $::coul(fond)
    frame .f
    pack .f
    # zone de configuration
    labelframe .f.f1 -text [::msgcat::mc "Configuration"]
    pack .f.f1 -fill y -expand 1 -side left
    catch {
        label .f.f1.ico -image img_config
        pack .f.f1.ico
    }
    
    button .f.f1.1 -text [::msgcat::mc "IP configuration"] -command {fenetre_choix_interface} -width 20
    pack .f.f1.1 -fill x

    button .f.f1.3 -text [::msgcat::mc "Name"] -command {fenetre_config_nom}
    pack .f.f1.3 -fill x

    button .f.f1.4 -text [::msgcat::mc "DNS"] -command {fenetre_config_client_dns}
    pack .f.f1.4 -fill x

    button .f.f1.2 -text [::msgcat::mc "Static routing"] -command {fenetre_config_routage_statique}
    pack .f.f1.2 -fill x

    #zone d'informations
    labelframe .f.f2 -text [::msgcat::mc "Information"]
    pack .f.f2 -fill y -expand 1 -side left
    label .f.f2.ico -image img_info
    pack .f.f2.ico
    
    button .f.f2.4 -text [::msgcat::mc "Routing table"] -command {fenetre_table_routage}
    pack .f.f2.4 -fill x
    button .f.f2.6 -text [::msgcat::mc "About"] -command {ouverture_a_propos}
    pack .f.f2.6 -fill x

    button .f.f2.5 -text [::msgcat::mc "Terminal"] -command {ouverture_console}
    pack .f.f2.5 -fill x -side bottom

    button .arret -compound left -text [::msgcat::mc "Switch off"] -image img_eteindre -relief flat -command {exec halt &}
    pack .arret -anchor w

    update
    winid_maj [winid_parent [winfo id .]]
}

################################################################################
proc ouverture_console {} {
  source [file join $::rep xterm.tcl]
  xterm
}

################################################################################
proc ouverture_a_propos {} {
  source [file join $::rep a_propos.tcl]
	a_propos
}

# Fenetre d'affichage de la table de routage
################################################################################
proc fenetre_table_routage {} {

    if [winfo exists .cfgr] {
        raise .cfgr
        return
    }
    
    toplevel .cfgr
    positionne_fenetre .cfgr
    
    wm title .cfgr [::msgcat::mc "Routing table"]
    label .cfgr.ico -image img_config
    pack .cfgr.ico

    # zone de saisie
    #set nom [exec hostname]
    labelframe .cfgr.f -text "$::nom_machine - [::msgcat::mc "Routes list"]"
    pack .cfgr.f -fill both -expand 1
    text .cfgr.f.t -height 10 -width 80 -yscroll {.cfgr.f.sv set}
    pack .cfgr.f.t -side left -fill both
    scrollbar .cfgr.f.sv -orient vertical -command {.cfgr.f.t yview}
    pack .cfgr.f.sv -side left -fill y

    # exécution de la commande route et affichage
    #set res [exec /sbin/networkin-bin/route -n]
    set res [exec /sbin/networkin-bin/ip route]
    .cfgr.f.t insert end $res
    .cfgr.f.t configure -state disable

    # boutons
    frame .cfgr.fb
    pack .cfgr.fb
    button .cfgr.fb.a -compound left -text [::msgcat::mc "Close"] -image img_annuler -command {destroy .cfgr} -relief flat
    pack .cfgr.fb.a -side left

    update
    winid_maj [winid_parent [winfo id .cfgr]]
}

# Fenetre de config des routes
################################################################################
proc fenetre_config_routage_statique {} {

    if [winfo exists .cfgst] {
        raise .cfgst
        return
    }

    array unset ::tmp
    # réinitialisation/récupération de la config
    array unset ::conf
    set res [lire_param_routage static]
    set i 0
    foreach item $res {
        incr i
        set ::conf($i) $item
    }
    set nb_route $i

    toplevel .cfgst
    wm title .cfgst  [::msgcat::mc "Static routing configuration"]
    wm transient .cfgst .
    positionne_fenetre .cfgst

    label .cfgst.ico -image img_config
    pack .cfgst.ico

    label .cfgst.l -text [::msgcat::mc "Routing decides how to join other networks"]
    pack .cfgst.l

    # zone d'affichage des routes
    labelframe .cfgst.f1 -text "$::nom_machine - [::msgcat::mc "Existing routes"]"
    pack .cfgst.f1 -fill both -expand 1
    ttk::treeview .cfgst.f1.t -columns {network netmask gateway} -show headings -yscroll {.cfgst.f1.sv set} -height 3
    pack .cfgst.f1.t -side left
    scrollbar .cfgst.f1.sv -orient vertical -command {.cfgst.f1.t yview}
    pack .cfgst.f1.sv -side left -fill y
    .cfgst.f1.t heading network -text [::msgcat::mc "Network"]
    .cfgst.f1.t heading netmask -text [::msgcat::mc "Network mask"]
    .cfgst.f1.t heading gateway -text [::msgcat::mc "Gateway"]

    # insertion des routes actuelles
    for {set i 1} {$i<=$nb_route} {incr i} {
        .cfgst.f1.t insert {} end -values $::conf($i)
    }

    # suppression de routes
    labelframe .cfgst.f3 -text [::msgcat::mc "Routes suppression"]
    pack .cfgst.f3 -fill both -expand 1
    label .cfgst.f3.l2 -text "[::msgcat::mc "Selected route suppression"] :"
    grid .cfgst.f3.l2 -row 0 -column 0 -sticky w
    button .cfgst.f3.b2 -width 16 -text [::msgcat::mc "Suppress"] -command {
        set n [.cfgst.f1.t selection]
        .cfgst.f1.t delete $n
    }
    grid .cfgst.f3.b2 -row 1 -column 0 -sticky w

    # ajout de routes
    labelframe .cfgst.f2 -text [::msgcat::mc "Add routes"]
    pack .cfgst.f2 -fill both -expand 1
    frame .cfgst.f2.f1
    pack .cfgst.f2.f1 -fill x
    label .cfgst.f2.f1.l1 -text "[::msgcat::mc "Network address"] :"
    grid .cfgst.f2.f1.l1 -row 1 -column 0 -sticky w
    entry .cfgst.f2.f1.e1 -background white -width 16 -textvariable ::tmp(network)
    grid .cfgst.f2.f1.e1 -row 1 -column 1 -sticky w
    label .cfgst.f2.f1.l2 -text "[::msgcat::mc "Network mask"] :"
    grid .cfgst.f2.f1.l2 -row 2 -column 0 -sticky w
    entry .cfgst.f2.f1.e2 -background white -width 16 -textvariable ::tmp(netmask)
    grid .cfgst.f2.f1.e2 -row 2 -column 1 -sticky w
    label .cfgst.f2.f1.l3 -text "[::msgcat::mc "Gateway address"] :"
    grid .cfgst.f2.f1.l3 -row 3 -column 0 -sticky w
    entry .cfgst.f2.f1.e3 -background white -width 16 -textvariable ::tmp(gateway)
    grid .cfgst.f2.f1.e3 -row 3 -column 1 -sticky w
    button .cfgst.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
        .cfgst.f1.t insert {} end -values [list $::tmp(network) $::tmp(netmask) $::tmp(gateway)]
    }
    grid .cfgst.f2.f1.b1 -row 4 -column 0 -sticky w

    # boutons
    frame .cfgst.fb
    pack .cfgst.fb
    button .cfgst.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
    set ::conf(static) {}
    set liste [.cfgst.f1.t children {}]
    foreach i $liste {
        set record [.cfgst.f1.t set $i]
        set record [list [lindex $record 1] [lindex $record 3] [lindex $record 5]]
        lappend ::conf(static) $record
        puts $::conf(static)
    }
        applique_routage_statique
        destroy .cfgst
    }
    pack .cfgst.fb.v -side left
    button .cfgst.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfgst} -relief flat
    pack .cfgst.fb.a -side left
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
    wm transient .cfgci .
    wm title .cfgci [::msgcat::mc "IP configuration"]
    positionne_fenetre .cfgci

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
    set ::tmp(ip) [lindex $::tmp($interf) 1]
    set ::tmp(netmask) [lindex $::tmp($interf) 2]
    set ::tmp(gateway) [lindex $::tmp($interf) 3]
    set ::tmp(etat) [lindex $::tmp($interf) 4]
    set ::tmp(sauve_ip) $::tmp(ip)
    set ::tmp(sauve_netmask) $::tmp(netmask)
    set ::tmp(sauve_gateway) $::tmp(gateway)
    
    toplevel .cfgcip
    wm title .cfgcip [::msgcat::mc "IP configuration"]
    wm transient .cfgcip .
    positionne_fenetre .cfgcip .cfgci
    wm withdraw .cfgci
    
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

    # zone de saisie
    labelframe .cfgcip.f -text [::msgcat::mc "Parameters"]
    pack .cfgcip.f -fill both -expand 1
    label .cfgcip.f.l1 -text "[::msgcat::mc "IP address"] : "
    entry .cfgcip.f.e1 -background white -width 16 -textvariable ::tmp(ip)
    label .cfgcip.f.l2 -text "[::msgcat::mc "Network mask"] : "
    entry .cfgcip.f.e2 -background white -width 16 -textvariable ::tmp(netmask)
    # label .cfgcip.f.l3 -text {Adresse de passerelle :}
    # entry .cfgcip.f.e3 -background white -width 16 -textvariable ::tmp(gateway)
    grid .cfgcip.f.l1 -row 1 -column 0 -sticky e
    grid .cfgcip.f.e1 -row 1 -column 1 -sticky w
    grid .cfgcip.f.l2 -row 2 -column 0 -sticky e
    grid .cfgcip.f.e2 -row 2 -column 1 -sticky w
    # grid .cfgcip.f.l3 -row 3 -column 0 -sticky e
    # grid .cfgcip.f.e3 -row 3 -column 1 -sticky w

    # boutons
    frame .cfgcip.fb
    pack .cfgcip.fb
    button .cfgcip.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {
        destroy .cfgcip
        wm deiconify .cfgci
        } -relief flat
    pack .cfgcip.fb.a -side right
    button .cfgcip.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command "ch_ip $interf"
    pack .cfgcip.fb.v -side right
    
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
  wm deiconify .cfgci
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
	wm transient .cfgnom .
	positionne_fenetre .cfgnom
	
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
    wm transient .cfgdns .
    positionne_fenetre .cfgdns

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
