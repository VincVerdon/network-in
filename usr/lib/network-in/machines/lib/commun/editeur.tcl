####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20241227

# Lanceur de l'application
#####################################
proc editeur {} {
  ed::start
}


namespace eval ed {
	
    variable rep
	variable fic
	variable modif

    #Démarrage
	######################################
	proc start {} {
        
        #change le comportement d'un bouton qui a le focus
        bind Button <Key-Return> [bind Button <Key-space>]
        
        set ed::modif 0
        set ed::rep $::env(HOME)
        
        set num [fenetre_editeur]
        
        set ed::fic [lindex $::argv 0]
        if {$ed::fic != ""} {
            ouvrir_fichier $ed::fic
        }
		
        maj_titre $num
        
	}

    
	#création fenetre éditeur
	######################################
	proc fenetre_editeur {} {

        #Nom aléatoire pour la fenêtre, afin de pouvoir en démarrer plusieurs
        set num [clock seconds]
        
        image create photo im_editeur -file $::rep/images/editor.gif
        image create photo im_cut -file $::rep/images/cut.gif
        image create photo im_copy -file $::rep/images/copy.gif
        image create photo im_paste -file $::rep/images/paste.gif	
      
        toplevel .$num
        wm iconphoto .$num im_editeur
        wm protocol .$num WM_DELETE_WINDOW "ed::quit $num"
        catch {positionne_fenetre .$num}
            
        set m .$num.menubar
        .$num configure -menu $m
        menu $m
        # menu fichier
        $m add cascade -menu $m.file -label [::msgcat::mc "File"]
        menu $m.file -tearoff 0
        $m.file add command -label [::msgcat::mc "New"] -command "ed::nouveau_fichier $num"
        $m.file add command -label [::msgcat::mc "Open"] -command "ed::dialogue_ouvrir_fichier $num"
        $m.file add command -label [::msgcat::mc "Save"] -command "ed::enregistrer_fichier $num"
        $m.file add command -label [::msgcat::mc "Save as"] -command "ed::dialogue_enregistrer_fichier $num"
        $m.file add command -label [::msgcat::mc "Quit"] -command "ed::quit $num"
        
        # menu edition
        $m add cascade -menu $m.edit -label [::msgcat::mc "Edit"]
        menu $m.edit -tearoff 0
        $m.edit add command -label [::msgcat::mc "Cut"] -command "[list event gen .$num.f.tex <<Cut>>]"
        $m.edit add command -label [::msgcat::mc "Copy"] -command "[list event gen .$num.f.tex <<Copy>>]"
        $m.edit add command -label [::msgcat::mc "Paste"] -command "[list event gen .$num.f.tex <<Paste>>]"	
		
		# menu aide
		$m add cascade -menu $m.help -label [::msgcat::mc "Help"]
		menu $m.help -tearoff 0
		$m.help add command -label [::msgcat::mc "About"] -command "ed::apropos $num"

		#Barre d'icones
		frame .$num.ic
		pack .$num.ic -fill x
	    button .$num.ic.cut -relief flat -compound top -text  [::msgcat::mc "Cut"] -image im_cut -command "[list event gen .$num.f.tex <<Cut>>]"
		pack .$num.ic.cut -side left
		button .$num.ic.copy -relief flat -image im_copy -compound top -text  [::msgcat::mc "Copy"] -command "[list event gen .$num.f.tex <<Copy>>]"
		pack .$num.ic.copy -side left
		button .$num.ic.paste -relief flat -image im_paste -compound top -text  [::msgcat::mc "Paste"] -command "[list event gen .$num.f.tex <<Paste>>]"
		pack .$num.ic.paste -side left
		button .$num.ic.quit -relief flat -image im_quitter -compound top -text  [::msgcat::mc "Quit"] -command "ed::quit $num"
		pack .$num.ic.quit -side right
		
		#le widget texte d'affichage
		frame .$num.f
		pack .$num.f -expand 1 -fill both
        text .$num.f.tex -yscrollcommand ".$num.f.scrolv set" \
	      -wrap word -undo true -width 40 -height 15 -background white
        pack .$num.f.tex -expand 1 -fill both -side left

        #création scrollbar verticale
        scrollbar .$num.f.scrolv -orient vert -command ".$num.f.tex yview"
        pack .$num.f.scrolv -side right -fill y
		
        bind .$num <Key> "ed::fic_modif $num"
        bind .$num <<Cut>> "ed::fic_modif $num"
        bind .$num <<Copy>> "ed::fic_modif $num"
        bind .$num <<Paste>> "ed::fic_modif $num"
        bind .$num <<Clear>> "ed::fic_modif $num"

        update
        ::winid_maj [::winid_parent [winfo id .$num]]

        return $num
	}
	
	#Appelé lors d'une modif du texte
	###############################################################################
	proc fic_modif {num} {
		set ed::modif 1
		maj_titre $num
	}
	
	################################################################################
	proc apropos {num} {
        set mess [::msgcat::mc "A simple editor for Network-In!"]
        set mess "$mess\nVersion 20241227\nV. Verdon Corp. !"
		tk_messageBox -icon info -title "[::msgcat::mc "About"]..." \
				-message $mess -parent .$num
	}
    
	
	#Nouveau fichier
	################
	proc nouveau_fichier {num} {
		if {$ed::modif} {
			set rep [tk_messageBox -type yesno -default no -icon warning -title [::msgcat::mc "File not saved"] -message [::msgcat::mc "File not saved. Continue anymore ?"] -parent .$num]
			if {$rep == "no"} {
				return
			}
		}
		.$num.f.tex delete 1.0 end
    		set ed::fic {}
    		set ed::modif 0
    		maj_titre $num
	}
	
	#Dialogue enregistrer fichier
	##############################
	proc dialogue_enregistrer_fichier {num} {
		puts [file tail $ed::fic]
		set f [tk_getSaveFile -initialdir $ed::rep -initialfile [file tail $ed::fic] -parent .$num]
		if {$f != {}} {
            set ed::fic $f
            set ed::rep [file dirname $f]
			ed::enregistrer_fichier $num
		}	
	}
	
	#Dialogue ouverture fichier
	##############################
	proc dialogue_ouvrir_fichier {num} {
		set f [tk_getOpenFile -initialdir $ed::rep -parent .$num]
		if {$f != ""} {
			ed::nouveau_fichier $num
			ed::ouvrir_fichier $num $f
		}	
	}
	
	#Ouverture de fichier
	######################
	proc ouvrir_fichier {num fichier} {
	  
		if {[file exists $fichier]} {
  		set f [open $fichier r]
  		#lecture et affichage du corps du texte
        set texte [read -nonewline $f]
        .$num.f.tex insert end $texte
		close $f
		} else {
			tk_messageBox -icon error -title "[::msgcat::mc "Error"]..." \
							-message [::msgcat::mc "This file doesn't exist"] -parent .$num
		}
		set ed::fic $fichier
		set ed::rep [file dirname $fichier]
		set ed::modif 0
		maj_titre $num
	}

	#Enregistrement de fichier
	###########################
	proc enregistrer_fichier {num} {
		if {$ed::fic == ""} {
			dialogue_enregistrer_fichier $num
		} else {	
			set err [catch {set f [open $ed::fic w]} err]
			if {$err} {
				tk_messageBox -icon error -title "[::msgcat::mc "Error"]..." \
											-message [::msgcat::mc "write file denied"] -parent .$num
			} else {
				puts -nonewline $f [.$num.f.tex get 1.0 end]
				close $f
                set ed::modif 0
				maj_titre $num
			}
		}
	}
	
	#Change le titre de la fenetre éditeur
	######################################
	proc maj_titre {num} {
      if {$ed::fic == ""} {
  	  set titre "[::msgcat::mc "Editor"] - [::msgcat::mc "unnamed"]"
      } else {
        set titre "[::msgcat::mc "Editor"] - $ed::fic"
      }
      if {$::ed::modif} {
        set titre "$titre *"
      }
      wm title .$num $titre
	}


    #quitter l'éditeur
	################
	proc quit {num} {
		if {$ed::modif} {
			set rep [tk_messageBox -type yesno -default no -icon warning -title [::msgcat::mc "File not saved"] -message [::msgcat::mc "File not saved. Continue anymore ?"] -parent .$num]
			if {$rep == "no"} {
				return
			}
		}
		destroy .$num
	}

}

