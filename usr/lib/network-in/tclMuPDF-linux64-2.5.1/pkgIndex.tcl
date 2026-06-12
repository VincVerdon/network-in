package ifneeded tkMuPDF 2.5.1 [list apply { {dir ver} {
	source [file join $dir mupdf.tcl]
	load [mupdf::_findDLL $dir "tkMuPDF"] Mupdf
	package provide tkMuPDF $ver
}} $dir 2.5.1] ;# end of lambda apply

package ifneeded tclMuPDF 2.5.1 [list apply { {dir ver}  {
	source [file join $dir mupdf.tcl]
	load [mupdf::_findDLL $dir "tclMuPDF"] Mupdf
	package provide tclMuPDF $ver
}} $dir 2.5.1] ;# end of lambda apply

# --- Alias
package ifneeded MuPDF 2.5.1 [list apply { {dir ver}  {
	package require -exact tkMuPDF $ver
	package provide MuPDF $ver
}} $dir 2.5.1] ;# end of lambda apply
