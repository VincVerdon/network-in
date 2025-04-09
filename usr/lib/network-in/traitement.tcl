####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version 20250408

# Suppression d'un câble
################################################################################
proc supprimer_connexion {id} {
  
  # on debranche d'abord le câble
  arrete_connexion $id
  
  # on efface le câble
  $::c delete $id
  # on supprime le câble
  set id1 $::obj($id,id1)
  set id2 $::obj($id,id2)
  set interf1 $::obj($id,interf1)
  set interf2 $::obj($id,interf2)
  set ::obj($id1,$interf1) {}
  set ::obj($id2,$interf2) {}
  array unset ::obj $id,*
  # on sauvegarde les données obj
  sauvegarder_projet
  
}

# Suppression d'un matériel
################################################################################
proc supprimer_objet {id} {
  
  # suppression des câbles
  if {[lsearch $::obj($id,techno) "ethernet"]  != {-1}} {
    for  {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
      if {$::obj($id,eth$i) != {}} {
        supprimer_connexion $::obj($id,eth$i)
      }
    }
  }
  # suppression des fichiers (répertoire ou archive suivant les cas)
  catch {file delete -force $::rep_proj/datas/$id}
  catch {file delete -force $::rep_proj/datas/$id.tgz}
  # suppression de l'objet
  array unset ::obj $id,*
  # on efface l'objet
  $::c delete $id
  # on sauvegarde les données obj
  sauvegarder_projet
  
}


################################################################################
proc demarre_ordinateur {id} {
	
	#On vérifie si le disque système existe
	#On gère le cas de configuration d'un nouveau disque système
	if {$::obj($id,dd) == "new.img"} {
		#Cas de la création d'un nouveau disque système
		set disk $::rep_conf/disks/new.img
		set opts "con0=fd:0,fd:1 con1=xterm"
		if ![file exists $disk] {
  		dialogue_system_disk_missing new.img
  		return
		}
	} else {
		#Cas normal
		if [file exists $::rep/disks/$::obj($id,dd)] {
			set disk $::rep_proj/datas/$id/system.cow,$::rep/disks/$::obj($id,dd)
			set opts $::obj($id,exe_options)
		} elseif [file exists $::rep_conf/disks/$::obj($id,dd)] {
			set disk $::rep_proj/datas/$id/system.cow,$::rep_conf/disks/$::obj($id,dd)
			set opts $::obj($id,exe_options)
		} else {
			dialogue_system_disk_missing $::obj($id,dd)
			return
		}
	}
	
	set opts "con0=fd:0,fd:1 con1=xterm"
	
  puts ">>>>STARTING MACHINE $id"
  set famille $::obj($id,famille)
  set type $::obj($id,type)
  
  # l'objet est déclaré actif désormais
  set ::tmp($id,etat) 1
  affiche_objet_demarre $id
  
  # désarchivage éventuel d'une archive compressée
  if {[file exists $::rep_proj/datas/$id.tgz]} {
    exec tar -C $::rep_proj --sparse -xzf $::rep_proj/datas/$id.tgz
    file delete $::rep_proj/datas/$id.tgz
  }
	
  # création du rep d'échanges avec la machine virtuelle
  catch {file mkdir $::rep_proj/datas/$id/com}
  
  # Prise en compte de la langue
  file delete $::rep_proj/datas/$id/interface/dict.actu
  catch {file copy -force $::rep/lang/dict.$::lang  $::rep_proj/datas/$id/interface/dict.actu}
  
  # on fixe une ip de communication avec le pc hôte si elle n'existe pas déjà
  if {[array names ::tmp $id,ip_com] == {}} {
    incr ::tmp(n_ip_com)
    set ::tmp($id,ip_com) "$::tmp(reseau).$::tmp(n_ip_com)"
  }

  # on écrit un fichier d'échange contenant le numéro de machine
  ecrire_fichier_echange $id id $id
  # on écrit un fichier qui indique le message a propos
  ecrire_fichier_echange $id apropos "$::apropos"
  # on écrit un fichier qui indique quel est le type de matériel
  ecrire_fichier_echange $id type "$famille $type"
  # on écrit un fichier qui indique l'ip de l'hôte
  ecrire_fichier_echange $id ip_hote $::ip_hote
  # on écrit un fichier qui indique l'ip de communication de l'uml
  ecrire_fichier_echange $id ip_com $::tmp($id,ip_com)
  # on écrit un fichier qui indique le display de l'hôte
  ecrire_fichier_echange $id display $::env(DISPLAY)
  
  # On initialise les interfaces réseau et on écrit un fichier de com
	set interf ""
  if {[lsearch $::obj($id,techno) "ethernet"]  != {-1}} {
     if {$::obj($id,nb_eth) != {0}} {
        append interf "eth $::obj($id,nb_eth) "
        for  {set i 0} {$i<$::obj($id,nb_eth)} {incr i} {
          # valeur actu de la config ip de l'interface
          set ::tmp($id,etat_eth$i) {}
        }
     }
  }
  if {[lsearch $::obj($id,techno) "wifi"]  != {-1}} {
    if {$::obj($id,nb_wifi) != {0}} {
      append interf "wlan $::obj($id,nb_wifi)"
      for  {set i 0} {$i<$::obj($id,nb_wifi)} {incr i} {
        # valeur actu de la config ip de l'interface
        set ::tmp($id,etat_wlan$i) {}
      }
    }  
  }
  ecrire_fichier_echange $id interfaces $interf
	
	# Nom de l'exe usermode linux a lancer
	# On vérifie que le noyau existe sinon on remplace par le noyau par défaut
	if [file exists $::rep/kernels/$::obj($id,kernel)/linux.uml] {
		set exe_linux $::rep/kernels/$::obj($id,kernel)/linux.uml
		set modules_dd $::rep/kernels/$::obj($id,kernel)/modules.img
	} elseif [file exists $::rep_conf/kernels/$::obj($id,kernel)/linux.uml] {
			set exe_linux $::rep_conf/kernels/$::obj($id,kernel)/linux.uml
			set modules_dd $::rep_conf/kernels/$::obj($id,kernel)/modules.img
	} else {
		set exe_linux $::rep/kernels/$::kernel/linux.uml
		set modules_dd $::rep/kernels/$::kernel/modules.img
		#dialogue_kernel_missing $exe_linux
	}
	
	set exe "$exe_linux $opts mem=$::obj($id,mem) ubd0=$disk root=/dev/ubda ubd1=$::rep_proj/datas/$id/modules.cow,$modules_dd umid=$id hostfs=$::rep_proj/datas/$id"
	
	# activation des câbles réseau et des interfaces eth
	set ::tmp($id,pid_vde) ""
  if {[lsearch $::obj($id,techno) "ethernet"]  != {-1}} {
    for  {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
      # démarrage du socket VDE pour l'interface
			eval exec vde_switch -d -nostdin -hub -s $::rep_tmp/vde/$id-eth$i
			set pid [string range [lindex [eval exec lsof -Fp $::rep_tmp/vde/$id-eth$i/ctl 2>/dev/null] end] 1 end]
			lappend ::tmp($id,pid_vde) $pid
      # ajout de la carte eth à la ligne de commande de l'uml
			set exe [concat $exe eth$i=vde,$::rep_tmp/vde/$id-eth$i,$::obj($id,mac_eth$i)]
      if {$::obj($id,eth$i) != {}} {
        demarre_connexion $::obj($id,eth$i)
      }
    }
  }
	set exe [concat $exe eth99=vde,$::rep_tmp/vde/switch_com]
	
	# démarrage du pc
	set ::tmp($id,pid) [eval exec $exe > $::rep_tmp/$id.log 2>&1 &]

  # démarrage de la boucle de surveillance de machine
  boucle_demarre_objet $id
}

################################################################################
proc demarre_routeur {id} {
  demarre_ordinateur $id
}


################################################################################
proc demarre_switch {id} {
	
	puts ">>>>STARTING SWITCH $id"
	
  set famille $::obj($id,famille)
  set type $::obj($id,type)
  
  # démarrage du vde_switch
  if {$famille == {hub}} {
    # cas d'un hub
    eval exec vde_switch -d -nostdin --fstp -n $::obj($id,nb_eth) -hub -s $::rep_tmp/vde/$id
  } else  {
	  eval exec vde_switch -d -nostdin --fstp -n $::obj($id,nb_eth) -M $::rep_tmp/terminal/$id -s $::rep_tmp/vde/$id
  }
	#set ::tmp($id,pid_vde) {}
	set ::tmp($id,pid_vde) [string range [eval exec lsof -Fp $::rep_tmp/vde/$id/ctl 2>/dev/null] 1 end]
  # l'objet est déclaré actif désormais
  set ::tmp($id,etat) 1
  affiche_objet_on $id
	
  # activation des câbles réseau
  if {[lsearch $::obj($id,techno) "ethernet"]  != {-1}} {
    for  {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
      # valeur actu de la config ip de l'interface (sera toujours vide !)
      set ::tmp($id,etat_eth$i) {}
      # démarrage des connexions
      if {$::obj($id,eth$i) != {}} {
        demarre_connexion $::obj($id,eth$i)
      }
    }
  }
}


# etablissement d'une connexion entre deux éléments
################################################################################
proc demarre_connexion {id} {
    
  if {$id == {}} {return}
	
  #Les 2 objets liés par ce cable
  set id1 $::obj($id,id1)
  set id2 $::obj($id,id2)
	
  # Si le choix de la connexion est mauvais, on sort
	switch $::obj($id,type) {
		{straight} {
			if {$::obj($id1,categorie) == $::obj($id2,categorie)} {
  			set valid false
  		} else  {
  			set valid true
  		}
		}
		{cross} {
			if {$::obj($id1,categorie) == $::obj($id2,categorie)} {
				set valid true
			} else  {
				set valid false
			}
		}
	} 
	
  if {!$valid} {
    return
  }
	
	puts "Starting connection $id1 : $::tmp($id1,etat) ; $id2 : $::tmp($id2,etat)"
  if {$::tmp($id1,etat) && $::tmp($id2,etat)} {
    set n 0
    foreach i "$id1 $id2" {
      incr n
      switch $::obj($i,famille) {
        {computer} {set rep$n $::rep_tmp/vde/$i-$::obj($id,interf$n)}
        {router} {set rep$n $::rep_tmp/vde/$i-$::obj($id,interf$n)}
        {switch} {set rep$n $::rep_tmp/vde/$i}
        {hub} {set rep$n $::rep_tmp/vde/$i}
        {output} {
			switch $::obj($i,type) {
				{nat} {set rep$n $::rep_tmp/vde/switch_gateway}
				{bridge} {set rep$n $::rep_tmp/vde/$i}
			}
        }
        {vm} {
            switch $::obj($i,type) {
                {virtualbox} {set rep$n $::rep_tmp/vde/$i}
            }
        } 
      }
    }
    # On branche !
    set ::tmp($id,pid) [exec dpipe vde_plug $rep1 = vde_plug $rep2 &]
		puts "Connection $id1 - $id2 established"
		#Mise à jour étiquettes infos
		maj_infos_connexion $id
  }
	
}

#Duplication d'un ordinateur à partir d'un autre
##################################################################################
proc dupliquer_ordinateur {id} {

	# On stocke l'id du parent
	set parent $id
	
	# dimensions de l'image
	#set imx [image width im_$type]
	#set imy [image height im_$type]
	
	# on définit le numéro d'id de l'objet
	incr ::tmp(lastid)
	set id m$::tmp(lastid)
	
	# initialisation des données de l'objet
	set ::obj($id,x) [expr $::obj($parent,x)+10]
	set ::obj($id,y) [expr $::obj($parent,y)+10]
	set ::obj($id,nom) $::obj($parent,nom)
	set ::obj($id,mem) $::obj($parent,mem)
	set ::obj($id,famille) $::obj($parent,famille)
	set ::obj($id,type) $::obj($parent,type)
	set ::obj($id,techno) $::obj($parent,techno)
	set ::obj($id,categorie) $::obj($parent,categorie)
	set ::obj($id,reconf) $::obj($parent,reconf)
	set ::obj($id,dd) $::obj($parent,dd)
	set ::obj($id,exe_options) $::obj($parent,exe_options)
	set ::obj($id,kernel) $::obj($parent,kernel)
	
	# Initialisation des interfaces ethernet
	set ::obj($id,nb_eth) $::obj($parent,nb_eth)
	if {$::obj($id,nb_eth) != {0}} {
  	for {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
  		set ::obj($id,eth$i) {}
  		set ::obj($id,mac_eth$i) $::obj($parent,mac_eth$i)
  	}
	}
	
	if [array exists $parent,nb_wifi] {
  	# Initialisation des interfaces wifi
  	set ::obj($id,nb_wifi) $::obj($parent,nb_wifi)
  	if {$::obj($id,nb_wifi) != {0}} {
  		for {set i 0} {$i < $::obj($id,nb_wifi)} {incr i} {
  			set ::obj($id,wlan$i) {}
  			set ::obj($id,mac_wlan$i) $::obj($parent,mac_wlan$i)
  		}
  	}
	}
		
	# a la creation l'objet n'est pas démarré
	set ::tmp($id,etat) 0
	set ::tmp($id,win_id) {}
	
	# Copie des fichiers
	file copy $::rep_proj/datas/$parent $::rep_proj/datas/$id
	
	# on sauvegarde les données obj
	sauvegarder_projet
	
	# dessin sur le canvas
	
	dessine_objet $id
	
}

# suppression d'une connexion entre deux éléments
################################################################################
proc arrete_connexion {id} {
	
	if {$id == {}} {return}

	set id1 $::obj($id,id1)
	set id2 $::obj($id,id2)
	puts "Connection $id1 - $id2 stopped"
    kill $::tmp($id,pid)
    set ::tmp($id,pid) {}
  
}

# Arrêt d'un switch ou hub virtuel VDE
################################################################################
proc arrete_switch {id} {
  
	kill $::tmp($id,pid_vde)
  set ::tmp($id,pid_vde) {}
  # l'objet est déclaré inactif désormais
  set ::tmp($id,etat) 0
  affiche_objet_off $id
	puts ">>>>SWITCH $id arrêté"
  
}


# Demande d'arrêt d'un ordinateur ou routeur transmis à la machine
# Arrêt effectué par la machine elle-même par une séquence halt
################################################################################
proc arrete_ordinateur {id} {
  
  	# on écrit un fichier qui indique à la machine que l'on souhaite l'arret
  	ecrire_fichier_echange $id halt "STOP"
	
}


# Arrêt forcé de la machine virtuelle de type ordinateur ou routeur
# (Arrêt de l'instance usermode-linux)
################################################################################
proc force_arrete_ordinateur {id} {
	
	puts ">>>>Arrêt forcé MACHINE $id"
	
	#Arrêt forcé par la console uml
	catch {exec /usr/bin/uml_mconsole $id halt &}
	
	clean_machine_context $id
	
	#Destruction des fenêtres ouvertes
	foreach wid $::tmp($id,win_id) {
		catch {exec xkill -id $wid &}
	}
    
}

# Demande d'arrêt d'un routeur
################################################################################
proc arrete_routeur {id} {
  arrete_ordinateur $id
}


# produit un caractère hexa aléatoire
################################################################################
proc aleatoire_hexa {} {
  
  set table {0123456789abcdef}
  set a [expr rand()]
  set n [expr int($a * 16)]
  set res [string index $table $n]
  return $res
  
}


# produit une adresse mac aléatoire
################################################################################
proc aleatoire_mac {} {
	set n [expr (10 - [string length $::mac_prefix]) /2]
  append res $::mac_prefix
  for  {set i 0} {$i <=  $n} {incr i} {
    append res ":[aleatoire_hexa][aleatoire_hexa]"
  }
  return $res
}


#initialisation des interfaces et adresses mac du composant
################################################################################
proc init_eth_mac {id} {
	
	if {$::obj($id,nb_eth) == 1} {
		set ::obj($id,eth0) {}
		set ::obj($id,mac_eth0) [aleatoire_mac]
	} else {
		# dans le cas de plusieurs adresses, on produit une liste ordonnée de mac
    set base_mac  [string range [aleatoire_mac] 0 14]
    for  {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
      set ::obj($id,eth$i) {}
      set ::obj($id,mac_eth$i) "[set base_mac]0[expr $i + 1]"
    }
	}
	
}


#initialisation des interfaces seules (pas d'adresses mac) du composant
################################################################################
proc init_eth {id} {
	
  for  {set i 0} {$i < $::obj($id,nb_eth)} {incr i} {
    set ::obj($id,eth$i) {}
  }
	
}


# Boucle de scan lancée au démarrage d'une machine virtuelle
################################################################################
proc boucle_demarre_objet {id} {
	
  if  {[file exists $::rep_proj/datas/$id/com/on]} {
    affiche_objet_on $id
    boucle_scan_objet $id
  } else  {
    after 100 boucle_demarre_objet $id
  }
	
}


# Boucle de scan lancée après le démarrage d'une machine virtuelle 
# Pour surveiller son état durant son fonctionnement
################################################################################
proc boucle_scan_objet {id} {
  
	if  {[file exists $::rep_proj/datas/$id/com/on] || [file exists $::rep_proj/datas/$id/com/reboot]} {
        
        #Machine en fonctionnement ou en train de redémarrer
        #récupération du nouveau nom de machine
        set res  [lire_fichier_echange $id hostname]
        if  {$res != {-1}} {
          set ::obj($id,nom) $res
          # on met à jour l'affichage
          dessine_objet $id
        }
        #récuperation de la configuration des interfaces
        for {set i 0} {$i<$::obj($id,nb_eth)} {incr i} {
          set res [lire_fichier_echange $id interface_eth$i]
          if {$res != {-1}} {
            set ::tmp($id,etat_eth$i) $res
        	#on met à jour l'affichage les infos sur l'IP si elles sont affichées actuellement
        	set id_liaison $::obj($id,eth$i)
        	if {$id_liaison != "" && $::tmp($id_liaison,infos_connexion)} {
        		maj_infos_connexion $id_liaison
        	}
          }
        }
      	#récupération de la liste des winid de la machine
      	set ::tmp($id,win_id) [lire_fichier_echange $id window_id]
		#on relance la boucle
    	after 2000 boucle_scan_objet $id
    		
    } else {
        
		clean_machine_context $id
		
    }
  
}

# Nettoie l'environnement d'une machine lors de son arrêt
################################################################################
proc clean_machine_context {id} {
	
	#on coupe le branchement de ses interfaces eth
	foreach i $::tmp($id,pid_vde) {
		kill $i
	}
	#mise a 0 de la configuration des interfaces
	for {set i 0} {$i<$::obj($id,nb_eth)} {incr i} {
		set ::tmp($id,etat_eth$i) {}
		#on met à jour l'affichage les infos sur l'IP si elles sont affichées actuellement
		set id_liaison $::obj($id,eth$i)
		if {$id_liaison != "" && $::tmp($id_liaison,infos_connexion)} {
			maj_infos_connexion $id_liaison
		}
	}
	# Suppression des rep inutiles désormais
	#On supprime le répertoire d'échange dans le rep du projet
	file delete -force $::rep_proj/datas/$id/com
	file delete $::rep_proj/datas/$id/interface/dict.actu
	puts ">>>>MACHINE $id STOPPED"
	after 2000 "set ::tmp($id,etat) 0 ; affiche_objet_off $id"
}


# Ecriture fichier d'échange avec les machines UML
################################################################################
proc ecrire_fichier_echange {id fic texte} {
  set f [open $::rep_proj/datas/$id/com/$fic w]
  puts $f $texte
  close $f
}

# Lecture fichier d'échange avec les machines UML
################################################################################
proc lire_fichier_echange {id fic} {
  if {![file exists $::rep_proj/datas/$id/com/$fic]} {return -1}
  set f [open $::rep_proj/datas/$id/com/$fic r]
  set texte [read $f]
  close $f
  return [string trim $texte]
}

# Création d'un câble droit ou croisé
################################################################################
proc creation_connexion {id1 id2 con1 con2 type} {
	
    # on définit le numéro d'id de l'objet
    incr ::tmp(lastid)
    set id m$::tmp(lastid)
    # Initialisation
    initialisation_$type  $id $id1 $id2 $con1 $con2
    # on sauvegarde les données obj
    sauvegarder_projet
    
    # par définition un cable ne se démarre pas !
    set ::tmp($id,etat) 0
    set ::tmp($id,pid) {}
    # Pas d'affichage des étiquettes par défaut
  	set ::tmp($id,infos_connexion) 0
	
	  # dessin dans le canvas
    dessine_connexion $id
	
    # on tente de démarrer la connexion
    demarre_connexion $id
  
}

# creation d'un objet du reseau
################################################################################
proc creation_objet {famille type x y} {
  
  # On traite les cas particuliers
	switch $type {
		{nat} {
			#On cherche si un composant passerelle a déjà été créé ce qui n'est pas accepté
  		foreach t [array get ::obj *,type] {
        if {$t == {nat}} {
          dialogue_creation_passerelle_impossible
          return
        }
      }
		}
  }
  
  # dimensions de l'image
  set imx [image width im_$type]
  set imy [image height im_$type]
  
  # on définit le numéro d'id de l'objet
  incr ::tmp(lastid)
  set id m$::tmp(lastid)
  
  # initialisation des données de l'objet
  set ::obj($id,x) $x
  set ::obj($id,y) $y
  
  # a la creation l'objet n'est pas démarré
  set ::tmp($id,etat) 0
	set ::tmp($id,win_id) {}
  
  # initialisation
  initialisation_$type $id
  
  # on sauvegarde les données obj
  sauvegarder_projet
  
  # dessin sur le canvas
  dessine_objet $id
  
}

# fonction qui retourne 1 si toutes les machines sont arrêtées et 0 sinon
################################################################################
proc verif_arret {} {
	set ret 1
  # on vérifie si tout a été arrêté
  for  {set i 1} {$i <= $::tmp(lastid)} {incr i} {
    set id m$i
    if {[array name ::obj $id,*] != {}} {
      if {$::tmp($id,etat)} {
          set ret 0
      }
    }
  }
  return $ret
}

# sortie du logiciel - une confirmation est demandée si machines pas arrêtées
################################################################################
proc quit {} {
    
	if ![verif_arret] {
		dialogue_arreter_tout
	} else {
    	# on sauvegarde les données obj
    	sauvegarder_projet
        # on supprime les fichiers tmp inutiles
        set liste [glob -nocomplain $::rep_tmp/m*]
        foreach i $liste {
            file delete -force $i
        }
        exit
	}
	
}

# Provoque l'arrêt de tout matériel allumé sans confirmation
################################################################################
proc arreter_tout {} {
	
  for  {set i 1} {$i <= $::tmp(lastid)} {incr i} {
    set id m$i
    if {[array name ::obj $id,*] != {}} {
      if {$::tmp($id,etat)} {
        switch $::obj($id,famille) {
            {computer} {arrete_ordinateur $id}
            {router} {arrete_ordinateur $id}
            {switch} {arrete_switch $id}
            {hub} {arrete_switch $id}
            {output} {
        		if {$::obj($id,type) == {nat}} {arrete_passerelle $id}
                if {$::obj($id,type) == {bridge}} {arrete_bridge $id}
        	}
            {vm} {
                if {$::obj($id,type) == {virtualbox}} {arrete_virtualbox $id}
            }
        	{default} {}
        }
      }
    }
  }
	
}


# Provoque le démarrage de tout le matériel de la simulation
################################################################################
proc demarrer_tout {} {
	
  for  {set i 1} {$i <= $::tmp(lastid)} {incr i} {
	set id m$i
	if {[array name ::obj $id,*] != {}} {
	  if {! $::tmp($id,etat)} {
		switch $::obj($id,famille) {
			{computer} {demarre_ordinateur $id}
			{router} {demarre_ordinateur $id}
			{switch} {demarre_switch $id}
			{hub} {demarre_switch $id}
			{output} {
				if {$::obj($id,type) == {nat}} {demarre_passerelle $id}
				if {$::obj($id,type) == {bridge}} {demarre_bridge $id}
			}
			{vm} {
				if {$::obj($id,type) == {virtualbox}} {demarre_virtualbox $id}
			}
			{default} {}
		}
	  }
	}
  }
	
}


# Sauvegarde du projet courant dans le fichier structure.xml
################################################################################
proc sauvegarder_projet {} {
  
	#on récupère la taille actuelle du canvas
	update
	set ::tmp(width) [winfo width .]
	set ::tmp(height) [winfo height .]
	
	set date_time [clock seconds]
	set ::tmp(date) [clock format $date_time -format "%Y-%m-%d %H:%M:%S"]
	
	#puts [array get ::tmp]
	#puts [array get ::obj]
	
  if {[file exists $::rep_proj/structure.xml]} {
    file rename -force $::rep_proj/structure.xml $::rep_proj/structure.sav
  }
	
	xml_structure_write $::rep_proj/structure.xml
	
}


# Chargement du projet courant depuis le fichier structure.cfg
################################################################################
proc restaurer_projet {} {
	
	set liste_types {desktop laptop server linux switch4 switch8 hub4 hub8 router2 router4 straight cross nat bridge virtualbox}
  
	#récupération de la structure
	xml_structure_read $::rep_proj/structure.xml
	#puts [array get ::tmp]
	#puts [array get ::obj]
	
	# mise à jour du titre
	maj_titre
	
	#prise en compte du niveau de détail
	change_niveau_detail $::tmp(details)
	
	# mise à la taille du canvas
	wm geometry . $::tmp(width)x$::tmp(height)
	
	# on initialise quelques variables
	set ::tmp(id1) {}
	set ::tmp(id2) {}
	
	# dessin de la structure
	for  {set i 1} {$i <= $::tmp(lastid)} {incr i} {
        set id m$i
        # l'objet est inactif au démarrage
        set ::tmp($id,etat) 0
        if [info exists ::obj($id,famille)] {
			if {[lsearch -exact $liste_types $::obj($id,type)] >= 0} {
                if {$::obj($id,famille) == "connection"} {
                	set ::tmp($id,pid) {}
    				set ::tmp($id,infos_connexion) 0
    				dessine_connexion $id
                } else {
    				#On commence par nettoyer le répertoire d'échange dans le rep du projet
    				file delete -force $::rep_proj/datas/$id/com
    				#Vérification configuration VM virtualbox
    				if {$::obj($id,type) == "virtualbox"} {
    					set ::tmp($id,is_present) 0
    					set name [get_vbox_name $id]
    					if {$name != {}} {
    						set ::tmp($id,is_present) 1
    						if {$::obj($id,name_from_vbox)} {
    							set ::tmp($id,name) $name
    						} else {
    							set ::tmp($id,name) $::obj($id,nom)
    						}
    					}
    				}
    				set ::tmp($id,win_id) {}
    				dessine_objet $id
                }
            } else {
				#Log info type inconnu
				puts "Type unknown for $id : $::obj($id,type). Disabled"
            }
        }
    }
	
}


#Initialisation ou réinitialisation d'un projet
#efface tout si projet existant
################################################################################
proc init_projet {} {
  
  	# on initialise quelques variables
  	array unset ::obj
	set ::tmp(author) $::tcl_platform(user)
	set ::tmp(description) ""
  	set ::tmp(lastid) 0
	set ::tmp(width) $::taille(l)
	set ::tmp(height) $::taille(h)
	set ::tmp(file) "[::msgcat::mc "unnamed"].net"
	set date_time [clock seconds]
	set ::tmp(cdate) [clock format $date_time -format "%Y-%m-%d %H:%M:%S"]
	set ::tmp(date) $::tmp(cdate)
	set ::tmp(id1) {}
	set ::tmp(id2) {}
	
	# mise à jour du titre
	set :: "[::msgcat::mc "unnamed"].net"
	maj_titre
	
	#prise en compte du niveau de détail
	set ::tmp(details) $::niveau(defaut)
	change_niveau_detail $::niveau(defaut)
	
	# effacement des objets sur le canvas
	$::c delete all
	
	# mise à la taille du canvas
	wm geometry . $::tmp(width)x$::tmp(height)
	
	# nettoyage et creation du nouveau répertoire de projet
	catch {file delete -force $::rep_proj/datas}
	catch {file delete -force $::rep_proj/structure.xml}
	catch {file delete -force $::rep_proj/structure.sav}
	catch {file mkdir $::rep_proj/datas}
	
}

# Appel de la commande kill
################################################################################
proc kill {pid} {
  if {$pid != {}}  {
    catch {exec kill $pid &}
  }
}

################################################################################
proc archiver_projet {f} {
  
  # on affiche le nouveau nom du projet
  set ::tmp(file) [file tail $f]
  maj_titre
  
  # on conserve la dernière version
  if {[file exists $f]} {
    file rename -force $f $f.sav
  }
  
  # Sauvegarde de la structure
  sauvegarder_projet
  
  # Création de l'archive contenant les machines virtuelles
  exec tar -C $::rep_proj -cf $f structure.xml
  update
  # Sauvegarde de chaque machine UML
	cd $::rep_proj
  set l_rep_c [glob -nocomplain {datas/m[0-9]*}]
  foreach rep_c $l_rep_c {
    set rep [file tail $rep_c]
    # on vérifie si l'archive existe déjà ou non
    if {[file extension $rep] != ".tgz"} {
      # création de l'archive pour la machine UML
			exec tar --sparse -czf $rep_c.tgz $rep_c
			update
      # insertion dans l'archive du projet de cette nouvelle archive compressée
      exec tar -rf $f $rep_c.tgz > /dev/null
      update
      file delete $rep_c.tgz
      update
    } else  {
      # insertion dans l'archive du projet de l'archive compressée déjà existante
      exec tar -rf $f $rep_c > /dev/null
      update
    }
		
  }
}

#Charge un projet à partir d'un fichier archive
#se charge de l'initialisation
################################################################################
proc desarchiver_projet {f} {
  	
	#Nettoyage et réinitialisation espace projet
	init_projet
	
	# désarchivage dans le rep de projet
	exec tar -C $::rep_proj -xf $f
	if {[file exists $::rep_proj/datas/structure.xml]} {
		# Prise en compte version avant 2.0beta6 : déplacement fichier structure
		file rename $::rep_proj/datas/structure.xml $::rep_proj/structure.xml
		set ::tmp(cdate) $::tmp(date)
	}
	
	# ouverture du projet
	restaurer_projet
	
}


#Ajout d'une carte eth ou wifi à la machine id
#################################################################################
proc ajout_carte {id type} {
	
	# l'objet doit d'abord être arrêté
	if {$::tmp($id,etat)} {
		tk_messageBox -icon info -title [::msgcat::mc "Impossible"] -message [::msgcat::mc "You must first stop this equipment"]
		return
	}
	
	set ::obj($id,$type$::obj($id,nb_$type)) {}
	set ::obj($id,mac_${type}$::obj($id,nb_$type)) [aleatoire_mac]
	incr ::obj($id,nb_$type)
	tk_messageBox -icon info -title [::msgcat::mc "Add network card"] -message [::msgcat::mc "New network card added"]
	
}

#Suppression d'une carte eth ou wifi à la machine id
#################################################################################
proc supprime_carte {id type n} {
	
	# l'objet doit d'abord être arrêté
	if {$::tmp($id,etat)} {
		tk_messageBox -icon info -title [::msgcat::mc "Impossible"] -message [::msgcat::mc "You must first stop this equipment"]
		return
	}
	
	#suppression des connexions
	if {$::obj($id,$type$n) != {}} {
		supprimer_connexion $::obj($id,$type$n)
	}
	#effacement des données sur la carte
	unset ::obj($id,$type$n)
	unset ::obj($id,mac_${type}$n)
  incr ::obj($id,nb_$type) {-1}
	tk_messageBox -icon info -title [::msgcat::mc "Delete network card"] -message [::msgcat::mc "Network card suppressed"]
	
}

#Copie d'un ensemble de fichiers suivant un motif
##################################################################################
proc file_copy_motif {motif dest} {
	set liste  [glob -nocomplain $motif]
	foreach f $liste {
		set f_dest $dest/[file tail $f]
		if {[file isdirectory $f] && [file exists $f_dest]} {
			file_copy_motif "$f/*" $f_dest
			#file_copy_motif "$f/*" $dest/[string map {$f $dest} $f]
		} else {
			file copy -force $f $dest
		}
	}
}

# Traduit le masque en notation CIDR
# Si déjà en notation CIDR la valeur est renvoyée
################################################################################
proc calcul_mask_dec2cidr {masque} {
    set res $masque
    if [regexp  -line {^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$} $masque res] {
		set masque [split $masque "."]
		set res 0
		foreach n $masque {
				set reste $n
				for {set i 7} {$i>=0} {incr i -1} {
						set val [expr $reste / 2**$i]
						set res [expr $res + $val]
						set reste [expr $reste % 2**$i]
				}
		}
    }
	return $res
}

#Fonction qui calcule le masque décimal pointé à partir du CIDR
#Si le masque est déjà dans le format décimal pointé, il est renvoyé
################################################################################
proc calcul_mask_cidr2dec {cidr} {
    set ret $cidr
    if [regexp -line {^[0-9]{1,2}$} $cidr res] {
        set dec(1) 0
        set dec(2) 0
        set dec(3) 0
        set dec(4) 0
        
        set n [expr $cidr / 8]
        for {set i 1} {$i <= $n} {incr i} {
            set dec($i) 255
        }
        set val [expr $cidr % 8]
        set exp 7
        for {set j 1} {$j <= $val} {incr j} {
            set dec($i) [expr $dec($i) + 2**$exp]
            set exp [expr $exp - 1]
        }
        set ret "$dec(1).$dec(2).$dec(3).$dec(4)"
    }
    return $ret
}

# Renvoie l'adresse mac d'une interface sur machine hôte
#################################################################################
proc get_interface_mac {interf} {
	set ip_inf [exec /sbin/ip address show $interf]
	set regexp {link/ether ([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}).*}
	regexp $regexp $ip_inf res mac
	return $mac
}


# Renvoie l'adresse IP et masque d'une interface sur machine hôte
#################################################################################
proc get_interface_ip {interf} {
	set ip_inf [exec /sbin/ip address show $interf]
	set exp {inet ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2}).*}
	if {[regexp $exp $ip_inf res ip mask]} { 
		set ret [list $ip $mask]
	} else {
		set ret {}
	}
	return $ret
}
