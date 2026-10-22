####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Fonctions gestion réseau ordinateur et routeur
####################################################################
# Version 20261021

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


# Changement de la configuration IP d'une interface
# Enregistrement de la nouvelle config dans /etc/network/interfaces
################################################################################
proc changer_ip_machine {interface config} {
    
    # arret des interfaces
    catch {exec systemctl stop networking.service}
    # chargement de la liste de toutes les interfaces
    set l_interf [get_all_interfaces_list]
    # mise à jour du fichier interfaces
    set f [open /etc/network/interfaces.new w]
    puts $f "#Automatic configuration by Network-In interface"
    puts $f ""
    # config de l'interface loopback
    puts $f "#Interface lo"
    puts $f "auto lo"
    puts $f "iface lo inet loopback"
    # config des interfaces déjà existantes
    foreach interf $l_interf {
        catch {exec ip a flush $interf}
        if {$interface == $interf} {
            set conf $config
        } else {
            set conf [lire_interface $interf]
        }
        # si l'interface est marquée pour suppression, on ne l'enregistre pas
        if {!($interf == $interface && $config == {delete})} {
            write_interf_block $f $interf $conf
        }
    }
    # config de l'interface si elle est nouvelle
    if {[lsearch $l_interf $interface] == -1} {
        write_interf_block $f $interface $config
    }
    close $f
    file rename -force /etc/network/interfaces.new /etc/network/interfaces
    # redémarrage des interfaces réseau
    catch {exec systemctl start networking.service &}
    
}


# Enregistrement du bloc concernant l'interface dans /etc/network/interfaces
################################################################################
proc write_interf_block {f interface conf} {
    
    set address [lindex $conf 1]
    set mode [lindex $conf 0]
    set etat  [lindex $conf 4]
    if {$mode == {static} && $address != {}} {
        puts $f ""
        puts $f "#Interface $interface"
        if {$etat == {1}} {
            puts $f "auto $interface"
        }
        puts $f "iface $interface inet static"
        set netmask [lindex $conf 2]
        set gateway [lindex $conf 3]
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


# Lit le fichier d'échange des interfaces et retourne la liste
# Retourne également les interfaces virtuelles (lliste des vlans dans ::tmp(ethX,vlan)
################################################################################
proc get_interfaces_list {} {

    set liste {}
    set l_int [lire_fichier_echange interfaces]
    foreach {type nb} $l_int {
        for  {set i 0} {$i < $nb} {incr i} {
            lappend liste $type$i
        }
    }
    return $liste
    
}

# Lit le fichier d'échange des interfaces et retourne la liste
# Retourne également les interfaces virtuelles (lliste des vlans dans ::tmp(ethX,vlan)
################################################################################
proc get_all_interfaces_list {} {

    set l_interf [get_interfaces_list]
    foreach interf $l_interf {
        foreach vlan [get_virtual_interfaces_vlan $interf] {
            lappend l_interf $interf.$vlan
        }
    }
    return $l_interf
    
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
    set stop 0
    set f [open /etc/network/interfaces r]
    # recherche de l'interface
    while {![eof $f] && $stop == 0} {
        gets $f ligne
        if {[lindex $ligne 0] == "auto" && [lindex $ligne 1] == $interface} {
            set etat 1
        } elseif {[lindex $ligne 0]  == "iface" && [lindex $ligne 1] == $interface} {
            set mode [lindex $ligne 3]
            if {$mode == "dhcp"} {
                set stop 1
            } else {
                while {![eof $f] && $stop == 0} {
                    gets $f ligne
                    switch [lindex $ligne 0] {
                        {iface} {
                            # on tombe sur la config d'une autre interface. On a términé
                            set stop 1
                        }
                        {address} {set address [lindex $ligne 1]}
                        {netmask} {set netmask [lindex $ligne 1]}
                        {gateway} {set gateway [lindex $ligne 1]}
                    }
                }
            }
        }
    }
    close $f
    return [list $mode $address $netmask $gateway $etat]
    
}


# recherche d'interfaces virtuelles pour l'interface en paramètre
# retourne la liste des vlan correspondants
################################################################################
proc get_virtual_interfaces_vlan {interf} {
    
    set ret {}
    set f [open /etc/network/interfaces r]
    set exp "iface.*$interf\.(\[0-9\]+)"
    # recherche de l'interface
    while {![eof $f]} {
        gets $f ligne
        if {[regexp $exp $ligne res vlan]} {
            lappend ret $vlan
        }
     }
     return $ret
     
}


# lecture de l'interface configurée
################################################################################
proc lire_ifconfig {interf} {
  
    set ret {}
    set err [catch {set ip_inf [exec /sbin/ip address show $interf]}]
    if {$err == {0}} {
        set exp {inet ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2}).*}
        if {[regexp $exp $ip_inf res ip netmask]} { 
            set ret [list $ip $netmask]
        }
    }
  
    # recherche de la passerelle
    set err [catch {set route_inf [exec /sbin/ip route]}]
    if {$err == {0}} {
        #set exp {default via.*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*$interf}
        set exp "(\[0-9\]{1,3}\.\[0-9\]{1,3}\.\[0-9\]{1,3}\.\[0-9\]{1,3}).*$interf"
        if {[regexp $exp $route_inf res gateway]} { 
            lappend ret $gateway
        }
    }
    
    return $ret
  
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
    if {[lindex $ligne 0] == "search" || [lindex $ligne 0] == "domain"} {
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
