####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface bureau Linux texte
####################################################################
# Version 20260501
set version(equipment) {1.1}

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
	ttk::style configure TNotebook -tabposition nw 
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
    pack .fb.arret -side left -padx {0 30}
    menu .fb.arret.men -tearoff 0
    .fb.arret.men add command -label [::msgcat::mc "Shutdown"] -command {exec halt &}
    .fb.arret.men add command -label [::msgcat::mc "Reboot"] -command {exec reboot &}
    button .fb.copy -compound left -relief flat -text [::msgcat::mc "Copy"] -image im_copy -command  "clipboard_copy .not"
	pack .fb.copy -side left
    button .fb.paste -compound left -relief flat -text [::msgcat::mc "Paste"] -image im_paste -command  "clipboard_paste .not"
	pack .fb.paste -side left
    button .fb.about -compound right -relief flat -text [::msgcat::mc "About"] -image im_info -command {ouverture_a_propos}
    pack .fb.about -side right

    # ON déplace le curseur de souris au dessus de la partie terminal, de façon à avoir le focus automatiquement
    bind .not  <<NotebookTabChanged>> {traite_change_panneau}
    after 100 "event generate .not.1 <Motion> -x 50 -y 50 -warp 1"

    # Enregistrement de la fenêtre auprès du simulateur
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
	#eval exec st -B $::coul(bg_st) -F $::coul(fg_st) -f $::font(xterm) -w [winfo id $onglet.f] -e $::rep/login.sh &
	eval exec st -f $::font(name) -w [winfo id $onglet.f] -e $::rep/login.sh &
    update
    
}

################################################################################
proc ouverture_a_propos {} {
  source [file join $::rep a_propos.tcl]
	a_propos
}

