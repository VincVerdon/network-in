####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Outils config routeur
####################################################################
# Version 20241218
source [file join $::rep lib_reseau.tcl]

# Enregistre et crée les scripts de routage statique
################################################################################
proc applique_routage_statique {} {

  # sauvegarde des données
  ecrire_param_routage static $::conf(static)
  
  # Suppression des routes actuelles
  catch {exec $::rep_conf/routage_off.sh}
  
  # creation du script de config de routage
  set f [open $::rep_conf/routage_on.sh w]
  puts $f "#!/bin/sh"
  puts $f "#Automatic configuration by Network-In interface"
  puts $f "##############"
  puts $f ""
  puts $f "#Add routes"
  foreach i $::conf(static) {
    set network [lindex $i 0]
    set netmask [lindex $i 1]
    set gateway [lindex $i 2]
    #puts $f "route add  -net $network netmask $netmask gw $gateway"
    puts $f "ip route add $network/$netmask via $gateway"
  }
  close $f
  file attributes $::rep_conf/routage_on.sh -permissions 0700
  
  # creation du (nouveau) script de déconfig de routage
  set f [open $::rep_conf/routage_off.sh w]
  puts $f "#!/bin/sh"
  puts $f "#Automatic configuration by Network-In interface"
  puts $f "##############"
  puts $f ""
  puts $f "#Suppress routes"
  foreach i $::conf(static) {
    set network [lindex $i 0]
    set netmask [lindex $i 1]
    set gateway [lindex $i 2]
    #puts $f "route del  -net $network netmask $netmask gw $gateway"
    puts $f "ip route del $network/$netmask via $gateway"
  }
  close $f
  file attributes $::rep_conf/routage_off.sh -permissions 0700
	
	demarre_routage
}

# Activation des règles de routage statique
################################################################################
proc demarre_routage {} {
	# execution du script de routage
	exec $::rep_conf/routage_on.sh &
}

# lecture des paramètres suivant le type de routage
################################################################################
proc lire_param_routage {type} {
  set fic $::rep_conf/$type
  if {![file exists $fic]} {return {}}
  set f [open $fic r]
  set res [read $f]
  close $f
  return $res
}

################################################################################
proc ecrire_param_routage {type don} {
  set fic $::rep_conf/$type
  set f [open $fic w]
  puts $f $don
  close $f
}

