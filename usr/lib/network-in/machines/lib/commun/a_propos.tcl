####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20250207

proc a_propos {} {
    set apropos "[lire_fichier_echange apropos]\n[::msgcat::mc "Equipment version"] : $::version(equipment)"
    tk_messageBox -title "[::msgcat::mc "About"]..." -icon info -message $apropos
}
