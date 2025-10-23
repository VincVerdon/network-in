interp alias {} varsubst {} subst -nobackslashes -nocommands

set delay 25
#set delay 500

proc loadpackage {} {
    package require fsdialog 3

    file delete -force /tmp/fsdlg.cfg
    ttk::fsdialog configfile /tmp/fsdlg.cfg

    ttk::fsdialog preferences {*}{
	details	0
	duopane	0
	hidden	0
	mixed	0
	reverse	0
	sort	name
	columns	{name size mtime}
    }
}

# Create a directory tree to stress test the file dialogs
proc testtree {} {
    global testpath
    set testpath /tmp/fsdlg
    file delete -force $testpath
    file mkdir $testpath
    for {set mtime 1670722139; set i 1} {$i <= 25} {incr i; incr mtime 300} {
	touch [file join $testpath [format file%03d.txt $i]] $mtime
    }
    touch [file join $testpath file.txt] 1679510748
    touch [file join $testpath image.png] 1697522425
    touch [file join $testpath image.gif] 1684523292
    touch [file join $testpath image.jpg] 1692203485
    touch [file join $testpath image.svg] 1703517182
    touch [file join $testpath .hidden] 1705684672
    touch [file join $testpath ./~home] 1702049964
    touch [file join $testpath {name with spaces}] 1689298491
    file mkdir [file join $testpath home/subdir]
    touch [file join $testpath home somefile.txt] 1679692454
    file mkdir [file join $testpath empty]
    file mkdir [file join $testpath linked]
    file link [file join $testpath linked subdir] [file join $testpath empty]
    file mkdir [file join $testpath ./~user]
    file mkdir [file join $testpath {dir with spaces}]
    # Create a broken symlink
    touch [file join $testpath missing.txt]
    file link [file join $testpath severed.txt] missing.txt
    file delete [file join $testpath missing.txt]
}

proc touch {name {mtime ""}} {
    close [open $name a]
    if {$mtime ne ""} {
	file mtime $name $mtime
    }
}

proc visibility {w} {
    if {[winfo ismapped $w]} return
    bind $w <Map> [list [info coroutine] map]
    yield
    bind $w <Map> {}
}

proc sleep {{ms idle}} {
    set id [after $ms [list [info coroutine] "sleep $ms"]]
    set rc [yield]
    after cancel $id
    return $rc
}

proc elements {} {
    set w [lindex [wm stackorder .] end]
    set list {}
    while {[llength $list] < 100} {
	set w [tk_focusNext $w]
	if {$w eq [lindex $list 0]} break
	lappend list $w
    }
    return $list
}

proc keystrokes {window keys} {
    global delay
    set coro [info coroutine]
    if {$coro eq ""} {
	tailcall coroutine coro-[info cmdcount] {*}[info level 0]
    }
    sleep
    if {![winfo ismapped $window]} {
	bind $window <Map> [list $coro %W]
	while {[yield] ne $window} {}
	bind $window <Map> {}
	sleep 100
    }
    frame $window.canary
    bind $window.canary <Destroy> [list $coro gone]
    set lines [split $keys \n]
    # Discard empty lines and comments
    set lines [lsearch -all -inline -regexp -not $lines {^\s*#}]
    foreach s [concat {*}$lines] {
	switch -glob $s {
	    <<<*>>> {
		set cmd [string range $s 3 end-3]
		uplevel #0 $cmd
	    }
	    <Sleep-*> {
		if {[scan $s <Sleep-%d> ms] == 1} {
		    if {[sleep $ms] eq "gone"} break
		}
	    }
	    <*> {
		if {[sleep [expr {2 * $delay}]] eq "gone"} break
		event generate [focus] $s -when mark
	    }
	    default {
		foreach c [split $s ""] {
		    if {[sleep $delay] eq "gone"} break
		    switch $c {
			" " {set c <space>}
			"<" {set c <less>}
			">" {set c <greater>}
		    }
		    event generate [focus] $c -when mark
		}
	    }
	}
    }
    sleep
    # The keystrokes are expected to have closed the dialog
    if {[winfo exists $window]} {
	puts "Error: The dialog did not close"
	catch {bind $window.canary <Destroy> {}}
	destroy $window
    }
}

proc warp {x y {win ""} {b ""}} {
    set state 16
    if {$b ne ""} {incr state [expr {128 << $b}]}
    if {$win ne ""} {
	visibility $win
	incr x [winfo rootx $win]
	incr y [winfo rooty $win]
    }
    visibility .
    set wx [winfo rootx .]
    set wy [winfo rooty .]
    set tx [expr {$x - $wx}]
    set ty [expr {$y - $wy}]
    lassign [winfo pointerxy .] x y
    set x [expr {$x - $wx}]
    set y [expr {$y - $wy}]
    set sx [expr {$tx < $x ? -1 : 1}]
    set dx [expr {abs($x - $tx)}]
    set sy [expr {$ty < $y ? -1 : 1}]
    set dy [expr {abs($y - $ty)}]
    set n [expr {$dx - $dy}]
    set d 0
    while {$x != $tx || $y != $ty} {
	if {$n < 0} {
	    incr y $sy
	    incr n $dx
	} else {
	    incr x $sx
	    incr n -$dy
	}
	if {[incr d -1] <= 0} {
	    event generate . <Motion> -warp 1 -x $x -y $y -state $state
	    set d 20
	    sleep 10
	}
    }
    event generate . <Motion> -warp 1 -x $x -y $y -state $state
}

set bgerror {}
interp bgerror {} bgerror

proc bgerror {msg opts} {
    global bgerror
    lappend bgerror [dict get $opts -errorinfo]
}

proc collect {result} {
    global bgerror
    set id [after 100 [list set bgerror $bgerror]]
    vwait bgerror
    after cancel $id
    if {[llength $bgerror]} {
	set err "[llength $bgerror] background errors:\n[join $bgerror]"
	set bgerror {}
	return -code error $err
    }
    return $result
}

namespace eval package {
    variable hidden {}
    if {[namespace which package] ne "[namespace current]::package"} {
	# Move the original package command into the current namespace
	rename package package
    }
    # In Tcl 9, the 'package' command also has a 'files' subcommand
    namespace ensemble create -map {
	expose {expose}
	forget {package forget}
	hide {hide}
	ifneeded {package ifneeded}
	names {names}
	prefer {package prefer}
	present {package present}
	provide {package provide}
	require {require}
	unknown {package unknown}
	vcompare {package vcompare}
	versions {versions}
	vsatisfies {package vsatisfies}
    }

    proc hide {args} {
	variable hidden
	foreach n $args {
	    if {$n ni $hidden} {lappend hidden $n}
	}
    }

    proc expose {args} {
	variable hidden
	set hidden [lmap n $hidden {
	    if {$n in $args} continue
	    set n
	}]
    }

    proc names {} {
	variable hidden
	return [lmap n [package names] {
	    if {$n in $hidden} continue
	    set n
	}]
    }

    proc require {package args} {
	variable hidden
	if {$package eq "-exact"} {
	    lassign $args name
	} else {
	    set name $package
	}
	if {$name in $hidden} {
	    return -code error -errorcode {TCL PACKAGE UNFOUND} \
	      "can't find package $name"
	} else {
	    tailcall package require $package {*}$args
	}
    }

    proc versions {package} {
	variable hidden
	if {$package in $hidden} return
	tailcall package version $package
    }
}

# trace add execution vwait {enter leave} exectrace
proc exectrace {cmd args} {
    set op [lindex $args end]
    puts "$cmd ($op)"
}
