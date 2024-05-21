####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version du 20240320
#ce fichier définit la façon dont sont présentés les différents composants dans l'interface

# Définition des différentes familles et de leurs composants dans l'ordre d'apparition dans l'interface
set def(liste_familles) {ordinateur hub switch routeur sortie liaison}
set def(ordinateur,liste) {pc portable serveur pctexte virtualbox}
set def(hub,liste) {hub4 hub8}
set def(switch,liste) {switch4 switch8}
set def(routeur,liste) {routeur2 routeur4}
set def(liaison,liste) {droit croise}
set def(sortie,liste) {passerelle bridge}


# Définition des noms affichés pour les différents matériels
set def(ordinateur,label) [::msgcat::mc "Computer"]
set def(hub,label)  [::msgcat::mc "Hub"]
set def(switch,label)  [::msgcat::mc "Switch"]
set def(routeur,label)  [::msgcat::mc "Router"]
set def(liaison,label)  [::msgcat::mc "Cable"]
set def(pc,label)  [::msgcat::mc "Desk computer"]
set def(portable,label)  [::msgcat::mc "Laptop"]
set def(serveur,label)  [::msgcat::mc "Server"]
set def(pctexte,label)  [::msgcat::mc "Text interface computer"]
set def(switch4,label)  [::msgcat::mc "4 ports switch"]
set def(switch8,label)  [::msgcat::mc "8 ports switch"]
set def(hub4,label)  [::msgcat::mc "4 ports hub"]
set def(hub8,label)  [::msgcat::mc "8 ports hub"]
set def(routeur2,label)  [::msgcat::mc "2 interfaces router"]
set def(routeur4,label)  [::msgcat::mc "4 interfaces router"]
set def(droit,label) [::msgcat::mc "Uncrossed cable"]
set def(croise,label) [::msgcat::mc "Crossed cable"]
set def(sortie,label)  [::msgcat::mc "Host network"]
set def(passerelle,label)  [::msgcat::mc "Real network gateway"]
set def(bridge,label)  [::msgcat::mc "Bridge"]
set def(virtualbox,label)  [::msgcat::mc "Virtualbox"]

# Définition des éléments vus en fonction du niveau d'interface
#familles
set def(ordinateur,voir) 1
set def(hub,voir) 1
set def(switch,voir) 1
set def(routeur,voir) 1
set def(liaison,voir) 1
set def(sortie,voir) 1
#éléments
set def(pc,voir) 1
set def(portable,voir) 1
set def(serveur,voir) 2
set def(switch4,voir) 1
set def(switch8,voir) 1
set def(hub4,voir) 1
set def(hub8,voir) 1
set def(routeur2,voir) 1
set def(routeur4,voir) 1
set def(droit,voir) 1
set def(croise,voir) 1
set def(sortie,voir) 2
set def(passerelle,voir) 2
set def(bridge,voir) 2
set def(virtualbox,voir) 2
set def(pctexte,voir) 2

#Description des niveaux d'interface
set def(niveau1,label) [::msgcat::mc "Beginner"]
set def(niveau2,label) [::msgcat::mc "Complete"]

# definition de couleurs et types de traits pour les connexions
set def(droit,coul) #777777
set def(droit,trait) {}
set def(croise,coul) #777777
set def(croise,trait) {8 4}
