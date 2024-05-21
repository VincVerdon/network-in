####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20240103

proc termshark {} {
    catch {file link -symbolic /root/captures /root/.cache/termshark/pcaps/}
	fenetre_termshark
}


# Fenetre de lancement de termshark
#####################################
proc fenetre_termshark {} {
    
  image create photo img_capture -file $::rep/images/wireshark.gif
  image create photo img_lire -file $::rep/images/lire.gif
  
  destroy .fen
  toplevel .fen
  wm title .fen  [::msgcat::mc "Frame analysis"]
  wm iconphoto .fen img_capture
  positionne_fenetre .fen
  
  # boutons
  frame .fen.fb
  pack .fen.fb -fill x -expand 1
  ttk::button .fen.fb.a -compound right -text [::msgcat::mc "Quit"] -image img_quitter -command {destroy .fen}
  pack .fen.fb.a -side right
  
  # Création boutons radios pour le choix de l'interface
  ttk::labelframe .fen.newcap -text [::msgcat::mc "New capture"]
  pack .fen.newcap -fill both -expand 1
  # choix du type
  frame .fen.newcap.f
  #pack .fen.newcap.f
  #ttk::labelframe .fen.newcap.f -text [::msgcat::mc "Interface"]
  pack .fen.newcap.f -fill both -expand 1
  label .fen.newcap.f.l -text "[::msgcat::mc "Choose interface"] :"
  pack .fen.newcap.f.l -side left
  ttk::radiobutton .fen.newcap.f.lo -text [::msgcat::mc "lo"] -variable ::tmp(choix_interf) -value "lo"
  pack .fen.newcap.f.lo -side left
  set l_int [lire_fichier_echange interfaces]
  foreach {type nb} $l_int {
    for {set i 0} {$i < $nb} {incr i} {
        set interf "$type$i"
        # creation bouton radio de choix
        ttk::radiobutton .fen.newcap.f.$interf -text [::msgcat::mc $interf] -variable ::tmp(choix_interf) -value "$interf"
        pack .fen.newcap.f.$interf -side left
    }
  }
  # sélection lo par défaut
  .fen.newcap.f.lo invoke
  # bouton démarrage
  ttk::button .fen.newcap.v -compound left -text [::msgcat::mc "Start"] -image img_capture -command {
    destroy .fen
    exec_termshark_capture $::tmp(choix_interf)
  }
  pack .fen.newcap.v -side right
  
  # zone d'affichage des captures enregistrées
  ttk::labelframe .fen.seecap -text [::msgcat::mc "Saved captures"]
  pack .fen.seecap -fill both -expand 1
  label .fen.seecap.l -text "[::msgcat::mc "List of captures"] :"
  pack .fen.seecap.l -side left
  ttk::treeview .fen.seecap.t -columns {file} -yscroll {.fen.seecap.sv set} -height 5 -displaycolumns {file} -show headings
  pack .fen.seecap.t -side left -fill x -expand 1
  scrollbar .fen.seecap.sv -orient vertical -command {.fen.seecap.t yview}
  pack .fen.seecap.sv -side right -fill y
  # insertion des données
  foreach fic [lecture_liste_captures] {
    .fen.seecap.t insert {} end -values $fic
  }
  # boutons gestion des captures
  label .fen.f3
  
  ttk::button .fen.f3.b1 -compound left -text [::msgcat::mc "Suppress selection"]  -image img_supprimer -command {
    set liste_sel [.fen.seecap.t selection]
    if {$liste_sel != {}} {
        foreach n $liste_sel {
            set fic [file join "/root/captures" [.fen.seecap.t item $n -values]]
            file delete $fic
            .fen.seecap.t delete $n
        }
    }
  }
  
  ttk::button .fen.f3.b2 -compound left -text [::msgcat::mc "Open capture"]  -image img_lire -command {
    set liste_sel [.fen.seecap.t selection]
    if {$liste_sel != {}} {
        set fic [file join "/root/captures"  [.fen.seecap.t item [lindex $liste_sel 0] -values]]
        destroy .fen
        exec_termshark_pcap $fic
    }
  }
  pack .fen.f3 -side right
  pack .fen.f3.b2 -side right
  pack .fen.f3.b1 -side right
	
  update
  winid_maj [winid_parent [winfo id .fen]]
  
}

# retourne la liste des fichiers de captures enregistrés
##########################################################
proc lecture_liste_captures {} {
    return [lsort -decreasing [glob -directory /root/captures -nocomplain -tails "*.pcap"]]
}

# Exécution analyseur termshark dans une fenêtre xterm
# Nouvelle capture
########################################################
proc exec_termshark_capture {interf} {
	set pid [exec xterm  +ai -T [wm title .] -geometry 80x25+[winfo x .]+[winfo y .] -bg $::coul(fond) -fg $::coul(texte) -fn 10x20 -fa "DejaVu Sans Mono" -fs 12 -e "termshark -i $interf" &]
    # on récupère l'id de fenêtre
	winid_maj [winid_from_pid $pid]
}

# Exécution analyseur termshark dans une fenêtre xterm
# Lecture d'un fichier pcap
########################################################
proc exec_termshark_pcap {fic} {
	set pid [exec xterm  +ai -T [wm title .] -geometry 80x30+[winfo x .]+[winfo y .] -bg $::coul(fond) -fg $::coul(texte) -fn 10x20 -fa "DejaVu Sans Mono" -fs 12 -e "termshark -r $fic" &]
    # on récupère l'id de fenêtre
    winid_maj [winid_from_pid $pid]
}
