####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface bureau
####################################################################
# Version 20250208
set version(equipment) {1.0}

# Création de l'interface principale machine type Linux
################################################################################
proc fenetre_principale {} {
    
    set nom [exec hostname] 
    wm title . $nom
    wm protocol . WM_DELETE_WINDOW {#}
    wm iconphoto . -default im_icone
	
	# zone des terminaux virtuels
	ttk::notebook .not -width $::size(width) -height $::size(height)
	pack .not -fill both -expand 1
	# creation des onglets
	for {set i 1} {$i<=$::term_number} {incr i} {
		creation_onglet $i
	}
	
    # zone de boutons
    frame .fb
    pack .fb  -fill x
    menubutton .fb.arret -compound left -text [::msgcat::mc "Stop"] -image im_eteindre -menu .fb.arret.men
    pack .fb.arret -side left -fill both
    menu .fb.arret.men -tearoff 0
    .fb.arret.men add command -label [::msgcat::mc "Shutdown"] -command {exec halt &}
    .fb.arret.men add command -label [::msgcat::mc "Reboot"] -command {exec reboot &}
    frame .fb.h
      pack .fb.h -side right
      label .fb.h.h1 -text "[::msgcat::mc "Keys ctrl-shift-C : copy text"] / [::msgcat::mc "Keys ctrl-shift-V : paste text"]"
      #label .fb.h.h2 -text [::msgcat::mc "Keys ctrl-shift-V : paste text"]
      pack .fb.h.h1 -side right
      #pack .fb.h.h2 -side right

      bind .not  <<NotebookTabChanged>> {traite_change_panneau}
      after 100 "event generate .not.1 <Motion> -x 20 -y 20 -warp 1"
	
    update
    winid_maj [winid_parent [winfo id .]]
	
}


################################################################################
proc traite_change_panneau {} {
    set w [.not select]
    #On déplace le curseur sur le terminal pour avoir le focus, pas d'autre solution !
    after 100 "event generate $w <Motion> -x 20 -y 20 -warp 1"
    update
}


################################################################################
proc creation_onglet {nb} {
  
	set onglet .not.$nb
	frame $onglet
	.not add $onglet -text term$nb
	frame $onglet.f -container 1
	pack $onglet.f -fill both -expand 1
	update
	exec st -f "DejaVu Sans Mono-12" -w [scan [winfo id $onglet.f] %x] -e $::rep/login.sh &
    
}

