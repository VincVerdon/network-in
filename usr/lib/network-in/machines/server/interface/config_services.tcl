####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20250509
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
  
    destroy .srv
    toplevel .srv
    wm title .srv  [::msgcat::mc "Services configuration"]
	wm protocol .srv WM_DELETE_WINDOW quit_srv
    positionne_fenetre .srv

    image create photo im_config_serveur -file $::rep/images/server_conf.gif
    label .srv.ico -image im_config_serveur
    pack .srv.ico

    labelframe .srv.f -text [::msgcat::mc "Services configuration"]
    pack .srv.f -fill both -expand 1

    button .srv.f.1 -text [::msgcat::mc "DHCP server"] -command {fenetre_config_dhcp}
    pack .srv.f.1 -fill x

    button .srv.f.2 -text [::msgcat::mc "DNS server"] -command {fenetre_config_dns}
    pack .srv.f.2 -fill x

    button .srv.f.3 -text [::msgcat::mc "HTTP server"] -command {fenetre_config_http}
    pack .srv.f.3 -fill x

    button .srv.f.4 -text [::msgcat::mc "FTP server"] -command {fenetre_config_ftp}
    pack .srv.f.4 -fill x

    button .srv.f.5 -text [::msgcat::mc "SSH server"] -command {fenetre_config_ssh}
    pack .srv.f.5 -fill x

    button .srv.q -compound left -text [::msgcat::mc "Close"] -image im_annuler -command {quit_srv}
    pack .srv.q
	focus .srv.q

    update
    winid_maj [winid_parent [winfo id .srv]]
	
	bind Button <Key-Return> { 
		%W invoke
	}
	
}


# Destruction de toutes les fenêtre lors de la sortie
################################################################################
proc quit_srv {} {
	
	destroy .srv
	destroy .sftp
	destroy .sdns
	destroy .sssh
	destroy .shttp
	destroy .sdhcp
	
}


# Fenetre de config du serveur dns
################################################################################
proc fenetre_config_dns {} {

    if [winfo exists .sdns] {
        raise .sdns
        return
    }

    # réinitialisation/récupération de la config
    array unset ::conf_dns
    set res [lire_param dns]
        if {$res == {}} {
        set ::conf_dns(dns) 0
        set ::conf_dns(dns_records) {}
        set ::conf_dns(domain) {}
    } else  {
        array set ::conf_dns $res
    }
    
    toplevel .sdns
    wm title .sdns  [::msgcat::mc "DNS server configuration"]
    wm transient .sdns .srv
    positionne_fenetre .sdns .srv

    label .sdns.ico -image im_config_serveur
    pack .sdns.ico

    label .sdns.l -text [::msgcat::mc "The DNS server translates computers names into IP address"]
    pack .sdns.l

    # Choix du type de config
    labelframe .sdns.f0 -text [::msgcat::mc "Server state"]
    pack .sdns.f0 -fill both -expand 1
    radiobutton .sdns.f0.1 -text [::msgcat::mc "On"]  -variable ::conf_dns(dns) -value 1
    pack .sdns.f0.1 -side left
    radiobutton .sdns.f0.2 -text [::msgcat::mc "Off"] -variable ::conf_dns(dns) -value 0
    pack .sdns.f0.2 -side left

    # Choix du domaine
    labelframe .sdns.f4 -text [::msgcat::mc "Domain name"]
    pack .sdns.f4 -fill both -expand 1
    label .sdns.f4.l1 -text "[::msgcat::mc "Domain"] :"
    grid .sdns.f4.l1 -row 1 -column 0 -sticky e
    entry .sdns.f4.e1 -background white -width 16 -textvariable ::conf_dns(domain)
    grid .sdns.f4.e1 -row 1 -column 1 -sticky w

    # zone d'affichage des enregistrements
    labelframe .sdns.f1 -text [::msgcat::mc "Current records"]
    pack .sdns.f1 -fill both -expand 1
    ttk::treeview .sdns.f1.t -columns {nom type param} -show headings -yscroll {.sdns.f1.sv set} -height 5
    pack .sdns.f1.t -side left  
    scrollbar .sdns.f1.sv -orient vertical -command {.sdns.f1.t yview}
    pack .sdns.f1.sv -side left -fill y
    .sdns.f1.t heading nom -text [::msgcat::mc "Name"]
    .sdns.f1.t heading type -text [::msgcat::mc "Type"]
    .sdns.f1.t heading param -text [::msgcat::mc "Parameters"]
    labelframe .sdns.f3 -text [::msgcat::mc "Records suppression"]
    pack .sdns.f3 -fill both -expand 1
    label .sdns.f3.l2 -text "[::msgcat::mc "Suppression of a selected record"] :"
    grid .sdns.f3.l2 -row 0 -column 0 -sticky w
    button .sdns.f3.b2 -width 16 -text [::msgcat::mc "Suppress"] -command {
        set n [.sdns.f1.t selection]
        .sdns.f1.t delete $n
    }
    grid .sdns.f3.b2 -row 0 -column 2 -sticky w

    # insertion des données
    foreach i $::conf_dns(dns_records) {
        .sdns.f1.t insert {} end -values [list [lindex $i 0] [lindex $i 1] [lindex $i 2]]
    }

    labelframe .sdns.f2 -text [::msgcat::mc "Add records"]
    pack .sdns.f2 -fill both -expand 1
    # choix du type
    frame .sdns.f2.f
    pack .sdns.f2.f
    label .sdns.f2.f.l -text "[::msgcat::mc "Type"] :"
    pack .sdns.f2.f.l -side left
    radiobutton .sdns.f2.f.1 -text [::msgcat::mc "A"] -variable ::tmp(type) -value A -command "interf_ajout_dns A"
    pack .sdns.f2.f.1 -side left
    radiobutton .sdns.f2.f.2 -text [::msgcat::mc "CNAME"] -variable ::tmp(type) -value CNAME -command "interf_ajout_dns CNAME"
    pack .sdns.f2.f.2 -side left
    # sélection du type A par défaut
    .sdns.f2.f.1 invoke

    # boutons
    frame .sdns.fb
    pack .sdns.fb
    button .sdns.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command {
        set ::conf_dns(dns_records) {}
        set liste [.sdns.f1.t children {}]
        foreach i $liste {
            set record [.sdns.f1.t set $i]
            set record [list [lindex $record 1]  [lindex $record 3]  [lindex $record 5]]
            lappend ::conf_dns(dns_records) $record
        }
        applique_config_dns
        destroy .sdns
    }
    pack .sdns.fb.v -side left
    button .sdns.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {
        destroy .sdns
    }
    pack .sdns.fb.a -side left
	focus .sdns.fb.a
    
}


# frame ajout DNS
################################################################################
proc interf_ajout_dns {type} {
  
    destroy .sdns.f2.f1
    frame .sdns.f2.f1
    pack .sdns.f2.f1 -fill x

    # réinitialisation des données
    # array unset ::conf_dns
    set ::tmp(nom) {}
    set ::tmp(ip) {}
    set ::tmp(cname) {}

    switch $type {
        {A} {
            label .sdns.f2.f1.l1 -text "[::msgcat::mc "Name"] :"
            pack .sdns.f2.f1.l1 -side left
            entry .sdns.f2.f1.e1 -background white -width 16 -textvariable ::tmp(nom)
            pack .sdns.f2.f1.e1 -side left
            label .sdns.f2.f1.l2 -text "[::msgcat::mc "IP"] :"
            pack .sdns.f2.f1.l2 -side left
            entry .sdns.f2.f1.e2 -background white -width 16 -textvariable ::tmp(ip)
            pack .sdns.f2.f1.e2 -side left
            button .sdns.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
            .sdns.f1.t insert {} end -values [list $::tmp(nom) $::tmp(type) $::tmp(ip)]
            }
            pack .sdns.f2.f1.b1 -side right
        }
        {CNAME} {
            label .sdns.f2.f1.l1 -text "[::msgcat::mc "Name"] :"
            pack .sdns.f2.f1.l1 -side left
            entry .sdns.f2.f1.e1 -background white -width 16 -textvariable ::tmp(nom)
            pack .sdns.f2.f1.e1 -side left
            label .sdns.f2.f1.l2 -text {Nom canonique :}
            pack .sdns.f2.f1.l2 -side left
            entry .sdns.f2.f1.e2 -background white -width 16 -textvariable ::tmp(cname)
            pack .sdns.f2.f1.e2 -side left
            button .sdns.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
            .sdns.f1.t insert {} end -values [list $::tmp(nom) $::tmp(type) $::tmp(cname)]
            }
            pack .sdns.f2.f1.b1 -side right
        }
    }
    
}


# On applique la configuration DNS définie dans l'interface
################################################################################
proc applique_config_dns {} {

    # sauvegarde des données
    ecrire_param dns [array get ::conf_dns]

    # ecriture du fichier de config named.local
    set f [open /etc/bind/named.conf.local w]
    puts $f "// Automatic configuration by Network-In interface"
    puts $f ""
    # définition de la zone directe
    puts $f "zone \"$::conf_dns(domain)\" \{"
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
	
	# ecriture du fichier de config named.options
	set f [open /etc/bind/named.conf.options w]
	puts $f "// Automatic configuration by Network-In interface"
	puts $f ""
	puts $f "options \{"
	puts $f "directory \"/var/cache/bind\";"
	puts $f "// forwarders \{"
	puts $f "//      0.0.0.0;"
	puts $f "// \};"
    puts $f ""
	puts $f "dnssec-validation auto;"
	puts $f "listen-on-v6 \{ any; \};"
	puts $f "recursion yes;"
	puts $f "allow-query \{ any; \};"
	puts $f "allow-query-cache \{ any; \};"
	puts $f "allow-recursion \{ any; \};"
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
    foreach r $::conf_dns(dns_records) {
        set nom [lindex $r 0]
        set type [lindex $r 1]
        switch $type {
            {A} {
                set ip [lindex $r 2]
                puts $fd "$nom    IN    A    $ip"
                puts $fi "[renverse_ip $ip]    IN    PTR     $nom"
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
    maj_service named $::conf_dns(dns)

    array unset ::conf_dns
    
}


# Renverse l'IP
################################################################################
proc renverse_ip {ip} {
	
  set ip [split $ip {.}]
  set inv {}
  for  {set i 3} {$i >= 0} {incr i -1} {
    set inv "$inv.[lindex $ip $i]"
  }
  set inv [string range $inv 1 end]
  return $inv
	
}


# Fenetre de config du serveur ftp
################################################################################
proc fenetre_config_ftp {} {

    if [winfo exists .sftp] {
        raise .sftp
        return
    }

    # réinitialisation/récupération de la config
    array unset ::conf_ftp
    set res [lire_param ftp]
    if {$res == {}} {
        set ::conf_ftp(ftp) 0
        set ::conf_ftp(ftp_users) {}
        set ::tmp(ftp_users_init) {}
        # set ::conf_ftp(ftp_rep_ftp) 1
        set ::conf_ftp(ftp_rep_www) 0
    } else  {
        array set ::conf_ftp $res
        set ::tmp(ftp_users_init) $::conf_ftp(ftp_users)
    }
    set ::tmp(nom) {}
    set ::tmp(passe) {}

    toplevel .sftp
    wm title .sftp  [::msgcat::mc "FTP server configuration"]
    wm transient .sftp .srv
    positionne_fenetre .sftp .srv

    label .sftp.ico -image im_config_serveur
    pack .sftp.ico

    label .sftp.l -text [::msgcat::mc "The FTP server allows to put and to access files"]
    pack .sftp.l

    # Choix du type de config
    labelframe .sftp.f0 -text [::msgcat::mc "Server state"]
    pack .sftp.f0 -fill both -expand 1
    radiobutton .sftp.f0.1 -text [::msgcat::mc "On"]  -variable ::conf_ftp(ftp) -value 1
    pack .sftp.f0.1 -side left
    radiobutton .sftp.f0.2 -text [::msgcat::mc "Off"] -variable ::conf_ftp(ftp) -value 0
    pack .sftp.f0.2 -side left

    # zone de choix des répertoires accessibles
    labelframe .sftp.f4 -text [::msgcat::mc "Reachable directories"]
    pack .sftp.f4 -fill both -expand 1

    frame .sftp.f4.f
    pack .sftp.f4.f -fill x
    label .sftp.f4.f.l -text "[::msgcat::mc "Access to the HTTP server"] :"
    grid .sftp.f4.f.l  -row 0 -column 0 -sticky w
    # checkbutton .sftp.f4.f.1 -text {Répertoire par défaut (/home/ftp)} -variable ::conf_ftp(ftp_rep_ftp) -state disable
    # grid .sftp.f4.f.1  -row 1 -column 0 -sticky w
    checkbutton .sftp.f4.f.2 -text [::msgcat::mc "HTTP server directory (/var/www)"] -variable ::conf_ftp(ftp_rep_www)
    grid .sftp.f4.f.2  -row 2 -column 0 -sticky w

    # zone d'affichage des utilisateurs
    labelframe .sftp.f1 -text [::msgcat::mc "Users accounts"]
    pack .sftp.f1 -fill both -expand 1
    ttk::treeview .sftp.f1.t -columns {nom passe} -show headings -yscroll {.sftp.f1.sv set} -height 3
    pack .sftp.f1.t -side left
    scrollbar .sftp.f1.sv -orient vertical -command {.sftp.f1.t yview}
    pack .sftp.f1.sv -side left -fill y
    .sftp.f1.t heading nom -text [::msgcat::mc "Name"]
    .sftp.f1.t heading passe -text [::msgcat::mc "Password"]
    # insertion des données sur les comptes
    foreach i $::conf_ftp(ftp_users) {
        .sftp.f1.t insert {} end -values [list [lindex $i 0] [lindex $i 1]]
    }

    # suppression de comptes
    labelframe .sftp.f3 -text [::msgcat::mc "Accounts suppression"]
    pack .sftp.f3 -fill both -expand 1
    label .sftp.f3.l2 -text "[::msgcat::mc "Selected account suppression"] :"
    grid .sftp.f3.l2 -row 0 -column 0 -sticky w
    button .sftp.f3.b2 -width 16 -text [::msgcat::mc "Suppress"] -command {
        set n [.sftp.f1.t selection]
        .sftp.f1.t delete $n
    }
    grid .sftp.f3.b2 -row 1 -column 2 -sticky w

    # ajout de comptes
    labelframe .sftp.f2 -text [::msgcat::mc "Accounts addition"]
    pack .sftp.f2 -fill both -expand 1
    frame .sftp.f2.f1
    pack .sftp.f2.f1 -fill x
    label .sftp.f2.f1.l1 -text "[::msgcat::mc "Name"] :"
    pack .sftp.f2.f1.l1 -side left
    entry .sftp.f2.f1.e1 -background white -width 16 -textvariable ::tmp(nom)
    pack .sftp.f2.f1.e1 -side left
    label .sftp.f2.f1.l2 -text "[::msgcat::mc "Password"] :"
    pack .sftp.f2.f1.l2 -side left
    entry .sftp.f2.f1.e2 -background white -width 16 -textvariable ::tmp(passe)
    pack .sftp.f2.f1.e2 -side left
    button .sftp.f2.f1.b1 -width 16 -text [::msgcat::mc "Add"] -command {
        .sftp.f1.t insert {} end -values [list $::tmp(nom) $::tmp(passe)]
    }
    pack .sftp.f2.f1.b1 -side right

    # boutons
    frame .sftp.fb
    pack .sftp.fb
    button .sftp.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command {
        set ::conf_ftp(ftp_users) {}
        set liste [.sftp.f1.t children {}]
        foreach i $liste {
            set record [.sftp.f1.t set $i]
            set record [list [lindex $record 1]  [lindex $record 3]]
            lappend ::conf_ftp(ftp_users) $record
        }
        applique_config_ftp
        destroy .sftp
    }
    pack .sftp.fb.v -side left
    button .sftp.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .sftp}
    pack .sftp.fb.a -side left
	focus .sftp.fb.a
    
}


################################################################################
proc creer_user_ftp {nom pass} {
  exec $::rep/../services/bin/creer_user_ftp $nom $pass &
}


################################################################################
proc supprimer_user {nom} {
  exec /usr/sbin/userdel $nom &
}

# On applique la configuration FTP définie dans l'interface
################################################################################
proc applique_config_ftp {} {
  
  # sauvegarde des données
  ecrire_param ftp [array get ::conf_ftp]
  
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
  foreach i $::conf_ftp(ftp_users) {
	set nom [lindex $i 0]
	set pass [lindex $i 1]
	if {[lsearch $liste_comptes $nom] == {-1}} {
	  creer_user_ftp $nom $pass
	}
  }
  # suppression de comptes
  set liste_comptes_nouv {}
  foreach i $::conf_ftp(ftp_users) {
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
  if {$::conf_ftp(ftp_rep_www)} {
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
  maj_service proftpd $::conf_ftp(ftp)
  
  array unset ::conf_ftp
  
}


# Fenetre de config du serveur dhcp
################################################################################
proc fenetre_config_dhcp {} {

    if [winfo exists .sdhcp] {
        raise .sdhcp
        return
    }

    # réinitialisation/récupération de la config
    # lecture de toutes les interfaces
    lire_interfaces

    array unset ::conf_dhcp
    set res [lire_param dhcp]
    if {$res == {}} {
    set ::conf_dhcp(ip1) {}
    set ::conf_dhcp(ip2) {}
    set ::conf_dhcp(netmask) {}
    set ::conf_dhcp(gateway) {}
    set ::conf_dhcp(dns) {}
    set ::conf_dhcp(domain) {}
    set ::conf_dhcp(network) {}
    set ::conf_dhcp(dhcp) 0
    set ::conf_dhcp(eth) eth0
    } else  {
    array set ::conf_dhcp $res
    }
    
    toplevel .sdhcp
    wm title .sdhcp  [::msgcat::mc "DHCP server configuration"]
    wm transient .sdhcp .srv
    positionne_fenetre .sdhcp .srv

    label .sdhcp.ico -image im_config_serveur
    pack .sdhcp.ico

    label .sdhcp.l -text [::msgcat::mc "The DHCP server provides IP address for the other computers of the LAN"]
    pack .sdhcp.l

    # Choix du type de config
    labelframe .sdhcp.f0 -text [::msgcat::mc "Server state"]
    pack .sdhcp.f0 -fill both -expand 1
    radiobutton .sdhcp.f0.1 -text [::msgcat::mc "On"]  -variable ::conf_dhcp(dhcp) -value 1
    pack .sdhcp.f0.1 -side left
    radiobutton .sdhcp.f0.2 -text [::msgcat::mc "Off"] -variable ::conf_dhcp(dhcp) -value 0
    pack .sdhcp.f0.2 -side left

    # zone de saisie
    labelframe .sdhcp.f3 -text [::msgcat::mc "Listening interface"]
    pack .sdhcp.f3 -fill both -expand 1
    for  {set i 0} {$i < $::tmp(nb_eth)} {incr i} {
        radiobutton .sdhcp.f3.$i -text eth$i  -variable ::conf_dhcp(eth) -value eth$i
        pack .sdhcp.f3.$i -side left
    }

    labelframe .sdhcp.f2 -text [::msgcat::mc "Configuration options"]
    pack .sdhcp.f2 -fill both -expand 1
    #label .sdhcp.f2.l2 -text "[::msgcat::mc "Network mask"] :"
    #grid .sdhcp.f2.l2 -row 1 -column 0 -sticky e
    #entry .sdhcp.f2.e2 -background white -width 16 -textvariable ::conf_dhcp(netmask)
    #grid .sdhcp.f2.e2 -row 1 -column 1 -sticky w
    label .sdhcp.f2.l3 -text "[::msgcat::mc "Gateway address"] :"
    grid .sdhcp.f2.l3 -row 2 -column 0 -sticky e
    entry .sdhcp.f2.e3 -background white -width 16 -textvariable ::conf_dhcp(gateway)
    grid .sdhcp.f2.e3 -row 2 -column 1 -sticky w
    label .sdhcp.f2.l5 -text "[::msgcat::mc "DNS address"] :"
    grid .sdhcp.f2.l5 -row 3 -column 0 -sticky e
    entry .sdhcp.f2.e5 -background white -width 16 -textvariable ::conf_dhcp(dns)
    grid .sdhcp.f2.e5 -row 3 -column 1 -sticky w
    label .sdhcp.f2.l6 -text "[::msgcat::mc "Domain name"] :"
    grid .sdhcp.f2.l6 -row 4 -column 0 -sticky e
    entry .sdhcp.f2.e6 -background white -width 16 -textvariable ::conf_dhcp(domain)
    grid .sdhcp.f2.e6 -row 4 -column 1 -sticky w

    labelframe .sdhcp.f1 -text [::msgcat::mc "IP address slot"]
    pack .sdhcp.f1 -fill both -expand 1
    label .sdhcp.f1.l1 -text "[::msgcat::mc "First IP address"] :"
    grid .sdhcp.f1.l1 -row 1 -column 0 -sticky e
    entry .sdhcp.f1.e1 -background white -width 16 -textvariable ::conf_dhcp(ip1)
    grid .sdhcp.f1.e1 -row 1 -column 1 -sticky w
    label .sdhcp.f1.l4 -text "[::msgcat::mc "Last IP address"] :"
    grid .sdhcp.f1.l4 -row 1 -column 2 -sticky e
    entry .sdhcp.f1.e4 -background white -width 16 -textvariable ::conf_dhcp(ip2)
    grid .sdhcp.f1.e4 -row 1 -column 3 -sticky e

    # boutons
    frame .sdhcp.fb
    pack .sdhcp.fb
    button .sdhcp.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command {
        applique_config_dhcp
        destroy .sdhcp
    }
    pack .sdhcp.fb.v -side left
    button .sdhcp.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .sdhcp}
    pack .sdhcp.fb.a -side left
	focus .sdhcp.fb.a

}


# On applique la configuration DHCP définie dans l'interface
################################################################################
proc applique_config_dhcp {} {

    # calcul du réseau
    set ::conf_dhcp(netmask) [lindex [lire_interface $::conf_dhcp(eth)] 2]
	# Le réseau doit être au format décimal pas en CIDR dans le fichier de config de isc-dhcp-server
	set netmask [calcul_mask_cidr2dec $::conf_dhcp(netmask)]
    set ::conf_dhcp(network) [calcul_reseau $::conf_dhcp(ip1) $netmask]
  
  # sauvegarde des données
  ecrire_param dhcp [array get ::conf_dhcp]
  
  # ecriture du fichier de config dhcpd.conf
  set f [open /etc/dhcp/dhcpd.conf w]
  puts $f "#Automatic configuration by Network-In interface"
  puts $f ""
  puts $f "default-lease-time 200;"
  puts $f "max-lease-time 500;"
  puts $f "option subnet-mask $netmask;"
  if {$::conf_dhcp(gateway) != ""} {
    puts $f "option routers $::conf_dhcp(gateway);"
  }
  if {$::conf_dhcp(dns) != ""} {
    puts $f "option domain-name-servers $::conf_dhcp(dns);"
  }
  if {$::conf_dhcp(domain) != ""} {
    puts $f "option domain-name \"$::conf_dhcp(domain)\";"
  }
  puts $f "subnet $::conf_dhcp(network) netmask $netmask \{"
  if {$::conf_dhcp(ip1)!={} && $::conf_dhcp(ip2)!={}} {
      puts $f "range $::conf_dhcp(ip1) $::conf_dhcp(ip2);"
  }
  puts $f "\}" 
  close $f

  # Modification du fichier de config /etc/default/isc-dhcp-server
  exec sed -i s/^INTERFACESv4=.*/INTERFACESv4=\"$::conf_dhcp(eth)\"/ /etc/default/isc-dhcp-server
  
  # redémarrage du service
  maj_service isc-dhcp-server $::conf_dhcp(dhcp)
  
  array unset ::conf_dhcp
}


# Fenetre de config du serveur http
################################################################################
proc fenetre_config_http {} {

    if [winfo exists .shttp] {
        raise .shttp
        return
    }
    
    # réinitialisation/récupération de la config
    array unset ::conf_http
    set res [lire_param http]
    if {$res == {}} {
    set ::conf_http(http) 0
    } else  {
    array set ::conf_http $res
    }

    toplevel .shttp
    wm title .shttp  [::msgcat::mc "HTTP server configuration"]
    wm transient .shttp .srv
    positionne_fenetre .shttp .srv

    label .shttp.ico -image im_config_serveur
    pack .shttp.ico

    label .shttp.l -text [::msgcat::mc "The HTTP server hosts Websites"]
    pack .shttp.l

    # Choix du type de config
    labelframe .shttp.f0 -text [::msgcat::mc "Server state"]
    pack .shttp.f0 -fill both -expand 1

    # zone de saisie
    labelframe .shttp.f1 -text [::msgcat::mc "index.html file content"]
    pack .shttp.f1 -fill both -expand 1
    text .shttp.f1.t1 -width 50 -height 10
    pack .shttp.f1.t1
    .shttp.f1.t1 insert end [lire_fichier /var/www/html/index.html]

    # Choix du type de config... Suite
    radiobutton .shttp.f0.1 -text [::msgcat::mc "On"]  -variable ::conf_http(http) -value 1
    pack .shttp.f0.1 -side left
    radiobutton .shttp.f0.2 -text [::msgcat::mc "Off"] -variable ::conf_http(http) -value 0
    pack .shttp.f0.2 -side left

    # boutons
    frame .shttp.fb
    pack .shttp.fb
    button .shttp.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command {
        # on écrit les modifs du fichier index.html
        ecrire_fichier /var/www/html/index.html [.shttp.f1.t1 get 1.0 end]
        # on applique la config
        applique_config_http 
        destroy .shttp
    }
    pack .shttp.fb.v -side left
    button .shttp.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .shttp}
    pack .shttp.fb.a -side left
	focus .shttp.fb.a
    
}


# On applique la configuration HTTP définie dans l'interface
################################################################################
proc applique_config_http {} {
  
  # sauvegarde des données
  ecrire_param http [array get ::conf_http]
  
  # redémarrage du service
  maj_service apache2 $::conf_http(http)
  
  array unset ::conf_http
  
}


# Fenetre de config du serveur SSH
################################################################################
proc fenetre_config_ssh {} {

    if [winfo exists .sssh] {
        raise .sssh
        return
    }

    # réinitialisation/récupération de la config
    array unset ::conf_ssh
    set res [lire_param ssh]
    if {$res == {}} {
        set ::conf_ssh(ssh) 0
        set ::conf_ssh(ssh_refuse_root) 0
    } else  {
        array set ::conf_ssh $res
    }

    toplevel .sssh
    wm title .sssh  [::msgcat::mc "SSH server configuration"]
    wm transient .sssh .srv
    positionne_fenetre .sssh .srv

    label .sssh.ico -image im_config_serveur
    pack .sssh.ico

    label .sssh.l -text [::msgcat::mc "The SSH server offers ability to control the computer at distance "]
    pack .sssh.l

    # Choix du type de config
    labelframe .sssh.f0 -text [::msgcat::mc "Server state"]
    pack .sssh.f0 -fill both -expand 1

    # Choix du type de config... Suite
    radiobutton .sssh.f0.1 -text [::msgcat::mc "On"]  -variable ::conf_ssh(ssh) -value 1
    pack .sssh.f0.1 -side left
    radiobutton .sssh.f0.2 -text [::msgcat::mc "Off"] -variable ::conf_ssh(ssh) -value 0
    pack .sssh.f0.2 -side left

    # zone de choix de connexion root possible
    labelframe .sssh.f4 -text [::msgcat::mc "Security"]
    pack .sssh.f4 -fill both -expand 1
    frame .sssh.f4.f
    pack .sssh.f4.f -fill x
    label .sssh.f4.f.l -text "[::msgcat::mc "Direct admin (root) connexion"] :"
    grid .sssh.f4.f.l  -row 0 -column 0 -sticky w
    checkbutton .sssh.f4.f.2 -text [::msgcat::mc "Refuse"] -variable ::conf_ssh(ssh_refuse_root)
    grid .sssh.f4.f.2  -row 2 -column 0 -sticky w

    # boutons
    frame .sssh.fb
    pack .sssh.fb
    button .sssh.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command {
        # on applique la config
        applique_config_ssh
        destroy .sssh
    }
    pack .sssh.fb.v -side left
    button .sssh.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .sssh}
    pack .sssh.fb.a -side left
	focus .sssh.fb.a
    
}


# On applique la configuration SSH définie dans l'interface
################################################################################
proc applique_config_ssh {} {
  
  # sauvegarde des données
  ecrire_param ssh [array get ::conf_ssh]
	
	#Cas où on refuse la connexion directe de root
	if {$::conf_ssh(ssh_refuse_root)} {
		exec sed -E -i "s/^#?PermitRootLogin.*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
	} else {
		exec sed -E -i "s/^#?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
	}
  
  # redémarrage du service
  maj_service ssh $::conf_ssh(ssh)
  
  array unset ::conf_ssh
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


# Ecriture des paramètres saisis pour un service
################################################################################
proc ecrire_param {service don} {
    set fic $::rep_conf/$service
    set f [open $fic w]
    puts $f $don
    close $f
}


# Lecture des paramètres saisis pour un service
################################################################################
proc lire_param {service} {
	set fic $::rep_conf/$service
	if {![file exists $fic]} {return {}}
	
	set f [open $fic r]
	set res [read $f]
	close $f
	return $res
}

