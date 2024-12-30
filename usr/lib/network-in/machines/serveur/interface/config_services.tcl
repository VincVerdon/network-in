####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20241229
# Ce module a besoin des libs réseau
source [file join $::rep lib_reseau.tcl]

# proc de démarrage du module
################################################################################
proc config_services {} {
	set ::rep_conf $::rep/../services
	
  # lancement de l'interface
  fenetre_config_services
}

# Interface de configuration de base de la machine
################################################################################
proc fenetre_config_services {} {
  
  destroy .cfg
  toplevel .cfg
  wm title .cfg  [::msgcat::mc "Services configuration"]
	positionne_fenetre .cfg
  
  image create photo img_config_serveur -file $::rep/images/config_serveur.gif
  label .cfg.ico -image img_config_serveur
  pack .cfg.ico
  
  labelframe .cfg.f -text [::msgcat::mc "Services configuration"]
  pack .cfg.f -fill both -expand 1
  
  button .cfg.f.1 -text [::msgcat::mc "DHCP server"] -command {fenetre_config_dhcp}
  pack .cfg.f.1 -fill x
  
  button .cfg.f.2 -text [::msgcat::mc "DNS server"] -command {fenetre_config_dns}
  pack .cfg.f.2 -fill x
  
  button .cfg.f.3 -text [::msgcat::mc "HTTP server"] -command {fenetre_config_http}
  pack .cfg.f.3 -fill x
  
  button .cfg.f.4 -text [::msgcat::mc "FTP server"] -command {fenetre_config_ftp}
  pack .cfg.f.4 -fill x
  
  button .cfg.f.5 -text [::msgcat::mc "SSH server"] -command {fenetre_config_ssh}
  pack .cfg.f.5 -fill x
	
  button .cfg.q -compound left -text [::msgcat::mc "Close"] -image img_annuler -command {destroy .cfg} -relief flat
  pack .cfg.q
	
  update
  winid_maj [winid_parent [winfo id .cfg]]
}

# Fenetre de config du serveur dns
################################################################################
proc fenetre_config_dns {} {
  
  # réinitialisation/récupération de la config
  array unset ::conf
  set res [lire_param dns]
  if {$res == {}} {
    set ::conf(dns) 0
    set ::conf(dns_records) {}
    set ::conf(domain) {}
  } else  {
    array set ::conf $res
  }
  
  destroy .cfg2
  toplevel .cfg2
  wm title .cfg2  [::msgcat::mc "DNS server configuration"]
  wm transient .cfg2 .cfg
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config_serveur
  pack .cfg2.ico
  
  label .cfg2.l -text [::msgcat::mc "The DNS server translates computers names into IP address"]
  pack .cfg2.l
  
  # Choix du type de config
  labelframe .cfg2.f0 -text [::msgcat::mc "Server state"]
  pack .cfg2.f0 -fill both -expand 1
  radiobutton .cfg2.f0.1 -text [::msgcat::mc "On"]  -variable ::conf(dns) -value 1
  pack .cfg2.f0.1 -side left
  radiobutton .cfg2.f0.2 -text [::msgcat::mc "Off"] -variable ::conf(dns) -value 0
  pack .cfg2.f0.2 -side left

  # Choix du domaine
  labelframe .cfg2.f4 -text [::msgcat::mc "Domain name"]
  pack .cfg2.f4 -fill both -expand 1
  label .cfg2.f4.l1 -text "[::msgcat::mc "Domain"] :"
  grid .cfg2.f4.l1 -row 1 -column 0 -sticky e
  entry .cfg2.f4.e1 -background white -width 16 -textvariable ::conf(domain)
  grid .cfg2.f4.e1 -row 1 -column 1 -sticky w
  
  # zone d'affichage des enregistrements
  labelframe .cfg2.f1 -text [::msgcat::mc "Current records"]
  pack .cfg2.f1 -fill both -expand 1
  ttk::treeview .cfg2.f1.t -columns {nom type param} -show headings -yscroll {.cfg2.f1.sv set} -height 5
  pack .cfg2.f1.t -side left  
  scrollbar .cfg2.f1.sv -orient vertical -command {.cfg2.f1.t yview}
  pack .cfg2.f1.sv -side left -fill y
  .cfg2.f1.t heading nom -text [::msgcat::mc "Name"]
  .cfg2.f1.t heading type -text [::msgcat::mc "Type"]
  .cfg2.f1.t heading param -text [::msgcat::mc "Parameters"]
  labelframe .cfg2.f3 -text [::msgcat::mc "Records suppression"]
  pack .cfg2.f3 -fill both -expand 1
  label .cfg2.f3.l2 -text "[::msgcat::mc "Suppression of a selected record"] :"
  grid .cfg2.f3.l2 -row 0 -column 0 -sticky w
  button .cfg2.f3.b2 -width 16 -text [::msgcat::mc "Suppress"] -command {
    set n [.cfg2.f1.t selection]
    .cfg2.f1.t delete $n
  }
  grid .cfg2.f3.b2 -row 0 -column 2 -sticky w
  
  # insertion des données
  foreach i $::conf(dns_records) {
    .cfg2.f1.t insert {} end -values [list [lindex $i 0] [lindex $i 1] [lindex $i 2]]
  }
  
  labelframe .cfg2.f2 -text [::msgcat::mc "Add records"]
  pack .cfg2.f2 -fill both -expand 1
  # choix du type
  frame .cfg2.f2.f
  pack .cfg2.f2.f
  label .cfg2.f2.f.l -text "[::msgcat::mc "Type"] :"
  pack .cfg2.f2.f.l -side left
  radiobutton .cfg2.f2.f.1 -text [::msgcat::mc "A"] -variable ::tmp(type) -value A -command "interf_ajout_dns A"
  pack .cfg2.f2.f.1 -side left
  radiobutton .cfg2.f2.f.2 -text [::msgcat::mc "CNAME"] -variable ::tmp(type) -value CNAME -command "interf_ajout_dns CNAME"
  pack .cfg2.f2.f.2 -side left
  # sélection du type A par défaut
  .cfg2.f2.f.1 invoke
  
  # boutons
  frame .cfg2.fb
  pack .cfg2.fb
  button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
    set ::conf(dns_records) {}
    set liste [.cfg2.f1.t children {}]
    foreach i $liste {
      set record [.cfg2.f1.t set $i]
      set record [list [lindex $record 1]  [lindex $record 3]  [lindex $record 5]]
      lappend ::conf(dns_records) $record
    }
    applique_config_dns
    destroy .cfg2
  }
  pack .cfg2.fb.v -side left
  button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
  pack .cfg2.fb.a -side left
}

################################################################################
proc interf_ajout_dns {type} {
  
  destroy .cfg2.f2.f1
  frame .cfg2.f2.f1
  pack .cfg2.f2.f1 -fill x
  
  # réinitialisation des données
  # array unset ::conf
  set ::tmp(nom) {}
  set ::tmp(ip) {}
  set ::tmp(cname) {}
  
  switch $type {
    {A} {
      label .cfg2.f2.f1.l1 -text "[::msgcat::mc "Name"] :"
      pack .cfg2.f2.f1.l1 -side left
      entry .cfg2.f2.f1.e1 -background white -width 16 -textvariable ::tmp(nom)
      pack .cfg2.f2.f1.e1 -side left
      label .cfg2.f2.f1.l2 -text "[::msgcat::mc "IP"] :"
      pack .cfg2.f2.f1.l2 -side left
      entry .cfg2.f2.f1.e2 -background white -width 16 -textvariable ::tmp(ip)
      pack .cfg2.f2.f1.e2 -side left
      button .cfg2.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
        .cfg2.f1.t insert {} end -values [list $::tmp(nom) $::tmp(type) $::tmp(ip)]
      }
      pack .cfg2.f2.f1.b1 -side right
    }
    
    {CNAME} {
      label .cfg2.f2.f1.l1 -text "[::msgcat::mc "Name"] :"
      pack .cfg2.f2.f1.l1 -side left
      entry .cfg2.f2.f1.e1 -background white -width 16 -textvariable ::tmp(nom)
      pack .cfg2.f2.f1.e1 -side left
      label .cfg2.f2.f1.l2 -text {Nom canonique :}
      pack .cfg2.f2.f1.l2 -side left
      entry .cfg2.f2.f1.e2 -background white -width 16 -textvariable ::tmp(cname)
      pack .cfg2.f2.f1.e2 -side left
      button .cfg2.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
        .cfg2.f1.t insert {} end -values [list $::tmp(nom) $::tmp(type) $::tmp(cname)]
      }
      pack .cfg2.f2.f1.b1 -side right
    }
    
  }
}

# Fenetre de config du serveur ftp
################################################################################
proc fenetre_config_ftp {} {
  
  # réinitialisation/récupération de la config
  array unset ::conf
  set res [lire_param ftp]
  if {$res == {}} {
    set ::conf(ftp) 0
    set ::conf(ftp_users) {}
    set ::tmp(ftp_users_init) {}
    # set ::conf(ftp_rep_ftp) 1
    set ::conf(ftp_rep_www) 0
  } else  {
    array set ::conf $res
    set ::tmp(ftp_users_init) $::conf(ftp_users)
  }
  set ::tmp(nom) {}
  set ::tmp(passe) {}
  
  destroy .cfg2
  toplevel .cfg2
  wm title .cfg2  [::msgcat::mc "FTP server configuration"]
  wm transient .cfg2 .cfg
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config_serveur
  pack .cfg2.ico
  
  label .cfg2.l -text [::msgcat::mc "The FTP server allows to put and to access files"]
  pack .cfg2.l
  
  # Choix du type de config
  labelframe .cfg2.f0 -text [::msgcat::mc "Server state"]
  pack .cfg2.f0 -fill both -expand 1
  radiobutton .cfg2.f0.1 -text [::msgcat::mc "On"]  -variable ::conf(ftp) -value 1
  pack .cfg2.f0.1 -side left
  radiobutton .cfg2.f0.2 -text [::msgcat::mc "Off"] -variable ::conf(ftp) -value 0
  pack .cfg2.f0.2 -side left
  
  # zone de choix des répertoires accessibles
  labelframe .cfg2.f4 -text [::msgcat::mc "Reachable directories"]
  pack .cfg2.f4 -fill both -expand 1
  
  frame .cfg2.f4.f
  pack .cfg2.f4.f -fill x
  label .cfg2.f4.f.l -text "[::msgcat::mc "Access to the HTTP server"] :"
  grid .cfg2.f4.f.l  -row 0 -column 0 -sticky w
  # checkbutton .cfg2.f4.f.1 -text {Répertoire par défaut (/home/ftp)} -variable ::conf(ftp_rep_ftp) -state disable
  # grid .cfg2.f4.f.1  -row 1 -column 0 -sticky w
  checkbutton .cfg2.f4.f.2 -text [::msgcat::mc "HTTP server directory (/var/www)"] -variable ::conf(ftp_rep_www)
  grid .cfg2.f4.f.2  -row 2 -column 0 -sticky w
  
  # zone d'affichage des utilisateurs
  labelframe .cfg2.f1 -text [::msgcat::mc "Users accounts"]
  pack .cfg2.f1 -fill both -expand 1
  ttk::treeview .cfg2.f1.t -columns {nom passe} -show headings -yscroll {.cfg2.f1.sv set} -height 3
  pack .cfg2.f1.t -side left
  scrollbar .cfg2.f1.sv -orient vertical -command {.cfg2.f1.t yview}
  pack .cfg2.f1.sv -side left -fill y
  .cfg2.f1.t heading nom -text [::msgcat::mc "Name"]
  .cfg2.f1.t heading passe -text [::msgcat::mc "Password"]
  # insertion des données sur les comptes
  foreach i $::conf(ftp_users) {
    .cfg2.f1.t insert {} end -values [list [lindex $i 0] [lindex $i 1]]
  }
  
  # suppression de comptes
  labelframe .cfg2.f3 -text [::msgcat::mc "Accounts suppression"]
  pack .cfg2.f3 -fill both -expand 1
  label .cfg2.f3.l2 -text "[::msgcat::mc "Selected account suppression"] :"
  grid .cfg2.f3.l2 -row 0 -column 0 -sticky w
  button .cfg2.f3.b2 -width 16 -text [::msgcat::mc "Suppress"] -command {
    set n [.cfg2.f1.t selection]
    .cfg2.f1.t delete $n
  }
  grid .cfg2.f3.b2 -row 1 -column 2 -sticky w
  
  # ajout de comptes
  labelframe .cfg2.f2 -text [::msgcat::mc "Accounts addition"]
  pack .cfg2.f2 -fill both -expand 1
  frame .cfg2.f2.f1
  pack .cfg2.f2.f1 -fill x
  label .cfg2.f2.f1.l1 -text "[::msgcat::mc "Name"] :"
  pack .cfg2.f2.f1.l1 -side left
  entry .cfg2.f2.f1.e1 -background white -width 16 -textvariable ::tmp(nom)
  pack .cfg2.f2.f1.e1 -side left
  label .cfg2.f2.f1.l2 -text "[::msgcat::mc "Password"] :"
  pack .cfg2.f2.f1.l2 -side left
  entry .cfg2.f2.f1.e2 -background white -width 16 -textvariable ::tmp(passe)
  pack .cfg2.f2.f1.e2 -side left
  button .cfg2.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
    .cfg2.f1.t insert {} end -values [list $::tmp(nom) $::tmp(passe)]
  }
  pack .cfg2.f2.f1.b1 -side right
  
  # boutons
  frame .cfg2.fb
  pack .cfg2.fb
  button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
    set ::conf(ftp_users) {}
    set liste [.cfg2.f1.t children {}]
    foreach i $liste {
      set record [.cfg2.f1.t set $i]
      set record [list [lindex $record 1]  [lindex $record 3]]
      lappend ::conf(ftp_users) $record
    }
    applique_config_ftp
    destroy .cfg2
  }
  pack .cfg2.fb.v -side left
  button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
  pack .cfg2.fb.a -side left
}

################################################################################
proc creer_user_ftp {nom pass} {
  exec $::rep/../services/bin/creer_user_ftp $nom $pass &
}

################################################################################
proc supprimer_user {nom} {
  exec /usr/sbin/userdel $nom &
}

# Fenetre de config du serveur dhcp
################################################################################
proc fenetre_config_dhcp {} {
  
  # réinitialisation/récupération de la config
  # lecture de toutes les interfaces
  lire_interfaces
  
  array unset ::conf
  set res [lire_param dhcp]
  if {$res == {}} {
    set ::conf(ip1) {}
    set ::conf(ip2) {}
    set ::conf(netmask) {}
    set ::conf(gateway) {}
    set ::conf(dns) {}
    set ::conf(domain) {}
    set ::conf(network) {}
    set ::conf(dhcp) 0
    set ::conf(eth) eth0
  } else  {
    array set ::conf $res
  }
  
  destroy .cfg2
  toplevel .cfg2
  wm title .cfg2  [::msgcat::mc "DHCP server configuration"]
  wm transient .cfg2 .cfg
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config_serveur
  pack .cfg2.ico
  
  label .cfg2.l -text [::msgcat::mc "The DHCP server provides IP address for the other computers of the LAN"]
  pack .cfg2.l
  
  # Choix du type de config
  labelframe .cfg2.f0 -text [::msgcat::mc "Server state"]
  pack .cfg2.f0 -fill both -expand 1
  radiobutton .cfg2.f0.1 -text [::msgcat::mc "On"]  -variable ::conf(dhcp) -value 1
  pack .cfg2.f0.1 -side left
  radiobutton .cfg2.f0.2 -text [::msgcat::mc "Off"] -variable ::conf(dhcp) -value 0
  pack .cfg2.f0.2 -side left

  # zone de saisie
  labelframe .cfg2.f3 -text [::msgcat::mc "Listening interface"]
  pack .cfg2.f3 -fill both -expand 1
  for  {set i 0} {$i < $::tmp(nb_eth)} {incr i} {
    radiobutton .cfg2.f3.$i -text eth$i  -variable ::conf(eth) -value eth$i
    pack .cfg2.f3.$i -side left
  }
  
  labelframe .cfg2.f2 -text [::msgcat::mc "Configuration options"]
  pack .cfg2.f2 -fill both -expand 1
  #label .cfg2.f2.l2 -text "[::msgcat::mc "Network mask"] :"
  #grid .cfg2.f2.l2 -row 1 -column 0 -sticky e
  #entry .cfg2.f2.e2 -background white -width 16 -textvariable ::conf(netmask)
  #grid .cfg2.f2.e2 -row 1 -column 1 -sticky w
  label .cfg2.f2.l3 -text "[::msgcat::mc "Gateway address"] :"
  grid .cfg2.f2.l3 -row 2 -column 0 -sticky e
  entry .cfg2.f2.e3 -background white -width 16 -textvariable ::conf(gateway)
  grid .cfg2.f2.e3 -row 2 -column 1 -sticky w
  label .cfg2.f2.l5 -text "[::msgcat::mc "DNS address"] :"
  grid .cfg2.f2.l5 -row 3 -column 0 -sticky e
  entry .cfg2.f2.e5 -background white -width 16 -textvariable ::conf(dns)
  grid .cfg2.f2.e5 -row 3 -column 1 -sticky w
  label .cfg2.f2.l6 -text "[::msgcat::mc "Domain name"] :"
  grid .cfg2.f2.l6 -row 4 -column 0 -sticky e
  entry .cfg2.f2.e6 -background white -width 16 -textvariable ::conf(domain)
  grid .cfg2.f2.e6 -row 4 -column 1 -sticky w

  labelframe .cfg2.f1 -text [::msgcat::mc "IP address slot"]
  pack .cfg2.f1 -fill both -expand 1
  label .cfg2.f1.l1 -text "[::msgcat::mc "First IP address"] :"
  grid .cfg2.f1.l1 -row 1 -column 0 -sticky e
  entry .cfg2.f1.e1 -background white -width 16 -textvariable ::conf(ip1)
  grid .cfg2.f1.e1 -row 1 -column 1 -sticky w
  label .cfg2.f1.l4 -text "[::msgcat::mc "Last IP address"] :"
  grid .cfg2.f1.l4 -row 1 -column 2 -sticky e
  entry .cfg2.f1.e4 -background white -width 16 -textvariable ::conf(ip2)
  grid .cfg2.f1.e4 -row 1 -column 3 -sticky e
  
  # boutons
  frame .cfg2.fb
  pack .cfg2.fb
  button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
    # calcul du réseau
    # On doit d'abord récupérer le masque et le mettre au format décimal s'il est au format CIDR
    set ::conf(netmask) [lindex [lire_interface $::conf(eth)] 2]
    set ::conf(network) [calcul_reseau $::conf(ip1) $::conf(netmask)]
    applique_config_dhcp
    destroy .cfg2
  }
  pack .cfg2.fb.v -side left
  button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
  pack .cfg2.fb.a -side left
}

# Fenetre de config du serveur http
################################################################################
proc fenetre_config_http {} {
  
  # réinitialisation/récupération de la config
  array unset ::conf
  set res [lire_param http]
  if {$res == {}} {
    set ::conf(http) 0
  } else  {
    array set ::conf $res
  }
  
  destroy .cfg2
  toplevel .cfg2
  wm title .cfg2  [::msgcat::mc "HTTP server configuration"]
  wm transient .cfg2 .cfg
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config_serveur
  pack .cfg2.ico
  
  label .cfg2.l -text [::msgcat::mc "The HTTP server hosts Websites"]
  pack .cfg2.l
  
  # Choix du type de config
  labelframe .cfg2.f0 -text [::msgcat::mc "Server state"]
  pack .cfg2.f0 -fill both -expand 1
  
  # zone de saisie
  labelframe .cfg2.f1 -text [::msgcat::mc "index.html file content"]
  pack .cfg2.f1 -fill both -expand 1
  text .cfg2.f1.t1 -width 50 -height 10
  pack .cfg2.f1.t1
  .cfg2.f1.t1 insert end [lire_fichier /var/www/html/index.html]
  
  # Choix du type de config... Suite
  radiobutton .cfg2.f0.1 -text [::msgcat::mc "On"]  -variable ::conf(http) -value 1
  pack .cfg2.f0.1 -side left
  radiobutton .cfg2.f0.2 -text [::msgcat::mc "Off"] -variable ::conf(http) -value 0
  pack .cfg2.f0.2 -side left
  
  # boutons
  frame .cfg2.fb
  pack .cfg2.fb
  button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
    # on écrit les modifs du fichier index.html
    ecrire_fichier /var/www/html/index.html [.cfg2.f1.t1 get 1.0 end]
    # on applique la config
    applique_config_http 
    destroy .cfg2
  }
  pack .cfg2.fb.v -side left
  button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
  pack .cfg2.fb.a -side left
}


################################################################################
proc applique_config_dhcp {} {
  
  # Le réseau doit être au format décimal pas en CIDR
  set ::conf(netmask) [calcul_mask_cidr2dec $::conf(netmask)]
  # sauvegarde des données
  ecrire_param dhcp [array get ::conf]
  
  # ecriture du fichier de config dhcpd.conf
  set f [open /etc/dhcp/dhcpd.conf w]
  puts $f "#Automatic configuration by Network-In interface"
  puts $f ""
  puts $f "default-lease-time 200;"
  puts $f "max-lease-time 500;"
  puts $f "option subnet-mask $::conf(netmask);"
  if {$::conf(gateway) != ""} {
    puts $f "option routers $::conf(gateway);"
  }
  if {$::conf(dns) != ""} {
    puts $f "option domain-name-servers $::conf(dns);"
  }
  if {$::conf(domain) != ""} {
    puts $f "option domain-name \"$::conf(domain)\";"
  }
  puts $f "subnet $::conf(network) netmask $::conf(netmask) \{"
  if {$::conf(ip1)!={} && $::conf(ip2)!={}} {
      puts $f "range $::conf(ip1) $::conf(ip2);"
  }
  puts $f "\}" 
  close $f

  # Modification du fichier de config /etc/default/isc-dhcp-server
  exec sed -i s/^INTERFACESv4=.*/INTERFACESv4=\"$::conf(eth)\"/ /etc/default/isc-dhcp-server
  
  # redémarrage du service
  maj_service isc-dhcp-server $::conf(dhcp)
  
  array unset ::conf
}


################################################################################
proc applique_config_ftp {} {
  
  # sauvegarde des données
  ecrire_param ftp [array get ::conf]
  
  # ecriture du fichier de config proftpd.conf
  set f [open /etc/proftpd/conf.d/networkin.conf w]
  puts $f "#Automatic configuration by Network-In interface
UseIPv6 off
RequireValidShell off
TimeoutNoTransfer 3600
TimeoutStalled 3600
TimeoutIdle 7200
DefaultRoot ~
Umask 022 022
ServerName [lire_nom_machine]
AccessGrantMsg \"[::msgcat::mc {Welcome to %u in Network-In FTP Server}]\"
"

  close $f
  
  # gestion des comptes
  set liste_comptes {}
  foreach i $::tmp(ftp_users_init) {
	lappend liste_comptes [lindex $i 0]
  }
  # ajout de comptes
  foreach i $::conf(ftp_users) {
	set nom [lindex $i 0]
	set pass [lindex $i 1]
	if {[lsearch $liste_comptes $nom] == {-1}} {
	  creer_user_ftp $nom $pass
	}
  }
  # suppression de comptes
  set liste_comptes_nouv {}
  foreach i $::conf(ftp_users) {
	lappend liste_comptes_nouv [lindex $i 0]
  }
  foreach i $liste_comptes {
	if {[lsearch $liste_comptes_nouv $i] == {-1}} {
	  supprimer_user $i
	}
  }
  
  # création du répertoire ftp
  if {![file exists /home/ftp]} {
	file mkdir /home/ftp
	# on fixe des droits très permissifs... mais ici ce n'est pas un pb !
	file attributes /home/ftp -permissions 0777
  }
  # gestion du rep www
  if {$::conf(ftp_rep_www)} {
	if {![file exists /home/ftp/www]} {
	  file mkdir /home/ftp/www
	  # on fixe des droits très permissifs... mais ici ce n'est pas un pb !
	  file attributes /var/www/html -permissions 0777
	}
	set res [exec mount | grep /home/ftp/www &]
	if {$res != {}} {
	  catch {exec mount --bind /var/www/html /home/ftp/www}
	}
  } else  {
	catch {exec umount /home/ftp/www}
	file delete /home/ftp/www
  }
  
  # redémarrage du service
  maj_service proftpd $::conf(ftp)
  
  array unset ::conf
}


################################################################################
proc applique_config_http {} {
  
  # sauvegarde des données
  ecrire_param http [array get ::conf]
  
  # redémarrage du service
  maj_service apache2 $::conf(http)
  
  array unset ::conf
}

################################################################################
proc applique_config_ssh {} {
  
  # sauvegarde des données
  ecrire_param ssh [array get ::conf]
	
	#Cas où on refuse la connexion directe de root
	if {$::conf(ssh_refuse_root)} {
		exec sed -E -i "s/^#?PermitRootLogin.*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
	} else {
		exec sed -E -i "s/^#?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
	}
  
  # redémarrage du service
  maj_service ssh $::conf(ssh)
  
  array unset ::conf
}

# Renverse l'IP
################################################################################
proc inverse_ip {ip} {
  set ip [split $ip {.}]
  set inv {}
  for  {set i 3} {$i >= 0} {incr i -1} {
    set inv "$inv.[lindex $ip $i]"
  }
  set inv [string range $inv 1 end]
  return $inv
}

################################################################################
proc applique_config_dns {} {
  
  # sauvegarde des données
  ecrire_param dns [array get ::conf]
  
  # ecriture du fichier de config named.local
  set f [open /etc/bind/named.conf.local w]
  puts $f "// Automatic configuration by Network-In interface"
  puts $f ""
  # définition de la zone directe
  puts $f "zone \"$::conf(domain)\" \{"
  puts $f "type master;"
  puts $f "file \"/etc/bind/db.direct\";"
  puts $f "\};"
  # définition de la zone inverse
  puts $f ""
  puts $f "zone \"in-addr.arpa\" \{"
  puts $f "type master;"
  puts $f "file \"/etc/bind/db.inverse\";"
  puts $f "\};"
  close $f
  
  # ecriture du fichier de zone directe
  set fd [open /etc/bind/db.direct w]
  puts $fd "; Automatic configuration by Network-In interface"
  puts $fd ";"
  puts $fd "\$TTL 86400"
  puts $fd "@    IN    SOA    localhost.    root.localhost. ("
  puts $fd "    1               ; numero de version"
  puts $fd "    604800    ; rafraichissement"
  puts $fd "    86400      ; re-essai"
  puts $fd "    2419200  ; expiration"
  puts $fd "    86400 )    ; cache TTL negatif"
  puts $fd ";"
  puts $fd "@    IN    NS    localhost."
  
  # ecriture du fichier de zone inverse
  set fi [open /etc/bind/db.inverse w]
  puts $fi "; Automatic configuration by Network-In interface"
  puts $fi ";"
  puts $fi "\$TTL 86400"
  puts $fi "@    IN    SOA    localhost.    root.localhost. ("
  puts $fi "    1               ; numero de version"
  puts $fi "    604800    ; rafraichissement"
  puts $fi "    86400      ; re-essai"
  puts $fi "    2419200  ; expiration"
  puts $fi "    86400 )    ; cache TTL negatif"
  puts $fi ";"
  puts $fi "@    IN    NS    localhost."
  
  # ajout des entrées dans fd et fi
  foreach r $::conf(dns_records) {
    set nom [lindex $r 0]
    set type [lindex $r 1]
    switch $type {
      {A} {
        set ip [lindex $r 2]
        puts $fd "$nom    IN    A    $ip"
        puts $fi "[inverse_ip $ip]    IN    PTR     $nom"
      }
      {CNAME} {
        set cname [lindex $r 2]
        puts $fd "$nom    IN    CNAME    $cname"
      }
    }
  }
  close $fd
  close $fi
  
  # redémarrage du service
  maj_service named $::conf(dns)
  
  array unset ::conf
}

# Fenetre de config du serveur http
################################################################################
proc fenetre_config_ssh {} {
  
  # réinitialisation/récupération de la config
  array unset ::conf
  set res [lire_param ssh]
  if {$res == {}} {
	set ::conf(ssh) 0
    set ::conf(ssh_refuse_root) 1
  } else  {
	array set ::conf $res
  }
  
  destroy .cfg2
  toplevel .cfg2
  wm title .cfg2  [::msgcat::mc "SSH server configuration"]
  wm transient .cfg2 .cfg
  positionne_fenetre .cfg2
  
  label .cfg2.ico -image img_config_serveur
  pack .cfg2.ico
  
  label .cfg2.l -text [::msgcat::mc "The SSH server offers ability to control the computer at distance "]
  pack .cfg2.l
  
  # Choix du type de config
  labelframe .cfg2.f0 -text [::msgcat::mc "Server state"]
  pack .cfg2.f0 -fill both -expand 1
  
  # Choix du type de config... Suite
  radiobutton .cfg2.f0.1 -text [::msgcat::mc "On"]  -variable ::conf(ssh) -value 1
  pack .cfg2.f0.1 -side left
  radiobutton .cfg2.f0.2 -text [::msgcat::mc "Off"] -variable ::conf(ssh) -value 0
  pack .cfg2.f0.2 -side left
  
	# zone de choix de connexion root possible
	labelframe .cfg2.f4 -text [::msgcat::mc "Security"]
	pack .cfg2.f4 -fill both -expand 1
	
	frame .cfg2.f4.f
	pack .cfg2.f4.f -fill x
	label .cfg2.f4.f.l -text "[::msgcat::mc "Direct admin (root) connexion"] :"
	grid .cfg2.f4.f.l  -row 0 -column 0 -sticky w
	checkbutton .cfg2.f4.f.2 -text [::msgcat::mc "Refuse"] -variable ::conf(ssh_refuse_root)
	grid .cfg2.f4.f.2  -row 2 -column 0 -sticky w
	
  # boutons
  frame .cfg2.fb
  pack .cfg2.fb
  button .cfg2.fb.v -compound left -text [::msgcat::mc "Confirm"] -image img_valider -relief flat -command {
	# on applique la config
	applique_config_ssh
	destroy .cfg2
  }
  pack .cfg2.fb.v -side left
  button .cfg2.fb.a -compound left -text [::msgcat::mc "Abort"] -image img_annuler -command {destroy .cfg2} -relief flat
  pack .cfg2.fb.a -side left
}


# Désactivation ou activation d'un service (systemd)
################################################################################
proc maj_service {daemon etat} {
    if {$etat} {
      # installation
      exec /bin/systemctl enable $daemon &
      # le service doit tourner
	  exec /bin/systemctl restart $daemon &
    } else  {
      # désinstallation
	  exec /bin/systemctl disable $daemon &
      # le service doit être arrêté
	  exec /bin/systemctl stop $daemon &
    }
}


################################################################################
proc ecrire_param {service don} {
  set fic $::rep_conf/$service
  set f [open $fic w]
  puts $f $don
  close $f
}


################################################################################
proc lire_param {service} {
	set fic $::rep_conf/$service
	if {![file exists $fic]} {return {}}
	
	set f [open $fic r]
	set res [read $f]
	close $f
	return $res
}

