####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20250208

# Lanceur de l'application
#####################################
proc xterm {} {
	term::fenetre_term
}


namespace eval term {

    # Fenetre de lancement de term
    #####################################
    proc fenetre_term {{exe {}}} {

      #Nom aléatoire pour le terminal, afin de pouvoir en démarrer plusieurs
      set term ".[clock seconds]"
        
      image create photo im_term -file $::rep/images/xterm.gif
      toplevel $term
      wm title $term  "[::msgcat::mc "Terminal"] ([wm title .])"
      wm withdraw $term
      wm iconphoto $term im_term
      wm protocol $term WM_DELETE_WINDOW "term::quit $term"
      positionne_fenetre $term
      wm geometry $term 640x480
      
      # Menus
      set m $term.menubar
      $term configure -menu $m
      menu $m
      # menu fichier
      $m add cascade -menu $m.file -label [::msgcat::mc "File"]
      menu $m.file -tearoff 0
      $m.file add command -label [::msgcat::mc "New terminal"] -command term::fenetre_term
      $m.file add command -label [::msgcat::mc "Quit"] -command "term::quit $term"

      # menu aide
      $m add cascade -menu $m.help -label [::msgcat::mc "Help"]
      menu $m.help -tearoff 0
      $m.help add command -label [::msgcat::mc "About"] -command "term::apropos $term"

      # Barre de boutons
      frame $term.fb
      pack $term.fb -fill x
      frame $term.fb.h
      pack $term.fb.h -fill x -side left
      label $term.fb.h.h1 -text [::msgcat::mc "Keys ctrl-shift-C : copy text"]
      label $term.fb.h.h2 -text [::msgcat::mc "Keys ctrl-shift-V : paste text"]
      pack $term.fb.h.h1
      pack $term.fb.h.h2
      button $term.fb.q -compound right -relief flat -text [::msgcat::mc "Quit"] -image im_quitter -command  "term::quit $term"
      pack $term.fb.q -side right
      frame $term.f -container 1
      pack $term.f -fill both -expand 1
      if {$exe != {}} {
          exec st -f "DejaVu Sans Mono-12"  -w [scan [winfo id $term.f] %x] -e $exe &
      } else {
          exec st -f "DejaVu Sans Mono-12"  -w [scan [winfo id $term.f] %x] &
      }
      wm deiconify $term
      winid_maj [winid_parent [winfo id $term]]
      
      #On déplace le curseur sur le terminal pour avoir le focus, pas d'autre solution !
      after 100 "event generate $term.f <Motion> -x 150 -y 150 -warp 1"
      
      #Si st est fermé (commande exit ou logout) alors on détruit la fenêtre
      tkwait window $term.f
      term::quit $term
      
    }

    # A propos
    #######################################################
    proc apropos {term} {
        set mess [::msgcat::mc "A terminal for Network-In!"]
        set mess "$mess\nVersion 20241227\nV. Verdon Corp. !"
        tk_messageBox -icon info -title "[::msgcat::mc "About"]..." \
                -message $mess -parent $term
    }

    # Sortie
    #######################################################
    proc quit {term} {
        destroy $term
    }

}
