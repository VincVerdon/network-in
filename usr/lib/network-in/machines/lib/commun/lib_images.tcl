####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Fonctions utilitaires interface bureau ordinateur et routeur
####################################################################
# Version 20250106

# creation des images communes de l'interface
################################################################################
image create photo im_icone -file $::rep/images/$::icone
image create photo im_eteindre -file $::rep/images/shutdown.gif
image create photo im_annuler -file $::rep/images/cancel.gif
image create photo im_valider -file $::rep/images/apply.gif
image create photo im_config -file $::rep/images/configure.gif
image create photo im_supprimer -file $::rep/images/delete.gif
image create photo im_quitter -file $::rep/images/quit.gif
image create photo im_info -file $::rep/images/info.gif
