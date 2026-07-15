####################################################################
#Programme écrit par V. Verdon
#Network-in est un logiciel de simulation de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20260525


# Création connexion pour capture
#################################################################################
proc creation_capture {id} {
	
	# On supprime l'ancienne capture
	supprimer_capture
	
	# On lance la capture actuelle et la connexion
	arrete_connexion $id
	catch {exec sudo $::rep/bin/conf_capture $id start}
	set ::tmp(capture,id) $id
	demarre_connexion $id
	dessine_capture $id
	
	if {$::tmp(capture,exe_pid) == {}} {
		demarrer_capture_exe $id
	}
}


# Démarrage outil de capture (Wireshark) et sauvegarde de son pid
#################################################################################
proc demarrer_capture_exe {id} {
	
	set pid [eval exec $::exe(capture) &]
	lappend ::tmp(capture,win_id) [winid_from_pid $pid]
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
	
	$::c delete capture
	
	#Infos des 2 objets connectés par cette connexion
	set id1 $::obj($id,id1)
	set id2 $::obj($id,id2)
	set x1 $::obj($id1,x)
	set y1 $::obj($id1,y)
	set x2 $::obj($id2,x)
	set y2 $::obj($id2,y)
	set XM [expr ($x1 + $x2) / 2]
	set YM [expr ($y1 + $y2) / 2]
	
	$::c create image $XM $YM -tag "capture"  -image im_capture -anchor c
	update
	
}


# Suppression connexion pour capture
#################################################################################
proc supprimer_capture {} {
	
	if {$::tmp(capture,id) != {}} {
		set id $::tmp(capture,id)
		arrete_connexion $id
		$::c delete capture
		set ::tmp(capture,id) {}
		demarre_connexion $id
	}
	
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
proc show_capture {} {
	
	foreach wid $::tmp(capture,win_id) {
		raise_x_window $wid
	}

}
