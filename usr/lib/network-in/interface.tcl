####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version 20241214

# creation de la fenetre principale du simulateur
################################################################################
proc fenetre_principale {} {
  
  # paramètres généraux de la fenêtre
  wm protocol . WM_DELETE_WINDOW {quit}
  wm iconphoto . -default im_network-in
  
  # création barre de menus
  set m .menubar
  . configure -menu $m
  menu $m
  # menu fichier
  $m add cascade -menu $m.file -label [::msgcat::mc "File"]
  menu $m.file -tearoff 0
  $m.file add command -label [::msgcat::mc "New project"] -command "dialogue_nouveau_projet"
  $m.file add command -label [::msgcat::mc "Open an existing project"] -command "dialogue_ouvrir_projet {}"
  $m.file add command -label [::msgcat::mc "Save the actual project"] -command "dialogue_enregistrer_projet"
	$m.file add separator
  $m.file add command -label [::msgcat::mc "Quit"] -command "quit"
  # menu outils
  $m add cascade -menu $m.tools -label [::msgcat::mc "Options"]
  menu $m.tools -tearoff 0
	$m.tools add cascade -label [::msgcat::mc "Type of interface"] -menu $m.tools.niv
	creation_menu_niveau $m.tools.niv
	$m.tools add separator
  $m.tools add command -label [::msgcat::mc "Messages"] -command affiche_logs
  $m.tools add command -label [::msgcat::mc "Console"] -command affiche_console
  # menu aide
  $m add cascade -menu $m.help -label [::msgcat::mc "Help"]
  menu $m.help -tearoff 0
  $m.help add command -label [::msgcat::mc "License"] \
      -command "affiche_texte $::rep/licence.txt"
  .menubar.help add separator
  .menubar.help add command -label [::msgcat::mc "About"] \
      -command {tk_messageBox -icon info -title "[::msgcat::mc "About"]..." \
        -message $::apropos}
  
  # zone de boutons en haut
  set comp right
  ttk::frame .fb
  pack .fb -fill x
  #ttk::button .fb.zp -image im_zoom+ -command {$::c scale all 0 0 2 2}
  #pack .fb.zp -side left
  #ttk::button .fb.zm -image im_zoom- -command {$::c scale all 0 0 0.5 0.5}
  #pack .fb.zm -side left
	ttk::button .fb.si -compound $comp -text [::msgcat::mc "Delete infos"] -image im_del_infos -command {efface_infos_connexion}
	pack .fb.si -side left
  ttk::button .fb.quit -compound $comp -text [::msgcat::mc "Quit"] -image im_quitter -command {quit}
  pack .fb.quit -side right
  ttk::frame .f -relief sunken
  pack .f -fill both -expand 1
  
  # zone de boutons à gauche
  frame .f.bg
  pack .f.bg -side left
  
  # Creation du canvas de dessin
  set ::c .f.c
  canvas $::c -background $::coul(fond) -cursor hand2 -scrollregion {0 0 1500 1000} \
		-xscrollcommand ".hscroll set" \
		-yscrollcommand ".f.vscroll set"
  pack $::c -expand 1 -fill both -side left
	
	# Scroll barres
	scrollbar .f.vscroll -command "$::c yview"
  scrollbar .hscroll -orient horiz -command "$::c xview"
  #pack .f.vscroll -side left -fill y
	#pack .hscroll -fill x
	
  # événements canvas
  set ::tmp(event_move) 0
  bind $::c <B1-Motion> {clic_gauche_canvas_bouge %x %y}
  bind $::c <ButtonPress-1> {clic_gauche_canvas %x %y}
  bind $::c <ButtonPress-3> {clic_droit_canvas %x %y}
	
  # zone des outils de conception reseau
  ttk::notebook .fc
  pack .fc -side left
  bind .fc  <<NotebookTabChanged>> {traite_changement_panneau}
  # creation des onglets
  foreach famille $::def(liste_familles) {
		creation_onglet $famille
  }
	
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
  		.fc add .fc.$famille
			#On affiche à l'intérieur de l'onglet uniquement les composants qui doivent l'être
			foreach type $::def($famille,liste) {
				if {$::def($type,voir) <= $n} {
					pack .fc.$famille.$type -fill x -side left -fill y
				} else {
					pack forget .fc.$famille.$type
				}
			}
  	} else {
  		.fc hide .fc.$famille
  	}
	}
	#on sauvegarde le niveau actuel
	set ::tmp(niveau) $n
}

# Création du menu d'affichage/sélection du niveau de détail de l'interface
################################################################################
proc creation_menu_niveau {m} {
	menu $m -tearoff 0
	#on cherche le nombre de niveaux définis
	set nb [llength [array names ::def niveau*,label]]
	
	for {set i 1} {$i<=$nb} {incr i} { 
		if {$i <= $::niveau(max)} {
			$m add radiobutton -label [::msgcat::mc "$::def(niveau$i,label)"] -variable ::tmp(niveau) -value $i -command "change_niveau_detail $i"
		} else {
			$m add radiobutton -label [::msgcat::mc "$::def(niveau$i,label)"] -variable ::tmp(niveau) -value $i -state disable
		}
	}
}

################################################################################
proc affiche_barre {message} {
  # on récupère la taille de l'écran
  set l  [winfo screenwidth .]
  set h [winfo screenheight .]
  set t .barre
  destroy $t
  toplevel $t
  wm title $t "[::msgcat::mc "Please, be patient"]"
  wm transient $t .
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
  destroy .barre
}

################################################################################
proc maj_titre {} {
  set proj [split $::tmp(file) .]
  set proj [lindex $proj 0]
  wm title . "[::msgcat::mc "Network-In! simulator"] - $proj"
}

# Gestion du clic simple gauche sur le canvas
################################################################################
proc clic_gauche_canvas {x y} {

    after 1
    if {$::tmp(event_move) == 1} {
        return
    }
	puts "$::tmp(event_move)"
	#set X [lindex [.hscroll get ] 0]
	#set tx [$::c cget -width]
	#set tx [winfo width $::c]
	
	#destruction de certains éléments s'ils existent
	destroy .note
	destroy $::c.mc
	
	set tags [$::c find closest $x $y 0]
	set tags [$::c gettags $tags]
	
	if {[lindex $tags end] == {current}} {
		
		#On a cliqué sur un objet
		set id [lindex $tags 0]
		
		if {[lindex $tags 1] == "note"} {
			#Affichage d'une note car clic sur l'icone de note
			affiche_note $id
		} elseif {$::obj($id,famille) == {liaison}} {
			#On a cliqué sur une connexion, on affiche les infos sur cette connexion
			set ::tmp($id,infos_connexion) 1
			maj_infos_connexion $id
		} elseif {$::tmp(sel,type) != {0} && $::tmp(sel,famille) == {liaison}} {
			#On est en mode création de liaison
			creation_liaison $id
		} else {
			#on a cliqué sur un objet on veut mettre en avant ses fenêtres s'il est démarré ou le masquer
			raise_objet $id
		}
		
	} else {
		
		#On a cliqué dans le vide (aucun objet sélectionné)
		if {$::tmp(sel,type) != {0} && $::tmp(sel,famille) != {liaison}} {
			# on veut créer un objet (pas une liaison)
			creation_objet $::tmp(sel,famille) $::tmp(sel,type) $x $y
			# on repasse en mode sélection
			set ::tmp(sel,type) 0
			$::c configure -cursor hand2
		}
	}
	
}

# met en avant les fenêtres de l'objet
################################################################################
proc raise_objet {id} {
		switch $::obj($id,type) {
			"passerelle" {
				raise_passerelle
			}
			"virtualbox" {
				raise_vbox
			}
			"bridge" {
				raise_bridge
			}
			
			default {
				
				set cpt 1
				foreach wid $::tmp($id,win_id) {
					if {$cpt != 1} {
						catch {exec wmctrl -i -a $wid}
					} else {
						set desk_wid $wid
					}
					incr cpt
  			}
				#On met le bureau au premier plan
				catch {exec wmctrl -i -a $desk_wid}
			}
		}
}


# réduit les fenêtres de l'objet
################################################################################
proc masque_objet {id} {
		switch $::obj($id,type) {
			"passerelle" {
				hide_passerelle
			}
			"virtualbox" {
				hide_vbox
			}
			"bridge" {
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
	# cas où on veut créer une connexion
	if {$::tmp(id1) == {}} {
		# on vient de sélectionner le 1er objet
		set ::tmp(sel,interface) {}
		menu_choix_connexion $id
		if {$::tmp(sel,interface) != {}} {
			set ::tmp(id1) $id
			set ::tmp(id1,eth) $::tmp(sel,interface)
		} else  {
			set ::tmp(id1) {}
			set ::tmp(id1,eth) {}
			set ::tmp(id2) {}
			set ::tmp(id2,eth) {}
		}
	} else  {
		# on vient de sélectionner le 2ème objet
		set ::tmp(sel,interface) {}
		menu_choix_connexion $id
		if {$::tmp(sel,interface) != {}} {
			set ::tmp(id2) $id
			set ::tmp(id2,eth) $::tmp(sel,interface)
			# on crée la connexion
			if {$::tmp(id1)==$::tmp(id2)} {
				tk_messageBox -icon warning -title [::msgcat::mc "Impossible"] -message [::msgcat::mc "Cannot connect on itself !"]
			} else {
				creation_connexion $::tmp(id1) $::tmp(id2) $::tmp(id1,eth) $::tmp(id2,eth) $::tmp(sel,type)
			}
			# on repasse en mode sélection
			set ::tmp(sel,type) 0
			$::c configure -cursor hand2
		}
		set ::tmp(id1) {}
		set ::tmp(id1,eth) {}
		set ::tmp(id2) {}
		set ::tmp(id2,eth) {}
	}
}

################################################################################
proc clic_droit_canvas {x y} {
  
  set tags [$::c find closest $x $y 0]
  set tags [$::c gettags $tags]
  
  if {[lindex $tags end] == {current}} {
    # cas où on a cliqué sur un objet
    set id [lindex $tags 0]
    # coordonnées dans le repère écran
    set X [winfo pointerx .]
    set Y [winfo pointery .]
    menu_contextuel_objet $id $X $Y
  }
  
}

################################################################################
proc menu_contextuel_objet {id x y} {
	
  destroy $::c.mc
  menu $::c.mc -tearoff 0
  set famille $::obj($id,famille)
	set type $::obj($id,type)
	
	#prise en compte du niveau de fonctionnalités autorisées en fonction du niveau de détails
	if {$::def($type,voir) <= $::tmp(niveau)} {
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
    
    {liaison} {
			#rien de particulier
			# infos sur l'objet sélectionné
			$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
			#$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Suppress"] -command "supprimer_connexion $id"
    }
    
    {ordinateur} {
			
      $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_ordinateur $id" -state $etat3
      $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_ordinateur $id" -state $etat2
      $::c.mc add command -label [::msgcat::mc "Force stop"] -command "force_arrete_ordinateur $id" -state $etat2
			# infos sur l'objet sélectionné
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
			$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Duplicate"] -command "dialogue_dupliquer $id" -state $etat3
			$::c.mc add command -label [::msgcat::mc "Suppress"] -command "supprimer_objet $id" -state $etat3
    
    }
    
    {routeur} {
			
      $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_routeur $id" -state $etat3
      $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_routeur $id" -state $etat2
			$::c.mc add command -label [::msgcat::mc "Force stop"] -command "force_arrete_ordinateur $id" -state $etat2
			# infos sur l'objet sélectionné
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
			$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Duplicate"] -command "dialogue_dupliquer $id" -state $etat3
			$::c.mc add command -label [::msgcat::mc "Suppress"] -command "supprimer_objet $id" -state $etat3
    
    }
    
    {sortie} {
        
			switch $type {
				{passerelle} {
                    if {$::obj($id,ip_eth0) != {} && $::obj($id,netmask_eth0) != {}} {
                        $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_passerelle $id" -state $etat3
                        $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_passerelle $id" -state $etat2
                    } else {
                        $::c.mc add command -label [::msgcat::mc "Start"] -state disabled
                        $::c.mc add command -label [::msgcat::mc "Stop"] -state disabled
                    }
					$::c.mc add separator
					$::c.mc add command -label [::msgcat::mc "Configuration"] -command "fenetre_config_passerelle $id"
				}
				{bridge} {
					$::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_bridge $id" -state $etat3
					$::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_bridge $id" -state $etat2
					$::c.mc add separator
					$::c.mc add command -label [::msgcat::mc "Configuration"] -command "fenetre_config_bridge $id" -state $etat3
				}
				{virtualbox} {
					if {$::tmp(vbox_found)} {
						if {$::tmp($id,is_present)} {
                            $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_virtualbox $id" -state $etat3
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
			$::c.mc add command -label [::msgcat::mc "Suppress"] -command "supprimer_objet $id" -state $etat3
			
    }
    
    {switch} {
			
      $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_switch $id" -state $etat3
      $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_switch $id" -state $etat2
			# infos sur l'objet sélectionné
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
			$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Suppress"] -command "supprimer_objet $id" -state $etat3
			
    }
    
    {hub} {
			
      $::c.mc add command -label [::msgcat::mc "Start"] -command "demarre_switch $id" -state $etat3
      $::c.mc add command -label [::msgcat::mc "Stop"] -command "arrete_switch $id" -state $etat2
			# infos sur l'objet sélectionné
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Informations"] -command "fenetre_infos_objet $id"
			$::c.mc add command -label [::msgcat::mc "Add or change comment"] -command "fenetre_modif_note $id"
			$::c.mc add separator
			$::c.mc add command -label [::msgcat::mc "Suppress"] -command "supprimer_objet $id" -state $etat3
			
    }
		
    {default} {}
		
  }
	
	#Sous-menu de changement/ajout/suppression de carte et mac
	if {$::obj($id,famille) != {liaison} && $::obj($id,reconf)} {
		menu_contextuel_gestion_cartes $id
	}
  
  # coordonnées dans le repère écran
  set X [winfo pointerx .]
  set Y [winfo pointery .]
  # affichage
  $::c.mc post $X $Y
}

# Dialogue appelé lors de la demande de duplication d'un composant
###############################################################
proc dialogue_dupliquer {id} {
	tk_messageBox -type ok -icon warning -title [::msgcat::mc "Duplicate"] -message [::msgcat::mc "After duplication, MAC address should be changed !"]	
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
	if {$::def($type,voir) <= $::tmp(niveau)} {
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
	wm transient .com .
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
	set X [winfo pointerx .]
	set Y [winfo pointery .]
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

################################################################################
proc fenetre_infos_objet {id} {
  destroy .inf
  toplevel .inf
  
  wm title .inf "$id - [::msgcat::mc "Informations"]"
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
    if {$::obj($id,famille) == {liaison}} {
        label .inf.f.l6 -text "[::msgcat::mc {cable}]"
    } else {
        label .inf.f.l6 -text "[::msgcat::mc $::obj($id,categorie)]"
    }
	
	grid .inf.f.l6 -row 1 -column 1 -sticky w
	
	switch $::obj($id,famille) {
			{ordinateur} {
				fenetre_infos_ordinateur $id
			}
			{routeur} {
				fenetre_infos_ordinateur $id
			}
			{switch} {
				fenetre_infos_switch $id
			}
			{hub} {
				fenetre_infos_switch $id
			}
			{sortie} {
				fenetre_infos_sortie $id
			}
			{liaison} {
				fenetre_infos_cable $id
			}
		}
  
  #création du bouton fermer
  ttk::button .inf.bou -compound right -text [::msgcat::mc "Close"] -image im_valider -command {
    destroy .inf
  }
  pack .inf.bou
  focus .inf.bou
  
  # coordonnées dans le repère écran
  set X [winfo pointerx .]
  set Y [winfo pointery .]
  wm geometry .inf +$X+$Y
	update
}

#Fenêtre d'infos pour un pc/routeur
####################################
proc fenetre_infos_ordinateur {id} {
	
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


#Fenêtre d'infos pour passerelle, bridge ou vbox sortie
####################################
proc fenetre_infos_sortie {id} {
	
	labelframe .inf.if -text [::msgcat::mc "Ethernet interfaces"]
	pack .inf.if -fill x
	
	if {$::obj($id,type) == "passerelle"} {
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
	
	if {$::obj($id,type) == "bridge"} {
		label .inf.if.l1 -text "$::obj($id,tap) :"
		grid .inf.if.l1 -row 0 -column 0 -sticky e
		if {$::tmp($id,etat)} {
  		label .inf.if.l2 -text [get_interface_mac $::obj($id,tap)]
  		grid .inf.if.l2 -row 0 -column 1 -sticky w
			if {$::tmp($id,etat_eth0) != ""} {
  			set ip_mask [get_interface_ip $::obj($id,tap)]
  			label .inf.if.l3 -text "[lindex $ip_mask 0]/[lindex $ip_mask 1]"
  			grid .inf.if.l3 -row 1 -column 1 -sticky w
			}
		}
	}
	
	if {$::obj($id,type) == "virtualbox"} {
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


#Fenêtre d'infos pour un switch/hub
#####################################
proc fenetre_infos_switch {id} {
	
	labelframe .inf.if -text [::msgcat::mc "Ethernet ports"]
	pack .inf.if -fill x
	for  {set i 0} {$i<$::obj($id,nb_eth)} {incr i} {
		#frame contenant les infos d'une interface
		frame .inf.if.f$i
		pack .inf.if.f$i -fill x
        if {$::obj($id,eth$i) != {}} {
            set m $::obj($::obj($id,eth$i),id1)
            if {$m == $id} {
                set m $::obj($::obj($id,eth$i),id2)
            }
            
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


################################################################################
proc clic_gauche_canvas_bouge {x y} {
    set ::tmp(event_move) 1
  puts $::tmp(event_move)
  if {$::tmp(sel,type) != {0}} {
    # cas où on est en mode ajout, on sort
    set ::tmp(event_move) 0
    return
  }
  
  set tags [$::c find closest $x $y 0]
  set tags [$::c gettags $tags]
  
  # si on n'a pas cliqué sur un objet, on sort
  if {[lindex $tags end] != {current}} {
      set ::tmp(event_move) 0
      return
  }
  
  set id [lindex $tags 0]
  
  if {$::obj($id,famille) == {liaison}} {
    # cas où on a cliqué sur une connexion : rien à faire alors
    set ::tmp(event_move) 0
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
  set ::tmp(event_move) 0
}

################################################################################
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
  
  set pal_m .fc.$famille
  frame $pal_m
  .fc add $pal_m -text $::def($famille,label)
	
  # Bouton de sélection
  ttk::radiobutton $pal_m.sel -image im_select -width 80 -variable ::tmp(sel,type) -value 0 -command {$::c configure -cursor hand2}
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
  set w [.fc select]
  set ::tmp(sel,famille) [file extension $w]
  set ::tmp(sel,famille) [string range $::tmp(sel,famille) 1 end]
  set ::tmp(sel,type) 0
}

# creation des images utilisees
################################################################################
proc creer_images_interface {} {
  
  image create photo im_network-in -file $::rep/images/network-in.gif
  #image create photo im_zoom+ -file $::rep/images/zoom+.gif
  #image create photo im_zoom- -file $::rep/images/zoom-.gif
  image create photo im_quitter -file $::rep/images/quitter.gif
  image create photo im_select -file $::rep/images/select.gif
  image create photo im_off -file $::rep/images/off.gif
  image create photo im_demarre -file $::rep/images/demarre.gif
  image create photo im_on -file $::rep/images/on.gif
  image create photo im_config -file $::rep/images/configuration.gif
  image create photo im_annuler -file $::rep/images/annuler.gif
  image create photo im_valider -file $::rep/images/valider.gif
  image create photo im_eteindre -file $::rep/images/eteindre.gif
  image create photo im_del_infos -file $::rep/images/del_infos.gif
  image create photo im_carte -file $::rep/images/carte.gif
  image create photo im_note -file $::rep/images/note.gif
  image create photo im_rafraichir -file $::rep/images/rafraichir.gif
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
  tk_messageBox -icon error -type ok -message "[::msgcat::mc "Error"] : $msg\n\n$::errorInfo"
  #puts $msg
	
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
  if {$::obj($id,nom)  == "unnamed"} {
    $::c create text $x [expr $y + [image height im_$type] / 2 + 30] -tag "$id $famille $type" -text [::msgcat::mc "unnamed"] -anchor c -fill $::coul(texte)
  } else  {
    $::c create text $x [expr $y + [image height im_$type] / 2 + 30] -tag "$id $famille $type" -text $nom -anchor c -fill $::coul(texte)
  }
  
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
  set x1 $::obj($id1,x)
  set y1 $::obj($id1,y)
  set x2 $::obj($id2,x)
  set y2 $::obj($id2,y)
  set l [$::c create line $x1 $y1 $x2 $y2 -tag "$id connectique $type" -dash $::def($type,trait) -width 2 -fill $::def($type,coul)] 
  #canvas
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
  set x1 $::obj($id1,x)
  set y1 $::obj($id1,y)
  set x2 $::obj($id2,x)
  set y2 $::obj($id2,y)
  
  set d [expr sqrt(pow($x2-$x1,2)+pow($y2-$y1,2))]
  set dx [expr ($d-$x2+$x1) * 0.05]
  set dy [expr ($d-$y2+$y1) * 0.05]
  set X1 [expr $x1 + $dx + ($x2 - $x1) / 3.0]
  set Y1 [expr $y1 + $dy + ($y2 - $y1) / 3.0]
  set X2 [expr $x2 - $dx - ($x2 - $x1) / 3.0]
  set Y2 [expr $y2 - $dy - ($y2 - $y1) / 3.0]

  if {$famille1 == "hub" || $famille1 == "switch"} {
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
  
	#dessin des infos dans le canvas
	$::c create rectangle [expr $X1-50] [expr $Y1-10] [expr $X1+50] [expr $Y1+30] -fill white -tag "$id info inf$id"
	$::c create rectangle [expr $X2-50] [expr $Y2+10] [expr $X2+50] [expr $Y2-30] -fill white -tag "$id info inf$id"
  $::c create text [expr $X1-45] $Y1 -tag "$id info inf$id" -anchor w -text $nom_interf1 -fill $::def($type,coul) -font infos
  $::c create text [expr $X2-45] [expr $Y2-20] -tag "$id info inf$id" -anchor w -text $nom_interf2 -fill $::def($type,coul) -font infos
  
	# Affichage éventuel des ip et masques
  if {$::tmp($id1,etat) != {0} && $::tmp($id1,etat_$interf1) != {}} {
		set info1 $::tmp($id1,etat_$interf1)
    $::c create text [expr $X1-45] [expr $Y1 +15] -tag "$id info inf$id" -anchor w -text $info1 -fill $::def($type,coul) -font infos
  }
  if {$::tmp($id2,etat) != {0} && $::tmp($id2,etat_$interf2) != {}} {
		set info2  $::tmp($id2,etat_$interf2)
    $::c create text [expr $X2-45] [expr $Y2 -0] -tag "$id info inf$id" -anchor w -text $info2 -fill $::def($type,coul) -font infos
	}
	
	#Effacement des étiquettes si on clique sur  une étiquette
  $::c bind inf$id <Button> "$::c delete inf$id ; set ::tmp($id,infos_connexion) 0"
  
}

################################################################################
proc affiche_objet_off {id} {
  $id blank
  $id copy im_off
}

################################################################################
proc affiche_objet_demarre {id} {
  $id blank
  $id copy im_demarre
}

################################################################################
proc affiche_objet_on {id} {
  $id blank
  $id copy im_on
}

#enlève l'icone de note à côté de l'objet
################################################################################
proc affiche_note_off {id} {
	$id-note blank
}

#ajoute l'icone de note à côté de l'objet
################################################################################
proc affiche_note_on {id} {
	$id-note blank
	$id-note copy im_note_mini
}

#Ouvre un dialogue de confirmation d'ouverture de nouveau projet
################################################################################
proc dialogue_ouvrir_projet {fic} {
  
  # on vérifie si les machines ont été arrêtées
  if {![verif_arret]} {
    dialogue_arreter_tout
    return
  }
  
  set reponse [tk_messageBox -type yesno -icon warning -title [::msgcat::mc "Open a project"] -message [::msgcat::mc "Do you really want to open another project ? If you don't  save the actual project, it will be lost"]]
  if {$reponse != "no"} {
  	if {$fic == {} } {
      set fic [tk_getOpenFile -initialdir $::rep_home -filetypes {{Network-in! .net}}]
  	}
    if {$fic != {}} {
      desarchiver_projet $fic
    }
      
  }
}

################################################################################
proc dialogue_nouveau_projet {} {
  
  # on vérifie si les machines ont été arrêtées
  if {![verif_arret]} {
    dialogue_arreter_tout
    return
  }
  
  set reponse [tk_messageBox -type yesno -icon warning -title [::msgcat::mc "New project"] -message [::msgcat::mc "Do you really want to start a new project ? If you don't  save the actual project, it will be lost"]]
  if {$reponse == "no"} {
    return
  } else {
    init_projet
  }
}

################################################################################
proc dialogue_arreter_tout {} {
  set rep [tk_messageBox -icon info -title [::msgcat::mc "Quit Network-In!"] -message [::msgcat::mc "You must stop every equipment before doing this"]]
}


################################################################################
proc dialogue_creation_passerelle_impossible {} {
  tk_messageBox -icon info -title [::msgcat::mc "Network-In!"] -message [::msgcat::mc "You can't create more than one gateway"]
}

################################################################################
proc dialogue_enregistrer_projet {} {
  
  # on vérifie si les machines ont été arrêtées
  if {![verif_arret]} {
    dialogue_arreter_tout
    return
  }
  
  set f [tk_getSaveFile -initialdir $::rep_home -initialfile $::tmp(file) -filetypes {{Network-in! .net} {Network-in! .NET}}]
  if {$f == {}} {
    return
  }
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

################################################################################
proc affiche_texte {fichier} {
  
  toplevel .t_texte
  frame .t_texte.f
  pack .t_texte.f -expand 1 -fill both
  
  text .t_texte.f.tex -yscrollcommand {.t_texte.f.scrolv set} \
      -wrap word
  pack .t_texte.f.tex -expand 1 -fill both -side left
  
  #création scrollbar verticale
  scrollbar .t_texte.f.scrolv -orient vert -command {.t_texte.f.tex yview}
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
proc affiche_console {} {
  exec xterm +ai -title "Network-In! - xterm" -bg $::coul(fond) -fg $::coul(texte) -fn 10x20 &
}

#Affichage des messages (fichier journal network-in.log)
################################################################################
proc affiche_logs {} {
	
	proc maj_log {} {
		.t_mess.f.tex configure -state normal
		.t_mess.f.tex delete 1.0 end
		 #Appel commande tail Unix
		 set fic $::rep_proj/network-in.log
		 set txt [exec tail -n 200 $fic]
		 .t_mess.f.tex insert end "$txt\n"
		 .t_mess.f.tex configure -state disabled
		 .t_mess.f.tex yview moveto 1
		 update
	}
	
  destroy .t_mess
  toplevel .t_mess
  wm title .t_mess [::msgcat::mc "Logs print"]
  
  frame .t_mess.f
  pack .t_mess.f -expand 1 -fill both
  
  text .t_mess.f.tex -yscrollcommand {.t_mess.f.scrolv set} \
      -wrap word -background $::coul(fond) -foreground $::coul(texte)
  pack .t_mess.f.tex -expand 1 -fill both -side left
  
  #création scrollbar verticale
  scrollbar .t_mess.f.scrolv -orient vert -command {.t_mess.f.tex yview}
  pack .t_mess.f.scrolv -side right -fill y

  #création zone boutons
  frame .t_mess.f_bou
  ttk::button .t_mess.f_bou.val -compound right -text [::msgcat::mc "Close"] -image im_valider -command {
    destroy .t_mess
  }
  ttk::button .t_mess.f_bou.raf -compound right -text [::msgcat::mc "Refresh"] -image im_rafraichir -command {
    maj_log
  }
  pack  .t_mess.f_bou
  pack .t_mess.f_bou.val -side left
  pack .t_mess.f_bou.raf -side left
  focus .t_mess.f_bou.val
	
  #Mise à jour texte log
	maj_log
}


#fenetre permettant de changer d'adresse mac pour les cartes existantes
################################################################################
proc fenetre_change_carte {id type n} {
	set ::tmp(mac) $::obj($id,mac_${type}$n)
	
	destroy .fcc
	toplevel .fcc
	wm transient .fcc .
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
