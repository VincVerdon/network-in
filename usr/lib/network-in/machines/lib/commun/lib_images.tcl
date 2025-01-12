####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
# Fonctions utilitaires interface bureau ordinateur et routeur
####################################################################
# Version 20250106

# creation des images communes de l'interface
################################################################################
image create photo img_icone -file $::rep/images/$::icone
image create photo img_eteindre -file $::rep/images/eteindre.gif
image create photo img_annuler -file $::rep/images/annuler.gif
image create photo img_valider -file $::rep/images/valider.gif
image create photo img_config -file $::rep/images/configuration.gif
image create photo img_supprimer -file $::rep/images/supprimer.gif
image create photo img_quitter -file $::rep/images/quitter.gif
image create photo img_info -file $::rep/images/info.gif
