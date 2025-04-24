####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version 20250422

#Lecture de ::obj et ::tmp et enregistrement de la structure en XML
####################################
proc xml_structure_write {file} {
	
	set f [open $file w]
	
	#Ecriture bloc global
	xml_bloc_global_write $f
	
	#Ecriture des composants
	puts $f "<components>"
	for {set i 1} {$i<=$::tmp(lastid)} {incr i} {
		set id m$i
		if {[info exists ::obj($id,famille)]} {
				if {$::obj($id,famille) == {connection}} {
						#c'est un câble
					  xml_bloc_connection_write $f $id
				} else {
						#c'est un équipement (pc, routeur, switch)
						xml_bloc_equipment_write $f $id
				}
		}
	}
	puts $f "</components>"
	puts $f "</structure>"
	close $f
}


#Enregistrement du bloc global
############################################
proc xml_bloc_global_write {f} {
	
	puts $f "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>"
	puts $f "<structure version=\"1.0\">"
	puts $f "<!-- Definition of network structure and components for Network-In! Simulator -->"
	puts $f "<global>"
	puts $f "    <version>$::version(network-in)</version>"
	puts $f "    <file>$::tmp(file)</file>"
	puts $f "    <cdate>$::tmp(cdate)</cdate>"
	puts $f "    <date>$::tmp(date)</date>"
	puts $f "    <author>$::tmp(author)</author>"
	puts $f "    <description>$::tmp(description)</description>"
	puts $f "    <details>$::tmp(details)</details>"
	puts $f "</global>"

}


#Enregistrement d'un cable
############################################
proc xml_bloc_connection_write {f id} {
	
	set type $::obj($id,type)
	puts $f "<connection id=\"$id\">"
	puts $f "    <type>$type</type>"
	puts $f "    <techno>$::obj($id,techno)</techno>"
	if {[info exists ::obj($id,nom)]} {
			puts $f "    <name>$::obj($id,nom)</name>"
	}
	if {[info exists ::obj($id,note)]} {
		puts $f "    <note>$::obj($id,note)</note>"
	}
	
	if {[lsearch $::obj($id,techno) "ethernet"]  != {-1}} {
							puts $f "    <plug>"
							puts $f "        <id>$::obj($id,id1)</id>"
							puts $f "        <interf>$::obj($id,interf1)</interf>"
							puts $f "    </plug>"
							puts $f "    <plug>"
							puts $f "        <id>$::obj($id,id2)</id>"
							puts $f "        <interf>$::obj($id,interf2)</interf>"
							puts $f "    </plug>"
					}
						puts $f "</connection>"
	
}


#Enregistrement d'un matériel
############################################
proc xml_bloc_equipment_write {f id} {
	
	set family $::obj($id,famille)
	set type $::obj($id,type)
	
	puts $f "<equipment id=\"$id\">"
	puts $f "    <family>$family</family>"
	puts $f "    <type>$type</type>"
	puts $f "    <techno>$::obj($id,techno)</techno>"
	puts $f "    <category>$::obj($id,categorie)</category>"
	
	if {[info exists ::obj($id,nom)]} {
			puts $f "    <name>$::obj($id,nom)</name>"
	}
	if {[info exists ::obj($id,note)]} {
		puts $f "    <note>$::obj($id,note)</note>"
	}
	#Dans le cas d'une virtualbox, id de la VM
	if {[info exists ::obj($id,vbox_id)]} {
			puts $f "    <vbox_id>$::obj($id,vbox_id)</vbox_id>"
	}
	if {[info exists ::obj($id,name_from_vbox)]} {
			puts $f "    <name_from_vbox>$::obj($id,name_from_vbox)</name_from_vbox>"
	}
	puts $f "    <position>"
	puts $f "        <x>$::obj($id,x)</x>"
	puts $f "        <y>$::obj($id,y)</y>"
	puts $f "    </position>"
	puts $f "    <reconf>$::obj($id,reconf)</reconf>"
	if {[info exists ::obj($id,kernel)]} {
			puts $f "    <exec>"
			puts $f "        <kernel>$::obj($id,kernel)</kernel>"
			puts $f "        <disk>$::obj($id,dd)</disk>"
			puts $f "        <options>$::obj($id,exe_options)</options>"
			puts $f "        <memory>$::obj($id,mem)</memory>"
			puts $f "    </exec>"
	}
	
	if {[lsearch $::obj($id,techno) "ethernet"] != {-1}} {   
		#enregistrement des interfaces eth
		for  {set j 0} {$j<$::obj($id,nb_eth)} {incr j} {
			set eth eth$j
			puts $f "    <interf>"
			puts $f "        <type>ethernet</type>"
			puts $f "        <name>$eth</name>"
			if {[info exists ::obj($id,mac_eth$j)]} {
					puts $f "        <mac>$::obj($id,mac_eth$j)</mac>"
			}
			if {[info exists ::obj($id,ip_eth$j)]} {
					puts $f "        <ip>$::obj($id,ip_eth$j)</ip>"
			}
			if {[info exists ::obj($id,netmask_eth$j)]} {
					puts $f "        <netmask>$::obj($id,netmask_eth$j)</netmask>"
			}
			if {[info exists ::obj($id,vbox_interf)]} {
												puts $f "        <vbox_interf>$::obj($id,vbox_interf)</vbox_interf>"
										}
			puts $f "    </interf>"
		}
        #enregistrement interface TAP d'un bridge
        if {[info exists ::obj($id,nom_tap)]} {
            puts $f "    <interf>"
            puts $f "        <type>tap</type>"
            puts $f "        <name>$::obj($id,nom_tap)</name>"
            puts $f "        <mac>$::obj($id,mac_tap)</mac>"
            puts $f "        <configure>$::obj($id,conf_tap)</configure>"
            if {[info exists ::obj($id,ip_tap)]} {
                    puts $f "        <ip>$::obj($id,ip_tap)</ip>"
                }
                if {[info exists ::obj($id,netmask_tap)]} {
                    puts $f "        <netmask>$::obj($id,netmask_tap)</netmask>"
                }
                if {[info exists ::obj($id,gateway_tap)]} {
                    puts $f "        <gateway>$::obj($id,gateway_tap)</gateway>"
                }
            puts $f "    </interf>"
        }
	}
	
	puts $f "</equipment>"
}


#Lecture de la structure xml et affectation de ::obj et ::tmp
############################################
proc xml_structure_read {file} {
	
  set ::tmp(lastid) 0
  set f [open $file r]
  gets $f ligne
  while {![eof $f]} {
      if [regexp -expanded {<structure\ version=\"(.+)\">} $ligne res version] {
      		#On traite la balise de version
          set ::tmp(structure_version) $version
  			
      } elseif [regexp -expanded {<global>} $ligne res] {
  			
  				xml_bloc_global_read $f	
  			
      } elseif [regexp -expanded {<components>} $ligne res] {
  			
    			#On traite le bloc des composants
      		while {![regexp -expanded {</components>} $ligne res]} {
  					gets $f ligne
  					if [regexp -expanded {<equipment\ id=\"(m[0-9]+)\">} $ligne res id] {
							set n [string range $id 1 end]
							if {$n > $::tmp(lastid)} {
								set ::tmp(lastid) $n
							}
  						xml_bloc_equipment_read $f $id
  						
  					} elseif [regexp -expanded {<connection\ id=\"(m[0-9]+)\">} $ligne res id] {
							set n [string range $id 1 end]
							if {$n > $::tmp(lastid)} {
								set ::tmp(lastid) $n
							}
  						xml_bloc_connection_read $f $id
  					}
      		}
      		gets $f ligne
      		#fin bloc composants
      }
      gets $f ligne
  }
	close $f
	
}


#Lecture du bloc global
############################################
proc xml_bloc_global_read {f} {
	
	gets $f ligne
	while {![regexp -expanded {</global>} $ligne res]} {
		set param {}
		regexp -expanded {<(.+)>(.*)</.+>} $ligne res param valeur
		set ::tmp($param) $valeur
		gets $f ligne
	}
	
}


#Lecture d'un équipement
############################################
proc xml_bloc_equipment_read {f id} {
	
	set ::obj($id,nb_eth) 0
	gets $f ligne
	while {![regexp -expanded {</equipment>} $ligne res]} {
		if [regexp -expanded {<position>} $ligne res] {
			#On traite le bloc position
			gets $f ligne
			while {![regexp -expanded {</position>} $ligne res]} {
				if [regexp -expanded {<x>(.*)</x>} $ligne res valeur] {
					set ::obj($id,x) $valeur
				} elseif [regexp -expanded {<y>(.*)</y>} $ligne res valeur] {
					set ::obj($id,y) $valeur
				}
				gets $f ligne
			}
			#fin bloc position
		} elseif [regexp -expanded {<exec>} $ligne res] {
			#Traitement bloc exec
			gets $f ligne
			while {![regexp -expanded {</exec>} $ligne res]} {
				set param {}
				regexp -expanded {<(.+)>(.*)</.+>} $ligne res param valeur
				set param [string map {disk dd memory mem options exe_options} $param]
				set ::obj($id,$param) $valeur
				gets $f ligne
				#fin bloc exec
			}
		} elseif [regexp -expanded {<interf>} $ligne res] {
			#Traitement bloc interface (eth ou autre)
			gets $f ligne
			while {![regexp -expanded {</interf>} $ligne res]} {
                if [regexp -expanded {<type>(.*)</type>} $ligne res valeur] {
					set type $valeur
                    
					if {$type == "ethernet"} {
						incr ::obj($id,nb_eth)
                        set tmp_type $type
					}
                    if {$type == "tap"} {
                        set tmp_type $type
                    }
				} elseif [regexp -expanded {<name>(.*)</name>} $ligne res valeur] {
					set name $valeur
                    switch $type {
                        {ethernet} {set ::obj($id,$name) {}}
                        {tap} {
                            set ::obj($id,nom_tap) $name
                            set name tap
                        }
                    }
				} elseif [regexp -expanded {<mac>(.*)</mac>} $ligne res valeur] {
                    set ::obj($id,mac_$name) $valeur
				} elseif [regexp -expanded {<ip>(.*)</ip>} $ligne res valeur] {
					set ::obj($id,ip_$name) $valeur
				} elseif [regexp -expanded {<netmask>(.*)</netmask>} $ligne res valeur] {
					set ::obj($id,netmask_$name) $valeur
                } elseif [regexp -expanded {<gateway>(.*)</gateway>} $ligne res valeur] {
                    set ::obj($id,gateway_$name) $valeur
                } elseif [regexp -expanded {<configure>(.*)</configure>} $ligne res valeur] {
                    set ::obj($id,conf_$name) $valeur
				} elseif [regexp -expanded {<vbox_interf>(.*)</vbox_interf>} $ligne res valeur] {
					set ::obj($id,vbox_interf) $valeur
				}
				gets $f ligne
			}
			#fin bloc interface
		} else {
			#Autres balises
			set param {}
			regexp -expanded {<(.+)>(.*)</.+>} $ligne res param valeur
			set param [string map {name_from_vbox name_from_vbox family famille name nom category categorie} $param]
			set ::obj($id,$param) $valeur
		}
		gets $f ligne
	}
	
}


#Lecture d'un câble
############################################
proc xml_bloc_connection_read {f id} {
	
	set ::obj($id,famille) {connection}
	set n_con 1
	gets $f ligne
	while {![regexp -expanded {</connection>} $ligne res]} {
		#exit
		if [regexp -expanded {<plug>} $ligne res] {
			#Traitement bloc connection
			gets $f ligne
			while {![regexp -expanded {</plug>} $ligne res]} {
				if [regexp -expanded {<id>(.*)</id>} $ligne res id_equipment] {
					set ::obj($id,id$n_con) $id_equipment
				} elseif [regexp -expanded {<interf>(.*)</interf>} $ligne res interf] {
					set ::obj($id,interf$n_con) $interf
				}
				gets $f ligne
			}
			#Mise à jour de la connexion dans l'équipement
			set ::obj($id_equipment,$interf) $id
			incr n_con 
			#fin bloc connection
		} else {
			#Autres balises
			if [regexp -expanded {<(.+)>(.*)</.+>} $ligne res param valeur] {
			set ::obj($id,$param) $valeur
			}
		}
	gets $f ligne
	}
	
}
