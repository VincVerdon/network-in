####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20250427

proc a_propos {} {

    set apropos "[lire_fichier_echange apropos]\n[::msgcat::mc "Equipment version"] : $::version(equipment)"
	msg_box .apropos "[::msgcat::mc "About"]..." $apropos
	positionne_fenetre .apropos .
    
}
