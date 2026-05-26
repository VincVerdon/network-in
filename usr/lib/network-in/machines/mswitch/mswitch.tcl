####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface de config de la bridge nat
####################################################################
# Version 20260430
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
	
	if [winfo exists .mswitch$id] {
		show_mswitch $id
	} else {
		term_switch_window $id
	}
	
}


# Terminal de management d'un switch
###############################################################
proc term_switch_window {id} {
	
	set term .mswitch$id
	toplevel $term -screen $::screen
	maj_nom_mswitch $id
	wm withdraw $term
	wm iconphoto $term im_mswitch16
	wm protocol $term WM_DELETE_WINDOW "destroy $term"
	positionne_fenetre_principale $id $term
	wm geometry $term 750x600
	
	# Barre de boutons
	frame $term.fb
	pack $term.fb -fill x
	button $term.fb.copy -compound right -relief flat -text [::msgcat::mc "Copy"] -image im_copy -command  "term_clipboard_copy $term.f"
	pack $term.fb.copy -side left
	button $term.fb.paste -compound right -relief flat -text [::msgcat::mc "Paste"] -image im_paste -command  "term_clipboard_paste $term.f"
	pack $term.fb.paste -side left
	button $term.fb.q -compound right -relief flat -text [::msgcat::mc "Quit"] -image im_quitter -command  "destroy $term"
	pack $term.fb.q -side right
	button $term.fb.about -compound right -relief flat -text [::msgcat::mc "About"] -image im_info -command  "a_propos_sim $::version(mswitch) $term"
	pack $term.fb.about -side right -padx {0 10}
	
	# Frame contenant le terminal st
	frame $term.f -container 1
	pack $term.f -fill both -expand 1
	
	eval exec $::rep/bin/mswitch_term $id $::screen [winfo id $term.f] "$::font(xterm)" &

	wm deiconify $term
	
	#On déplace le curseur sur le terminal pour avoir le focus, pas d'autre solution !
	after 100 "event generate $term.f <Motion> -x 50 -y 50 -warp 1"
	
	#Si st est fermé (commande exit ou logout) alors on détruit la fenêtre
	tkwait window $term.f
	destroy $term
	
}


#Mise en avant console de mswitch
#############################################################################
proc show_mswitch {id} {
	
	if [winfo exists .mswitch$id] {
	raise .mswitch$id
	}

}

#MAJ du nom du mswitch dans l'interface Term
#############################################################################
proc maj_nom_mswitch {id} {
	
	set term .mswitch$id
	wm title $term  "[::msgcat::mc "Switch CLI"] ($::obj($id,nom))"
	
}


# Boucle de scan lancée au démarrage d'un switch manageable
################################################################################
proc boucle_scan_mswitch {id} {
	
	if {[file exists $::rep_proj/datas/$id/com/pid]} {
		#récupération du nouveau nom de machine
		set res  [lire_fichier_echange $id hostname 1]
		if  {$res != {}} {
		  	set ::obj($id,nom) $res
			if [winfo exists .mswitch$id] {
			# mise à jour dans l'interface de la VM
			wm title .mswitch$id $::obj($id,nom)
			} 	
			# on met à jour le schéma
			dessine_objet $id
		}
		after 2000 boucle_scan_mswitch $id
	} else  {
		arrete_switch $id
		#On supprime le répertoire d'échange dans le rep du projet
		file delete -force $::rep_proj/datas/$id/com
	}
	
}


# Démarrage d'un switch manageable mswitch
################################################################################
proc demarre_mswitch {id} {
	
	# désarchivage éventuel d'une archive compressée
	if {[file exists $::rep_proj/datas/$id.tgz]} {
		exec tar -C $::rep_proj --sparse -xzf $::rep_proj/datas/$id.tgz
		file delete $::rep_proj/datas/$id.tgz
	}
	set f_conf $::rep_proj/datas/$id/init.conf
	#eval exec $::vde(mswitch) -d --nostdin -n $::obj($id,nb_eth) --macaddr $::obj($id,mac) -M $::rep_tmp/terminal/$id -p $::rep_proj/datas/$id/com/pid -s $::rep_tmp/vde/$id &
	eval exec $::vde(mswitch) -d --nostdin -n $::obj($id,nb_eth) --macaddr $::obj($id,mac) -w $f_conf -f $f_conf -M $::rep_tmp/terminal/$id -l $::rep_proj/logs/$id.log -p $::rep_proj/datas/$id/com/pid -s $::rep_tmp/vde/$id &
	after 1000 boucle_scan_mswitch $id
	
}
