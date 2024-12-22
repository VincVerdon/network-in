####################################################################
#Programme écrit par V. Verdon
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt"
####################################################################
# Version 20241220

proc xterm {} {
    #set exe {xterm  +ai -T [wm title .] -geometry 60x20+[winfo x .]+[winfo y .] -bg $::coul(fond) -fg $::coul(texte) -fn 10x20 -fa "DejaVu Sans Mono" -fs 12}
    set exe {st -T [wm title .] -g 60x20+[winfo x .]+[winfo y .] -f "DejaVu Sans Mono-12"}
    lancer $exe
}
