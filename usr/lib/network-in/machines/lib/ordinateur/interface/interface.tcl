####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Interface bureau
####################################################################
# Version 20250108

# Création de l'interface principale (bureau)
################################################################################
proc fenetre_principale {} {
    
    set nom [exec hostname] 
    wm title . $nom
    wm protocol . WM_DELETE_WINDOW {#}
    wm iconphoto . -default img_icone
    wm resizable . 0 0
    
    # zone de placement des icones
    # On crée un canvas qui va contenir les icones
    canvas .c -background $::coul(fond) -width $::taille(l) -height $::taille(h)
    pack .c  
    update
    
    # creation des icones des applications
    set larg [winfo width .c]
    set nb_app_l [expr int($larg / 100) - 1]
    set marg [expr ($larg - $nb_app_l * 100) / 2]
    set i 1
    set x $marg
    set y 25
    foreach {nom app ico} $::liste_app {
          if {$x >= $larg} {
            set x $marg
            set y [expr $y + 70]
          }
          # chargement des icones des appli
           image create photo icone_$i -file $::rep/images/$ico
          .c create image $x $y -image icone_$i -anchor c -tag ico$i
          set nom [::msgcat::mc $nom]
          .c create text $x [expr $y + 15] -text $nom -width 100 -anchor n -justify center -tag ico$i -fill $::coul(texte)
          # comportement de l'icone face au clic
          .c bind ico$i <Double-ButtonPress>  "lancer [list $app]"
          incr i
          set x [expr $x + 100]
    }
    
    # zone de boutons
    frame .fb
    pack .fb  -fill x
    menubutton .fb.arret -compound left -text [::msgcat::mc "Stop"] -image img_eteindre -menu .fb.arret.men
    pack .fb.arret -side left -fill both
    menu .fb.arret.men -tearoff 0
    .fb.arret.men add command -label [::msgcat::mc "Shutdown"] -command {exec halt &}
    .fb.arret.men add command -label [::msgcat::mc "Reboot"] -command {exec reboot &}

    update
    winid_maj [winid_parent [winfo id .]]
	
}



