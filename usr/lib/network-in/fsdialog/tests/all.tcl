package require Tcl 8.6 9.0
package require Tk 8.6 9.0
package require tcltest 2.2
namespace import tcltest::*

set dir [file normalize [file dirname [info script]]]
configure {*}$argv
configure -testdir $dir
configure -loadfile [file join $dir init.tcl]
configure -singleproc 0

runAllTests
