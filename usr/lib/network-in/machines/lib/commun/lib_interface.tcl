####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Fonctions utilitaires interface bureau ordinateur et routeur
####################################################################
# Version 20260411

# proc positionnant une toplevel à la position du bureau
###############################################################################
proc positionne_fenetre {top {parent {.}}} {
    
	set x [winfo x $parent]
	set y [winfo y $parent]
	wm geometry $top +$x+$y
    
}


# Positionne la fenêtre principale (bureau) sur l'écran en fonction de la position sur le schéma
################################################################################################
proc positionne_fenetre_principale {} {

    set pos [lire_fichier_echange position]
    eval wm geometry . $pos
    
}


# lecture fichier d'échange avec le simulateur
################################################################################
proc lire_fichier_echange {fic} {
    
	if {![file exists $::rep_com/$fic]} {return -1}
	set f [open $::rep_com/$fic r]
	set texte [read $f]
	close $f
	return [string trim $texte]
    
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


# Permet la mise à jour du nom sur l'interface graphique
################################################################################
proc boucle_scan_hostname {} {
    
    set nom [exec hostname] 
    wm title . $nom
    after 5000 boucle_scan_hostname
    
}


# Création d'une boite type messageBox
################################################################################
proc msg_box {path {title {}} {message {}} {parent .}} {

    destroy $path
    toplevel $path
	wm title $path $title
	wm transient $path $parent
	wm resizable $path 0 0
	wm transient $path $parent
	
	label $path.ico -image im_info
	pack $path.ico
	label $path.l -text $message
	pack $path.l
	
	button $path.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider \
	-command "destroy $path"
	pack $path.v
	focus $path.v

    bind Button <Key-Return> { 
        %W invoke
    }
	
}


# Place la sélection dans le presse papier des machines ET de l'hôte
#######################################################
proc clipboard_copy {widg} {
	
	set txt [exec xsel --primary -o]
	ecrire_fichier_echange clip $txt
	eval exec echo -n $txt | xsel --clipboard -i &
	
}


# Colle le contenu du presse papier dans le terminal
#######################################################
proc clipboard_paste {widg} {
	
	event generate $widg <Motion> -x 200 -y 200 -warp 1
	after 10 {exec xdotool key ctrl+shift+v}
	
}
