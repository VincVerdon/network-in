####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface routeur
####################################################################
# Version 20240101

# Création de l'interface de configuration principale
################################################################################
proc fenetre_principale {} {
  
  set nom [exec hostname]
  if {$nom == "unnamed"} {
    wm title . [::msgcat::mc "unnamed"]
  } else  {
    wm title . $nom
  }
  wm protocol . WM_DELETE_WINDOW {#}
  wm iconphoto . -default img_icone
	ecrire_fichier_echange window_id [winfo id .]
  
  label .ico -image img_icone
  pack .ico
  
  labelframe .f -text [::msgcat::mc "Configuration"]
  pack .f -fill both -expand 1
  button .f.1 -text [::msgcat::mc "IP configuration"] -command {fenetre_choix_interface} -width 20
  pack .f.1 -fill x
	
	button .f.3 -text [::msgcat::mc "Name"] -command {fenetre_config_nom}
  pack .f.3 -fill x
  
  button .f.2 -text [::msgcat::mc "Static routing"] -command {fenetre_config_routage_statique}
  pack .f.2 -fill x
  
  button .f.5 -text [::msgcat::mc "Terminal"] -command {ouverture_console}
  pack .f.5 -fill x
	
	labelframe .f2 -text [::msgcat::mc "Information"]
	pack .f2 -fill both -expand 1
	button .f2.4 -text [::msgcat::mc "Routing table"] -command {fenetre_table_routage}
  pack .f2.4 -fill x
  button .f2.6 -text [::msgcat::mc "About"] -command {ouverture_a_propos}
  pack .f2.6 -fill x
  
  button .arret -compound left -text [::msgcat::mc "Stop"] -image img_eteindre -relief flat -command {exec halt &}
  pack .arret
	
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
  
  destroy .cfgr
  toplevel .cfgr
	positionne_fenetre .cfgr

  set nom [exec hostname]
  if {$nom == "unnamed"} {
    wm title .cfgr "[::msgcat::mc "unnamed"] - [::msgcat::mc "Routing table"]"
  } else  {
    wm title .cfgr "$nom - [::msgcat::mc "Routing table"]"
  }
  #wm transient .cfgr .cfg
  positionne_fenetre .cfgr
  
  label .cfgr.ico -image img_config
  pack .cfgr.ico
  
  # zone de saisie
  labelframe .cfgr.f -text [::msgcat::mc "Routes list"]
  pack .cfgr.f -fill both -expand 1
  text .cfgr.f.t -height 10 -width 80 -yscroll {.cfgr.f.sv set}
  pack .cfgr.f.t -side left -fill both
  scrollbar .cfgr.f.sv -orient vertical -command {.cfgr.f1.t yview}
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
  
  destroy .cfg2
  toplevel .cfg2
  wm title .cfg2  [::msgcat::mc "Static routing configuration"]
  wm transient .cfg2 .
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config
  pack .cfg2.ico
  
  label .cfg2.l -text [::msgcat::mc "Routing decides how to join other networks"]
  pack .cfg2.l
  
  # zone d'affichage des routes
  labelframe .cfg2.f1 -text [::msgcat::mc "Existing routes"]
  pack .cfg2.f1 -fill both -expand 1
  ttk::treeview .cfg2.f1.t -columns {network netmask gateway} -show headings -yscroll {.cfg2.f1.sv set} -height 3
  pack .cfg2.f1.t -side left
  scrollbar .cfg2.f1.sv -orient vertical -command {.cfg2.f1.t yview}
  pack .cfg2.f1.sv -side left -fill y
  .cfg2.f1.t heading network -text [::msgcat::mc "Network"]
  .cfg2.f1.t heading netmask -text [::msgcat::mc "Network mask"]
  .cfg2.f1.t heading gateway -text [::msgcat::mc "Gateway"]
  
  # insertion des routes actuelles
  for {set i 1} {$i<=$nb_route} {incr i} {
    .cfg2.f1.t insert {} end -values $::conf($i)
  }
  
  # suppression de routes
  labelframe .cfg2.f3 -text [::msgcat::mc "Routes suppression"]
  pack .cfg2.f3 -fill both -expand 1
  label .cfg2.f3.l2 -text "[::msgcat::mc "Selected route suppression"] :"
  grid .cfg2.f3.l2 -row 0 -column 0 -sticky w
  button .cfg2.f3.b2 -width 16 -text [::msgcat::mc "Suppress"] -command {
    set n [.cfg2.f1.t selection]
    .cfg2.f1.t delete $n
  }
  grid .cfg2.f3.b2 -row 1 -column 0 -sticky w
  
  # ajout de routes
  labelframe .cfg2.f2 -text [::msgcat::mc "Add routes"]
  pack .cfg2.f2 -fill both -expand 1
  frame .cfg2.f2.f1
  pack .cfg2.f2.f1 -fill x
  label .cfg2.f2.f1.l1 -text "[::msgcat::mc "Network address"] :"
  grid .cfg2.f2.f1.l1 -row 1 -column 0 -sticky w
  entry .cfg2.f2.f1.e1 -background white -width 16 -textvariable ::tmp(network)
  grid .cfg2.f2.f1.e1 -row 1 -column 1 -sticky w
  label .cfg2.f2.f1.l2 -text "[::msgcat::mc "Network mask"] :"
  grid .cfg2.f2.f1.l2 -row 2 -column 0 -sticky w
  entry .cfg2.f2.f1.e2 -background white -width 16 -textvariable ::tmp(netmask)
  grid .cfg2.f2.f1.e2 -row 2 -column 1 -sticky w
  label .cfg2.f2.f1.l3 -text "[::msgcat::mc "Gateway address"] :"
  grid .cfg2.f2.f1.l3 -row 3 -column 0 -sticky w
  entry .cfg2.f2.f1.e3 -background white -width 16 -textvariable ::tmp(gateway)
  grid .cfg2.f2.f1.e3 -row 3 -column 1 -sticky w
  button .cfg2.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
    .cfg2.f1.t insert {} end -values [list $::tmp(network) $::tmp(netmask) $::tmp(gateway)]
  }
  grid .cfg2.f2.f1.b1 -row 4 -column 0 -sticky w
  
  # boutons
  frame .cfg2.fb
  pack .cfg2.fb
  button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
    set ::conf(static) {}
    set liste [.cfg2.f1.t children {}]
    foreach i $liste {
      set record [.cfg2.f1.t set $i]
      set record [list [lindex $record 1] [lindex $record 3] [lindex $record 5]]
      lappend ::conf(static) $record
      puts $::conf(static)
    }
    applique_routage_statique
    destroy .cfg2
  }
  pack .cfg2.fb.v -side left
  button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
  pack .cfg2.fb.a -side left
}

################################################################################
proc fenetre_choix_interface {} {
  
  # lecture de toutes les interfaces
  lire_interfaces
  
  set nb_eth $::tmp(nb_eth)
  set nb_wlan $::tmp(nb_wlan)
  
  destroy .cfg2
  toplevel .cfg2
  wm transient .cfg2 .
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
  set ::tmp(ip) [lindex $::tmp($interf) 1]
  set ::tmp(netmask) [lindex $::tmp($interf) 2]
  set ::tmp(gateway) [lindex $::tmp($interf) 3]
  set ::tmp(etat) [lindex $::tmp($interf) 4]
  set ::tmp(sauve_ip) $::tmp(ip)
  set ::tmp(sauve_netmask) $::tmp(netmask)
  set ::tmp(sauve_gateway) $::tmp(gateway)
  
  destroy .cfg3
  toplevel .cfg3
  wm title .cfg3 [::msgcat::mc "IP configuration"]
  if {[winfo exists .cfg2]} {
    wm transient .cfg3 .cfg2
  } else  {
    wm transient .cfg3 .
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
  
  # zone de saisie
  labelframe .cfg3.f -text [::msgcat::mc "Parameters"]
  pack .cfg3.f -fill both -expand 1
  label .cfg3.f.l1 -text "[::msgcat::mc "IP address"] : "
  entry .cfg3.f.e1 -background white -width 16 -textvariable ::tmp(ip)
  label .cfg3.f.l2 -text "[::msgcat::mc "Network mask"] : "
  entry .cfg3.f.e2 -background white -width 16 -textvariable ::tmp(netmask)
  # label .cfg3.f.l3 -text {Adresse de passerelle :}
  # entry .cfg3.f.e3 -background white -width 16 -textvariable ::tmp(gateway)
  grid .cfg3.f.l1 -row 1 -column 0 -sticky e
  grid .cfg3.f.e1 -row 1 -column 1 -sticky w
  grid .cfg3.f.l2 -row 2 -column 0 -sticky e
  grid .cfg3.f.e2 -row 2 -column 1 -sticky w
  # grid .cfg3.f.l3 -row 3 -column 0 -sticky e
  # grid .cfg3.f.e3 -row 3 -column 1 -sticky w
  
  # boutons
  frame .cfg3.fb
  pack .cfg3.fb
  button .cfg3.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg3} -relief flat
  pack .cfg3.fb.a -side right
  button .cfg3.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command "ch_ip $interf"
  pack .cfg3.fb.v -side right
  
}

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

