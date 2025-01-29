####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Fonctions utilitaires interface bureau ordinateur et routeur
####################################################################
# Version 20250122

# proc positionnant une toplevel à la position du bureau
###############################################################################
proc positionne_fenetre {top {parent {.}}} {
	set x [winfo x $parent]
	set y [winfo y $parent]
	wm geometry $top +$x+$y
}


# lecture fichier d'échange avec le simulateur
################################################################################
proc lire_fichier_echange {fic} {
	if {![file exists $::rep_com/$fic]} {return -1}
	set f [open $::rep_com/$fic r]
	set texte [read $f]
	close $f
	# file delete $::rep_proj/$id/com/$fic
	return $texte
}


# écriture fichier d'échange avec le simulateur
################################################################################
proc ecrire_fichier_echange {type don} {
	set fic $::rep_com/$type
	set f [open $fic w]
	puts $f $don
	close $f
}


# renvoie le véritable id de fenêtre, pas celui donné par winfo id de tcl
################################################################################
proc winid_parent {winid} {
    set infos [exec xwininfo -children -id $winid]
    regexp -line {Parent.*(0x[0-9a-f]+).*} $infos res res2
    return $res2
}

# met à jour la liste des id de fenêtres en ajoutant le nouvel id
################################################################################
proc winid_maj {winid} {
    append ::window_id "$winid "
    ecrire_fichier_echange window_id $::window_id
}

# récupère l'id de fenêtre d'un exe à partir de son PID
################################################################################
proc winid_from_pid {pid} {
    set winid {}
    after 1000
    set res [eval exec wmctrl -l -p]
    set res [split $res \n]
    set long [llength $res]
    for {set i 0} {$i < $long} {incr i} {
        set ligne [lindex $res $i]
        set ps [lindex $ligne 2]
        if {$pid  == $ps} {
            set winid [lindex $ligne 0]
        }
    }
    return $winid
}

# Lancement d'une application et récupération de son winid
################################################################################
proc lancer {app} {
	. configure -cursor watch
	if {[file extension $app] == {.tcl}} {
		source $::rep/$app
		# extraction du nom de la proc initiale à appeler
		set app [file tail $app]
		set app [split $app {.}]
		set app [lindex $app 0]
		after 1000 . configure -cursor left_ptr
		# appel de la proc de démarrage du script
		$app
	} else  {
		set pid [eval exec $app &]
		# on récupère l'id de fenêtre
		winid_maj [winid_from_pid $pid]
		after 1000 . configure -cursor left_ptr
	}
	
}
