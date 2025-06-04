####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Fonctions gestion réseau ordinateur et routeur
####################################################################
# Version 20250527

# Ecriture du nom dans /etc/hostname
################################################################################
proc changer_nom_machine {nom} {
	# Mise à jour hostname
	exec echo $nom > /etc/hostname
	exec hostname $nom
	
	# On met à jour le nom dans le fichier hosts
	exec sed -i s/$::nom_machine/$nom/ /etc/hosts
	
	# On sauvegarde le nouveau nom
	set ::nom_machine $nom
	
	# Affichage
	wm title . "$nom"
}


# Changement de la configuration IP des interfaces
# Enregistrement de la nouvelle config dans /etc/network/interfaces
################################################################################
proc changer_ip_machine {} {
	
	# arret des interfaces
	catch {exec systemctl stop networking.service}
	for {set i 0} {$i < $::tmp(nb_eth)} {incr i} {
        catch {exec ip a flush eth$i}
    }
    
	# mise à jour du fichier interfaces
	set f [open /etc/network/interfaces w]
	puts $f "#Automatic configuration by Network-In interface"
	puts $f ""
	# config de l'interface loopback
	puts $f "#Interface lo"
	puts $f "auto lo"
	puts $f "iface lo inet loopback"
	# config des ethernet
	for {set i 0} {$i < $::tmp(nb_eth)} {incr i} {
		set interface eth$i
		set address [lindex $::tmp($interface) 1]
		set mode [lindex $::tmp($interface) 0]
		set etat  [lindex $::tmp($interface) 4]
		if {$mode == {static} && $address != {}} {
			puts $f ""
			puts $f "#Interface $interface"
			if {$etat == {1}} {
				puts $f "auto $interface"
			}
			puts $f "iface $interface inet static"
			set address [lindex $::tmp($interface) 1]
			set netmask [lindex $::tmp($interface) 2]
			set gateway [lindex $::tmp($interface) 3]
			puts $f "address $address"
			puts $f "netmask $netmask"
			if {$gateway != {}} {
				puts $f "gateway $gateway"
			}
		}
		if {$mode == {dhcp}} {
			puts $f ""
			puts $f "#Interface $interface"
			if {$etat == {1}} {
				puts $f "auto $interface"
			}
			puts $f "iface $interface inet dhcp"
		}
	}
	close $f
	
	# redémarrage des interfaces réseau
	catch {exec systemctl start networking.service &}
	
}


# Lit le fichier d'échange des interfaces et complète les données dans $tmp
# $tmp(nb_eth) et $nb(nb_wlan) et les ip dans $tmp(eth0)... $tmp(wlan1)...
################################################################################
proc lire_interfaces {} {
	set ::tmp(nb_eth) 0
	set ::tmp(nb_wlan) 0
	
	set l_int [lire_fichier_echange interfaces]
	foreach {type nb} $l_int {
		set ::tmp(nb_$type) $nb
		for  {set i 0} {$i < $::tmp(nb_$type)} {incr i} {
			# lecture de la config ip des interfaces
			set ::tmp($type$i) [lire_interface $type$i]
		}
	}
}


# lecture du fichier hostname
################################################################################
proc lire_nom_machine {} {
	return [exec cat /etc/hostname]
}


# lecture du fichier interfaces
################################################################################
proc lire_interface {interface} {
	
	set mode {static}
	set etat 0
	set address {}
	set netmask {}
	set gateway {}
	
	set f [open /etc/network/interfaces r]
	
	# recherche de l'interface
	while {![eof $f]} {
		gets $f ligne
		if {[lindex $ligne 0] == "auto" && [lindex $ligne 1] == $interface} {
			set etat 1
		} elseif {[lindex $ligne 0]  == "iface" && [lindex $ligne 1] == $interface} {
			break
		} else  {
			set ligne {}
		}
	}
	if {$ligne == {}} {
		return [list $mode $address $netmask $gateway $etat]
	}
	
	# si dhcp, alors on a finit de lire le fichier et on sort
	set mode [lindex $ligne 3]
	if {$mode == "dhcp"} {
		close $f
		return [list $mode $address $netmask $gateway $etat ]
	}
	
	# recherche des autres paramètres
	while {![eof $f]} {
		gets $f ligne
		switch [lindex $ligne 0] {
			{iface} {
				# on tombe sur la config d'une autre interface. On sort !
				break
			}
			{address} {set address [lindex $ligne 1]}
			{netmask} {set netmask [lindex $ligne 1]}
			{gateway} {set gateway [lindex $ligne 1]}
		}
	}
	close $f
	return [list $mode $address $netmask $gateway $etat]
}


# lecture de l'interface configurée
################################################################################
proc lire_ifconfig {interf} {
  
  # recherche de l'ip
  set a [catch {set res [exec /sbin/ifconfig $interf]}]
  if {$a != {0}} {return {{} {} {}}}
  set n [lsearch $res "addr:*"]
  if {$n == {-1}} {
    set n [lsearch $res "adr:*"]
  }
  
  if {$n == {-1}} {
    # pas d'ip configurée
    return {{} {} {}}
  }
  
  set ip [lindex $res $n]
  set ip [split $ip {:}]
  set ip [lindex $ip 1]
  
  # recherche du masque
  set n [lsearch $res "Mas*"]
  set netmask [lindex $res $n]
  set netmask [split $netmask {:}]
  set netmask [lindex $netmask 1]
  
  # recherche de la passerelle
  set a [catch {set res [eval exec /sbin/route -n | grep "^0.0.0.0.*$interf"]}]
  if {$a != {0}} {return "$ip $netmask {}"}
  set gateway [lindex $res 1]
  return "$ip $netmask $gateway"
  
}


#Fonction qui calcule le masque décimal pointé à partir du CIDR
################################################################################
proc calcul_mask_cidr2dec {cidr} {
    set ret $cidr
    if [regexp -line {^[0-9]{1,2}$} $cidr res] {
        set dec(1) 0
        set dec(2) 0
        set dec(3) 0
        set dec(4) 0
        
        set n [expr $cidr / 8]
        for {set i 1} {$i <= $n} {incr i} {
            set dec($i) 255
        }
        set val [expr $cidr % 8]
        set exp 7
        for {set j 1} {$j <= $val} {incr j} {
            set dec($i) [expr $dec($i) + 2**$exp]
            set exp [expr $exp - 1]
        }
        set ret "$dec(1).$dec(2).$dec(3).$dec(4)"
    }
    return $ret
}


#Fonction qui calcule l'ip de réseau à partir de l'IP+masque
################################################################################
proc calcul_reseau {ip mask} {
	
	  # Convertir l'adresse IP et le masque en listes d'octets
	  set ipBytes [split $ip "."]
	  set maskBytes [split $mask "."]
  
	  # Initialiser une liste pour stocker les octets de l'adresse réseau
	  set networkBytes {}
  
	  # Calculer chaque octet de l'adresse réseau
	  for {set i 0} {$i < 4} {incr i} {
		  set ipByte [lindex $ipBytes $i]
		  set maskByte [lindex $maskBytes $i]
		  set networkByte [expr {$ipByte & $maskByte}]
		  lappend networkBytes $networkByte
	  }
  
	  # Joindre les octets pour former l'adresse réseau
	  return [join $networkBytes "."]
	
}

# Ecriture DNS dans resolv.conf
################################################################################
proc changer_dns_machine {domain serv1 serv2 serv3} {
  set f [open /etc/resolv.conf w]
  puts $f "#Automatic configuration by Network-In interface"
  if {$domain != {}} {
    puts $f "search $domain"
  }
  for  {set i 1} {$i <=3} {incr i} {
    if {[set serv$i] != {}} {
      puts $f "nameserver [set serv$i]"
    }
  }
  close $f
}


# lecture du fichier resolv.conf
################################################################################
proc lire_dns_machine {} {
  set domain {}
  set serv1 {}
  set serv2 {}
  set serv3 {}
  set i 1
  set f [open /etc/resolv.conf r]
  while {![eof $f]} {
    gets $f ligne
    if {[lindex $ligne 0] == "domain"} {
      set domain [lindex $ligne 1]
    }
    if {[lindex $ligne 0] == "nameserver" && $i <4} {
      set serv$i [lindex $ligne 1]
      incr i
    }
  }
  close $f
  return [list $domain $serv1 $serv2 $serv3]
}


# Ecriture de données textuelles dans un fichier
################################################################################
proc ecrire_fichier {fichier don} {
  set f [open $fichier w]
  puts $f $don
  close $f
}


# Lecture de données textuelles depuis un fichier
################################################################################
proc lire_fichier {fichier} {
  set f [open $fichier r]
  set don [read $f]
  close $f
  return $don
}
