####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20241222

namespace eval ed {
	
  variable rep
	variable fic
	variable modif
	
	#création fenetre éditeur
	######################################
	proc fenetre_editeur {} {
		
		image create photo img_editeur -file $::rep/images/editeur.gif
		image create photo img_cut -file $::rep/images/cut.gif
		image create photo img_copy -file $::rep/images/copy.gif
		image create photo img_paste -file $::rep/images/paste.gif	
	  
	  toplevel .t_texte
		wm iconphoto .t_texte img_editeur
		wm protocol .t_texte WM_DELETE_WINDOW {ed::quit}
		catch {positionne_fenetre .t_texte}
		
  	set m .t_texte.menubar
  	.t_texte configure -menu $m
  	menu $m
  	# menu fichier
  	$m add cascade -menu $m.file -label [::msgcat::mc "File"]
  	menu $m.file -tearoff 0
  	$m.file add command -label [::msgcat::mc "New"] -command ed::nouveau_fichier
    $m.file add command -label [::msgcat::mc "Open"] -command ed::dialogue_ouvrir_fichier
    $m.file add command -label [::msgcat::mc "Save"] -command {ed::enregistrer_fichier $::ed::fic}
  	$m.file add command -label [::msgcat::mc "Save as"] -command ed::dialogue_enregistrer_fichier
  	$m.file add command -label [::msgcat::mc "Quit"] -command ed::quit
  	
  	# menu edition
  	$m add cascade -menu $m.edit -label [::msgcat::mc "Edit"]
  	menu $m.edit -tearoff 0
  	$m.edit add command -label [::msgcat::mc "Cut"] -command "[list event gen .t_texte.f.tex <<Cut>>]"
  	$m.edit add command -label [::msgcat::mc "Copy"] -command "[list event gen .t_texte.f.tex <<Copy>>]"
  	$m.edit add command -label [::msgcat::mc "Paste"] -command "[list event gen .t_texte.f.tex <<Paste>>]"	
		
		# menu aide
		$m add cascade -menu $m.help -label [::msgcat::mc "Help"]
		menu $m.help -tearoff 0
		$m.help add command -label [::msgcat::mc "About"] -command ed::apropos

		#Barre d'icones
		frame .t_texte.ic
		pack .t_texte.ic -fill x
	  button .t_texte.ic.cut -relief flat -compound top -text  [::msgcat::mc "Cut"] -image img_cut -command "[list event gen .t_texte.f.tex <<Cut>>]"
		pack .t_texte.ic.cut -side left
		button .t_texte.ic.copy -relief flat -image img_copy -compound top -text  [::msgcat::mc "Copy"] -command "[list event gen .t_texte.f.tex <<Copy>>]"
		pack .t_texte.ic.copy -side left
		button .t_texte.ic.paste -relief flat -image img_paste -compound top -text  [::msgcat::mc "Paste"] -command "[list event gen .t_texte.f.tex <<Paste>>]"
		pack .t_texte.ic.paste -side left
		button .t_texte.ic.quit -relief flat -image img_quitter -compound top -text  [::msgcat::mc "Quit"] -command ed::quit
		pack .t_texte.ic.quit -side right
		
		#le widget texte d'affichage
		frame .t_texte.f
		pack .t_texte.f -expand 1 -fill both
	  text .t_texte.f.tex -yscrollcommand {.t_texte.f.scrolv set} \
	      -wrap word -undo true -width 40 -height 15 -background white
	  pack .t_texte.f.tex -expand 1 -fill both -side left
	  
	  #création scrollbar verticale
	  scrollbar .t_texte.f.scrolv -orient vert -command {.t_texte.f.tex yview}
	  pack .t_texte.f.scrolv -side right -fill y
		
        bind .t_texte <Key> {ed::fic_modif}
        bind .t_texte <<Cut>> {ed::fic_modif}
        bind .t_texte <<Copy>> {ed::fic_modif}
        bind .t_texte <<Paste>> {ed::fic_modif}
        bind .t_texte <<Clear>> {ed::fic_modif}

        update
        ::winid_maj [::winid_parent [winfo id .t_texte]]
	  
	}
	
	#Appelé lors d'une modif du texte
	###############################################################################
	proc fic_modif {} {
		set ed::modif 1
		nom_fichier $::ed::fic
	}
	
	################################################################################
	proc apropos {} {
        set mess [::msgcat::mc "A simple editor for Network-In!"]
        set mess "$mess\nVersion 20241222\nV. Verdon Corp. !"
		tk_messageBox -icon info -title "[::msgcat::mc "About"]..." \
				-message $mess -parent .t_texte
	}
	
	#quitter l'éditeur
	################
	proc quit {} {
		if {$ed::modif} {
			set rep [tk_messageBox -type yesno -icon warning -title [::msgcat::mc "File not saved"] -message [::msgcat::mc "File not saved. Continue anymore ?"]]
			if {$rep == "no"} {
				return
			}
		}
		destroy .t_texte
	}
	
	#Nouveau fichier
	################
	proc nouveau_fichier {} {
		if {$ed::modif} {
			set rep [tk_messageBox -type yesno -icon warning -title [::msgcat::mc "File not saved"] -message [::msgcat::mc "File not saved. Continue anymore ?"]]
			if {$rep == "no"} {
				return
			}
		}
		.t_texte.f.tex delete 1.0 end
    		set ed::fic {}
    		set ed::rep $::env(HOME)
    		set ed::modif 0
    		nom_fichier ""
	}
	
	#Dialogue enregistrer fichier
	##############################
	proc dialogue_enregistrer_fichier {} {
		puts [file tail $ed::fic]
		set f [tk_getSaveFile -initialdir $ed::rep -initialfile [file tail $ed::fic]]
		if {$f != {}} {
			ed::enregistrer_fichier $f
			set ed::fic $f
			set ed::rep [file dirname $f]
		}	
	}
	
	#Dialogue ouverture fichier
	##############################
	proc dialogue_ouvrir_fichier {} {
		set f [tk_getOpenFile -initialdir $ed::rep]
		if {$f != ""} {
			ed::nouveau_fichier
			ed::ouvrir_fichier $f
		}	
	}
	
	#Ouverture de fichier
	######################
	proc ouvrir_fichier {fichier} {
	  
		if {[file exists $fichier]} {
  		set f [open $fichier r]
  		#lecture et affichage du corps du texte
        set texte [read -nonewline $f]
        .t_texte.f.tex insert end $texte
		close $f
		} else {
			tk_messageBox -icon error -title "[::msgcat::mc "Error"]..." \
							-message [::msgcat::mc "This file doesn't exist"]
		}
		set ed::fic $fichier
		set ed::rep [file dirname $fichier]
		set ed::modif 0
		nom_fichier $fichier
	}

	#Enregistrement de fichier
	###########################
	proc enregistrer_fichier {fichier} {
		if {$fichier == ""} {
			dialogue_enregistrer_fichier
		} else {	
			set err [catch {set f [open $fichier w]} err]
			if {$err} {
				tk_messageBox -icon error -title "[::msgcat::mc "Error"]..." \
											-message [::msgcat::mc "write file denied"]
			} else {
				puts -nonewline $f [.t_texte.f.tex get 1.0 end]
				close $f
                set ed::modif 0
				nom_fichier $fichier
			}
		}
	}
	
	#Change le titre de la fenetre éditeur
	######################################
	proc nom_fichier {fic} {
      if {$fic == ""} {
  	  set titre [::msgcat::mc "unnamed"]
      } else {
        set titre $fic
      }
      if {$::ed::modif} {
        set titre "$titre *"
      }
      wm title .t_texte $titre
	}
	
	#Démarrage
	######################################

	proc start {} {

  	#change le comportement d'un bouton qui a le focus
  	bind Button <Key-Return> [bind Button <Key-space>]
		
		set ed::modif 0
		destroy .t_texte
  	fenetre_editeur
		
  	set fic [lindex $::argv 0]
		if {$fic != ""} {
            ouvrir_fichier $fic
		}	else  {
            set ed::rep $::env(HOME)
            set ed::fic {}
            nom_fichier ""
		}
	}

}

################################################################################
proc editeur {} {
  ::ed::start
}
