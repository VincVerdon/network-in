####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20250419

proc a_propos {} {
    set apropos "[lire_fichier_echange apropos]\n[::msgcat::mc "Equipment version"] : $::version(equipment)"
    
	destroy .apropos
    toplevel .apropos
	wm title .apropos "[::msgcat::mc "About"]..."
	wm resizable .apropos 0 0
	positionne_fenetre .apropos
	
	label .apropos.ico -image im_info
	pack .apropos.ico
	label .apropos.l -text $apropos
	pack .apropos.l
	button .apropos.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider  \
	-command {destroy .apropos}
	pack .apropos.v
    focus .apropos.v

    bind Button <Key-Return> { 
        %W invoke
    }
    
}
