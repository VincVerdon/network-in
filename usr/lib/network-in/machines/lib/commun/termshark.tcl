####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
set ::version(termshark) 20260414


# Lanceur de l'application
#####################################
proc termshark {} {
    set capt::rep /root/captures
    catch {file link -symbolic $capt::rep /root/.cache/termshark/pcaps/}
	capt::fenetre_termshark
}


namespace eval capt {

    # Fenetre de lancement de termshark
    #####################################
    proc fenetre_termshark {} {
        
      image create photo im_capture -file $::rep/images/wireshark.gif
      image create photo im_lire -file $::rep/images/read.gif
      
      destroy .cap
      toplevel .cap
      wm title .cap  "[::msgcat::mc "Frame analysis"] ([wm title .])"
      wm iconphoto .cap im_capture
      wm protocol .cap WM_DELETE_WINDOW capt::quit
      positionne_fenetre .cap

      # Menus
      set m .cap.menubar
      .cap configure -menu $m
      menu $m
      # menu fichier
      $m add cascade -menu $m.file -label [::msgcat::mc "File"]
      menu $m.file -tearoff 0
      $m.file add command -label [::msgcat::mc "Open"] -command capt::dialogue_ouvrir_fichier
      $m.file add command -label [::msgcat::mc "Quit"] -command capt::quit

      # menu aide
      $m add cascade -menu $m.help -label [::msgcat::mc "Help"]
      menu $m.help -tearoff 0
      $m.help add command -label [::msgcat::mc "About"] -command capt::apropos

      # Barre de boutons
      frame .cap.fb
      pack .cap.fb -fill x
      button .cap.fb.a -compound right -relief flat -text [::msgcat::mc "Quit"] -image im_quitter -command  capt::quit
      pack .cap.fb.a -side right

      frame .cap.f
      pack .cap.f -fill both -expand 1
      # zone d'affichage des captures enregistrées
      ##############################################
      ttk::labelframe .cap.f.seecap -text [::msgcat::mc "Saved captures"]
      pack .cap.f.seecap -fill both -expand 1 -side left
      label .cap.f.seecap.f2
      pack .cap.f.seecap.f2 -fill both -expand 1
      label .cap.f.seecap.f2.l -text "[::msgcat::mc "List"] :"
      pack .cap.f.seecap.f2.l -side left
      ttk::treeview .cap.f.seecap.f2.t -columns {file} -yscroll {.cap.f.seecap.f2.sv set} -height 5 -displaycolumns {file} -show headings
      pack .cap.f.seecap.f2.t -side left -fill x -expand 1
      scrollbar .cap.f.seecap.f2.sv -orient vertical -command {.cap.f.seecap.f2.t yview}
      pack .cap.f.seecap.f2.sv -side right -fill y
      # insertion des données
      foreach fic [lecture_liste_captures] {
        .cap.f.seecap.f2.t insert {} end -values $fic
      }
      # boutons gestion des captures
      label .cap.f.seecap.f3
      
      ttk::button .cap.f.seecap.f3.b1 -compound left -text [::msgcat::mc "Delete capture"]  -image im_supprimer -command {
        set liste_sel [.cap.f.seecap.f2.t selection]
        if {$liste_sel != {}} {
            foreach n $liste_sel {
                set fic [file join $capt::rep [.cap.f.seecap.f2.t item $n -values]]
                file delete $fic
                .cap.f.seecap.f2.t delete $n
            }
        }
      }
      ttk::button .cap.f.seecap.f3.b2 -compound left -text [::msgcat::mc "Open capture"]  -image im_lire -command {
        set liste_sel [.cap.f.seecap.f2.t selection]
        if {$liste_sel != {}} {
            set fic [file join $capt::rep  [.cap.f.seecap.f2.t item [lindex $liste_sel 0] -values]]
            capt::exec_termshark_pcap $fic
        }
      }
      pack .cap.f.seecap.f3 -side right
      pack .cap.f.seecap.f3.b2 -side right
      pack .cap.f.seecap.f3.b1 -side right

      # zone nouvelle capture
      ##############################################
      ttk::labelframe .cap.f.newcap -text [::msgcat::mc "New capture"]
      pack .cap.f.newcap -fill both -expand 1 -side right
      # choix du type
      frame .cap.f.newcap.f
      pack .cap.f.newcap.f 
      label .cap.f.newcap.f.l -text "[::msgcat::mc "Interface to capture"] :"
      pack .cap.f.newcap.f.l -side left
      # Création boutons radios pour le choix de l'interface
      ttk::radiobutton .cap.f.newcap.f.lo -text [::msgcat::mc "lo"] -variable ::tmp(choix_interf) -value "lo"
      pack .cap.f.newcap.f.lo -side left
      set l_int [lire_fichier_echange interfaces]
      foreach {type nb} $l_int {
        for {set i 0} {$i < $nb} {incr i} {
            set interf "$type$i"
            # creation bouton radio de choix
            ttk::radiobutton .cap.f.newcap.f.$interf -text [::msgcat::mc $interf] -variable ::tmp(choix_interf) -value "$interf"
            pack .cap.f.newcap.f.$interf -side left
        }
      }
      # sélection lo par défaut
      .cap.f.newcap.f.lo invoke
      frame .cap.f.newcap.inf -background black
      pack .cap.f.newcap.inf -fill both -expand 1
      # Bouton démarrage
      ttk::button .cap.f.newcap.v -compound left -text [::msgcat::mc "Start"] -image im_capture -command {
        .cap.f.newcap.v configure -state disabled
        .cap.f.newcap.a configure -state enabled
        capt::exec_termshark_capture $::tmp(choix_interf)
      }
      pack .cap.f.newcap.v -side right
      # Bouton arrêt
      ttk::button .cap.f.newcap.a -compound left -text [::msgcat::mc "Stop"] -image im_eteindre -state disabled -command {
        .cap.f.newcap.a configure -state disabled
        .cap.f.newcap.v configure -state enabled
        catch {exec kill $::tmp(pid_capture)}
        .cap.f.seecap.f2.t insert {} 0 -values [file tail $::tmp(fic_capture)]
        capt::exec_termshark_pcap $::tmp(fic_capture)
        unset ::tmp(pid_capture)
        unset ::tmp(fic_capture)
      }
      pack .cap.f.newcap.a -side right
      
      update
      winid_maj [winid_parent [winfo id .cap]]
      
    }


    # retourne la liste des fichiers de captures enregistrés
    ##########################################################
    proc lecture_liste_captures {} {
        return [lsort -decreasing [glob -directory $capt::rep -nocomplain -tails "*.pcap"]]
    }


    # Exécution analyseur termshark dans une fenêtre xterm
    # Nouvelle capture
    ########################################################
    proc exec_termshark_capture {interf} {
        frame .cap.f.newcap.inf.f  -container 1 -width 200
        pack .cap.f.newcap.inf.f -fill both -expand 1
        update
        set date [clock format [clock seconds] -format %Y-%m-%d--%H:%M:%S]
        set ::tmp(fic_capture) [file join $capt::rep $interf--$date.pcap]
        set exe "tcpdump -i $interf -v -w $::tmp(fic_capture)"
        set font1 [list "DejaVu Sans Mono-9"]
        set ::tmp(pid_capture) [eval exec st -f $font1 -w [scan [winfo id .cap.f.newcap.inf.f] %x] -e $exe &]
        # on récupère l'id de fenêtre
        winid_maj [winid_from_pid $::tmp(pid_capture)]
    }


    # Exécution analyseur termshark dans une fenêtre xterm
    # Lecture d'un fichier pcap
    ########################################################
    proc exec_termshark_pcap {fic} {
        set exe "termshark -r $fic"
        set font2 [list "DejaVu Sans Mono-12"]
        set pid [eval exec st -t Termshark -g 90x30+[winfo x .]+[winfo y .] -f $font2 -e $exe &]
        # on récupère l'id de fenêtre
        winid_maj [winid_from_pid $pid]
    }
    

    # A propos
    #######################################################
    proc apropos {} {
        set mess [::msgcat::mc "An interface to Termshark for Network-In!"]
        set mess "$mess\nVersion $::version(termshark)\nV. Verdon Corp. !"
        tk_messageBox -icon info -title "[::msgcat::mc "About"]..." \
                -message $mess -parent .cap
    }

    #Dialogue ouverture fichier
    ##############################
    proc dialogue_ouvrir_fichier {} {
        set f [tk_getOpenFile -initialdir $capt::rep -parent .cap]
        if {$f != ""} {
            capt::exec_termshark_pcap $f
        }	
    }

    # Sortie
    #######################################################
    proc quit {} {
        destroy .cap
    }

}
