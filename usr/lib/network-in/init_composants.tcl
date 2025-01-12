####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version 20250111
# Ce fichier permet d'initialiser chaque type de composant


################################################################################
proc initialisation_pc {id} {
	set ::obj($id,reconf) true
  set ::obj($id,famille) ordinateur
  set ::obj($id,type) pc
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
	file_copy_motif $::rep/machines/lib/ordinateur/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/pc/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_portable {id} {
	set ::obj($id,reconf) false
  set ::obj($id,famille) ordinateur
  set ::obj($id,type) portable
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
	file_copy_motif $::rep/machines/lib/ordinateur/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/portable/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_serveur {id} {
	set ::obj($id,reconf) true
  set ::obj($id,famille) ordinateur
  set ::obj($id,type) serveur
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
	file_copy_motif $::rep/machines/lib/ordinateur/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/serveur/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_pctexte {id} {
	set ::obj($id,reconf) true
  set ::obj($id,famille) ordinateur
  set ::obj($id,type) pctexte
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
	file_copy_motif $::rep/machines/lib/ordinateur/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/pctexte/* $::rep_proj/datas/$id
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
proc initialisation_routeur2 {id} {
	set ::obj($id,reconf) false
  set ::obj($id,famille) routeur
  set ::obj($id,type) routeur2
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
	file_copy_motif $::rep/machines/lib/routeur/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/routeur2/* $::rep_proj/datas/$id
}


################################################################################
proc initialisation_routeur4 {id} {
	set ::obj($id,reconf) false
  set ::obj($id,famille) routeur
  set ::obj($id,type) routeur4
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
	file_copy_motif $::rep/machines/lib/routeur/* $::rep_proj/datas/$id
	file_copy_motif $::rep/machines/routeur4/* $::rep_proj/datas/$id	
}


################################################################################
proc initialisation_droit {id id1 id2 eth1 eth2} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) liaison
	set ::obj($id,type) droit
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
proc initialisation_croise {id id1 id2 eth1 eth2} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) liaison
	set ::obj($id,type) croise
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
proc initialisation_passerelle {id} {
	set ::obj($id,reconf) false
	set ::obj($id,famille) sortie
	set ::obj($id,type) passerelle
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
	set ::obj($id,famille) sortie
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

