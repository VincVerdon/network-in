####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20260718


# Création connexion pour capture
#################################################################################
proc creer_capture {id} {
	
	# On lance la capture actuelle et la connexion
	arrete_connexion $id
	
	set ::capture($id,pid1) {}
	set ::capture($id,pid2) {}
	set ::capture($id,win_id) {}
	catch {exec sudo $::rep/bin/conf_capture $id start}
	demarre_connexion $id
	dessine_capture $id
	demarrer_capture_exe $id
	
}


# Démarrage outil de capture (Wireshark) et sauvegarde de son pid
#################################################################################
proc demarrer_capture_exe {id} {
	
	set pid [eval exec $::exe(capture) &]
	lappend ::capture($id,win_id) [winid_from_pid $pid]
	
}


# Contrôle si l'utilisateur a les droits de faire une capture (=appartient au group wireshark)
#################################################################################
proc has_capture_rights {} {
	
	set ret 0
	set res [exec groups]
	if {[lsearch $res "wireshark"] != -1} {
		set ret 1
	}
	return $ret
	
}


# Dessin icon capture au milieu du cable
################################################################################
proc dessine_capture {id} {
	
	$::c delete capture-$id
	
	#Infos des 2 objets connectés par cette connexion
	set id1 $::obj($id,id1)
	set id2 $::obj($id,id2)
	set x1 $::obj($id1,x)
	set y1 $::obj($id1,y)
	set x2 $::obj($id2,x)
	set y2 $::obj($id2,y)
	set xm [expr ($x1 + $x2) / 2]
	set ym [expr ($y1 + $y2) / 2]
	
	$::c create image $xm $ym -tag "$id capture capture-$id"  -image im_capture -anchor c
	update
	
}


# Suppression connexion pour capture
#################################################################################
proc supprimer_capture {id} {
	
	arrete_connexion $id
	catch {exec sudo $::rep/bin/conf_capture $id stop}
	$::c delete capture-$id
	unset ::capture($id,pid1)
	unset ::capture($id,pid2)
	unset ::capture($id,win_id)
	demarre_connexion $id
	
}


# Dialogue proposant de créer un point de mesure
################################################################################
proc dialogue_creer_capture {} {
	
		set reponse [tk_messageBox -type okcancel -default ok -parent .main -icon info -title [::msgcat::mc "Info"] \
		 -message [::msgcat::mc "Clic on a cable to select where the capture should be done"]]
	  if {$reponse == "ok"} {
		  set ::tmp(capture,add) 1
		  $::c configure -cursor plus
	  }
	
}


#Mise en avant fenêtre Wireshark de capture
#############################################################################
proc show_capture {id} {
	
	foreach wid $::capture($id,win_id) {
		raise_x_window $wid
	}

}
