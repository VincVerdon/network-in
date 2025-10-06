####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version 20250612

# creation de la fenetre principale du simulateur
################################################################################
proc fenetre_principale {} {
  
  	# paramètres généraux de la fenêtre
	toplevel .main
	wm protocol .main WM_DELETE_WINDOW {quit}
	wm iconphoto .main -default im_network-in
	wm minsize .main 800 600
	wm attributes .main -zoomed true
	#update suivant indispensable sous Ubuntu (Wayland)
	update
	
	# création barre de menus
	set m .main.menubar
	.main configure -menu $m
	menu $m
	# menu fichier
	$m add cascade -menu $m.file -label [::msgcat::mc "File"]
	menu $m.file -tearoff 0
	$m.file add command -label [::msgcat::mc "New project"] -command "dialogue_nouveau_projet"
	$m.file add command -label [::msgcat::mc "Open an existing project"] -command "dialogue_ouvrir_projet {}"
	$m.file add command -label [::msgcat::mc "Save the actual project"] -command "dialogue_enregistrer_projet"
	$m.file add separator
	$m.file add command -label [::msgcat::mc "Quit"] -command quit
	# menu outils
	$m add cascade -menu $m.tools -label [::msgcat::mc "Options"]
	menu $m.tools -tearoff 0
	$m.tools add cascade -label [::msgcat::mc "Type of interface"] -menu $m.tools.niv
	creation_menu_niveau $m.tools.niv
	$m.tools add separator
	$m.tools add command -label [::msgcat::mc "Messages"] -command fenetre_affiche_logs
	$m.tools add command -label [::msgcat::mc "Terminal"] -command affiche_term
	# menu aide
	$m add cascade -menu $m.help -label [::msgcat::mc "Help"]
	menu $m.help -tearoff 0
	$m.help add command -label [::msgcat::mc "License"] \
      -command "affiche_texte $::rep/licence.txt"
    $m.help add separator
    $m.help add command -label [::msgcat::mc "About"] -command {a_propos}
	
	# Zone de boutons en haut
	##########################
	set comp right
	ttk::frame .main.fb
	pack .main.fb -fill x
	#ttk::button .main.fb.zp -image im_zoom+ -command {$::c scale all 0 0 2 2}
	#pack .main.schb.f.zp -side left
	#ttk::button .main.fb.zm -image im_zoom- -command {$::c scale all 0 0 0.5 0.5}
	#pack .main.fb.zm -side left
	ttk::button .main.fb.si -compound $comp -text [::msgcat::mc "Delete info labels"] -image im_del_infos -command {efface_infos_connexion}
	pack .main.fb.si -side left -padx {0 10}
	ttk::button .main.fb.startall -compound $comp -text [::msgcat::mc "Start all"] -image im_start_all \
	-command {
		demarrer_tout
	}
	pack .main.fb.startall -side left -padx {10 0}
	ttk::button .main.fb.stopall -compound $comp -text [::msgcat::mc "Shutdown all"] -image im_stop_all \
	-command {
		if ![verif_arret] {
			if {[dialogue_confirm_arreter_tout]} {
				arreter_tout
			}
		}
	}
	pack .main.fb.stopall -side left -padx {0 10}
	ttk::button .main.fb.quit -compound $comp -text [::msgcat::mc "Quit"] -image im_quitter -command quit
	pack .main.fb.quit -side right
    
	#Création des panneaux : schéma + simulation
	############################################
	ttk::panedwindow .main.pan -orient $::orientation
	pack .main.pan -fill both -expand 1
	# Frame conteneur zone de schéma
	frame .main.sch
	frame .main.sim
	.main.pan add .main.sch -weight 1
	.main.pan add .main.sim -weight 1
	update
	
	set l [winfo width .main.pan]
	set h [winfo height .main.pan]
	set ::tmp(l) $l
	set ::tmp(h) $h
	panel_simulation $l [expr $h -10]
	panel_schema $l [expr $h -100]
	
}


# Zone de dessin du schéma
############################################################################
proc panel_schema {l h} {
	
	frame .main.sch.f
	pack .main.sch.f -fill both -expand 1
	set ::c .main.sch.f.c
	canvas $::c -background $::coul(bg_schema) -closeenough 5 -cursor hand2 \
		  -scrollregion "0 0 $l $h" \
		-xscrollcommand ".main.sch.hscroll set" -yscrollcommand ".main.sch.f.vscroll set"
	pack $::c -fill both  -side left -expand 1
	ttk::scrollbar .main.sch.f.vscroll -command "$::c yview"
	ttk::scrollbar .main.sch.hscroll -orient horiz -command "$::c xview"
	pack .main.sch.f.vscroll -side left -fill y
	pack .main.sch.hscroll -fill x
	
	# zone des outils de conception reseau
	ttk::notebook .main.sch.fc
	pack .main.sch.fc
	# creation des onglets
	foreach famille $::def(liste_familles) {
		creation_onglet $famille
	}
	
	# Gestion des événements
	########################
	bind .main.sch.fc  <<NotebookTabChanged>> {traite_changement_panneau}
	bind $::c <B1-Motion> {clic_gauche_canvas_bouge %x %y}
	bind $::c <ButtonPress-1> {clic_gauche_canvas %x %y}
	bind $::c <ButtonPress-3> {clic_droit_canvas %x %y}
	bind $::c <Motion> {canvas_bouge %x %y}
	
}


# Zone d'affichage de la simulation
###########################################################################
proc panel_simulation {l h} {
	
	frame .main.sim.f0
	pack .main.sim.f0 -fill both -expand 1
	
	ttk::scrollbar .main.sim.hbar -command {.main.sim.f0.t xview} -orient horizontal
	ttk::scrollbar .main.sim.f0.vbar -command {.main.sim.f0.t yview} -orient vertical
	canvas .main.sim.f0.t -background $::coul(bg_simul) -scrollregion "0 0 $l $h" \
	-yscrollcommand {.main.sim.f0.vbar set} -xscrollcommand {.main.sim.hbar set}
	pack .main.sim.f0.t -side right -fill both -expand 1
	pack .main.sim.hbar -fill x
	pack .main.sim.f0.vbar -fill y -side right
	frame .main.sim.f0.f -width $l -height $h -container 1
	.main.sim.f0.t create window [expr $l / 2] [expr $h / 2] -window .main.sim.f0.f
	update
	# Démarrage serveur d'affichage Xephyr et le WM associé
	start_x_server [scan [winfo id .main.sim.f0.f] %x] "${l}x${h}"
	
}


#Effacement de toutes les infos connexion affichées
#############################################################################
proc efface_infos_connexion {} {
	set liste [array names ::tmp *,infos_connexion]
	foreach el $liste {
		set ::tmp($el) 0
	}
	$::c delete info
}

#change le niveau de détail dans l'interface
##############################################################################
proc change_niveau_detail {n} {
	foreach famille $::def(liste_familles) {
  	#on affiche l'onglet de la famille si le niveau de détail de l'interface est ok
      	if {$::def($famille,voir) <= $n} {
      		.main.sch.fc add .main.sch.fc.$famille
			#On affiche à l'intérieur de l'onglet uniquement les composants qui doivent l'être
			foreach type $::def($famille,liste) {
				if {$::def($type,voir) <= $n} {
					pack .main.sch.fc.$famille.$type -fill x -side left -fill y
				} else {
					pack forget .main.sch.fc.$famille.$type
				}
			}
      	} else {
      		.main.sch.fc hide .main.sch.fc.$famille
      	}
	}
	
}


# Création du menu d'affichage/sélection du niveau de détail de l'interface
################################################################################
proc creation_menu_niveau {m} {
	
	menu $m -tearoff 0
	#on cherche le nombre de niveaux définis
	set nb [llength [array names ::def niveau*,label]]
	
	for {set i 1} {$i<=$nb} {incr i} { 
		if {$i <= $::niveau(max)} {
			$m add radiobutton -label [::msgcat::mc "$::def(niveau$i,label)"] -variable ::tmp(details) -value $i -command "change_niveau_detail $i"
		} else {
			$m add radiobutton -label [::msgcat::mc "$::def(niveau$i,label)"] -variable ::tmp(details) -value $i -state disable
		}
	}
	
}

################################################################################
proc affiche_barre {message} {
  # on récupère la taille de l'écran
  set l  [winfo screenwidth .main]
  set h [winfo screenheight .main]
  set t .main.barre
  destroy $t
  toplevel $t
  wm title $t "[::msgcat::mc "Please, be patient"]"
  wm transient $t .main
  wm geometry $t 100x40+[expr $l / 2 - 50]+[expr $h / 2 - 50]
  label $t.l -text $message
  pack $t.l
  wm attributes $t -topmost 1
  
  ttk::progressbar $t.pb -mode indeterminate
  pack $t.pb
  $t.pb start
  text $t.t
  update
}

################################################################################
proc detruit_barre {} {
  destroy .main.barre
}

# Mise à jour du titre de la fenêtre principale
################################################################################
proc maj_titre {} {
  set proj [split $::tmp(file) .]
  set proj [lindex $proj 0]
  wm title .main "[::msgcat::mc "Network-In! simulator"] - $proj"
}


# met en avant les fenêtres de l'objet
################################################################################
proc show_object {id} {
    
	switch $::obj($id,type) {
		{nat} {
			show_passerelle
		}
		{virtualbox} {
			show_vbox $id
		}
		{bridge} {
			show_bridge $id
		}
		default {
			#Rien
    	}
	}
	
	switch $::obj($id,famille) {
			{computer} {
				show_computer $id
			}
			{router} {
				show_computer $id
			}
			default {
				#Rien
			}
		}
    
}

#Mise en avant machine type ordinateur
#############################################################################
proc show_computer {id} {
	
	set cpt 1
	set desk_wid {}
	foreach wid $::tmp($id,win_id) {
		if {$cpt != 1} {
			#catch {env DISPLAY=:5 exec wmctrl -i -a $wid}
			raise_x_window $wid
		} else {
			set desk_wid $wid
		}
		incr cpt
	}
	#On met le bureau au premier plan
	#catch {exec wmctrl -i -a $desk_wid}
	if {$desk_wid != {}} {
	raise_x_window $desk_wid
	}
}


# réduit les fenêtres de l'objet
################################################################################
proc hide_object {id} {
    
	switch $::obj($id,type) {
		{nat} {
			hide_passerelle
		}
		{virtualbox} {
			hide_vbox
		}
		{bridge} {
			hide_bridge
		}
		default {
			foreach wid $::tmp($id,win_id) {
				catch {exec wmctrl -i -r $wid -b add,hidden &}
			}
		}
	}
    
}

# proc de gestion des clics de création d'une liaison entre 2 éléments
################################################################################
proc creation_liaison {id} {
	
	if {$::tmp(id1) == {}} {
		# on vient de sélectionner le 1er objet
		set ::tmp(sel,interface) {}
		menu_choix_connexion $id
		if {$::tmp(sel,interface) != {}} {
			# on a sélectionné l'interface à laquelle on veut attacher le câble
			set ::tmp(id1) $id
			set ::tmp(id1,eth) $::tmp(sel,interface)
		} else {
			# on repasse en mode sélection car on a annulé
			annule_creation_liaison
		}
	} else {
		# on vient de sélectionner le 2ème objet
		set ::tmp(sel,interface) {}
		menu_choix_connexion $id
		# On a bien sélectionné une interface dans le menu
		if {$::tmp(sel,interface) != {}} {
			# on a bien sélectionné la 2ème interface à connecter
			set ::tmp(id2) $id
			set ::tmp(id2,eth) $::tmp(sel,interface)
			if {$::tmp(id1)==$::tmp(id2)} {
				tk_messageBox -icon warning -title [::msgcat::mc "Impossible"] -parent .main \
				-message [::msgcat::mc "Cannot connect on itself !"]
			} else {
				creation_connexion $::tmp(id1) $::tmp(id2) $::tmp(id1,eth) $::tmp(id2,eth) $::tmp(sel,type)
			}
		}
		# on repasse en mode sélection
		annule_creation_liaison
	}
	
}


# Sortie du mode de création de liaison
#############################################€
proc annule_creation_liaison {} {
	
	# on repasse en mode sélection
	set ::tmp(sel,type) {}
	set ::tmp(id1) {}
	set ::tmp(id1,eth) {}
	set ::tmp(id2) {}
	set ::tmp(id2,eth) {}
	$::c delete tmp_connection
	$::c configure -cursor hand2
	
	
}


# Gestion du clic simple gauche sur le canvas
################################################################################
proc clic_gauche_canvas {x y} {
	
	set x [$::c canvasx $x]
	set y [$::c canvasy $y]	
	
	#destruction de certains éléments s'ils existent
	destroy .note
	destroy $::c.mc
	
	set tags [$::c find closest $x $y 0]
	set tags [$::c gettags $tags]
	if {[lindex $tags end] == {current}} {
		
		#On a cliqué sur un objet
		set id [lindex $tags 0]
		if {$id == 0} {
			# On a cliqué sur le trait rouge de création on sélectionne l'id suivant
			set id [lindex $tags 1]
		}
		if {[lindex $tags 1] == "note"} {
			#Affichage d'une note car clic sur l'icone de note
			affiche_note $id
		} elseif {$::obj($id,famille) == {connection}} {
			#On a cliqué sur une connexion, on affiche les infos sur cette connexion
			set ::tmp($id,infos_connexion) 1
			maj_infos_connexion $id
		} elseif {$::tmp(sel,type) != {} && $::tmp(sel,famille) == {connection}} {
			#On est en mode création de liaison
			creation_liaison $id
		} else {
			#on a cliqué sur un objet on veut mettre en avant ses fenêtres s'il est démarré ou le masquer
			show_object $id
			#Il passe en avant plan
			$::c raise $id
			
		}
	} else {
		
		#On a cliqué dans le vide (aucun objet sélectionné)
		if {$::tmp(sel,type) != {} && $::tmp(sel,famille) != {connection}} {
			# on veut créer un objet (pas une liaison)
			creation_objet $::tmp(sel,famille) $::tmp(sel,type) $x $y
			# on repasse en mode sélection
			set ::tmp(sel,type) {}
			$::c configure -cursor hand2
		} elseif {$::tmp(sel,type) != {} && $::tmp(sel,famille) == {connection}} {
			# on est en mode création de liaison mais on a cliqué dans le vide > on sort du mode
			annule_creation_liaison
			$::c configure -cursor hand2
			
		}
	}
	
}


################################################################################
proc clic_droit_canvas {x y} {
	
	set x [$::c canvasx $x]
	set y [$::c canvasy $y]	
  
  set tags [$::c find closest $x $y 0] 
  set tags [$::c gettags $tags]
  if {[lindex $tags end] == {current}} {
    # cas où on a cliqué sur un objet
    set id [lindex $tags 0]
	  if {$id == 0} {
			  # On a cliqué sur le trait rouge de création on sélectionne l'id suivant
			  set id [lindex $tags 1]
		  }
    # coordonnées dans le repère écran
    set X [winfo pointerx .main]
    set Y [winfo pointery .]
    menu_contextuel_objet $id $X $Y
  }
  
}


# Création menu contextuel pour un matériel
################################################################################
proc menu_contextuel_objet {id x y} {
	
    destroy $::c.mc
    menu $::c.mc -tearoff 0
    set famille $::obj($id,famille)
    set type $::obj($id,type)
    
    #prise en compte du niveau de fonctionnalités autorisées en fonction du niveau de détails
    	if {$::def($type,voir) <= $::tmp(details)} {
    		set etat normal
    	} else {
    		set etat disabled
    	}
      
    	#prise en compte de l'état actuel du composant (actions impossibles si composant allumé)
    if {$::tmp($id,etat)} {
    	set etat2 normal
    	set etat3 disabled
    } else {
    	set etat2 disabled
    	set etat3 normal
    }
	
    # menu suivant le type d'objet
    switch $famille {
        
        {connection} {
			
    		# infos sur l'objet sélectionné
    		$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
    		#$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
    		$::c.mc add separator
    		$::c.mc add command -label [::msgcat::mc "Suppress"] -command "supprimer_connexion $id"
    	}
    
    	{computer} {
        		
            $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_ordinateur $id" -state $etat3
            $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_ordinateur $id" -state $etat2
            $::c.mc add command -label [::msgcat::mc "Force stop"] -command "force_arrete_ordinateur $id" -state $etat2
        	# infos sur l'objet sélectionné
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
			$::c.mc add command -label [::msgcat::mc "Logs print"] -command "fenetre_affiche_logs $id"
        	$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Duplicate"] -command "dialogue_dupliquer $id" -state $etat3
        	$::c.mc add command -label [::msgcat::mc "Suppress"] -command "dialogue_supprimer_objet $id" -state $etat3
            #Sous-menu de changement/ajout/suppression de carte et mac
            if $::obj($id,reconf) {
                menu_contextuel_gestion_cartes $id
            }
        }
        
    	{router} {
    		
            $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_routeur $id" -state $etat3
            $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_routeur $id" -state $etat2
        	$::c.mc add command -label [::msgcat::mc "Force stop"] -command "force_arrete_ordinateur $id" -state $etat2
        	# infos sur l'objet sélectionné
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
			$::c.mc add command -label [::msgcat::mc "Logs print"] -command "fenetre_affiche_logs $id"
        	$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Duplicate"] -command "dialogue_dupliquer $id" -state $etat3
        	$::c.mc add command -label [::msgcat::mc "Suppress"] -command "dialogue_supprimer_objet $id" -state $etat3
            #Sous-menu de changement/ajout/suppression de carte et mac
            if $::obj($id,reconf) {
                menu_contextuel_gestion_cartes $id
            }
    	}
    
    	{output} {
        
    		switch $type {
    			{nat} {
                    $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_passerelle $id" -state $etat3
                    $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_passerelle $id" -state $etat2
    			}
    			{bridge} {
    				$::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_bridge $id" -state $etat3
    				$::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_bridge $id" -state $etat2
    			}
    		}
    		# infos sur l'objet sélectionné
    		$::c.mc add separator
    		$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
    		$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
    		$::c.mc add separator
    		$::c.mc add command -label [::msgcat::mc "Suppress"] -command "dialogue_supprimer_objet $id" -state $etat3
    		
    	}
    
    	{vm} {
            switch $type {
                {virtualbox} {
                    if {$::tmp(vbox_found)} {
                        if {$::tmp($id,is_present)} {
							if [winfo exists .vbox$id] {
								$::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_virtualbox $id" -state disabled
							} else {
								$::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_virtualbox $id" -state $etat3
							}
							$::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_virtualbox $id" -state $etat2
                            $::c.mc add command -label [::msgcat::mc "Force stop"] -command "force_arrete_virtualbox $id" -state $etat2
                        } else {
                            $::c.mc add command -label [::msgcat::mc "Start"] -state disabled
                            $::c.mc add command -label [::msgcat::mc "Stop"] -state disabled
                            $::c.mc add command -label [::msgcat::mc "Force stop"] -state disabled
                        }
                        $::c.mc add separator
                        $::c.mc add command -label [::msgcat::mc "Configuration"] -command "fenetre_config_vbox $id" -state $etat3
                    }
                }
            }
            # infos sur l'objet sélectionné
            $::c.mc add separator
            $::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
            $::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
            $::c.mc add separator
            $::c.mc add command -label [::msgcat::mc "Suppress"] -command "dialogue_supprimer_objet $id" -state $etat3
            
        }
      
        {switch} {
    		
            $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_switch $id" -state $etat3
            $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_switch $id" -state $etat2
        	# infos sur l'objet sélectionné
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
        	$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Suppress"] -command "dialogue_supprimer_objet $id" -state $etat3
    		
    	}
    
    	{hub} {
    		
            $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_switch $id" -state $etat3
            $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_switch $id" -state $etat2
        	# infos sur l'objet sélectionné
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
        	$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
        	$::c.mc add separator
        	$::c.mc add command -label [::msgcat::mc "Suppress"] -command "dialogue_supprimer_objet $id" -state $etat3
    			
        }
    }
    
    # coordonnées dans le repère écran
    set X [winfo pointerx .main]
    set Y [winfo pointery .main]
    # affichage
    $::c.mc post $X $Y
    
}


# Dialogue appelé lors de la demande de suppression d'un composant
###############################################################
proc dialogue_supprimer_objet {id} {
    
    # l'objet doit d'abord être arrêté
    if {$::tmp($id,etat)} {
        tk_messageBox -icon info -title [::msgcat::mc "Impossible"] -parent .main \
		-message [::msgcat::mc "You must first stop this equipment"]
    } else {
        set rep [tk_messageBox -type yesno -default no -icon warning -title [::msgcat::mc "Suppression"] -parent .main \
		 -message [::msgcat::mc "Do you really want to suppress this equipment ? \nIt will suppress all its configuration too"]]
        if {$rep == "yes"} {
            supprimer_objet $id
        }
    }
    
}


# Dialogue appelé lors de la demande de duplication d'un composant
###############################################################
proc dialogue_dupliquer {id} {
	tk_messageBox -type ok -icon warning -title [::msgcat::mc "Duplicate"] -parent .main \
	-message [::msgcat::mc "After duplication, MAC address should be changed !"]	
	dupliquer_ordinateur $id
}

#morceau de menu contextuel assurant la gestion des interfaces
###############################################################
proc menu_contextuel_gestion_cartes {id} {
	
	# le menu n'est ajouté que si la configuration du composant le permet
	if {!$::obj($id,reconf)} {
			return
	}
	
	#prise en compte du niveau de fonctionnalités autorisées en fonction du niveau de détails
	set type $::obj($id,type)
	if {$::def($type,voir) <= $::tmp(details)} {
		set etat normal
	} else {
		set etat disabled
	}
	
	$::c.mc add separator
	$::c.mc add command -label [::msgcat::mc "Add network card"] -command "ajout_carte $id eth" -state $etat
	$::c.mc add cascade -label [::msgcat::mc "Change network card"] -menu $::c.mc.mac -state $etat
	menu $::c.mc.mac -tearoff false
	for {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
		$::c.mc.mac add command -label "eth$i" -command "fenetre_change_carte $id eth $i"
	}
	$::c.mc add cascade -label [::msgcat::mc "Delete network card"] -menu $::c.mc.del -state $etat
	menu $::c.mc.del -tearoff false
	for {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
		if {$i == [expr $::obj($id,nb_eth) -1]} {
			#seule la dernière interface peut être supprimée
			$::c.mc.del add command -label "eth$i" -command "supprime_carte $id eth $i"
		} else {
			$::c.mc.del add command -label "eth$i" -state disable
		}
	}
	
}

#Modification / création d'un commentaire pour un composant
################################################################################
proc fenetre_modif_note {id} {
	
	destroy .com
	toplevel .com
	wm transient .com .main
	wm title .com [::msgcat::mc "Add or change comment"]
	ttk::label .com.ico -image im_note
	pack .com.ico
	
	ttk::label .com.l -text [::msgcat::mc "Here you can add or modify the comment for the component"]
	pack .com.l
	
	#Création de la zone de texte et remplissage éventuel avec les données
	text .com.text -background white -width 30 -height 8 -wrap word
	pack .com.text
	if {[array names ::obj $id,note] != ""} {
		set texte [string map {\\n \n} $::obj($id,note)]
		.com.text insert end $texte
	}
	
	# boutons
	ttk::frame .com.fb
	pack .com.fb
	ttk::button .com.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command "maj_note $id ; destroy .com"
	pack .com.fb.v -side left
	ttk::button .com.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .com}
	pack .com.fb.a -side left
	
}

#Met à jour le commentaire du composant id a partir de la zone de saisie
################################################################################
proc maj_note {id} {
	
	set texte [.com.text get 1.0 end]
	if {$texte != "\n"} {
		set texte [string trim $texte]
		set texte [string map {\n \\n} $texte]
		set ::obj($id,note) $texte
		affiche_note_on $id
	} else {
		catch {unset ::obj($id,note)}
		affiche_note_off $id
	}

}

#Affiche la note quand on clique sur l'icone
################################################################################
proc affiche_note {id} {
	
	# coordonnées dans le repère écran
	set X [winfo pointerx .main]
	set Y [winfo pointery .main]
	destroy .note
	toplevel .note
	wm overrideredirect .note 1
	wm geometry .note +$X+$Y
	text .note.t -width 30 -height 8 -wrap word -background $::coul(note)
	pack .note.t
	set texte [string map {\\n \n} $::obj($id,note)]
	.note.t insert end $texte
	.note.t configure -state disabled
	
	bind .note <Button> {destroy .note}
	
}

# Fenêtre d'information sur un matériel (accessible depuis clic droit)
################################################################################
proc fenetre_infos_objet {id} {
    
    destroy .inf
    toplevel .inf
    wm title .inf "$id - [::msgcat::mc "Informations"]"
	wm transient .inf .main
	
	label .inf.ico -image im_info
	pack .inf.ico
	label .inf.l -text "[::msgcat::mc "Informations about"] $id"
	pack .inf.l
	labelframe .inf.f -text [::msgcat::mc "Generalities"]
	pack .inf.f -fill x
	label .inf.f.l3 -text "[::msgcat::mc "Type"] : "
	grid .inf.f.l3 -row 0 -column 0 -sticky e
    label .inf.f.l4 -text $::def($::obj($id,type),label)
	grid .inf.f.l4 -row 0 -column 1 -sticky w
	label .inf.f.l5 -text "[::msgcat::mc "Equipment Category"] : "
	grid .inf.f.l5 -row 1 -column 0 -sticky e
    if {$::obj($id,famille) == {connection}} {
        label .inf.f.l6 -text "[::msgcat::mc {cable}]"
    } else {
        label .inf.f.l6 -text "[::msgcat::mc $::obj($id,categorie)]"
    }
	
	grid .inf.f.l6 -row 1 -column 1 -sticky w
	
	switch $::obj($id,famille) {
		{computer} {
			fenetre_infos_ordinateur $id
		}
		{router} {
			fenetre_infos_ordinateur $id
		}
		{switch} {
			fenetre_infos_switch $id
		}
		{hub} {
			fenetre_infos_switch $id
		}
		{output} {
            switch $::obj($id,type) {
                {nat} {fenetre_infos_passerelle $id}
                {bridge} {fenetre_infos_bridge $id}
            }
		}
		{vm} {
            fenetre_infos_vm $id
        }
		{connection} {
			fenetre_infos_cable $id
		}
	}
	
	#création du bouton fermer
	ttk::button .inf.bou -compound left -text [::msgcat::mc "Close"] -image im_valider -command {destroy .inf}
	pack .inf.bou
	focus .inf.bou
  
}


#Fenêtre d'infos pour un pc/routeur
####################################
proc fenetre_infos_ordinateur {id} {
	
	if {[file exists $::rep/disks/$::obj($id,dd)] || [file exists $::rep_conf/disks/$::obj($id,dd)]} {
		set disk $::obj($id,dd) 
	} else {
		set disk "$::obj($id,dd) - [::msgcat::mc "MISSING"]"
	}
	
	if {[file exists $::rep/kernels/$::obj($id,kernel)/linux.uml] || [file exists $::rep_conf/kernels/$::obj($id,kernel)/linux.uml]} {
		set kern $::obj($id,kernel) 
	} else {
		set kern "$::obj($id,kernel) - [::msgcat::mc "MISSING"]"
	}
	
	labelframe .inf.dd -text [::msgcat::mc "System"]
	pack .inf.dd -fill x
	label .inf.dd.l1 -text "[::msgcat::mc "System disk"] :"
	grid .inf.dd.l1 -row 0 -column 0 -sticky e
	label .inf.dd.l2 -text $disk
	grid .inf.dd.l2 -row 0 -column 1 -sticky w
	label .inf.dd.l3 -text "[::msgcat::mc "Kernel"] :"
	grid .inf.dd.l3 -row 1 -column 0 -sticky e
	label .inf.dd.l4 -text $kern
	grid .inf.dd.l4 -row 1 -column 1 -sticky w
	label .inf.dd.l5 -text "[::msgcat::mc "RAM memory"] :"
	grid .inf.dd.l5 -row 2 -column 0 -sticky e
	label .inf.dd.l6 -text $::obj($id,mem)
	grid .inf.dd.l6 -row 2 -column 1 -sticky w
	
	labelframe .inf.if -text [::msgcat::mc "Ethernet interfaces"]
	pack .inf.if -fill x
	for  {set i 0} {$i<$::obj($id,nb_eth)} {incr i} {
		#frame contenant les infos d'une interface
		frame .inf.if.f$i
		pack .inf.if.f$i -fill x
		label .inf.if.f$i.l1 -text "eth$i :"
		grid .inf.if.f$i.l1 -row 0 -column 0 -sticky e
		label .inf.if.f$i.l2 -text $::obj($id,mac_eth$i)
		grid .inf.if.f$i.l2 -row 0 -column 1 -sticky w
		if {$::tmp($id,etat) && $::tmp($id,etat_eth$i) != ""} {
			label .inf.if.f$i.l3 -text $::tmp($id,etat_eth$i)
			grid .inf.if.f$i.l3 -row 1 -column 1 -sticky w
		}
	}
}


#Fenêtre d'infos pour passerelle
####################################
proc fenetre_infos_passerelle {id} {
    
    labelframe .inf.if -text [::msgcat::mc "Ethernet interfaces"]
    pack .inf.if -fill x 
	label .inf.if.l1 -text "eth0 :"
	grid .inf.if.l1 -row 0 -column 0 -sticky e
    if {$::tmp($id,etat)} {
        #label .inf.if.l2 -text "mac adress"
        #grid .inf.if.l2 -row 0 -column 1 -sticky w
        if {$::tmp($id,etat_eth0) != ""} {
            label .inf.if.l3 -text "$::obj($id,ip_eth0)/$::obj($id,netmask_eth0)"
            grid .inf.if.l3 -row 1 -column 1 -sticky w
        }
    }

}


#Fenêtre d'infos pour bridge
####################################
proc fenetre_infos_bridge {id} {
    
    labelframe .inf.if -text [::msgcat::mc "Ethernet ports"]
    pack .inf.if -fill x
    
    #On détermine quel matériel est connecté au port eth0
    if {$::obj($id,eth0) != {}} {
        set m $::obj($::obj($id,eth0),id1)
        if {$m == $id} {
            set m $::obj($::obj($id,eth0),id2)
        }
    } else {
        set m "-"
    }
    
    label .inf.if.l1 -text "([::msgcat::mc "Simulator side"]) port1 : "
    grid .inf.if.l1 -row 0 -column 0 -sticky e
    label .inf.if.l2 -text $m
    grid .inf.if.l2 -row 0 -column 1 -sticky w
    label .inf.if.l3 -text "([::msgcat::mc "Host side"]) port2 : "
    grid .inf.if.l3 -row 1 -column 0 -sticky e
    label .inf.if.l4 -text "[::msgcat::mc "Connected interface"] = $::obj($id,nom_tap) ($::obj($id,mac_tap))"
    grid .inf.if.l4 -row 1 -column 1 -sticky w
    if {$::tmp($id,etat)} {
        set ip_mask [get_interface_ip $::obj($id,nom_tap)]
        label .inf.if.l5 -text $::tmp($id,etat_tap)
        grid .inf.if.l5 -row 2 -column 1 -sticky w
    }

}


#Fenêtre d'infos pour vm
####################################
proc fenetre_infos_vm {id} {
    
    labelframe .inf.if -text [::msgcat::mc "Ethernet interfaces"]
    pack .inf.if -fill x
    switch $::obj($id,type) {
        
        {virtualbox} {
            label .inf.f.l15 -text "[::msgcat::mc "Vbox name"] : "
            grid .inf.f.l15 -row 2 -column 0 -sticky e
            label .inf.f.l16 -text [get_vbox_name $id]
            grid .inf.f.l16 -row 2 -column 1 -sticky w
            label .inf.f.l17 -text "[::msgcat::mc "Vbox ID"] : "
            grid .inf.f.l17 -row 3 -column 0 -sticky e
            label .inf.f.l18 -text $::obj($id,vbox_id)
            grid .inf.f.l18 -row 3 -column 1 -sticky w
            if {$::tmp(vbox_found) && $::tmp($id,is_present)} {
                foreach {nb mac etat} [get_vbox_interfaces $id] {
                    set n [expr $nb - 1]
                    frame .inf.if.f$n
                    pack .inf.if.f$n -fill x
                    label .inf.if.f$n.l1 -text "eth$n :"
                    grid .inf.if.f$n.l1 -row 0 -column 0 -sticky e
                    label .inf.if.f$n.l2 -text $mac
                    grid .inf.if.f$n.l2 -row 0 -column 1 -sticky w
                    set txt "[::msgcat::mc "Not connected"]"
                    if {$::obj($id,vbox_interf) == $nb} {
                        set txt "[::msgcat::mc "Connected to simulator"]"
                    }
                    label .inf.if.f$n.l3 -text $txt
                    grid .inf.if.f$n.l3 -row 1 -column 1 -sticky w
                }
            }
        }
        
    }
    
}


#Fenêtre d'infos pour un switch/hub
#####################################
proc fenetre_infos_switch {id} {
	
	labelframe .inf.if -text [::msgcat::mc "Ethernet ports"]
	pack .inf.if -fill x
	for  {set i 0} {$i<$::obj($id,nb_eth)} {incr i} {
		#frame contenant les infos d'une interface
		frame .inf.if.f$i
		pack .inf.if.f$i -fill x
        
        #On détermine quel matériel est connecté au port
        if {$::obj($id,eth$i) != {}} {
            set m $::obj($::obj($id,eth$i),id1)
            if {$m == $id} {
                set m $::obj($::obj($id,eth$i),id2)
            }
			set m $::obj($m,nom)
        } else {
            set m "-"
        }
        
		label .inf.if.f$i.l1 -text "port$i : $m"
		grid .inf.if.f$i.l1 -row 0 -column 0
	}
}

#Fenêtre d'infos pour un cable
################################
proc fenetre_infos_cable {id} {
	
	#rien
}


# Comportement quand la souris bouge au dessus du canvas, sans aucun bouton appuyé
###############################################################################
proc canvas_bouge {x y} {
	
	$::c delete tmp_connection
	#Cas où on est en train de créer un nouveau câble : affichage câble en rouge en direct
	if {$::tmp(sel,type) != {} && $::tmp(id1) != {}} {
			set x1 $::obj($::tmp(id1),x)
			set y1 $::obj($::tmp(id1),y)
		if {$x1 < $x} {
			set x [expr $x - 10]
		} else {
			set x [expr $x + 10]
		}
		if {$y1 < $y} {
			set y [expr $y - 10]
		} else {
			set y [expr $y + 10]
		}
		set l [$::c create line $x1 $y1 $x $y -tag "0 tmp_connection" \
			   -width 2 -fill red]
		}
	
}

# Comportement si on bouge un objet en maintenant le clic
################################################################################
proc clic_gauche_canvas_bouge {x y} {
	
	set x [$::c canvasx $x]
	set y [$::c canvasy $y]	
	
  if {$::tmp(sel,type) != {}} {
    # cas où on est en mode ajout, on sort
    return
  }
  
  set tags [$::c find closest $x $y 0]
  set tags [$::c gettags $tags]
  
  # si on n'a pas cliqué sur un objet, on sort
  if {[lindex $tags end] != {current}} {
      return
  }
  
  set id [lindex $tags 0]
	if {$id == 0} {
		# On a cliqué sur le trait rouge de création on sélectionne l'id suivant
		set id [lindex $tags 1]
	}
	
  if {$::obj($id,famille) == {connection}} {
    # cas où on a cliqué sur une connexion : rien à faire alors
    return
  }
  
  # déplacement de l'objet
  $::c move $id [expr {$x-$::obj($id,x)}] [expr {$y-$::obj($id,y)}]
  
  # on met à jour la position de l'objet
  set ::obj($id,x) $x
  set ::obj($id,y) $y
  
  # on cherche si l'objet a des connexions avec d'autres
  foreach techno $::obj($id,techno) {
    if {$techno == {ethernet}} {
      for  {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
        set con $::obj($id,eth$i)
        if {$con != {}} {
          # redessin de la connexion
          dessine_connexion $con
        }
      }
    }
  }
  
}

# création d'un menu contextuel pour sélectionner une interface réseau sur un matériel
# (création d'une connexion)
#######################################################################################
proc menu_choix_connexion {id} {
  
  set ::tmp(sel,interface) {}
  destroy $::c.men
  menu $::c.men -tearoff 0
  $::c.men add command -label [::msgcat::mc "Abort"] -command {
    set ::tmp(sel,interface) {}
    destroy $::c.men
  }
  $::c.men add separator
  if {[lsearch $::obj($id,techno) "ethernet"]  != {-1}} {
    
    for  {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
      if {$::obj($id,categorie) == "dce"} {
        set type "port"
        set n [expr $i + 1]
      } else  {
        set type "eth"
        set n $i
      }
      if {$::obj($id,eth$i) == {}} {
        # la connexion n'est pas utilisée
        $::c.men add radio -label "$type$n" -indicatoron 1 -variable ::tmp(sel,interface) -value eth$i
      } else  {
        # la connexion est utilisée
        $::c.men add radio -label "$type$n" -indicatoron 1 -variable ::tmp(sel,interface) -value eth$i -state disabled
      }
    }
  }
  
  # coordonnées dans le repère écran
  set X [winfo pointerx .]
  set Y [winfo pointery .]
  # on affiche le menu
  $::c.men post $X $Y
  
  # on attend d'avoir fixé une valeur
  vwait ::tmp(sel,interface)
}


################################################################################
proc creation_onglet {famille} {
  
  set pal_m .main.sch.fc.$famille
  frame $pal_m
  .main.sch.fc add $pal_m -text $::def($famille,label)
	
  # Bouton de sélection
  ttk::radiobutton $pal_m.sel -image im_select -width 80 -variable ::tmp(sel,type) -value {} -command {$::c configure -cursor hand2}
  pack  $pal_m.sel -side left -fill y
  
  frame $pal_m.blanc -width 20
  pack  $pal_m.blanc -fill x -side left
  
  # création des différents items
  foreach type $::def($famille,liste) {
    image create photo im_$type -file $::rep/images/$type.gif
    ttk::radiobutton $pal_m.$type -compound top -text $::def($type,label) -image im_$type -variable ::tmp(sel,type) -value $type -command {$::c configure -cursor plus}
		if {$type == "virtualbox"} {
			image create photo im_${type}_no -file $::rep/images/${type}_no.gif
			if {! $::tmp(vbox_found)} {
				$pal_m.$type configure -state disabled
				im_$type configure -palette 64
				im_${type}_no configure -palette 64
			}
		}
	}
	
}


################################################################################
proc traite_changement_panneau {} {
  set w [.main.sch.fc select]
  set ::tmp(sel,famille) [file extension $w]
  set ::tmp(sel,famille) [string range $::tmp(sel,famille) 1 end]
  set ::tmp(sel,type) {}
}

# creation des images utilisees
################################################################################
proc creer_images_interface {} {
  
  image create photo im_network-in -file $::rep/images/network-in.gif
  #image create photo im_zoom+ -file $::rep/images/zoom+.gif
  #image create photo im_zoom- -file $::rep/images/zoom-.gif
  image create photo im_quitter -file $::rep/images/quit.gif
  image create photo im_select -file $::rep/images/select.gif
  image create photo im_off -file $::rep/images/off.gif
  image create photo im_demarre -file $::rep/images/start.gif
  image create photo im_on -file $::rep/images/on.gif
  image create photo im_config -file $::rep/images/configure.gif
  image create photo im_annuler -file $::rep/images/cancel.gif
  image create photo im_valider -file $::rep/images/apply.gif
  image create photo im_start_all -file $::rep/images/start_all.gif
  image create photo im_stop_all -file $::rep/images/stop_all.gif
  image create photo im_eteindre -file $::rep/images/shutdown.gif
  image create photo im_del_infos -file $::rep/images/delete_infos.gif
  image create photo im_carte -file $::rep/images/map.gif
  image create photo im_note -file $::rep/images/note.gif
  image create photo im_rafraichir -file $::rep/images/refresh.gif
  image create photo im_info -file $::rep/images/info.gif
  image create photo im_note_mini
  im_note_mini copy im_note -subsample 2
	
}

# creation des images utilisees
################################################################################
proc creer_fontes_interface {} {
	#la police pour les étiquettes d'info sur le schéma réseau
	font create infos -size 8
}


# gestion des erreurs
################################################################################
proc bgerror { msg } {
	
	puts $msg
  tk_messageBox -icon error -type ok -parent .main \
	-message "[::msgcat::mc "Error"] : $msg\n\n$::errorInfo"
	
}

# dessin d'un objet sur le canvas
################################################################################
proc dessine_objet {id} {
  
  # on commence par effacer l'objet s'il existait
  $::c delete $id
  set nom $::obj($id,nom)
  set famille $::obj($id,famille)
  set type $::obj($id,type)
	set x $::obj($id,x)
	set y $::obj($id,y)
	
  if {$::obj($id,type) == "virtualbox"} {
      set nom [get_vbox_current_name $id]
      if {$::tmp($id,is_present)} {
            #Dans le cas où un équipement vbox n'est pas installé sur l'hôte, on change l'icône
            $::c create image $x $y -tag "$id $famille $type"  -image im_$type -anchor c
      } else {
            $::c create image $x $y -tag "$id $famille $type"  -image im_${type}_no -anchor c
      }
  } else {
    $::c create image $x $y -tag "$id $famille $type"  -image im_$type -anchor c
  }
  $::c create text $x [expr $y + [image height im_$type] / 2 + 10] -tag "$id $famille $type" -text $::def($::obj($id,type),label) -anchor c -fill $::coul(texte)
  $::c create text $x [expr $y + [image height im_$type] / 2 + 30] -tag "$id $famille $type" -text $nom -anchor c -fill $::coul(texte)
  
  # affichage de l'état de l'objet
  image create photo $id
  $::c create image [expr $x + [image width im_$type] / 2] [expr $y - 10] -tag "$id $famille $type" -image $id -anchor w
  if {$::tmp($id,etat)} {
    affiche_objet_on $id
  } else  {
    affiche_objet_off $id
  }
	
	# affichage de l'indicateur de note
	image create photo $id-note
	set note [$::c create image [expr $x + [image width im_$type] / 2] [expr $y + 10] -tag "$id note $famille $type" -image $id-note -anchor w]
	
	if {[array names ::obj $id,note] != ""} {
		affiche_note_on $id
	} else  {
		affiche_note_off $id
	}
  
}

#dessin de la connexion sur le canvas
################################################################################
proc dessine_connexion {id} {
	
  	$::c delete $id
  	set type $::obj($id,type)
  	#Infos des 2 objets connectés par cette connexion
  	set id1 $::obj($id,id1)
  	set id2 $::obj($id,id2)
	
	set offset 0
	set i 0
	set m m$i
	while {$i <= $::tmp(lastid) && $m != $id} {
			set m m$i
		if {[info exists ::obj($m,famille)] &&  $::obj($m,famille) == "connection"} {
    		if {$id1 == $::obj($m,id1) && $id2 == $::obj($m,id2) || $id1 == $::obj($m,id2) && $id2 == $::obj($m,id1)} {
				set offset [expr $offset + 5]
    		}
		}
		incr i
	}
	set x1 $::obj($id1,x)
	set y1 $::obj($id1,y)
	set x2 $::obj($id2,x)
	set y2 $::obj($id2,y)
  	set x1 [expr $x1 + $offset]
	set y1 [expr $y1 + $offset]
	set x2 [expr $x2 + $offset]
	set y2 [expr $y2 + $offset]
	
	set l [$::c create line $x1 $y1 $x2 $y2 -tag "$id connectique $type" \
		-dash $::def($type,trait) -width 2 -fill $::def($type,coul)] 
	# le trait de connexion passe en dessous des autres objets
	$::c lower $l
	
	#Mise à jour étiquettes infos
	maj_infos_connexion $id
  
}


# Dessine ou met à jour les étiquettes d'infos des interfaces sur les connexions
################################################################################
proc maj_infos_connexion {id} {
	
	if {$id == {}} {return}
	if {$::tmp($id,infos_connexion) == 0} {return}
	
	set type $::obj($id,type)
	
	#Infos des 2 objets connectés par cette connexion
	set id1 $::obj($id,id1)
	set id2 $::obj($id,id2)
	set interf1 $::obj($id,interf1)
	set interf2 $::obj($id,interf2)
	set famille1 $::obj($id1,famille)
	set famille2 $::obj($id2,famille)
	set type1 $::obj($id1,type)
	set type2 $::obj($id2,type)
	set x1 $::obj($id1,x)
	set y1 $::obj($id1,y)
	set x2 $::obj($id2,x)
	set y2 $::obj($id2,y)
	
	#Points d'insertion des étiquettes
	if {[expr $x1 - $x2] >= 0} {
		set X1 [expr $x1 - 80]
		set X2 [expr $x2 + 80]
	} else {
		set X1 [expr $x1 + 80]
		set X2 [expr $x2 - 80]
	}
	if {[expr $y1 - $y2] >= 0} {
		set Y1 [expr $y1 - 30]
		set Y2 [expr $y2 + 30]
	} else {
		set Y1 [expr $y1 + 30]
		set Y2 [expr $y2 - 30]
	}
	
	
	if {$famille1 == {hub} || $famille1 == {switch}} {
		regexp -expanded {[0-9]+} $interf1 n
		set nom_interf1 "port$n"
	} else {
		set nom_interf1 $interf1
	}
	if {$famille2 == "hub" || $famille2 == "switch"} {
		regexp -expanded {[0-9]+} $interf2 n
		set nom_interf2 "port$n"
	} else {
		set nom_interf2 $interf2
	}
	
	# Dans le cas d'un bridge on crée une étiquette à côté du matériel
	# Pour renseigner sur l'interface côté hôte
	if {$type1 == {bridge}} {
		set nom_interf1 {port1}
		maj_etiquette_bridge $id1 $id $x1 $y1 $x2 $y2 $::def($type,coul)
		}
	if {$type2 == {bridge}} {
		set nom_interf2 {port1}
		maj_etiquette_bridge $id2 $id $x2 $y2 $x1 $y1 $::def($type,coul)
	}
	
	#dessin des infos dans le canvas
	$::c create rectangle [expr $X1-50] [expr $Y1-20] [expr $X1+50] [expr $Y1+20] -fill white -tag "$id info inf$id"
	$::c create rectangle [expr $X2-50] [expr $Y2+20] [expr $X2+50] [expr $Y2-20] -fill white -tag "$id info inf$id"
	$::c create text [expr $X1-45] [expr $Y1-10] -tag "$id info inf$id" -anchor w \
	-text $nom_interf1 -fill $::def($type,coul) -font infos
	$::c create text [expr $X2-45] [expr $Y2-10] -tag "$id info inf$id" -anchor w \
	-text $nom_interf2 -fill $::def($type,coul) -font infos
	
	# Affichage éventuel des ip et masques
	if {$::tmp($id1,etat) != {0}} {
		set info1 $::tmp($id1,etat_$interf1)
		$::c create text [expr $X1-45] [expr $Y1 +5] -tag "$id info inf$id" -anchor w \
      -text $info1 -fill $::def($type,coul) -font infos
     }
    if {$::tmp($id2,etat) != {0}} {
		set info2  $::tmp($id2,etat_$interf2)
		$::c create text [expr $X2-45] [expr $Y2 +5] -tag "$id info inf$id" -anchor w \
      -text $info2 -fill $::def($type,coul) -font infos
    }
	
	#Effacement des étiquettes si on clique sur  une étiquette
	$::c bind inf$id <Button> "$::c delete inf$id ; set ::tmp($id,infos_connexion) 0"
	
}


# Dessin étiquette d'info côté interface de l'hôte d'un bridge
# x1 et y1 sont les coordonnées du bridge
################################################################################
proc maj_etiquette_bridge {id id_liaison x1 y1 x2 y2 coul} {
	
	#Point d'insertion de l'étiquette
	if {[expr $x1 - $x2] >= 0} {
		set Xb1 [expr $x1 + 90]
	} else {
		set Xb1 [expr $x1 - 90]
	}
	if {[expr $y1 - $y2] >= 0} {
		set Yb1 [expr $y1 + 50]
	} else {
		set Yb1 [expr $y1 - 50]
	}
	$::c create rectangle [expr $Xb1-65] [expr $Yb1-30] [expr $Xb1+65] [expr $Yb1+35] -fill white -tag "$id_liaison info inf$id_liaison"
	$::c create text [expr $Xb1-60] [expr $Yb1-20] -tag "$id_liaison info inf$id_liaison" -anchor w \
	-text "port2 ([::msgcat::mc "Host side"])" -fill $coul -font infos
	$::c create text [expr $Xb1-60] [expr $Yb1-5] -tag "$id_liaison info inf$id_liaison" -anchor w \
	-text "[::msgcat::mc "Connected interface"] :" -fill $coul -font infos
	$::c create text [expr $Xb1-60] [expr $Yb1+10] -tag "$id_liaison info inf$id_liaison" -anchor w \
	-text "$::obj($id,nom_tap)" -fill $coul -font infos
	if {$::tmp($id,etat) != {0}} {
		$::c create text [expr $Xb1-60] [expr $Yb1+25] -tag "$id_liaison info inf$id_liaison" -anchor w \
		-text $::tmp($id,etat_tap) -fill $coul -font infos
	}
	
}


# Affichage matériel éteint
################################################################################
proc affiche_objet_off {id} {
  $id blank
  $id copy im_off
}


# Affichage matériel en cours de démarrage
################################################################################
proc affiche_objet_demarre {id} {
  $id blank
  $id copy im_demarre
}


# Affichage matériel démarré
################################################################################
proc affiche_objet_on {id} {
  	$id blank
  	$id copy im_on
	update
}


#enlève l'icone de note à côté de l'objet
################################################################################
proc affiche_note_off {id} {
	$id-note blank
	update
}


#ajoute l'icone de note à côté de l'objet
################################################################################
proc affiche_note_on {id} {
	$id-note blank
	$id-note copy im_note_mini
	update
}


#Ouvre un dialogue de confirmation d'ouverture de nouveau projet
################################################################################
proc dialogue_ouvrir_projet {fic} {
  
	# on vérifie si on souhaite bien arrêter les machines si ce n'est pas le cas
	if ![verif_arret] {
		dialogue_arreter_tout
		return
	}
	
  set reponse [tk_messageBox -type yesno -default no -icon warning -title [::msgcat::mc "Open a project"] -parent .main \
   -message [::msgcat::mc "Do you really want to open another project ? If you don't  save the actual project, it will be lost"]]
  if {$reponse != "no"} {
  	if {$fic == {} } {
      set fic [tk_getOpenFile -initialdir $::tmp(current_dir) -parent .main -filetypes {{Network-in! .net}}]
  	}
    if {$fic != {}} {
		# Nouveau rep courant
		set ::tmp(current_dir) [file dirname $fic]
		desarchiver_projet $fic
    }  
  }
	
}


# Dialogue proposant de tout arreter et effacer pour créer un nouveau projet
################################################################################
proc dialogue_nouveau_projet {} {
  
  	if ![verif_arret] {
	  dialogue_arreter_tout
    } else {
    	set reponse [tk_messageBox -type yesno -default no -icon warning -title [::msgcat::mc "New project"] -parent .main \
		 -message [::msgcat::mc "Do you really want to start a new project ? If you don't  save the actual project, it will be lost"]]
      	if {$reponse == "yes"} {
      		init_projet
      	}
    }
	
}


# Création d'une boite type messageBox adaptée à tout display
################################################################################
proc msg_box {path {title {}} {message {}} {parent .main} {screen {}}} {
	
	destroy $path
	if {$screen == {}} {
		toplevel $path
	} else {
		toplevel $path -screen $::screen
	}
	
	wm title $path $title
	wm transient $path $parent
	wm resizable $path 0 0
	#positionne_fenetre $path $parent
	
	label $path.ico -image im_info
	pack $path.ico
	label $path.l -text $message
	pack $path.l
	
	button $path.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider \
	-command "destroy $path"
	pack $path.v
	focus $path.v
	
}


# Affichage de la boite Apropos avec éventuellement la version du matériel
################################################################################
proc a_propos {{version {}} {parent .main} {screen {}}} {
    
	set text $::apropos
	if {$version != {}} {
		set text "$text\n[::msgcat::mc "Equipment version"] : $version"
	}
	msg_box .apropos "[::msgcat::mc "About"]..." $text $parent $screen
	
}


# Affichage de la boite Apropos avec éventuellement la version du matériel
################################################################################
proc a_propos_sim {version parent} {
	
	set text $::apropos
	set text "$text\n[::msgcat::mc "Equipment version"] : $version"
	msg_box .apropos "[::msgcat::mc "About"]..." $text $parent $::screen
	positionne_fenetre .apropos $parent
	
}


# Dialogue proposant de tout arreter et effacer pour créer un nouveau projet
################################################################################
proc dialogue_arreter_tout {{parent {.main}} {screen {}}} {
	
	#set reponse [tk_messageBox -icon info -title [::msgcat::mc "Information"] -message [::msgcat::mc "This action needs to shutdown every equipment"]]
	msg_box .apropos [::msgcat::mc "Information"] [::msgcat::mc "This action needs to shutdown every equipment"] $parent $screen
}

# Dialogue proposant de tout arreter et effacer pour créer un nouveau projet
################################################################################
proc dialogue_confirm_arreter_tout {} {
	
	set ret 0
	if [verif_arret] {
		set ret 1
	} else {
		set reponse [tk_messageBox -type yesno -default no -parent .main -icon warning -title [::msgcat::mc "Warning"] \
		 -message [::msgcat::mc "This action causes to stop every equipment. Proceed ?"]]
	  if {$reponse == "yes"} {
		  set ret 1
	  }
	}
	return $ret
}


#Dialogue appelé si le disque système d'une machine n'est pas trouvé
################################################################################
proc dialogue_system_disk_missing {img} {
	set rep [tk_messageBox -icon info -title [::msgcat::mc "System disk"] -parent .main \
	 -message "[::msgcat::mc "System disk not found for this equipment"] :\ $img"]
}


#Dialogue appelé si le disque système d'une machine n'est pas trouvé
################################################################################
proc dialogue_kernel_missing {kern} {
	set rep [tk_messageBox -icon info -title [::msgcat::mc "Kernel"] -parent .main \
	 -message "[::msgcat::mc "Kernel not found for this equipment"] :\ $kern"]
}


################################################################################
proc dialogue_creation_passerelle_impossible {} {
  tk_messageBox -icon info -title [::msgcat::mc "Network-In!"] -parent .main \
	-message [::msgcat::mc "You can't create more than one gateway"]
}

################################################################################
proc dialogue_enregistrer_projet {} {
    
    # on vérifie si on souhaite bien arrêter les machines si ce n'est pas le cas
    if ![verif_arret] {
        dialogue_arreter_tout
    } else {
        set f [tk_getSaveFile -initialdir $::tmp(current_dir) -parent .main -initialfile $::tmp(file) -filetypes {{Network-in! .net} {Network-in! .NET}}]
        if {$f == {}} {
          return
        }
		# Nouveau rep courant
		set ::tmp(current_dir) [file dirname $f]
        # affichage barre
        after 1 {
          affiche_barre [::msgcat::mc "Please, be patient"]
          update
        }
        after 100
        # enregistrement
        archiver_projet $f
        # fin affichage barre
        detruit_barre  
    }
	
}

################################################################################
proc affiche_texte {fichier} {
  
  toplevel .t_texte
  frame .t_texte.f
  pack .t_texte.f -expand 1 -fill both
  
  text .t_texte.f.tex -background $::coul(bg_schema) -foreground $::coul(texte) -yscrollcommand {.t_texte.f.scrolv set} \
      -wrap word
  pack .t_texte.f.tex -expand 1 -fill both -side left
  
  #création scrollbar verticale
  ttk::scrollbar .t_texte.f.scrolv -orient vert -command {.t_texte.f.tex yview}
  pack .t_texte.f.scrolv -side right -fill y
  
  #création du bouton fermer
  ttk::button .t_texte.bou -compound right -text [::msgcat::mc "Close"] -image im_valider -command {
    destroy .t_texte
  }
  pack .t_texte.bou
  focus .t_texte.bou
	
  #ouverture du fichier
  ouvrir_fichier_texte $fichier
  
}

#Ouverture de fichier
#########################
proc ouvrir_fichier_texte {fichier} {
  
  set fichier [open $fichier r]
  
  #lecture de la première ligne qui contient le nom de la fenêtre d'affichage du texte
  gets $fichier ligne
  wm title .t_texte $ligne
  
  #lecture et affichage du corps du texte
  while {[eof $fichier]==0} {
    gets $fichier ligne
    .t_texte.f.tex insert end "$ligne\n"
  }
}

#Affichage d'une console xterm
################################################################################
proc affiche_term {} {
  exec xterm +ai -title "Network-In! - xterm" -bg $::coul(bg_schema) -fg $::coul(texte) -fn 10x20 &
}

#Affichage des messages (fichier journal network-in.log)
################################################################################
proc fenetre_affiche_logs {{id {}}} {
	
	proc maj_log {{id {}}} {
		.t_mess.f.tex configure -state normal
		.t_mess.f.tex delete 1.0 end
		if {$id == {}} {
			set fic $::rep_proj/logs/network-in.log
		} else {
			set fic $::rep_proj/logs/$id.log
		}
		if {[file exists $fic]} {
			set f [open $fic r]
    		set txt [read $f]
    		close $f
    		.t_mess.f.tex insert end "$txt\n"
		}
		 
		 .t_mess.f.tex configure -state disabled
		 .t_mess.f.tex yview moveto 1
		 update
	}
	
  destroy .t_mess
  toplevel .t_mess
	wm transient .t_mess .main
	set titre [::msgcat::mc "Logs print"]
	if {$id != {}} {
		set titre "$titre - $id"
	} 
	wm title .t_mess $titre
  
  frame .t_mess.f
  pack .t_mess.f -expand 1 -fill both
  
  text .t_mess.f.tex -yscrollcommand {.t_mess.f.scrolv set} \
      -wrap word -background $::coul(bg_schema) -foreground $::coul(texte)
  pack .t_mess.f.tex -expand 1 -fill both -side left
  
  #création scrollbar verticale
  ttk::scrollbar .t_mess.f.scrolv -orient vert -command {.t_mess.f.tex yview}
  pack .t_mess.f.scrolv -side right -fill y

  #création zone boutons
  frame .t_mess.f_bou
  ttk::button .t_mess.f_bou.val -compound right -text [::msgcat::mc "Close"] -image im_valider -command {
    destroy .t_mess
  }
  ttk::button .t_mess.f_bou.raf -compound right -text [::msgcat::mc "Refresh"] -image im_rafraichir -command "maj_log $id"

  pack  .t_mess.f_bou
  pack .t_mess.f_bou.val -side left
  pack .t_mess.f_bou.raf -side left
  focus .t_mess.f_bou.val
	
  #Mise à jour texte log
	maj_log $id
}


#fenetre permettant de changer d'adresse mac pour les cartes existantes
################################################################################
proc fenetre_change_carte {id type n} {
	set ::tmp(mac) $::obj($id,mac_${type}$n)
	
	destroy .fcc
	toplevel .fcc
	wm transient .fcc .main
	wm title .fcc [::msgcat::mc "Change network card"]
	ttk::label .fcc.ico -image im_carte
	pack .fcc.ico
	
	ttk::label .fcc.l -text [::msgcat::mc "Here you can choose a new mac address"]
	pack .fcc.l
	
	ttk::labelframe .fcc.f
	pack .fcc.f -fill both -expand 1
	
	ttk::label .fcc.f.0 -text  "$type$n : "
	pack .fcc.f.0 -fill x -side left
	
	ttk::entry .fcc.f.1 -textvariable ::tmp(mac)  -width 17
	pack .fcc.f.1 -fill x -side left
	
	ttk::button .fcc.f.3 -text [::msgcat::mc "Choose a random Mac address"] -command {set ::tmp(mac) [aleatoire_mac]}
	pack .fcc.f.3 -fill x -side left
	
	# boutons
	ttk::frame .fcc.fb
	pack .fcc.fb
	ttk::button .fcc.fb.v -compound left -text [::msgcat::mc "Confirm"] -image im_valider -command "applique_change_mac $id $type $n"
	pack .fcc.fb.v -side left
	ttk::button .fcc.fb.a -compound left -text [::msgcat::mc "Abort"] -image im_annuler -command {destroy .fcc}
	pack .fcc.fb.a -side left
}

#applique le changement de mac sélectionné
##################################################################"
proc applique_change_mac {id type n} {
	set ::obj($id,mac_${type}$n) $::tmp(mac)
	destroy .fcc
}

# proc positionnant une toplevel à la position du bureau
###############################################################################
proc positionne_fenetre {top {parent {.main}}} {
    set x [winfo x $parent]
    set y [winfo y $parent]
    wm geometry $top +$x+$y
}


# Positionne la fenêtre principale d'un composant sur l'écran en fonction de la position sur le schéma
###############################################################################
proc positionne_fenetre_principale {id top} {

	eval wm geometry $top [calcul_position_desktop $id]
	
}


# Calcul la podition de la fenetre principale du matériel en fonction de sa position sur son schéma
###############################################################################
proc calcul_position_desktop {id} {
	
	set posx [expr round($::obj($id,x))]
	set posy [expr round($::obj($id,y))]
	return "+${posx}+${posy}"
	
}



# On supprime un ou des objets du schéma
###############################################################################
proc canvas_delete {val} {
	$::c delete $val
}

