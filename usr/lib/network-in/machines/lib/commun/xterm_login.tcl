####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20250419

# Lanceur de l'application
#####################################
proc xterm_login {} {
  source $::rep/xterm.tcl
  term::fenetre_term login
}
