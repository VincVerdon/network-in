####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20220930

proc a_propos {} {
    set apropos [lire_fichier_echange apropos]
    tk_messageBox -title "[::msgcat::mc "About"]..." -icon info -message $apropos
}
