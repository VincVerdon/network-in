####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface bureau Linux texte
####################################################################
# Version 20250605
set version(equipment) {1.0}

# Création de l'interface principale machine type Linux
################################################################################
proc fenetre_principale {} {
    
    #set nom [exec hostname] 
    #wm title . $nom
    boucle_scan_hostname
    wm protocol . WM_DELETE_WINDOW {#}
    wm iconphoto . -default im_icone
	positionne_fenetre_principale
	
	# zone des terminaux virtuels
	#ttk::style configure TNotebook -tabposition sw
	ttk::notebook .not -width $::size(width) -height $::size(height)
	pack .not -fill both -expand 1
	# creation des onglets
	for {set i 1} {$i<=$::term_number} {incr i} {
		creation_onglet $i
	}
    set ::tmp(tab) .not.1
    .not select .not.1
    traite_change_panneau
	
    # zone de boutons
    frame .fb
    pack .fb  -fill x
    menubutton .fb.arret -compound left -text [::msgcat::mc "Stop"] -image im_eteindre -menu .fb.arret.men
    pack .fb.arret -side left -fill both
    menu .fb.arret.men -tearoff 0
    .fb.arret.men add command -label [::msgcat::mc "Shutdown"] -command {exec halt &}
    .fb.arret.men add command -label [::msgcat::mc "Reboot"] -command {exec reboot &}
	button .fb.paste -compound right -relief flat -text [::msgcat::mc "Paste"] -image im_paste -command  "clipboard_paste .not"
	pack .fb.paste -side right
	button .fb.copy -compound right -relief flat -text [::msgcat::mc "Copy"] -image im_copy -command  "clipboard_copy .not"
	pack .fb.copy -side right

      bind .not  <<NotebookTabChanged>> {traite_change_panneau}
      after 100 "event generate .not.1 <Motion> -x 50 -y 50 -warp 1"
	
    update
    winid_maj [winid_parent [winfo id .]]
	
}

# Code exécuté au changement de terminal
################################################################################
proc traite_change_panneau {} {

    .not tab $::tmp(tab) -text [string tolower [.not tab $::tmp(tab) -text]]
    set w [.not select]
    set ::tmp(tab) $w
    .not tab $w -text [string toupper [.not tab $w -text]]
    #On déplace le curseur sur le terminal pour avoir le focus, pas d'autre solution !
    after 100 "event generate $w <Motion> -x 20 -y 20 -warp 1"
    update
    
}

# Création d'un nouveau panneau de terminal
################################################################################
proc creation_onglet {nb} {
  
	set onglet .not.$nb
	frame $onglet
    .not add $onglet -text term$nb -padding {0 5 0 0}
	frame $onglet.f -container 1
	pack $onglet.f -fill both -expand 1
    .not select .not.$nb
	exec st -f $::font(name) -w [scan [winfo id $onglet.f] %x] -e $::rep/login.sh &
    update
    
}
