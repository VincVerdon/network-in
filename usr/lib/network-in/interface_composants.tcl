####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
#Version du 20250109
#ce fichier définit la façon dont sont présentés les différents composants dans l'interface

# Définition de l'ordre d'apparition des familles de composants dans l'interface
set def(liste_familles) {computer hub switch router output connection}

# Définition des composants et famille d'appartenance
set def(computer,liste) {desktop laptop server linux virtualbox}
set def(hub,liste) {hub4 hub8}
set def(switch,liste) {switch4 switch8}
set def(router,liste) {router2 router4}
set def(output,liste) {nat bridge}
set def(connection,liste) {straight cross}

# Définition des noms affichés pour les différents matériels
set def(computer,label) [::msgcat::mc "Computer"]
set def(hub,label)  [::msgcat::mc "Hub"]
set def(switch,label)  [::msgcat::mc "Switch"]
set def(router,label)  [::msgcat::mc "Router"]
set def(connection,label)  [::msgcat::mc "Cable"]
set def(desktop,label)  [::msgcat::mc "Desk computer"]
set def(laptop,label)  [::msgcat::mc "Laptop"]
set def(server,label)  [::msgcat::mc "Server"]
set def(linux,label)  [::msgcat::mc "Linux text"]
set def(switch4,label)  [::msgcat::mc "4 ports switch"]
set def(switch8,label)  [::msgcat::mc "8 ports switch"]
set def(hub4,label)  [::msgcat::mc "4 ports hub"]
set def(hub8,label)  [::msgcat::mc "8 ports hub"]
set def(router2,label)  [::msgcat::mc "2 interfaces router"]
set def(router4,label)  [::msgcat::mc "4 interfaces router"]
set def(straight,label) [::msgcat::mc "Uncrossed cable"]
set def(cross,label) [::msgcat::mc "Crossed cable"]
set def(output,label)  [::msgcat::mc "Host network"]
set def(nat,label)  [::msgcat::mc "Real network NAT router"]
set def(bridge,label)  [::msgcat::mc "Bridge"]
set def(vm,label)  [::msgcat::mc "Virtual machine"]
set def(virtualbox,label)  [::msgcat::mc "Virtualbox VM"]

# Définition des éléments vus en fonction du niveau d'interface
#familles
set def(computer,voir) 1
set def(hub,voir) 1
set def(switch,voir) 1
set def(router,voir) 1
set def(connection,voir) 1
set def(output,voir) 1
#éléments
set def(desktop,voir) 1
set def(laptop,voir) 1
set def(server,voir) 2
set def(switch4,voir) 1
set def(switch8,voir) 1
set def(hub4,voir) 1
set def(hub8,voir) 1
set def(router2,voir) 1
set def(router4,voir) 1
set def(straight,voir) 1
set def(cross,voir) 1
set def(output,voir) 2
set def(nat,voir) 2
set def(bridge,voir) 2
set def(virtualbox,voir) 2
set def(linux,voir) 2

#Description des niveaux d'interface
set def(niveau1,label) [::msgcat::mc "Beginner"]
set def(niveau2,label) [::msgcat::mc "Complete"]

# definition de couleurs et types de traits pour les connexions
set def(straight,coul) #777777
set def(straight,trait) {}
set def(cross,coul) #777777
set def(cross,trait) {8 4}
