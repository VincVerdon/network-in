####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version 20250111
# Ce fichier permet d'initialiser chaque type de composant


################################################################################
proc initialisation_desktop {id} {
	set ::obj($id,reconf) true
  set ::obj($id,famille) computer
  set ::obj($id,type) desktop
  set ::obj($id,categorie) dte
  set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 1
	init_eth_mac $id
  set ::obj($id,nom) $id
  set ::obj($id,mem) 512M
	set ::obj($id,dd) $::img_dd
	set ::obj($id,exe_options) "con0=fd:0,fd:1 con1=null con=pts"
	set ::obj($id,kernel) $::kernel
	# création du rep de la machine et copie des fichiers nécessaires au fonctionnement
	file mkdir $::rep_proj/datas/$id/interface
	file copy -force $::rep/machines/lib/nid $::rep_proj/datas/$id
	file copy -force $::rep/machines/lib/images $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/commun/* $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/computer/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/desktop/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_laptop {id} {
	set ::obj($id,reconf) false
  set ::obj($id,famille) computer
  set ::obj($id,type) laptop
  set ::obj($id,categorie) dte
  set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 1
  init_eth_mac $id
  set ::obj($id,nom) $id
  set ::obj($id,mem) 512M
	set ::obj($id,dd) $::img_dd
	set ::obj($id,exe_options) "con0=fd:0,fd:1 con1=null con=pts"
	set ::obj($id,kernel) $::kernel
	# création du rep de la machine et copie des fichiers nécessaires au fonctionnement
	file mkdir $::rep_proj/datas/$id/interface
	file copy -force $::rep/machines/lib/nid $::rep_proj/datas/$id
	file copy -force $::rep/machines/lib/images $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/commun/* $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/computer/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/laptop/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_server {id} {
	set ::obj($id,reconf) true
  set ::obj($id,famille) computer
  set ::obj($id,type) server
  set ::obj($id,categorie) dte
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 1
  init_eth_mac $id
  set ::obj($id,nom) $id
  set ::obj($id,mem) 512M
	set ::obj($id,dd) $::img_dd
	set ::obj($id,exe_options) "con0=fd:0,fd:1 con1=null con=pts"
	set ::obj($id,kernel) $::kernel
	# création du rep de la machine et copie des fichiers nécessaires au fonctionnement
	file mkdir $::rep_proj/datas/$id/interface
	file copy -force $::rep/machines/lib/nid $::rep_proj/datas/$id
	file copy -force $::rep/machines/lib/images $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/commun/* $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/computer/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/server/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_linux {id} {
	set ::obj($id,reconf) true
  set ::obj($id,famille) computer
  set ::obj($id,type) linux
  set ::obj($id,categorie) dte
  set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 1
	init_eth_mac $id
  set ::obj($id,nom) $id
  set ::obj($id,mem) 256M
	set ::obj($id,dd) $::img_dd
	set ::obj($id,exe_options) "con0=fd:0,fd:1 con1=null con=pts"
	set ::obj($id,kernel) $::kernel
	# création du rep de la machine et copie des fichiers nécessaires au fonctionnement
	file mkdir $::rep_proj/datas/$id/interface
	file copy -force $::rep/machines/lib/nid $::rep_proj/datas/$id
	file copy -force $::rep/machines/lib/images $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/commun/* $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/computer/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/linux/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_switch4 {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) switch
	set ::obj($id,type) switch4
	set ::obj($id,categorie) dce
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 4
	init_eth $id
	set ::obj($id,nom) $id
}


################################################################################
proc initialisation_switch8 {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) switch
	set ::obj($id,type) switch8
	set ::obj($id,categorie) dce
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 8
	init_eth $id
	set ::obj($id,nom) $id
}


################################################################################
proc initialisation_hub4 {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) hub
	set ::obj($id,type) hub4
	set ::obj($id,categorie) dce
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 4
	init_eth $id
	set ::obj($id,nom) $id
}


################################################################################
proc initialisation_hub8 {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) hub
	set ::obj($id,type) hub8
	set ::obj($id,categorie) dce
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 8
	init_eth $id
	set ::obj($id,nom) $id
}


################################################################################
proc initialisation_router2 {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) router
	set ::obj($id,type) router2
	set ::obj($id,categorie) dte
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 2
	init_eth_mac $id
	set ::obj($id,nom) $id
	set ::obj($id,mem) 128M
	set ::obj($id,dd) $::img_dd
	set ::obj($id,exe_options) "con0=fd:0,fd:1 con1=null con=pts"
	set ::obj($id,kernel) $::kernel
	# création du rep de la machine et copie des fichiers nécessaires au fonctionnement
	file mkdir $::rep_proj/datas/$id/interface
	file copy -force $::rep/machines/lib/nid $::rep_proj/datas/$id
	file copy -force $::rep/machines/lib/images $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/commun/* $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/router/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/router2/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_router4 {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) router
  	set ::obj($id,type) router4
  	set ::obj($id,categorie) dte
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 4
  	init_eth_mac $id
  	set ::obj($id,nom) $id
  	set ::obj($id,mem) 128M
	set ::obj($id,dd) $::img_dd
	set ::obj($id,exe_options) "con0=fd:0,fd:1 con1=null con=pts"
	set ::obj($id,kernel) $::kernel
	# création du rep de la machine et copie des fichiers nécessaires au fonctionnement
	file mkdir $::rep_proj/datas/$id/interface
	file copy -force $::rep/machines/lib/nid $::rep_proj/datas/$id
	file copy -force $::rep/machines/lib/images $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/commun/* $::rep_proj/datas/$id/interface
	file_copy_motif $::rep/machines/lib/router/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/router4/* $::rep_proj/datas/$id	
}


################################################################################
proc initialisation_straight {id id1 id2 eth1 eth2} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) connection
	set ::obj($id,type) straight
	set ::obj($id,techno) ethernet
	set ::obj($id,nom) {}
	set ::obj($id,id1) $id1
	set ::obj($id,id2) $id2
	set ::obj($id,interf1) $eth1
	set ::obj($id,interf2) $eth2
	set ::obj($id1,$eth1) $id
	set ::obj($id2,$eth2) $id
}


################################################################################
proc initialisation_cross {id id1 id2 eth1 eth2} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) connection
	set ::obj($id,type) cross
	set ::obj($id,techno) ethernet
	set ::obj($id,nom) {}
	set ::obj($id,id1) $id1
	set ::obj($id,id2) $id2
	set ::obj($id,interf1) $eth1
	set ::obj($id,interf2) $eth2
	set ::obj($id1,$eth1) $id
	set ::obj($id2,$eth2) $id
}


################################################################################
proc initialisation_nat {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) output
	set ::obj($id,type) nat
	set ::obj($id,categorie) dte
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 1
	set ::obj($id,eth0) {}
	set ::obj($id,ip_eth0) {}
	set ::obj($id,netmask_eth0) {}
	set ::obj($id,nom) $id
}


################################################################################
proc initialisation_bridge {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) output
	set ::obj($id,type) bridge
	set ::obj($id,categorie) dce
	set ::obj($id,techno) ethernet
    set ::obj($id,nom) $id
	set ::obj($id,nb_eth) 1
	set ::obj($id,eth0) {}
    #Interface TAP côté machine hôte
    set ::obj($id,nom_tap) "eth_$id"
    set ::obj($id,mac_tap) [aleatoire_mac]
	set ::obj($id,ip_tap) {}
	set ::obj($id,netmask_tap) {}
    set ::obj($id,gateway_tap) {}
    set ::obj($id,conf_tap) {off}
}


################################################################################
proc initialisation_virtualbox {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) vm
	set ::obj($id,type) virtualbox
	set ::obj($id,categorie) dte
	set ::obj($id,techno) ethernet
	set ::obj($id,nb_eth) 1
	set ::obj($id,eth0) {}
	set ::obj($id,nom) $id
	set ::obj($id,name_from_vbox) false
	set ::obj($id,vbox_id) {}
	set ::obj($id,vbox_interf) {1}
	#A la création aucune VM attachée à l'objet
	set ::tmp($id,is_present) 0
}

