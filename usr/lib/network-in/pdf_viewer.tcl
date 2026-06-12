####################################################################
#Programme écrit par V. Verdon, à partir du code exemple de tclMuPDF
#Network-in est un simulateur de réseau
#placé sous licence GNU GPL (consulter le fichier joint intitulé "licence.txt")
####################################################################
# Version 20260612

namespace eval pdfviewer {
	
	variable currpage
	variable lastpage
	variable pdf
	variable w
	variable zoom

    lappend auto_path $::rep/tclMuPDF-linux64-2.5.1
    package require tkMuPDF
    
	# gestion événement scrollbar
	proc action {args} {
		if {[lindex $args 1] <0} {
			set page [prevPage]
			
		} else {
			set page [nextPage]
		}
		pdfviewer::showPage $page
	}
    
	# affichage page n (de 1 à nb de page du pdf)
    proc showPage {n} {
		incr n -1
        set page [$pdfviewer::pdf getpage $n]
        imagePage blank  ;# just in case the new page is smaller than previous
        $page saveImage imagePage -zoom $pdfviewer::zoom
		$pdfviewer::w.f.vbar set [expr ($n * 1.0) / $pdfviewer::lastpage ] [expr (($n + 1) * 1.0) / $pdfviewer::lastpage]
		$pdfviewer::w.ff.l configure -text "[expr $n + 1]/[expr $pdfviewer::lastpage + 1]"
    }
    
	# aller à la page suivante
    proc nextPage {} {
            if { $pdfviewer::currpage <= $pdfviewer::lastpage } {
                    incr pdfviewer::currpage
            }
            return $pdfviewer::currpage     
    }
    
	# aller à la page précédente
    proc prevPage {} {
            if { $pdfviewer::currpage > 1 } {
                    incr pdfviewer::currpage -1
            }
            return $pdfviewer::currpage
    }
	
	# ouvrir fichier pdf
	proc open {f} {
		set pdf [mupdf::open $f]
		set pdfviewer::currpage 1
		set pdfviewer::lastpage [expr [$pdf npages]-1]
		set pdfviewer::pdf $pdf
	}
	
	# Viewer window
	proc createViewer {w file title zoom} {
		
		set pdfviewer::w $w
		set pdfviewer::zoom $zoom
		
		pdfviewer::open $file
		
		destroy $w
		toplevel $w
		wm title $w $title
		
		frame $w.fb
		pack $w.fb -fill x
		ttk::button $w.fb.zp -image im_zoom+ -command {
			set pdfviewer::zoom [expr $pdfviewer::zoom + 0.2]
			pdfviewer::showPage $pdfviewer::currpage 
		}
		pack $w.fb.zp -side left
		ttk::button $w.fb.zm -image im_zoom- -command {
			if {$pdfviewer::zoom > 0.5} {
				set pdfviewer::zoom [expr $pdfviewer::zoom - 0.2]
			}
			pdfviewer::showPage $pdfviewer::currpage 
		}
		pack $w.fb.zm -side left
		ttk::button $w.fb.close -compound right -text [::msgcat::mc "Close"] -image im_valider -command {
		  destroy $pdfviewer::w
		}
		pack $w.fb.close -side right
		
		frame $w.f
		pack $w.f -expand 1 -fill both
		text $w.f.page -background $::coul(bg_schema) -foreground $::coul(texte) -padx 5 -pady 5
		pack $w.f.page -expand 1 -fill both -side left
		#Le texte suivant permet de centre l'image, pas d'autre moyen !
		$w.f.page insert 1.0 " " centre
		$w.f.page tag configure centre -justify center
		image create photo imagePage
		$w.f.page image create end -image imagePage
		$w.f.page configure -state disable
		
		ttk::scrollbar $w.f.vbar -command {pdfviewer::action} -orient vertical
		pack $w.f.vbar -fill y -side left
		
		frame $w.ff
		pack $w.ff -fill x
		entry $w.ff.e
		pack $w.ff.e -fill x -side left -expand 1
		$w.ff.e insert 0 $file
		$w.ff.e configure -state readonly
		label $w.ff.l
		pack $w.ff.l -side right
		
		bind $w <Key-Up> {
			set page [pdfviewer::prevPage]
			pdfviewer::showPage $page
		}
		
		bind $w <Key-Down> {
			set page [pdfviewer::nextPage]
			pdfviewer::showPage $page
		}
		
		focus $w.f.vbar
		showPage $pdfviewer::currpage
	}
	
}


