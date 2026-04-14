####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de config de la bridge nat
####################################################################
# Version 20260411
set ::version(mswitch) 1.0



#Duplication d'un mswitch à partir d'un autre
##################################################################################
proc dupliquer_mswitch {parent} {
	
	# dimensions de l'image
	#set imx [image width im_$type]
	#set imy [image height im_$type]
	
	# on définit le numéro d'id de l'objet
	incr ::tmp(lastid)
	set id m$::tmp(lastid)
	
	# initialisation des données de l'objet
	set ::obj($id,x) [expr $::obj($parent,x)+10]
	set ::obj($id,y) [expr $::obj($parent,y)+10]
	set ::obj($id,nom) $::obj($parent,nom)
	set ::obj($id,famille) $::obj($parent,famille)
	set ::obj($id,type) $::obj($parent,type)
	set ::obj($id,techno) $::obj($parent,techno)
	set ::obj($id,categorie) $::obj($parent,categorie)
	set ::obj($id,reconf) $::obj($parent,reconf)
	set ::obj($id,nb_eth) $::obj($parent,nb_eth)
	init_eth $id
	set ::obj($id,mac) [aleatoire_mac]
		
	# a la creation l'objet n'est pas démarré
	set ::tmp($id,etat) 0
	set ::tmp($id,win_id) {}
	
	# désarchivage éventuel d'une archive compressée
	if {[file exists $::rep_proj/datas/$parent.tgz]} {
		exec tar -C $::rep_proj --sparse -xzf $::rep_proj/datas/$parent.tgz
		file delete $::rep_proj/datas/$parent.tgz
	}
	# Copie des fichiers
	file copy $::rep_proj/datas/$parent $::rep_proj/datas/$id
	
	# on sauvegarde les données obj
	sauvegarder_projet
	
	# dessin sur le canvas
	dessine_objet $id
	
}


# Terminal de management d'un switch
###############################################################
proc fenetre_manage_switch {id} {
	
	if {$::tmp($id,pid) != {}} {
		set ::tmp($id,win_id) [winid_from_pid $::tmp($id,pid) $::screen]
	}
	if {$::tmp($id,win_id) != {}} {
		show_mswitch $id
	} else {
		set ::tmp($id,pid) [exec xterm +ai -title "Network-In! - Switch $::obj($id,nom) ($id)" -bg $::coul(bg_schema) \
		-fg $::coul(texte) -fn 10x20 -display $::screen -e "$::vde(term) $::rep_tmp/terminal/$id" &]
		set ::tmp($id,win_id) [winid_from_pid $::tmp($id,pid) $::screen]
	}
	
}


#Mise en avant console de mswitch
#############################################################################
proc show_mswitch {id} {
	
	raise_x_window $::tmp($id,win_id) $::screen

}


# Boucle de scan lancée au démarrage d'un switch manageable
################################################################################
proc boucle_scan_mswitch {id} {
	
	if {[file exists $::rep_proj/datas/$id/com/pid]} {
		#récupération du nouveau nom de machine
		set res  [lire_fichier_echange $id hostname 1]
		if  {$res != {}} {
		  set ::obj($id,nom) $res
		  # on met à jour l'affichage
		  dessine_objet $id
		}
		after 2000 boucle_scan_mswitch $id
	} else  {
		arrete_switch $id
		#On supprime le répertoire d'échange dans le rep du projet
		file delete -force $::rep_proj/datas/$id/com
	}
	
}
