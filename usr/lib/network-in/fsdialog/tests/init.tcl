set dir [file normalize [file dirname [info script]]]

lappend auto_path [file dirname $dir]

source [file join $dir utils.tcl]

testtree
