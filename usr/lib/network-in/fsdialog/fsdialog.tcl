# A file selection mega widget
# Copyright (C) Schelte Bron.  Freely redistributable.
# Version 3.0 - 12 Sep 2024

namespace eval ttk::fsdialog {
    # Need the tk::Megawidget changes that went into Tk 8.6.6
    package require Tk 8.6.6 9
    package require matchbox
    if {[catch {package require fswatch}]} {
	proc ::fswatch args {}
    }
    if {[catch {package require tooltip}]} {
	proc tooltip args {}
    } else {
	namespace import [namespace which tooltip::tooltip]
    }

    if {![package vsatisfies [package present Tk] 8.7 9]} {
	# Change the file command to behave like it does in Tcl 8.7/9
	source [file join [file dirname [info script]] compat-file.tcl]
    }

    namespace export tk_getOpenFile tk_getSaveFile tk_chooseDirectory
    namespace ensemble create -subcommands {
	preferences configfile history extensions filesystems icondir
    }

    variable config {
	prefs {
	    details	0
	    duopane	0
	    hidden	0
	    mixed	0
	    reverse	0
	    sort	name
	    columns	{name size mtime}
	}
	history {}
	filedialog {
	    geometry	700x480
	    sashpos	240
	}
	dirdialog {
	    geometry	400x380
	}
    }

    variable homedir {} defaultcfgfile {} scale [expr {96. / 72.}]

    # By default all filesystem types are allowed. This can be limited to
    # "native" when used in a starkit or starpack and the user should not
    # be allowed to peek inside the virtual file system
    variable filesystems {}
    variable extensions {}
    variable owner {} group {}
    variable iconcache {} iconfmt svg icondir \
      [file join [file dirname [file normalize [info script]]] icons]

    if {![package vsatisfies [package present Tk] 8.7 9]} {
	if {[catch {package require tksvg}]} {
	    # Will have to use png images
	    set iconfmt png
	}
    }

    namespace eval tcl::mathfunc {
	proc fpixels {window number} {
	    return [winfo fpixels $window $number]
	}

	proc pixels {window number} {
	    return [winfo pixels $window $number]
	}

	proc fit {size unit} {
	    return [expr {($size + $unit - 1) / $unit}]
	}
    }

    package require msgcat

    # Create an image for introducing some space between the icon and text
    # in a treeview widget
    image create photo [namespace current]::spacer \
      -width [winfo pixels . 2.25p] -height 1
    if {$iconfmt eq "svg"} {
	image create photo [namespace current]::increasing -format svg -data {
	    <?xml version="1.0" encoding="utf-8"?>
	    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
	    <polygon points="16,22 6,12 7.4,10.6 16,19.2 24.6,10.6 26,12"/>
	    </svg>
	}
	image create photo [namespace current]::decreasing -format svg -data {
	    <?xml version="1.0" encoding="utf-8"?>
	    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
	    <polygon points="16,10 26,20 24.6,21.4 16,12.8 7.4,21.4 6,20"/>
	    </svg>
	}
	image create photo [namespace current]::check -data {
	    <?xml version="1.0" encoding="utf-8"?>
	    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
	    <rect width="24" height="24" x="4" y="4" rx="2" \
	      style="fill:#eeeeee;stroke-width:2;stroke:#dddddd"/>
	    <polyline points="8,17 13,22 24,11" \
	      style="fill:none;stroke-width:3;stroke:#aaaaaa"/>
	    </svg>
	}
	image create photo [namespace current]::checkoff -data {
	    <?xml version="1.0" encoding="utf-8"?>
	    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
	    <rect width="24" height="24" x="4" y="4" rx="2" \
	      style="fill:#ffffff;stroke-width:2;stroke:#bbbbbb"/>
	    </svg>
	}
	image create photo [namespace current]::checkon -data {
	    <?xml version="1.0" encoding="utf-8"?>
	    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
	    <rect width="24" height="24" x="4" y="4" rx="2" \
	      style="fill:#bfe4f8;stroke-width:2;stroke:#3daee9"/>
	    <polyline points="8,17 13,22 24,11" \
	      style="fill:none;stroke-width:3;stroke:#333333"/>
	    </svg>
	}
    } else {
	image create photo [namespace current]::increasing -data {
	    iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAWklEQVQ4y+3PuwmA
	    QBBF0YMNmLhoiXZg6DZmYgcm1mOyioj4D73RwLz7mOHnc2oUB/siZRayTSBHj2pH
	    DuhQnl3RYNyUBAxor76yLrktz8QkDml+RHwj/1xkAgO8DAPiyawuAAAAAElFTkSu
	    QmCC
	}
	image create photo [namespace current]::decreasing -data {
	    iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAXElEQVQ4y+3SsQ1A
	    UBSF4S9MIFFYwCQarY2UxjKAxgZKhcQKKo08Dwmdvz7nP7e4/HxOiy4WSC/KDUoU
	    6J8uj8iRYbi65Ky8c1sSKkclySE0o8ISEKyoMf2/9TIb06IPaMV525sAAAAASUVO
	    RK5CYII=
	}
	image create photo [namespace current]::check -data {
	    iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAA90lEQVQ4y6WTPW6E
	    MBSEP/OzQkacIB1KylRY4i6cLBeIchigIGUU4SYdNRgo/NIQaaPNRpZwafkbjd/M
	    g5NHAYhIZK1tROQhkPsqy/JNKeUTAGttE0XRS5qmeQi97/s8jiPAa3I4eLxcLnmW
	    ZWG2lcqdc08A0dkZBAssy0Lbtjjnft0noXDf94gI3nviOA53cA1XVUWe5/e/sK4r
	    bdsyz3MQfCPgvcc5R9/3TNNE13WICMaYP+EbAa01xhgAhmEAwBiD1jo8hR+Roiio
	    qupf+G4KWmvqug6KNzma9blt2wwEVfl4+3G9TGocxwZ4DuzV+7FMcrbJfAMva3To
	    vPF7mAAAAABJRU5ErkJggg==
	}
	image create photo [namespace current]::checkoff -data {
	    iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAnUlEQVQ4y+2TIQ6D
	    QBBF30xwYAmijrSyJ9jgOAWX2XCLXqDhFKu4QWXTrKrZoNcyddWbYBk/7//5+QMH
	    RwC89+qcm4BLyZKqftd1XeZ53isA59zUNM2jbdu6BLBtWx6GAeBZAYjIteu6uu97
	    Ch3UMcYbgB7N4AScAIAKwMw+KaWsqkVVTill4P1/JjOTEMJkZvdC4dc4jouI2NEL
	    +AGl0SwVicH9yQAAAABJRU5ErkJggg==
	}
	image create photo [namespace current]::checkon -data {
	    iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABN0lEQVQ4y6WTP0tC
	    YRTGf+/L7Q+4RMUVUpGiGoLKL6DQV2j0A0gmRZNECBFobQ1p5lSTOPYVwqbGhBoi
	    CMqKe0VrEfRK921oCDHrDc/+e85zeJ4DA44AYFfJcMiOKiV8OpBEVcvXZok94RoA
	    4ZAdnRiVhYWxIY+OwO1bpxlZtilD0QAQLrNL48OeFd+Ilm1DCs9FtTX35WbA0Rao
	    PT+STcZoWC/dbnThk9QGrvtBx2l3rZX/gePpLN7AdP8T3msW2WQM6+lBC+4RcNot
	    GtYrhdQmN1eX5HcSKNdlPXP8I9wjYPqDxDM5AM72twGIZ3KY/qB+CqY/SOIgj29m
	    nrX00a9w3xQmpwJsHZ4ihPi7VABKcl+pO01DolXlSt1pgrr7fialROTcjoJa1GqV
	    olJe9ZYQQg3aZD4BU31y/8abE1oAAAAASUVORK5CYII=
	}
    }
    bind Magicscroll <Map> [namespace code [list map %W]]
}

proc ttk::fsdialog::mcflset {src {dest ""}} {
    ::msgcat::mcflset {*}[lassign [info level 0] cmd]
}

proc ttk::fsdialog::mcflmset {pairs} {
    ::msgcat::mcflmset $pairs
}

proc ttk::fsdialog::mc {args} {
    ::msgcat::mc {*}$args
}

proc ttk::fsdialog::posixerror {w errorcode {problem "Operation failed"} args} {
    set top [winfo toplevel $w]
    set reason [mc [string toupper [lindex $errorcode end] 0 0]]
    # Avoid multple popups for the same error. Last one wins.
    coroutine warning#$top warning $top [mc $problem {*}$args].\n$reason.
}

proc ttk::fsdialog::warning {w message} {
    set coro [list [info coroutine]]
    after cancel $coro
    after idle $coro
    yield
    protect $w {
	tk_messageBox -type ok -icon warning -parent $w -message $message
    }
}

proc ttk::fsdialog::homedir {{refresh 0}} {
    variable homedir
    global env tcl_platform
    if {$refresh} {
	if {[info exists env(HOME)] && $env(HOME) ne $homedir} {
	    try {
		set homedir [file home]
		if {![file isdirectory $homedir]} {
		    throw {TCL VALUE PATH HOMELESS} \
		      "HOME environment variable is invalid"
		}
	    } trap {TCL VALUE PATH HOMELESS} {} {
		# env(HOME) is useless. Try finding the home directory
		# another way.
		try {
		    set homedir [file home $::tcl_platform(user)]
		} on error {} {
		    # tcl_platform(user) is also useless.
		    set homedir ""
		}
	    }
	}
    }
    if {$homedir ne ""} {return $homedir}
    return -code error -errorcode {TCL VALUE PATH HOMELESS} \
      "the user's home directory is undetermined"
}

proc ttk::fsdialog::tvsee {tv item} {
    # Work around bug d82fa2953a
    # Force recalculation of the scroll area. Without this the 'see' command
    # doesn't always work right.
    $tv yview
    # The 'see' command is quite happy when only part of the item (however
    # small) is visible. A user may actually want to be able to read the item.
    $tv see $item
    # Force recalculation of the scroll area. Without this the 'bbox' command
    # doesn't always work right.
    $tv yview
    set bbox [$tv bbox $item]
    if {[llength $bbox]} {
	lassign $bbox x y w h
	set height [winfo height $tv]
	if {$y + $h > $height && $h < $height} {
	    # Bring the whole item into view
	    $tv yview scroll 1 units
	}
    } else {
	# When the height of the treeview widget is less than one line, the
	# view may be positioned one item too low. This also happens before
	# the widget is mapped for the first time (initial height is 1).
	$tv yview scroll -1 units
    }
}

proc ttk::fsdialog::protect {w body} {
    # Destroying any toplevel in the path leading up to a tk_messageBox
    # causes a segfault. As a work-around, clicking the close button on
    # any of those toplevel windows is temporarily disabled.
    set win $w
    set stack {}
    while {$win ne ""} {
	set win [winfo toplevel $win]
	lappend stack $win [wm protocol $win WM_DELETE_WINDOW]
	wm protocol $win WM_DELETE_WINDOW { }
	set win [winfo parent $win]
    }
    set rc [uplevel 1 $body]
    foreach {win cmd} $stack {
	if {[winfo exists $win]} {
	    wm protocol $win WM_DELETE_WINDOW $cmd
	}
    }
    return $rc
}

proc ttk::fsdialog::themeinit {} {
    # Not all Tk versions show a focus ring around the treeview widget
    # For consistency, remove any system focus ring and create our own
    ttk::style layout FSDialog.Treeview {
	Treeview.padding -sticky nswe -children {
	    Treeview.treearea -sticky nswe
	}
    }

    # Borderless treeview
    ttk::style configure Borderless.FSDialog.Treeview \
      -borderwidth 0 -padding 1
    if {"FSDialog.spacer" ni [ttk::style element names]} {
	set spacer [namespace which spacer]
	ttk::style element create FSDialog.spacer image [list $spacer]
    }
    ttk::style layout Borderless.FSDialog.Treeview.Item {
	Treeitem.padding -sticky nswe -children {
	    Treeitem.indicator -side left -sticky {}
	    Treeitem.image -side left -sticky {}
	    FSDialog.spacer -side left -sticky {}
	    Treeitem.text -sticky nswe
	}
    }

    # Create a treeview style without an indicator
    ttk::style configure Listbox.FSDialog.Treeview.Heading -padding {3p 0}
    ttk::style configure Listbox.FSDialog.Treeview.Item -padding {1.5p 0}
    if {"FSDialog.spacer" ni [ttk::style element names]} {
	set spacer [namespace which spacer]
	ttk::style element create FSDialog.spacer image [list $spacer]
    }
    ttk::style layout Listbox.FSDialog.Treeview.Item {
	Treeitem.padding -sticky nswe -children {
	    Treeitem.image -side left -sticky {}
	    FSDialog.spacer -side left -sticky {}
	    Treeitem.focus -side left -sticky {} -children {
		Treeitem.text -side left -sticky {}
	    }
	}
    }

    set font [ttk::style lookup FSDialog.Treeview -font {} TkDefaultFont]
    set height [font metrics $font -linespace]
    if {[lindex [increasing cget -format] 0] eq "svg"} {
	# Todo: Add fill="white" to the polygon for dark themes
	increasing configure -format [list svg -scaletoheight $height]
	decreasing configure -format [list svg -scaletoheight $height]
	check configure -format [list svg -scaletoheight $height]
	checkon configure -format [list svg -scaletoheight $height]
	checkoff configure -format [list svg -scaletoheight $height]
    }
    ttk::style configure FSDialog.Treeview \
      -rowheight [expr {$height + pixels(".", "1.5p")}]
}

proc ttk::fsdialog::extensions {{spec {}}} {
    variable extensions
    if {[llength [info level 0]] < 2} {
	return $extensions
    }
    set extensions $spec
    return
}

proc ttk::fsdialog::filesystems {{systems {}}} {
    variable filesystems
    if {[llength [info level 0]] < 2} {
	return $filesystems
    }
    set filesystems $systems
    return
}

proc ttk::fsdialog::icondir {{path {}}} {
    variable icondir
    if {[llength [info level 0]] < 2} {
	return $icondir
    }
    set icondir $path
    return
}

proc ttk::fsdialog::tk_getOpenFile {args} {
    try {
	return [dialog getOpenFile __ttk_filedialog $args]
    } on error {msg opts} {
	# Clean up the stack trace that's returned to the caller
	return -options $opts -level 1 -errorinfo "" $msg
    }
}

proc ttk::fsdialog::tk_getSaveFile {args} {
    try {
	return [dialog getSaveFile __ttk_filedialog $args]
    } on error {msg opts} {
	# Clean up the stack trace that's returned to the caller
	return -options $opts -level 1 -errorinfo "" $msg
    }
}

proc ttk::fsdialog::tk_chooseDirectory {args} {
    try {
	return [dialog chooseDirectory __ttk_dirdialog $args]
    } on error {msg opts} {
	# Clean up the stack trace that's returned to the caller
	return -options $opts -level 1 -errorinfo "" $msg
    }
}

proc ttk::fsdialog::readcfg {} {
    variable cfgfile
    variable cfgtime
    variable config
    try {
	if {[file readable $cfgfile] && [file mtime $cfgfile] > $cfgtime \
	  && ![catch {open $cfgfile RDONLY} fd]} {
	    set data [read $fd]
	    close $fd
	    set cfgtime [file mtime $cfgfile]
	    catch {
		if {[dict exists $data history]} {
		    set history [lmap n [dict get $data history] {
			set file [string trimleft [normalize $n]]
			if {$file eq ""} continue
			set file
		    }]
		    dict set config history $history
		}
	    }
	    catch {
		dict set data prefs \
		  [dict remove $data history filedialog dirdialog]
	    }
	    foreach n {prefs filedialog dirdialog} {
		catch {
		    if {![dict exists $data $n]} continue
		    set merge [dict merge [dict get $config $n] [dict get $data $n]]
		    foreach k [dict keys [dict get $config $n]] {
			dict set config $n $k [dict get $merge $k]
		    }
		}
	    }
	} elseif {$cfgtime == 0} {
	    set cfgtime [clock seconds]
	}
	if {[llength [dict get $config history]] == 0} {
	    set history {}
	    foreach n [list / ~/.. ~ ~/Documents ~/Desktop [pwd]] {
		set dir [normalize $n]
		if {$dir ni $history} {lappend history $dir}
	    }
	    dict set config history $history
	}
    } trap {POSIX} {} {
	# Possibly: POSIX ENOENT, POSIX EACCES, POSIX ENAMETOOLONG
	# Disregard file access issues
    }
    return $config
}

proc ttk::fsdialog::savecfg {} {
    variable cfgfile
    variable config
    # Only save the configuration if the file already exists
    if {$cfgfile eq ""} return
    if {[catch {open $cfgfile {WRONLY TRUNC}} fd]} return
    dict for {key val} [dict get $config prefs] {
	puts $fd [list $key $val]
    }
    append hist \n "    " [join [dict get $config history] "\n    "] \n
    puts $fd [list history $hist]
    foreach n {filedialog dirdialog} {
	set str ""
	set settings [lmap {key val} [dict get $config $n] {
	    list $key $val
	}]
	append str \n "    " [join $settings "\n    "] \n
	puts $fd [list $n $str]
    }
    close $fd
    variable cfgtime [clock seconds]
}

proc ttk::fsdialog::history {args} {
    variable config
    set history [dict get $config history]
    if {[llength $args] == 0} {
	return $history
    }
    set list [lmap entry $args {
	set path [normalize $entry]
	set history [lsearch -all -inline -exact -not $history $path]
	set path
    }]
    dict set config history [lrange [linsert $history 0 {*}$list] 0 49]
    return
}

proc ttk::fsdialog::histdirs {{size 10}} {
    # Only return existing directories
    set rc {}
    foreach n [history] {
	if {[file isdirectory $n]} {
	} elseif {[file isfile $n]} {
	    set n [file dirname $n]
	} else {
	    continue
	}
	if {$n ni $rc} {lappend rc $n}
    }
    return [lrange $rc 0 [expr {$size - 1}]]
}

proc ttk::fsdialog::fontwidth {font args} {
    return [::tcl::mathfunc::max {*}[lmap str $args {font measure $font $str}]]
}

proc ttk::fsdialog::geometry {dlg args} {
    variable config
    if {$dlg ni {filedialog dirdialog}} {
	error "invalid dialog: \"$dlg\"; must be: filedialog or dirdialog"
    }
    set data [dict get $config $dlg]
    set argc [llength $args]
    if {$argc == 0} {
	return $data
    } elseif {$argc == 1} {
	set arg [lindex $args 0]
	if {[dict exists $data $arg]} {
	   return [dict get $data $arg]
       } else {
	   error "unknown option: \"$arg\""
       }
   } elseif {$argc % 2 == 0} {
	set merge [dict merge $data $args]
	if {[dict size $merge] > [dict size $data]} {
	    error "unknown preference name:\
	      \"[lindex [dict keys $merge] [dict size $data]]\""
	}
	dict set config $dlg $merge
    } else {
	error "missing value for option: \"[lindex $args end]\""
    }
    return
}

# Convert a native file name (no change on linux/macOS)
proc ttk::fsdialog::filename {str} {
    return $str
}

proc ttk::fsdialog::path {dir name} {
    if {[string index $dir end] eq "/"} {
	return [string cat $dir $name]
    } else {
	return [string cat $dir / $name]
    }
}

# Check if a directory should be excluded
proc ttk::fsdialog::skip {dir} {
    variable filesystems
    if {[llength $filesystems]} {
	return [expr {[lindex [file system $dir] 0] ni $filesystems}]
    }
    return 0
}

proc ttk::fsdialog::globall {path {types {}}} {
    return [glob -nocomplain -types $types -path $path *]
}

proc ttk::fsdialog::dirmatchcommand {dir str} {
    if {$str eq ""} return
    try {
	set path [normalize $str $dir]
    } trap {TCL VALUE PATH NOUSER} {} {
	set path [normalize ./$str $dir]
    }
    if {[string index $str end] eq "/"} {
	set base $path
	append path /
    } else {
	set base [file dirname $path]
    }
    set list [if {[file readable $base]} {
	lsort -dictionary [globall $path d]
    }]
    return [lmap n $list {file nativename $n}]
}

proc ttk::fsdialog::filematchcommand {dir str} {
    if {$str eq ""} return
    if {[file pathtype $str] eq "relative" || [string index $str 0] eq "~"} {
	set l [expr {[string length $dir] + 1}]
	set str $dir/$str
    } else {
	set l 0
    }
    # Add a dot to correctly handle strings with a trailing '/'
    set list [if {[file readable [file dirname $str.]]} {
	lmap n [globall $str] {string range $n $l end}
    }]
    return [lsort -dictionary $list]
}

# Check if a directory has any subdirectories, other than . and ..
proc ttk::fsdialog::subdirs {dir} {
    if {[skip $dir]} {return 0}
    # Quick check: If a directory has more than 2 links, it definitely
    # contains one or more subdirectories
    if {[dict get [file stat $dir] nlink] > 2} {return 1}
    # There either are no real directories, or we're running on Windows
    # Even on linux, there may still be symbolic links to directories
    # No need for -nocomplain, as this should always return at least . and ..
    if {[catch {llength [glob -types d -directory $dir * .*]} nlink]} {
	# Possible reason: POSIX EACCES {permission denied}
	return 0
    }
    return [expr {$nlink > 2}]
}

proc ttk::fsdialog::ownership {name} {
    variable owner
    variable group
    file lstat $name stat
    set attr [file attributes $name]
    if {[dict exists $attr -owner]} {
	dict set owner $stat(uid) [dict get $attr -owner]
    } else {
	dict set owner $stat(uid) $stat(uid)
    }
    if {[dict exists $attr -group]} {
	dict set group $stat(gid) [dict get $attr -group]
    } else {
	dict set group $stat(gid) $stat(gid)
    }
}

proc ttk::fsdialog::value {name val} {
    return $val
}

proc ttk::fsdialog::date {name val} {
    return [clock format $val -format {%Y-%m-%d %T}]
}

proc ttk::fsdialog::mode {name val} {
    # The figure dash most closely matches the width of a lower case letter
    set dash \u2012
    set chars [lrepeat 10 $dash]
    foreach {mask pos char} {
	0o000400 1 r	0o000200 2 w	0o000100 3 x
	0o000040 4 r	0o000020 5 w	0o000010 6 x
	0o000004 7 r	0o000002 8 w	0o000001 9 x
	0o004000 1 s	0o002000 5 s	0o001000 8 t
	0o040000 0 d	0o020000 0 c	0o010000 0 p
	0o140000 0 s	0o120000 0 l	0o060000 0 b
    } {
	if {($val & $mask) == $mask} {lset chars $pos $char}
    }
    return [join $chars ""]
}

proc ttk::fsdialog::owner {name val} {
    variable owner
    if {![dict exists $owner $val]} {ownership $name}
    return [dict get $owner $val]
}

proc ttk::fsdialog::group {name val} {
    variable group
    if {![dict exists $group $val]} {ownership $name}
    return [dict get $group $val]
}

proc ttk::fsdialog::hidden {file} {
    return [string equal -length 1 [file tail $file] .]
}

# Alternative implementation of some procs when running on other platforms
if {$::tcl_platform(platform) eq "windows"} {
    proc ttk::fsdialog::globall {path {types {}}} {
	set rc [glob -nocomplain -types $types -path $path *]
	lappend types hidden
	lappend rc {*}[glob -nocomplain -types $types -path $path *]
    }

    # Convert a native file name (change backslash to forward slash)
    proc ttk::fsdialog::filename {str} {
	return [file join {*}[file split $str]]
    }
}
if {$::tcl_platform(platform) eq "windows" \
  || $::tcl_platform(os) in {MacOS Darwin}} {
    proc ttk::fsdialog::hidden {file} {
	return [file attributes $file -hidden]
    }
}

if {[tk windowingsystem] eq "x11"} {
    # Fix a misguided feature that causes a combobox to mess up the primary
    # selection for no good reason
    proc ttk::combobox::TraverseIn {w} {
	$w instate {!readonly !disabled} {
	    # $w selection range 0 end
	    $w icursor end
	}
    }

    proc ttk::combobox::SelectEntry {cb index} {
	$cb current $index
	# $cb selection range 0 end
	$cb icursor end
	event generate $cb <<ComboboxSelected>> -when mark
    }
}

# Should the iconcache be cleared when tk scaling is changed?
# trace add execution ::tk::scaling leave {apply {{cmd code result op} {}}}

proc ttk::fsdialog::icon {size args} {
    variable iconcache
    variable scale

    set name [lindex $args 0]
    if {[dict exists $iconcache $size $name]} {
	return [dict get $iconcache $size $name]
    }
    set file [xdgicon find $size {*}$args]
    if {$file eq ""} {
	if {$name ne "image-missing"} {
	    return [icon $size image-missing emblem-unreadable]
	}
	# Should this actually throw an error?
	set len [expr {round($size * $scale)}]
	set icon [image create photo -width $len -height $len]
    } else {
	if {[file extension $file] eq ".svg"} {
	    set format [list svg -scaletoheight [expr {round($size * $scale)}]]
	} else {
	    set format [list png]
	}
	set icon [image create photo -format $format -file $file]
    }
    dict set iconcache $size $name $icon
    return $icon
}

proc ttk::fsdialog::dim {image} {
    return [image create photo \
      -data [$image data -format png] -format {png -alpha 0.3}]
}

# Create a list of files and directories
proc ttk::fsdialog::ls {dir {filter {}}} {
    if {[skip $dir]} return
    set rc {}
    foreach types [list $filter [linsert $filter end hidden]] hidden {0 1} {
	# Don't use the -tails option. It is slow.
	foreach f [glob -nocomplain -types $types -directory $dir *] {
	    if {[file tail $f] in {. ..}} continue
	    try {
		lappend rc [stat $f $hidden]
	    } trap {POSIX ENOENT} {} {
		# The file has been deleted after running the glob command
	    }
	}
    }
    return $rc
}

proc ttk::fsdialog::stat {path {hidden ""}} {
    variable extensions
    set name [file tail $path]
    file lstat $path stat
    if {$stat(type) eq "link" && [file exists $path]} {
	file stat $path stat
    }
    if {$stat(type) eq "directory"} {
	variable homedir
	if {$path eq $homedir} {
	    set icon {user-home folder}
	} else {
	    set icon folder
	}
    } else {
	set ext [file extension $name]
	if {[dict exists $extensions $ext]} {
	    set icon [dict get $extensions $ext]
	} else {
	    set icon text-x-generic
	}
    }
    if {$hidden eq ""} {set hidden [hidden $path]}
    return [list $path $name $stat(type) $stat(size) $stat(mode) \
      $stat(mtime) $stat(atime) $stat(ctime) $stat(uid) $stat(gid) \
      $stat(ino) $stat(dev) $hidden $icon]
}

# Sort a list of files and directories
proc ttk::fsdialog::sort {list prefs} {
    set opts {}
    switch [dict get $prefs sort] {
	size {
	    lappend opts -index 3 -integer
	}
	mtime - date {
	    lappend opts -index 5 -integer 
	}
	atime {
	    lappend opts -index 6 -integer
	}
	ctime {
	    lappend opts -index 7 -integer
	}
	uid {
	    lappend opts -index 8 -integer
	}
	gid {
	    lappend opts -index 9 -integer
	}
	inode {
	    lappend opts -index 10 -integer
	}
	default {
	    lappend opts -index 1 -dictionary
	}
    }
    if {[dict get $prefs reverse]} {
	lappend opts -decreasing
    }
    return [lsort {*}$opts $list]
}

proc ttk::fsdialog::normalize {str {cwd .}} {
    # Normalize a user provided file name. This differs from a regular
    # normalize in the following respects:
    # - Tilde expansion is performed
    # - Symbolic links (and short names on Windows) are kept
    set path [file normalize $cwd]
    try {
	set str [file tildeexpand $str]
    } trap {TCL VALUE PATH} {} {
	# The user doesn't exist or the home directory could not be determined
    }
    foreach s [file split $str] {
	switch -glob $s {
	    / {set path ""}
	    . {}
	    .. {regsub {(.*)/.*} $path {\1} path}
	    default {append path / $s}
	}
    }
    if {$path eq ""} {set path /}
    return $path
}

proc ttk::fsdialog::magicscroll {w min max} {
    if {$min <= 0 && $max >= 1} {
	grid remove $w
    } else {
	$w set $min $max
	grid $w
    }
}

proc ttk::fsdialog::map {w} {
    # Magic borrowed from tklib's autoscroll
    #Suppression par VV pour placement fenêtre au centre
    #wm geometry [winfo toplevel $w] [wm geometry [winfo toplevel $w]]
}

proc ttk::fsdialog::dialog {cmd child arglist} {
    variable result
    variable scale
    set resolution [expr {[tk scaling] * 72 / 96}]
    if {$resolution != $scale} {
	variable iconcache
	# Assume at most one dialog is in use at any given time
	# Alternative: Update the images to versions at the new scale
	dict for {size map} $iconcache {
	    dict for {name image} $map {image delete $image}
	}
	set iconcache {}
	set scale $resolution
	xdgicon scale $scale
    }
    if {[llength $arglist] % 2 == 0 && [dict exists $arglist -parent]} {
	set parent [dict get $arglist -parent]
    } else {
	set parent .
    }
    if {[winfo exists $parent]} {
	if {$parent eq "."} {
	    set w .$child
	} else {
	    set w $parent.$child
	}
    } else {
	return -code error "bad window path name \"$parent\""
    }
    set var [namespace which -variable result]($w)
    set result($w) ""
    try {
	$cmd $w -resultvariable $var {*}$arglist
	wm transient $w $parent
	tkwait window $w
	return $result($w)
    } finally {
	unset result($w)
    }
}

proc ttk::fsdialog::configfile {{name ""}} {
    variable cfgfile
    if {[llength [info level 0]] > 1} {
	set cfgfile $name
	return
    } else {
	return $cfgfile
    }
}

proc ttk::fsdialog::preferences {args} {
    variable config
    variable cfgtime
    if {$cfgtime == 0} readcfg
    set prefs [dict get $config prefs]
    set argc [llength $args]
    if {$argc == 0} {
	return $prefs
    } elseif {$argc == 1} {
	set arg [lindex $args 0]
	if {[dict exists $prefs $arg]} {
	    return [dict get $prefs $arg]
	} else {
	    error "unknown preference name: \"$arg\""
	}
    } elseif {$argc % 2 == 0} {
	set merge [dict merge $prefs $args]
	if {[dict size $merge] > [dict size $prefs]} {
	    error "unknown preference name:\
	      \"[lindex [dict keys $merge] [dict size $prefs]]\""
	}
	dict set config prefs $merge
	savecfg
    } else {
	error "missing value for preference: \"[lindex $args end]\""
    }
    return
}

# Poor man's implemantation of xdgicons
namespace eval ttk::fsdialog::xdgicon {
    variable icondir \
      [file join [file dirname [file normalize [info script]]] icons]
    variable scale 1 sizes {16 16 22 22 32 32 48 48}
    variable formats {svg png}

    msgcat::mcload [file join [file dirname [info script]] msgs]
}

proc ttk::fsdialog::xdgicon::scale {val} {
    variable scale $val
    variable sizes
    set l 0
    set sizelist [lmap n [dict keys $sizes] {
	try {
	    list $n [expr {($l + $n) / 2}]
	} finally {
	    set l $n
	}
    }]
    foreach n [dict keys $sizes] {
	set v [expr {round($n * $scale)}]
	set x [lsearch -integer -bisect -index 1 $sizelist $v]
	dict set sizes $n [lindex $sizelist $x 0]
    }
}

proc ttk::fsdialog::xdgicon::find {size args} {
    variable sizes
    variable formats
    variable icondir
    set target [dict get $sizes $size]
    # SVG icons don't look very good when scaled down too much. For such
    # small icons the specifically designed PNG versions are preferred.
    if {$target >= 32 && "svg" in $formats} {
	set sizedir scalable
    } else {
	set sizedir [format {%dx%d} $target $target]
    }
    set path [file join $icondir Tango-fsd $sizedir]
    foreach icon $args {
	foreach dir [glob -nocomplain -directory $path -types d *] {
	    set root [file join $dir $icon.]
	    foreach file [glob -nocomplain -path $root {*}$formats] {
		return $file
	    }
	}
    }
    return
}

namespace eval ttk::fsdialog {
    try {
	set home [homedir 1]
	set defaultcfgfile [file join $home .config tcltk fsdialog.cfg]
    } trap {TCL VALUE PATH HOMELESS} {} {
	# Don't have a valid home directory
    }
    variable cfgfile $defaultcfgfile cfgtime 0

    if {[namespace which xdgicon] eq ""} {
	namespace eval xdgicon {
	    namespace ensemble create \
	      -subcommands {find basedirs themes scale cache imageformats}
	}
    }
}

::tk::Megawidget create ::ttk::fsdialog::scrollwidget {} {
    variable options

    constructor {args} {
	namespace path [linsert [namespace path] end ::ttk::fsdialog]
	next {*}$args
    }

    method GetSpecs {} {
	return {
	    {-cursor cursor Cursor {}}
	    {-height height Height 300}
	    {-takefocus takeFocus TakeFocus ::ttk::takefocus}
	    {-width width Width 200}
	}
    }

    method CreateHull {} {
	my variable w
	ttk::frame $w -style TEntry -padding 2 -takefocus 0 \
	  -width $options(-width) -height $options(-height)
	grid propagate $w 0
	variable hull [my CreateInner]
	ttk::scrollbar $w.vscroll -orient vertical -command [list $hull yview]
	ttk::scrollbar $w.hscroll -orient horizontal -command [list $hull xview]
	# Include bindings that are placed on the outer widget path
	# bindtags $hull [linsert [bindtags $hull] 2 $w]
	foreach widget [list $w.vscroll $w.hscroll] {
	    bindtags $widget [linsert [bindtags $widget] 1 Magicscroll]
	}
	$hull configure \
	  -yscrollcommand [list [namespace which magicscroll] $w.vscroll] \
	  -xscrollcommand [list [namespace which magicscroll] $w.hscroll]
	grid $hull $w.vscroll -sticky ns
	grid $w.hscroll -sticky ew
	grid $hull -sticky nsew
	grid columnconfigure $w $hull -weight 1
	grid rowconfigure $w $hull -weight 1
	bind $w <FocusIn> [namespace code [list my Focus focus]]
	bind $w <FocusOut> [namespace code [list my Focus !focus]]
    }

    method CreateInner {} {
	return [text $w.t]
    }

    method Focus {state} {
	my variable hull
	theWidget state $state
	if {$state eq "focus"} {
	    focus $hull
	}
    }

    method cget {option} {
	if {[info level] > 1 && $option eq "-takefocus"} {
	    # Make keyboard traversal skip the outer frame
	    if {[lindex [info level -1] 0] eq "tk::FocusOK"} {return 0}
	}
	next $option
    }
}

::tk::Megawidget create ::ttk::fsdialog::checklist \
  ::ttk::fsdialog::scrollwidget {
    variable hull
    method GetSpecs {} {
	return {
	    {-height height Height 80p}
	    {-title title Title ""}
	    {-width width Width 150p}
	}
    }

    method CreateInner {} {
	my variable w
	return [ttk::treeview $w.tv -style Listbox.FSDialog.Treeview \
	  -selectmode none]
    }

    method Create {} {
	my variable options
	$hull tag configure disabled -image [namespace which check] \
	  -foreground #cccccc
	$hull tag configure checked -image [namespace which checkon]
	$hull tag configure default -image [namespace which checkoff]
	if {$options(-title) ne ""} {
	    $hull configure -show {tree heading}
	    $hull heading #0 -text $options(-title)
	} else {
	    $hull configure -show tree
	}
	$hull column #0 -width 10
	bind $hull <1> [list [namespace which my] Button1 %x %y]
	bind $hull <space> [list [namespace which my] Toggle]
	bind $hull <Home> [namespace code {my Cursor}]
	bind $hull <End> [namespace code {my Cursor}]
	bind $hull <Prior> [namespace code {my Cursor}]
	bind $hull <Next> [namespace code {my Cursor}]
	bind $hull <<PrevLine>> [namespace code {my Cursor}]
	bind $hull <<NextLine>> [namespace code {my Cursor}]
	bind $hull <<PrevChar>> [namespace code {my Cursor}]
	bind $hull <<NextChar>> [namespace code {my Cursor}]
    }

    method Button1 {x y} {
	set id [$hull identify item $x $y]
	$hull focus $id
	my Toggle
    }

    method Toggle {} {
	set id [$hull focus]
	if {![$hull tag has disabled $id]} {
	    my selection toggle [list $id]
	}
    }

    method Cursor {} {
	if {[$hull focus] eq ""} {
	    set focus [lindex [$hull children {}] 0]
	    if {$focus ne {}} {
		tvsee $hull $focus
		$hull focus $focus
	    }
	    return -code break
	}
	after idle \
	  [format {%1$s %2$s [%2$s focus]} [namespace which tvsee] $hull]
    }

    method add {args} {
	my insert end {*}$args
    }

    method insert {index args} {
	foreach {op val} $args {
	    switch -- $op {
		-id - -text {continue}
		-state {
		    if {$val in {disabled}} {
			dict lappend args -tags $val
		    }
		}
	    }
	    dict unset args $op
	}
	dict lappend args -tags default
	$hull insert {} $index {*}$args
    }

    method selection {{op get} {list ""}} {
	switch $op {
	    get {
		return [$hull tag has checked]
	    }
	    set {
		$hull tag remove checked
		$hull tag add checked $list
	    }
	    add {
		$hull tag add checked $list
	    }
	    remove {
		$hull tag remove checked $list
	    }
	    toggle {
		# Add the checked tag to items in the list that are not checked
		$hull tag add add $list
		$hull tag remove add [$hull tag has checked]
		$hull tag add checked [$hull tag has add]
		# Remove the checked tag from checked items in the list
		$hull tag add delete $list
		$hull tag remove delete [$hull tag has add]
		$hull tag remove checked [$hull tag has delete]
		# Clean up helper tags
		$hull tag remove add
		$hull tag remove delete
	    }
	}
	return
    }
}

::tk::Megawidget create ::ttk::fsdialog::dirlist ::ttk::fsdialog::scrollwidget {
    variable hull options
    constructor {args} {
	variable fd [fswatch create [list [namespace which my] Watch]]
	variable watch {}
	next {*}$args
    }

    destructor {
	my variable fd
	fswatch close $fd
	next
    }

    method GetSpecs {} {
	return {
	    {-cursor cursor Cursor {}}
	    {-height height Height 375p}
	    {-hidden hidden Hidden 0}
	    {-selectmode selectMode SelectMode browse}
	    {-takefocus takeFocus TakeFocus 0}
	    {-title {} {} {}}
	    {-width width Width 200p}
	    {-xscrollcommand xScrollCommand ScrollCommand {}}
	    {-yscrollcommand yScrollCommand ScrollCommand {}}
	}
    }

    method CreateInner {} {
	my variable w
	themeinit
	return [ttk::treeview $w.tv -style Borderless.FSDialog.Treeview \
	  -selectmode browse -columns {name width watch} -displaycolumns {}]
    }

    method Create {} {
	my variable w
	if {$options(-title) eq ""} {
	    $hull configure -show tree
	} else {
	    $hull configure -show {tree headings}
	    $hull heading #0 -text $options(-title) -anchor w
	}
	$hull tag configure dir -image [icon 16 folder]
	$hull column #0 -width 40 -stretch 1
	# Create a detached item to host all hidden items
	$hull detach [list [my Make {} hidden]]
	bind $hull <<TreeviewOpen>> [list [namespace which my] Open]
	bind $hull <<TreeviewClose>> [list [namespace which my] Close]
	bind $hull <<TreeviewSelect>> \
	  [list event generate $w <<ListboxSelect>>]
	bind $hull <Return> \
	  "[list event generate $w <<DirectorySelect>>];break"
	bind $hull <<ThemeChanged>> [namespace which themeinit]
	my set /
    }

    method Open {} {
	my open [$hull focus]
    }

    method Close {} {
	my close [$hull focus]
    }

    method Resize {item} {
	set width [font measure TkDefaultFont [$hull item $item -text]]
	# Find if the item has any icon
	set img [$hull item $item -image]
	foreach tag [$hull item $item -tags] {
	    if {$img ne ""} break
	    set img [$hull tag configure $tag -image]
	}
	if {$img ne ""} {incr width [image width $img]}
	if {[$hull item $item -open]} {
	    # I haven't found a way to determine the actual size of the indicator
	    set offset 20
	    set width [tcl::mathfunc::max {*}[lmap n [$hull children $item] {
		expr {$offset + [$hull set $n width]}
	    }] $width]
	}
	if {$width != [$hull set $item width]} {
	    $hull set $item width $width
	    set parent [$hull parent $item]
	    if {$parent ne $item} {
		my Resize $parent
	    } else {
		$hull column #0 -minwidth $width -width $width
	    }
	}
    }

    method TreeItem {name} {
	if {![$hull exists $name]} {
	    if {![file exists $name]} {
		throw {POSIX ENOENT {no such file or directory}} \
		  "couldn't read directory \"$name\":\
		  no such file or directory"
	    } elseif {![file isdirectory $name]} {
		throw {POSIX ENOTDIR {not a directory}} \
		  "couldn't read directory \"$name\":\
		  not a directory"
	    }
	    set parent [file dirname $name]
	    if {$parent ne $name} {
		try {
		    my TreeItem $parent
		} trap {POSIX EACCES} {} {
		    # Special treatment if the parent directory is not readable
		    my Make $parent $name [file tail $name] {dir open}
		    set dot [file join $parent .]
		    if {[$hull exists $dot]} {$hull delete $dot}
		    my open $parent
		}
	    } else {
		foreach n [file volumes] {
		    my Make {} $n [file nativename $n] dir
		    my Make $n $n.
		}
	    }
	}
	my Glob $name
	return $name
    }

    method Make {item dir {name ""} {tags ""} {pos end}} {
	my variable fd watch
	set open [expr {"open" in $tags}]
	$hull insert $item $pos -id $dir \
	  -text $name -values [list $name 0] -open $open -tags $tags
	if {$name ne "" && [file readable $dir]} {
	    set id [fswatch add $fd $dir \
	      {create delete move deleteself moveself}]
	    $hull set $dir watch $id
	    dict set watch $id $dir
	}
	my Resize $dir
	return $dir
    }

    method Glob {dir} {
	my variable fd watch
	set list [lsort -dictionary -index 0 [ls $dir d]]
	$hull tag add delete [$hull children $dir]
	set w [$hull column #0 -width]
	set children [lmap d $list {
	    set id [lindex $d 0]
	    set name [lindex $d 1]
	    set hidden [lindex $d 12]
	    if {[$hull exists $id]} {
		$hull tag remove delete [list $id]
	    } else {
		my Make $dir $id $name dir
	    }
	    if {$hidden} {
		$hull tag add hidden [list $id]
	    } else {
		$hull tag remove hidden [list $id]
	    }
	    if {[llength [$hull children $id]] == 0} {
		if {![$hull tag has visited $id] && [subdirs $id]} {
		    # Cause the indicator to be shown. The real contents will
		    # be generated when the item is opened
		    my Make $id [file join $id .]
		}
	    }
	    if {$hidden && !$options(-hidden)} {
		$hull move $id hidden end
		continue
	    }
	    set id
	}]
	$hull delete [$hull tag has delete]
	$hull children $dir $children
	
	$hull tag add visited [list $dir]
    }

    method Refresh {{dir /}} {
	try {
	    my Glob $dir
	} trap {POSIX EACCES} {} {
	    # Directory is not readable, but known subdirectories may be
	}
	foreach item [$hull children $dir] {
	    # Closed items will be refreshed when they are opened
	    try {
		if {[$hull item $item -open]} {
		    my Refresh $item
		} elseif {![subdirs $item]} {
		    $hull delete [$hull children $item]
		} else {
		    set placeholder [file join $item .]
		    if {![$hull exists $placeholder]} {
			my Make $item $placeholder
		    }
		}
	    } trap {POSIX ENOENT} {} {
		# Item no longer exists
		$hull delete [list $item]
	    } trap {POSIX EACCES} {} {
		# Directory is no longer readable
		$hull delete [$hull children $item]
	    } trap {POSIX} {} {
		# Ignore other file access issues
	    }
	}
    }

    method Hide {} {
	set hidden [list {*}[$hull children hidden] {*}[$hull tag has hidden]]
	$hull children hidden $hidden
    }

    method Unhide {} {
	foreach item [$hull children hidden] {
	    set parent [file dirname $item]
	    $hull move $item $parent end
	    $hull tag add sort $parent
	    try {
		my Refresh $item
	    } trap {POSIX ENOENT} {} {
		$hull delete $item
	    } trap {POSIX EACCES} {} {
		$hull delete [$hull children $item]
	    } trap POSIX {} {
	    }
	}
	foreach item [$hull tag has sort] {
	    $hull children $item [lsort -dictionary [$hull children $item]]
	}
	$hull tag remove sort
    }

    method Watch {event} {
	my variable fd watch
	set id [dict get $event watch]
	if {[dict get $event isdir] == 0} {
	    if {[dict get $event event] eq "ignored"} {
		fswatch remove $fd $id
		dict unset watch $id
	    }
	    return
	}
	if {![dict exists $watch $id]} return
	set dir [dict get $watch $id]
	set name [dict get $event name]
	set node [path $dir $name]
	try {
	    switch [dict get $event event] {
		delete - movedfrom {
		    if {[$hull tag has visited $dir]} {
			set cwd [lindex [$hull selection] 0]
			$hull delete [list $node]
			while {![$hull exists $cwd]} {
			    if {$cwd eq [set cwd [file dirname $cwd]]} break
			    if {[$hull exists $cwd]} {
				$hull selection set [list $cwd]
			    }
			}
		    } elseif {![subdirs $dir]} {
			$hull delete [list [file join $dir .]]
		    }
		}
		create - movedto {
		    set list [lmap n [$hull children $dir] {$hull set $n name}]
		    set x [lsearch -bisect -dictionary $list $name]
		    if {[$hull tag has visited $dir]} {
			if {![$hull exists $node]} {
			    my Make $dir $node $name dir [incr x]
			    if {[hidden $node]} {
				$hull tag add hidden $node
				if {!$options(-hidden)} {
				    $hull move $node hidden end
				}
			    }
			}
			if {[subdirs $node]} {
			    my Make $node [file join $node .]
			}
		    } else {
			set node [file join $dir .]
			if {![$hull exists $node]} {
			    my Make $dir $node
			}
		    }
		}
	    }
	} trap POSIX {} {
	    # Ignore file access problems
	}
    }

    method configure {args} {
	if {[llength $args] < 2} {
	    return [next {*}$args]
	}
	set saved [array get options]
	next {*}$args
	dict for {key val} $args {
	    if {$val ne [dict get $saved $key]} {
		switch $key {
		    -hidden {
			if {$val} {my Unhide} else {my Hide}
		    }
		}
	    }
	}
    }

    method close {dir} {
	$hull item $dir -open false
	# $hull tag remove open [list $dir]
	my Resize $dir
    }

    method open {dir} {
	$hull item $dir -open true
	try {
	    my Refresh $dir
	    my Resize $dir
	} trap {POSIX ENOENT} {} {
	    $hull delete $dir
	} trap {POSIX EACCES} {} {
	    $hull delete [$hull children $dir]
	} trap POSIX {} {
	}
    }

    method set {dir} {
	try {
	    set dir [normalize $dir]
	    my TreeItem $dir
	} finally {
	    if {[$hull exists $dir]} {
		$hull selection set [list $dir]
		$hull focus $dir
		tvsee $hull $dir
		while {[set dir [$hull parent $dir]] ne ""} {
		    my open $dir
		}
	    }
	}
    }

    method get {} {
	return [lindex [$hull selection] 0]
    }

    method reload {} {
	set cwd [lindex [$hull selection] 0]
	my Refresh
	while {![$hull exists $cwd]} {
	    if {$cwd eq [set cwd [file dirname $cwd]]} return
	}
	my set $cwd
    }

    forward state theWidget state
}

# API summary:
#	<pathName> add <item> ...
#	<pathName> cget <option>
#	<pathName> configure ?<option>? ?<value>? ...
#	<pathName> delete <first> ?<last>?
#	<pathName> get <first> ?<last>?
#	<pathName> index <index>
#	<pathName> insert <index> <item> ...
#	<pathName> see <first> ?<last>?
#	<pathName> selection anchor ?<int>?
#	<pathName> selection clear <first> ?<last>?
#	<pathName> selection get
#	<pathName> selection includes <item>
#	<pathName> selection set <first> ?<last>?
#	<pathName> set <itemlist>

# items is a dict indexed by id:
# id {text image values tags admin}

::tk::Megawidget create ::ttk::fsdialog::iconlist \
  ::ttk::fsdialog::scrollwidget {
    variable hull options

    method GetSpecs {} {
	return {
	    {-background background Background #ffffff}
	    {-font font Font TkDefaultFont}
	    {-foreground foreground Foreground #000000}
	    {-height height Height 300p}
	    {-reverse reverse Reverse 0}
	    {-selectmode selectMode SelectMode extended}
	    {-sort sort Sort ""}
	    {-takefocus takeFocus TakeFocus 0}
	    {-width width Width 400p}
	}
    }

    method CreateInner {} {
	my variable w
	set canvas [canvas $w.c -highlightthickness 0 \
	  -takefocus 1 -background $options(-background)]
	# Create a focus ring
	$canvas create rect 0 0 1 1 -tags focus -dash {1 2} -state hidden
	bindtags $canvas [linsert [bindtags $canvas] 2 $w]
	return $canvas
    }

    method Create {} {
	variable seqnum 0 items {} idlist {}
	variable  maxheight 0 maxwidth 0 maxlength 0
	variable selection {} rows 0 anchor "" cursor ""
	bind $hull <Configure> [namespace code {my WhenIdle Arrange}]
	bind $hull <Button-1> [namespace code {my Button1 %x %y}]
	bind $hull <Shift-Button-1> [namespace code {my ShiftB1 %x %y}]
	bind $hull <Control-Button-1> [namespace code {my ControlB1 %x %y}]
	bind $hull <Home> [namespace code {my Cursor Home}]
	bind $hull <End> [namespace code {my Cursor End}]
	bind $hull <Prior> [namespace code {my Cursor Top}]
	bind $hull <Next> [namespace code {my Cursor Bottom}]
	bind $hull <<PrevLine>> [namespace code {my Cursor Up}]
	bind $hull <<NextLine>> [namespace code {my Cursor Down}]
	bind $hull <<PrevChar>> [namespace code {my Cursor Left}]
	bind $hull <<NextChar>> [namespace code {my Cursor Right}]
	bind $hull <Shift-Home> [namespace code {my Cursor Home 1}]
	bind $hull <Shift-End> [namespace code {my Cursor End 1}]
	bind $hull <Shift-Prior> [namespace code {my Cursor Top 1}]
	bind $hull <Shift-Next> [namespace code {my Cursor Bottom 1}]
	bind $hull <<SelectPrevLine>> [namespace code {my Cursor Up 1}]
	bind $hull <<SelectNextLine>> [namespace code {my Cursor Down 1}]
	bind $hull <<SelectPrevChar>> [namespace code {my Cursor Left 1}]
	bind $hull <<SelectNextChar>> [namespace code {my Cursor Right 1}]
	bind $hull <Control-Up> [namespace code {my Cursor Up -1}]
	bind $hull <Control-Down> [namespace code {my Cursor Down -1}]
	bind $hull <Control-Left> [namespace code {my Cursor Left -1}]
	bind $hull <Control-Right> [namespace code {my Cursor Right -1}]
	bind $hull <space> [namespace code {my Cursor Select}]

	themeinit
	variable selbg [ttk::style lookup TEntry -selectbackground focus]
	variable selfg [ttk::style lookup TEntry -selectforeground focus]
    }

    method MakeItem {data} {
	my variable seqnum items idmap maxheight maxwidth maxlength
	set item item$seqnum
	lassign $data id str
	set len [font measure $options(-font) $str]
	if {$len > $maxlength} {set maxlength $len}
	set image [icon 16 {*}[lindex $data 13 0]]
	set w [image width $image]
	if {$w > $maxwidth} {set maxwidth $w}
	set h [image height $image]
	if {$h > $maxheight} {set maxheight $h}
	set rect [$hull create rectangle 0 0 0 0 \
	  -fill "" -outline "" -tags [list $item rect]]
	set icon [$hull create image 0 0 -anchor w \
	  -image $image -tags [list $item icon]]
	set text [$hull create text 0 0 -anchor w -font $options(-font) \
	  -text $str -fill $options(-foreground) -tags [list $item text]]
	incr seqnum
	dict set idmap $item $id
	dict set items $id \
	  [list $item $image $data {} [list $rect $icon $text $len]]
	return $id
    }

    method MakeItemList {list} {
	return [lmap n $list {
	    my MakeItem $n
	}]
    }

    method DrawSelection {str {id ""}} {
	my variable items selbg selfg
	if {$str eq ""} {
	    $hull delete $id
	    return
	}
	set item [lindex [dict get $items $str] 0]
	set coords [lmap c [$hull bbox (icon||text)&&$item] d {-1p -1p 3p 1p} {
	    expr {$c + pixels($hull, $d)}
	}]
	if {$id eq ""} {
	    $hull create rectangle $coords \
	      -outline $selbg -fill $selbg -tags [list selection $item]
	} else {
	    $hull coords $id $coords
	    $hull itemconfigure $id -tags [list selection $item]
	}
	$hull itemconfigure text&&$item -fill $selfg
    }

    method Redraw {} {
	variable rows 0
	my WhenIdle Arrange
    }

    method Arrange {} {
	my variable idlist items maxheight maxwidth maxlength rows
	my variable selection cursor
	set pad \
	  [expr {max([$hull cget -highlightthickness] + [$hull cget -bd], 2)}]
	set height [expr {[winfo height $hull] - 2 * $pad}]
	set dy [expr {$maxheight + pixels($hull, "1.5p")}]
	# Avoid unneccessary work
	set cnt [expr {max($height / $dy, 1)}]
	if {$cnt == $rows} return

	# set dx [expr {$maxwidth + $maxlength + pixels($hull, "6p")}]
	set dx [expr {$maxwidth + pixels($hull, "9p")}]
	set cy [expr {$dy / 2}]
	set shift [expr {$maxwidth + pixels($hull, "3p")}]
	set rows $cnt

	set x [expr {$pad * 2}]
	set y $pad
	set w 0
	foreach id $idlist {
	    lassign [lindex [dict get $items $id] 4] rect icon text len
	    $hull coords $icon $x [expr {$y + $cy}]
	    $hull coords $text [expr {$x + $shift}] [expr {$y + $cy}]
	    $hull coords $rect $x $y [expr {$x + $dx}] [expr {$y + $dy}]

	    if {$len > $w} {set w $len}

	    if {[incr y $dy] + $dy > $height + $pad} {
		set y $pad
		incr x [expr {$w + $dx}]
		set w 0
	    }
	}
	foreach n $selection i [$hull find withtag selection] {
	    my DrawSelection $n $i
	}
	set width [expr {$y > $pad ? $x + $w + $dx : $x}]
	$hull configure -scrollregion [list 0 0 $width [expr {$rows * $dy}]]
	# Update the focus ring
	my SetFocus $cursor
    }

    method Focus {state} {
	my variable cursor
	next $state
	if {$state eq "focus" && $cursor ne ""} {
	    $hull itemconfigure focus -state normal
	} else {
	    $hull itemconfigure focus -state hidden
	}
    }

    method Button1 {x y} {
	my variable anchor
	focus $hull
	set id [my id @$x,$y]
	if {$id eq ""} return
	my selection set [list $id]
	set anchor $id
	my SetFocus $id
    }

    method ControlB1 {x y} {
	my variable anchor
	if {$options(-selectmode) ne "extended"} {tailcall my Button $x $y}
	focus $hull
	set id [my id @$x,$y]
	if {$id eq ""} return
	my selection toggle [list $id]
	set anchor $id
	my SetFocus $id
    }

    method ShiftB1 {x y} {
	my variable anchor idlist
	if {$options(-selectmode) ne "extended"} {tailcall my Button $x $y}
	focus $hull
	set id [my id @$x,$y]
	if {$id eq ""} return
	if {$anchor eq ""} {
	    my selection set [list $id]
	} else {
	    set i1 [my index $anchor]
	    set i2 [my index $id]
	    if {$i1 < $i2} {
		my selection add [lrange $idlist $i1 $i2]
	    } else {
		my selection add [lrange $idlist $i2 $i1]
	    }
	}
	set anchor $id
	my SetFocus $id
    }

    method Cursor {type {extend 0}} {
	my variable idlist anchor cursor rows
	if {$cursor eq ""} {
	    if {$type ni {End Bottom}} {set type Home}
	    set current 0
	} else {
	    set current [my index $cursor]
	}
	switch $type {
	    Home {
		set index 0
	    }
	    End {
		set index [expr {[llength $idlist] - 1}]
	    }
	    Up {
		set index [expr {$current - 1}]
	    }
	    Down {
		set index [expr {$current + 1}]
	    }
	    Left {
		set index [expr {$current - $rows}]
	    }
	    Right {
		set index [expr {$current + $rows}]
	    }
	    Top {
		set index [expr {$current / $rows * $rows}]
	    }
	    Bottom {
		set index [expr {($current / $rows + 1) * $rows - 1}]
		if {$index > [llength $idlist]} {set index end}
	    }
	    Select {
		if {$options(-selectmode) eq "extended"} {
		    my selection toggle $cursor
		}
		return
	    }
	}
	set id [lindex $idlist $index]
	if {$id eq ""} return
	if {!$extend || $options(-selectmode) ne "extended"} {
	    my selection set [list $id]
	    set anchor $id
	} elseif {$extend < 0} {
	    # Only move the cursor and update the acnhor
	    set anchor $id
	} else {
	    if {$anchor eq ""} {
		set start 0
		set anchor [lindex $idlist $start]
	    } else {
		set start [my index $anchor]
	    }
	    if {$index > $start} {
		my selection remove \
		  [lrange $idlist $current [expr {$start - 1}]]
		my selection remove \
		  [lrange $idlist [expr {$index + 1}] $current]
		my selection add \
		  [lrange $idlist $start $index]
	    } elseif {$index < $start} {
		my selection remove \
		  [lrange $idlist $current [expr {$index - 1}]]
		my selection remove \
		  [lrange $idlist [expr {$start + 1}] $current]
		my selection add \
		  [lrange $idlist $index $start]
	    } else {
		my selection remove \
		  [lrange $idlist $current [expr {$start - 1}]]
		my selection remove \
		  [lrange $idlist [expr {$start + 1}] $current]
	    }
	}
	my SetFocus $id
    }

    method SetFocus {item} {
	my variable items cursor
	if {![dict exists $items $item]} {
	    set cursor ""
	    $hull itemconfigure focus -state hidden
	    return
	}
	set id [lindex [dict get $items $item] 0]
	# Put the focus ring only around the text part of the item
	$hull coords focus [$hull bbox $id&&text]
	if {$cursor eq "" && [focus] eq $hull} {
	    $hull itemconfigure focus -state normal
	}
	# Give the focus item the item tag, so clicking on the focus ring will
	# behave the same as clicking on the actual item
	$hull itemconfigure focus -tags [list focus $id]
	$hull raise focus
	set cursor $item
	my see $item
    }

    method add {list} {
	my variable idlist
	lappend idlist {*}[my MakeItemList $list]
	my Redraw
	return
    }

    method delete {list} {
	my variable idlist items selection
	foreach n $list {
	    if {[dict exists $items $n]} {
		set id [lindex [dict get $items $n] 0]
		$hull delete $id
		set x [my index $n]
		if {$x >= 0} {
		    # Unshare the list for better performance
		    set idlist [lreplace $idlist[set idlist {}] $x $x]
		}
		set x [lsearch -exact $selection $n]
		if {$x >= 0} {set selection [lreplace $selection $x $x]}
		dict unset items $n
	    }
	}
	my Redraw
	return
    }

    method focus {{item ""}} {
	my variable idlist cursor
	if {[llength [info level 0]] <= 2} {
	    return $cursor
	} else {
	    my SetFocus $item
	}
    }

    method id {index} {
	if {[string is integer -strict $index] || [string match end* $index]} {
	    my variable idlist
	    return [lindex $idlist $index]
	} elseif {[scan $index @%d,%d x y] == 2} {
	    my variable idmap
	    set cx [$hull canvasx $x]
	    set cy [$hull canvasy $y]
	    set id [lindex [$hull find overlapping $cx $cy $cx $cy] end]
	    set item [lsearch -inline [$hull gettags $id] {item*}]
	    if {$item ne ""} {
		return [dict get $idmap $item]
	    }
	}
    }

    method index {id} {
	my variable idlist
	return [lsearch -exact $idlist $id]
    }

    method insert {index list} {
	my variable idlist
	set len [llength $idlist]
	if {![string is integer -strict $index]} {
	    if {[regsub {^end(\s*[+-]\s*\d+)?$} $index "$len\\1" expr]} {
		set index [expr $expr]
	    } else {
		error "bad index: $index"
	    }
	}
	if {$index < 0} {
	    set index 0
	} elseif {$index > $len} {
	    set index $len
	}
	set idlist [linsert $idlist $index {*}[my MakeItemList $list]]
	my Redraw
	return
    }

    method itemconfigure {data} {
	my variable items
	set id [lindex $data 0]
	dict update items $id entry {
	    lset entry 2 $data
	}
    }

    method see {item} {
	my variable items
	set id [lindex [dict get $items $item] 0]
	lassign [$hull bbox (text||icon)&&$id] x1 y1 x2 y2
	set x1 [expr {$x1 - pixels($hull, "1p")}]
	set x2 [expr {$x2 + pixels($hull, "3p")}]
	set maxx [lindex [$hull cget -scrollregion] 2]
	lassign [lmap n [$hull xview] {expr {$n * $maxx}}] left right
	if {$x1 < $left} {
	    $hull xview moveto [expr {double($x1) / $maxx}]
	} elseif {$x2 > $right} {
	    $hull xview moveto [expr {double($x2 - $right + $left) / $maxx}]
	}
    }

    method selection {{op ""} {list {}}} {
	my variable selection idlist items w
	set insert {}
	set remove {}
	switch -- $op {
	    "" {
		return $selection
	    }
	    add {
		set insert $list
	    }
	    remove {
		set remove $list
	    }
	    set {
		set remove [lmap n $selection {
		    if {$n in $list} continue
		    set n
		}]
		set insert [lmap n $list {
		    if {$n in $selection} continue
		    set n
		}]
	    }
	    toggle {
		foreach n $list {
		    if {$n in $selection} {
			lappend remove $n
		    } else {
			lappend insert $n
		    }
		}
	    }
	    default {
		error "unknown command: $op"
	    }
	}
	set event 0
	if {[llength $remove]} {
	    set selection [lmap n $selection {
		if {$n in $remove} {
		    set id [lindex [dict get $items $n] 0]
		    $hull delete selection&&$id
		    $hull itemconfigure text&&$id -fill $options(-foreground)
		    incr event
		    continue
		}
		set n
	    }]
	}
	set indices [lmap n $insert {
	    if {$n in $selection} continue
	    set x [lsearch -exact $idlist $n]
	    if {$x < 0} continue
	    my DrawSelection $n
	    incr event
	    set x
	}]
	if {[llength $indices]} {
	    foreach n $selection {
		lappend indices [lsearch -exact $idlist $n]
	    }
	    set selection [lmap n [lsort -integer -unique $indices] {
		lindex $idlist $n
	    }]
	    $hull lower selection
	}
	if {$event} {
	    event generate $w <<ListboxSelect>>
	}
    }

    method set {list} {
	my variable idlist items selection cursor
	set oldsel $selection
	# Delete all canvas items, except for the focus ring
	$hull delete !focus
	set items {}
	set idlist {}
	set selection {}
	my add $list
	# Restore the selection
	my selection set [lmap n $oldsel {
	    if {[dict exists $items $n]} {set n} else {continue}
	}]
	if {$cursor ne "" && ![dict exists $items $cursor]} {
	    set cursor ""
	}
    }

    method show {list} {
	my variable w idlist items selection cursor
	$hull addtag hidden withtag !focus
	set idlist [lmap n $list {
	    if {[dict exists $items $n]} {
		set id [lindex [dict get $items $n] 0]
		$hull dtag $id hidden
		$hull itemconfigure $id -state normal
	    } else {
		continue
	    }
	    set n
	}]
	$hull itemconfigure hidden -state hidden
	# Make sure the selection doesn't include any hidden items
	set gone [llength [$hull find withtag selection&&hidden]]
	if {$gone} {
	    set selection [lmap n $selection {
		set item [lindex [dict get $items $n] 0]
		set id [$hull find withtag $item&&selection&&hidden]
		if {[llength $id]} {
		    $hull delete {*}$id
		    $hull itemconfigure $item&&text -fill $options(-foreground)
		    continue
		}
		set n
	    }]
	    event generate $w <<ListboxSelect>>
	}
	# Check if the cursor item was hidden
	if {$cursor ne ""} {
	    set item [lindex [dict get $items $cursor] 0]
	    if {"hidden" in [$hull gettags $item&&rect]} {
		set cursor ""
	    }
	}
	my Redraw
	return
    }
}

::tk::Megawidget create ::ttk::fsdialog::infolist \
  ::ttk::fsdialog::scrollwidget {
    variable hull options

    method GetSpecs {} {
	return {
	    {-background background Background #ffffff}
	    {-columns columns Columns {}}
	    {-displaycolumns displayColumns DisplayColumns #all}
	    {-foreground foreground Foreground #000000}
	    {-height height Height 300p}
	    {-reverse reverse Reverse 0}
	    {-selectmode selectMode SelectMode extended}
	    {-sort sort Sort ""}
	    {-takefocus takeFocus TakeFocus 0}
	    {-width width Width 400p}
	}
    }

    method CreateInner {} {
	my variable w
	set cols [linsert $options(-columns) end _filler]
	set dcols $options(-displaycolumns)
	if {[lindex $dcols 0] ne "#all"} {lappend dcols _filler}
	set treeview [ttk::treeview $w.tv -style Listbox.FSDialog.Treeview \
	  -selectmode $options(-selectmode) -columns $cols \
	  -displaycolumns $dcols]
	bindtags $treeview [linsert [bindtags $treeview] 2 $w]
	return $treeview
    }

    method Create {} {
	my variable w
	variable commands {} command0 {string cat} sort {reverse 0}
	$hull column _filler -minwidth 0 -width 0
	$hull insert {} end -id hidden
	$hull detach hidden
	bind $hull <<TreeviewSelect>> \
	  [list event generate $w <<ListboxSelect>>]
	bind $hull <Home> [namespace code {my Cursor Home}]
	bind $hull <End> [namespace code {my Cursor End}]
	bind $hull <Prior> [namespace code {my Cursor Prior}]
	bind $hull <Next> [namespace code {my Cursor Next}]
	bind $hull <Up> [namespace code {my Cursor Up}]
	bind $hull <Down> [namespace code {my Cursor Down}]
	bind $hull <<PrevChar>> [namespace code {my Cursor}]
	bind $hull <<NextChar>> [namespace code {my Cursor}]
	bind $hull <Shift-Up> [namespace code {my Cursor ShiftUp}]
	bind $hull <Shift-Down> [namespace code {my Cursor ShiftDown}]
	bind $hull <Control-Up> [namespace code {my Cursor CtrlUp}]
	bind $hull <Control-Down> [namespace code {my Cursor CtrlDown}]
	bind $hull <space> [namespace code {my Cursor Select}]
	themeinit
	oo::objdefine [self] forward delete $hull delete
	oo::objdefine [self] forward tag $hull tag
	oo::objdefine [self] forward selection $hull selection
    }

    method Cursor {{key ""}} {
	set op set
	switch $key {
	    Home {
		set index 0
	    }
	    End {
		set index end
	    }
	    Up - Down {
		set cmd [bind Treeview <$key>]
		uplevel #0 [string map [list %W $hull] $cmd]
		set index [$hull index [$hull focus]]
	    }
	    ShiftUp - ShiftDown {
		set index [$hull index [$hull focus]]
		if {$key eq "ShiftDown"} {
		    incr index
		} elseif {$index} {
		    incr index -1
		}
		set op add
	    }
	    CtrlUp {
		set focus [$hull prev [$hull focus]]
		if {$focus ne ""} {
		    $hull focus $focus
		    tvsee $hull $focus
		}
		return -code break
	    }
	    CtrlDown {
		set focus [$hull next [$hull focus]]
		if {$focus ne ""} {
		    $hull focus $focus
		    tvsee $hull $focus
		}
		return -code break
	    }
	    Select {
		set index [$hull index [$hull focus]]
		set op add
	    }
	    Prior {
		set index [$hull index [$hull focus]]
		set index [expr {max(0, $index - [my PageSize])}]
		$hull yview scroll -1 pages
	    }
	    Next {
		if {[$hull focus] eq ""} {
		    set index 0
		} else {
		    set max [expr {[llength [$hull children {}]] - 1}]
		    set index [$hull index [$hull focus]]
		    set index [expr {min($max, $index + [my PageSize])}]
		    $hull yview scroll 1 pages
		    # Force recalculation of the scroll area. Without this the
		    # 'see' command below doesn't always work right.
		    #$hull yview
		}
	    }
	    default {
		if {[$hull focus] ne ""} return
		if {$key in {Up}} {
		    set index end
		} else {
		    set index 0
		}
	    }
	}
	set focus [lindex [$hull children {}] $index]
	if {$focus ne {}} {
	    tvsee $hull $focus
	    $hull focus $focus
	    $hull selection $op [list $focus]
	}
	return -code break
    }

    method PageSize {} {
	lassign [$hull yview] p1 p2
	set lines [llength [$hull children {}]]
	return [expr {round(($lines + 1) * ($p2 - $p1))}]
    }

    method SortArrow {args} {
	my variable sort
	set new [dict merge $sort $args]
	set old [dict merge $args $sort]
	if {[dict exists $old id]} {
	    set oldid [dict get $old id]
	    set newid [dict get $new id]
	    if {$newid ne $oldid} {
		$hull heading $oldid -image {}
	    }
	    if {[dict get $new reverse]} {
		$hull heading $newid -image [namespace which decreasing]
	    } else {
		$hull heading $newid -image [namespace which increasing]
	    }
	}
	set sort $new
    }

    method Sort {id cmd} {
	my variable sort
	set id [my Column $id]
	if {![dict exists $sort id] || [dict get $sort id] ne $id} {
	    set reverse 0
	} else {
	    set reverse [expr {![dict get $sort reverse]}]
	}
	my SortArrow id $id reverse $reverse
	tailcall {*}$cmd $reverse
    }

    method Column {id {default #0}} {
	if {[string is integer -strict $id] || $id eq "#0"} {return $id}
	if {$id eq "name"} {return #0}
	set index [lsearch -exact [$hull cget -columns] $id]
	if {$index >= 0} {return $index}
	return $default
    }

    method add {args} {
	my insert end {*}$args
    }

    method column {id args} {
	my variable commands command0
	foreach {opt val} $args {
	    switch -- $opt {
		-formatcommand {
		    if {$id eq "#0"} {
			set command0 $val
		    } else {
			set num [my Column $id]
			while {[llength $commands] < $num} {
			    lappend commands {}
			}
			lset commands [my Column $id] $val
		    }
		}
		-text {
		    $hull heading $id $opt $val -anchor w
		}
		-image {
		    $hull heading $id $opt $val
		}
		-sortcommand {
		    $hull heading $id \
		      -command [list [namespace which my] Sort $id $val]
		}
		default {
		    $hull column $id $opt $val
		}
	    }
	}
    }

    method columns {list} {
	$hull configure -displaycolumns [linsert $list end _filler]
	# Trigger recalculation of which columns to stretch
	$hull column #0 -width [$hull column #0 -width]
    }

    method configure {args} {
	if {[llength $args] < 2} {return [next {*}$args]}
	set saved [array get options]
	next {*}$args
	foreach {opt val} $args {
	    if {$val eq [dict get $saved $opt]} continue
	    switch -- $opt {
		-columns - -displaycolumns {
		    $hull configure $opt [linsert $val end _filler]
		}
		-reverse {
		    my SortArrow reverse $val
		}
		-sort {
		    set col [my Column $val ""]
		    if {$col ne ""} {
			my SortArrow id $col
		    } else {
			set valid [linsert [$hull cget -columns] 0 name]
			set valid [lsearch -all -inline -not $valid _*]
			if {[llength $valid] > 1} {
			    lset valid end "or [lindex $valid end]"
			}
			return -code error "invalid column: \"$val\".\
			  Must be [join $valid {, }]"
		    }
		}
	    }
	}
	return
    }

    method insert {pos list} {
	my variable commands command0
	foreach n $list {
	    set tags [lindex $n end 0]
	    set values [lmap val [lassign $n id name] cmd $commands {
		if {$cmd eq ""} {
		    set val
		} elseif {[catch {{*}$cmd $id $val} str]} {
		    set val
		} else {
		    set str
		}
	    }]
	    $hull insert {} $pos \
	      -id $id -text [{*}$command0 $name] -values $values -tags $tags
	}
    }

    method itemconfigure {data} {
	my variable command0 commands
	set tags [lindex $data end]
	set values [lmap val [lassign $data id name] cmd $commands {
	    if {$cmd ne ""} {{*}$cmd $id $val}
	}]
	$hull item $id -text [{*}$command0 $name] -values $values -tags $tags
    }

    method set {list} {
	set oldsel [$hull selection]
	set focus [$hull focus]
	$hull delete [$hull children {}]
	$hull delete [$hull children hidden]
	my insert end $list
	$hull selection set [lmap n $oldsel {
	    if {[$hull exists $n]} {set n} else {continue}
	}]
	if {[$hull exists $focus]} {$hull focus $focus}
    }

    method show {list} {
	set oldsel [$hull selection]
	$hull children hidden \
	  [concat [$hull children hidden] [$hull children {}]]
	$hull children {} $list
	# Remove the hidden items from the selection, otherwise they will
	# still be selected when they become visible again
	set newsel [$hull selection]
	set remove [lmap n $oldsel {
	    if {$n ni $newsel} {set n} else {continue}
	}]
	$hull selection remove $remove
    }
}

oo::class create ::ttk::fsdialog::commonMethods {
    method ButtonHome {} {
	try {
	    my ChangeDir [homedir]
	} trap {TCL VALUE PATH HOMELESS} {} {
	    # The home directory of the user could not be determined
	}
    }

    method ButtonReload {} {
	my ReloadDir
    }

    method ButtonNewfolder {} {
	my variable w cwd dirlist
	set top [toplevel $w.new]
	place [ttk::frame $top.b] -relwidth 1 -relheight 1
	wm transient $top $w
	wm title $top [mc "New Folder"]
	ttk::label $top.l \
	  -text "[mc {Create new folder in}]:\n[file nativename $cwd]"
	grid $top.l -columnspan 4 -sticky ew -padx 6p -pady {6p 0}
	ttk::entrybox $top.e -width [winfo pixels $top 30p]
	grid $top.e -columnspan 4 -sticky ew -padx 6p -pady 3p
	ttk::separator $top.sep
	grid $top.sep -columnspan 4 -sticky ew -padx 6p -pady 3p
	ttk::button $top.b1 -width 0 -text [mc Cancel] \
	  -command [list destroy $top]
	ttk::button $top.b2 -width 0 -text [mc OK] \
	  -command [list [namespace which my] MakeDir $top.e]
	grid x $top.b1 $top.b2 x -padx 9p -sticky ew -pady {3p 9p}
	grid columnconfigure $top all -weight 1
	grid columnconfigure $top [list $top.b1 $top.b2] \
	  -uniform buttons -weight 0
	grab $top
	wm resizable $top 0 0
	focus $top.e

	bind $top.e <Escape> [list $top.b1 invoke]
	bind $top.e <Return> [list $top.b2 invoke]
    }

    method MakeDir {e} {
	my variable w cwd
	try {
	    set dir [path $cwd [$e get]]
	    set name [file tail $dir]
	    if {[file exists $dir]} {
		throw {POSIX EEXIST {file exists}} {file exists}
	    }
	    file mkdir $dir
	    destroy [winfo toplevel $e]
	    my ChangeDir $dir
	} trap POSIX {- err} {
	    posixerror $e [dict get $err -errorcode] \
	      {Cannot create directory "%s"} [file nativename $dir]
	}
    }
}

# Dialogs

::tk::Megawidget create ::ttk::fsdialog::chooseDirectory \
  ::ttk::fsdialog::commonMethods {
    constructor {args} {
	variable result ""
	namespace path [linsert [namespace path] end ::ttk::fsdialog]
	next {*}$args
    }

    destructor {
	my variable options result w
	# The object may be destroyed because an error was found during
	# option parsing. Then $w and the options array don't yet exist.
	if {[winfo exists $w]} {
	    event generate $w <<FSDialogDone>> -data $result
	    next
	    savecfg
	    uplevel #0 [list set $options(-resultvariable) $result]
	} else {
	    next
	}
    }

    method GetSpecs {} {
	return {
	    {-initialdir "" "" ""}
	    {-parent "" "" ""}
	    {-mustexist "" "" 0}
	    {-resultvariable "" "" ""}
	    {-title "" "" ""}
	}
    }

    method CreateHull {} {
	my variable w hull options
	# Check for valid values for some of the user provided options
	if {![string is boolean -strict $options(-mustexist)]} {
	    return -code error -errorcode {TCL VALUE NUMBER} \
	      "expected boolean value but got \"$options(-mustexist)\""
	}
	toplevel $w -class TkFDialog
	# The framework will add a <Destroy> binding to the hull widget. This
	# means the hull widget should never be a toplevel, because a toplevel
	# widget receives <Destroy> events for all of its children.
	place [set hull [ttk::frame $w.bg]] -relwidth 1 -relheight 1
	wm protocol $w WM_DELETE_WINDOW [list [namespace which my] Cancel]
    }

    method Create {} {
	my variable w options cwd

	# on Android, use a full screen dialog
	if {[info exists ::tk::android] && $::tk::android} {
	    wm attributes $w -fullscreen 1
	} else {
	    wm geometry $w [dict get [readcfg] dirdialog geometry]
	}

	variable toolbar [ttk::frame $w.toolbar]
	set list [histdirs]
	foreach n [file volumes] {if {$n ni $list} {lappend list $n}}
	variable dirbox [ttk::matchbox $w.toolbar.dir \
	  -matchcommand [list [namespace which my] DirMatchCommand] \
	  -textvariable [my varname dir] \
	  -values [lmap n $list {file nativename $n}]]
	foreach {name icon key} {
	    home      go-home      <Alt-Home>
	    reload    view-refresh <F5>
	    newfolder folder-new   <F10>
	} {
	    set img [icon 22 {*}$icon]
	    set image [list $img]
	    if {$name in {home}} {
		lappend image disabled [dim $img]
	    }
	    ttk::button $w.toolbar.$name -style Toolbutton \
	      -image $image -takefocus 0 \
	      -command [list [namespace which my] Button[string totitle $name]]
	    pack $w.toolbar.$name -side left
	    bind $w $key [list $w.toolbar.$name invoke]
	}
	pack $toolbar.dir -fill x -expand 1 -padx 1.5p
	grid $toolbar -sticky news -padx 1.5p
	grid [ttk::separator $w.sep] -padx 0 -pady 1.5p -sticky ew
	variable dirlist [dirlist $w.list -width 300p -title [mc Folder]]
	grid $w.list -sticky news -padx 3p -pady 1.5p
	grid columnconfigure $w all -weight 1
	grid rowconfigure $w $w.list -weight 1
	ttk::frame $w.buttonbar
	ttk::button $w.buttonbar.cancel -text [mc Cancel] -width 0 \
	  -command [list [namespace which my] Cancel]
	ttk::button $w.buttonbar.ok -text [mc OK] -width 0 \
	  -command [list [namespace which my] Done]
	grid $w.buttonbar.cancel $w.buttonbar.ok -padx 3p -pady 3p -sticky ew
	grid columnconfigure $w.buttonbar all -uniform buttons
	grid $w.buttonbar -sticky e

	if {$options(-title) ne ""} {
	    wm title $w $options(-title)
	} else {
	    wm title $w [mc "Choose Directory"]
	}
	set cwd [if {[file isdirectory $options(-initialdir)]} {
	    normalize $options(-initialdir)
	} else {
	    pwd
	}]
	$dirlist set $cwd
	$dirlist open $cwd
	$dirbox set [file nativename $cwd]
	$dirbox icursor end
	$dirbox xview moveto 1
	$dirbox validate

	# Check that the user has a known home directory
	try {
	    homedir 1
	} trap {TCL VALUE PATH HOMELESS} {} {
	    $w.toolbar.home state disabled
	}

	bind $dirlist <<DirectorySelect>> [list $w.buttonbar.ok invoke]
	bind $dirbox <Alt-Home> "[list $w.toolbar.home invoke];break"

	bind $w <Return> [list $w.buttonbar.ok invoke]
	bind $w <Escape> [list $w.buttonbar.cancel invoke]
	bind $w <Alt-Up> [namespace code {my ChangeDir ..}]
	bind $w <<ListboxSelect>> [namespace code {my DirSelect}]
	bind $w <F6> [list focus $dirbox]

	focus $w.toolbar.dir
    }

    method DirMatchCommand {str} {
	my variable cwd
	return [dirmatchcommand $cwd $str]
    }

    method DirSelect {} {
	my variable cwd dir dirlist dirbox
	set str [$dirlist get]
	if {$str ne ""} {
	    set cwd $str
	    set dir [file nativename $str]
	    $dirbox icursor end
	    $dirbox xview moveto 1
	    $dirbox validate
	}
    }

    method ChangeDir {dir} {
	my variable cwd dirlist dirbox
	try {
	    set path [normalize $dir $cwd]
	    $dirbox selection clear
	    if {$path ne $cwd} {
		set cwd $path
		$dirlist set $path
		$dirlist open $path
	    } else {
		$dirbox set [file nativename $path]
		$dirbox icursor end
		$dirbox xview moveto 1
		$dirbox validate
	    }
	} trap POSIX {- err} {
	    posixerror $dirlist [dict get $err -errorcode] \
	      {Cannot change to the directory "%s"} [file nativename $path]
	}
	return $cwd
    }

    method ReloadDir {} {
	my variable dirlist
	$dirlist reload
    }

    method Done {} {
	my variable cwd dir result options
	if {$dir eq [file nativename $cwd]} {
	} elseif {$options(-mustexist) || [file isdirectory $dir]} {
	    my ChangeDir $dir
	    return
	} else {
	    set cwd [normalize $dir]
	}
	set result $cwd
	history $result
	my Cancel
    }

    method Cancel {} {
	my variable w
	set geometry [lindex [split [wm geometry $w] +] 0]
	geometry dirdialog geometry $geometry
	my destroy
    }

    method cget {option} {
	if {$option eq "-takefocus"} {return 0}
	return [next $option]
    }
}

::tk::Megawidget create ::ttk::fsdialog::chooseFile \
  ::ttk::fsdialog::commonMethods {
    variable hull options
    constructor {args} {
	variable result "" text ""
	namespace path [linsert [namespace path] end ::ttk::fsdialog]
	variable fd [fswatch create [list [namespace which my] Watch]]
	variable watch {}
	next {*}$args
    }

    destructor {
	my variable options result w fd
	fswatch close $fd
	# The object may be destroyed because an error was found during
	# option parsing. Then $w and the options array don't yet exist.
	if {[winfo exists $w]} {
	    event generate $w <<FSDialogDone>> -data $result
	    next
	    savecfg
	    uplevel #0 [list set $options(-resultvariable) $result]
	} else {
	    next
	}
    }

    method GetSpecs {} {
	return {
	    {-confirmoverwrite "" "" 1}
	    {-defaultextension "" "" ""}
	    {-filetypes "" "" ""}
	    {-initialdir "" "" ""}
	    {-initialfile "" "" ""}
	    {-multiple "" "" 0}
	    {-parent "" "" ""}
	    {-resultvariable "" "" ""}
	    {-title "" "" ""}
	    {-typevariable "" "" ""}
	}
    }

    method CreateHull {} {
	my variable w hull
	toplevel $w -class TkFDialog
	# The framework will add a <Destroy> binding to the hull widget. This
	# means the hull widget should never be a toplevel, because a toplevel
	# widget receives <Destroy> events for all of its children.
	place [set hull [ttk::frame $w.bg]] -relwidth 1 -relheight 1
	wm protocol $w WM_DELETE_WINDOW [list [namespace which my] Cancel]
    }

    method Create {} {
	my variable w lst prefs list pw font cwd trail pos text
	set list {}
	set prefs [preferences]
	set font TkDefaultFont
	set cwd [file normalize $options(-initialdir)]
	set text [file tail $options(-initialfile)]
	set trail [list $cwd]
	set pos 0

	themeinit
	set geometry [geometry filedialog]
	# on Android, use a full screen dialog
	if {[info exists ::tk::android] && $::tk::android} {
	    wm attributes $w -fullscreen 1
	} else {
	    wm geometry $w [dict get $geometry geometry]
	}
	wm title $w $options(-title)

	# Build the toolbar
	grid [my Toolbar $w.toolbar] -sticky ew

	ttk::separator $w.separator
	grid $w.separator -sticky ew

	set pw [ttk::panedwindow $w.filearea -orient horizontal]
	grid $pw -sticky nesw -padx 1.5p -pady 1.5p
	grid columnconfigure $w $pw -weight 1
	grid rowconfigure $w $pw -weight 1

	grid [my ControlArea $w.control] -sticky ew

	bind $w <Return> [list [namespace which my] Done]
	bind $w <Escape> [list [namespace which my] Cancel]

	::tk::SetFocusGrab $w $w.control.fnent
	my Reconfigure
	my WhenIdle TrailPos 0
    }

    method CreateFileList {win} {
	my variable font prefs
	infolist $win -selectmode [my SelectMode] -columns {
	    _type size mode mtime atime ctime uid gid inode _dev _hidden _icon
	}
	$win configure -displaycolumns [lrange [dict get $prefs columns] 1 end]

	set my [namespace which my]
	$win column #0 -text [mc Name] -stretch 0 \
	  -minwidth [winfo pixels $hull 120p] -sortcommand [list $my Sort name]
	$win column size -text [mc Size] -anchor e -stretch 0 \
	  -width [fontwidth $font *0000000000*] \
	  -formatcommand value -sortcommand [list $my Sort size]
	$win column inode -text [mc Inode] -anchor e -stretch 0 \
	  -width [fontwidth $font "*00000000*"] \
	  -formatcommand value -sortcommand [list $my Sort inode]
	$win column mtime -text [mc Modified] -anchor center -stretch 0 \
	  -width [fontwidth $font "*0000-00-00 00:00:00*"] \
	  -formatcommand date -sortcommand [list $my Sort mtime]
	$win column atime -text [mc Accessed] -anchor center -stretch 0 \
	  -width [fontwidth $font "*0000-00-00 00:00:00*"] \
	  -formatcommand date -sortcommand [list $my Sort atime]
	$win column ctime -text [mc Changed] -anchor center -stretch 0 \
	  -width [fontwidth $font "*0000-00-00 00:00:00*"] \
	  -formatcommand date -sortcommand [list $my Sort ctime]
	$win column mode -text [mc Permissions] -anchor w -stretch 0 \
	  -width [fontwidth $font *[mc Permissions]* *drwxrwxrwx*] \
	  -formatcommand mode
	$win column uid -text [mc Owner] -anchor w -stretch 0 \
	  -width [fontwidth $font *[mc Owner]* mmmmmm] \
	  -formatcommand owner -sortcommand [list $my Sort uid]
	$win column gid -text [mc Group] -anchor w -stretch 0 \
	  -width [fontwidth $font *[mc Group]* mmmmmm] \
	  -formatcommand group -sortcommand [list $my Sort gid]
	set extensions [lsort -unique [dict values [extensions]]]
	foreach n [linsert $extensions 0 folder text-x-generic] {
	    $win tag configure [lindex $n 0] -image [icon 16 {*}$n]
	}
	return $win
    }

    method CreateIconList {win} {
	iconlist $win -selectmode [my SelectMode]
	# bind $win <Return> [list [namespace which my] Done]
	return $win
    }

    method SelectMode {} {
	return browse
    }

    method Toolbar {win} {
	my variable w
	variable toolbar [ttk::frame $win]
	foreach {name icon key tooltip} {
	    prev go-previous <Alt-Left> "Go back"
	    next go-next <Alt-Right> "Go forward"
	    up go-up <Alt-Up> "Go up"
	    home go-home <Alt-Home> "Go to home directory"
	    reload view-refresh <F5> "Refresh"
	    newfolder folder-new <F10> "Create new folder"
	    options {configure preferences-system} <Alt-o> "Display options"
	} {
	    set img [icon 22 {*}$icon]
	    set image [list $img]
	    if {$name in {up prev next home}} {
		lappend image disabled [dim $img]
	    }
	    ttk::button $win.$name -style Toolbutton \
	      -image $image -takefocus 0 \
	      -command [list [namespace which my] Button[string totitle $name]]
	    tooltip $win.$name [mc $tooltip]
	    pack $win.$name -side left
	    bind $w $key [list $win.$name invoke]
	}
	set list [histdirs]
	variable dirbox [ttk::matchbox $win.dir \
	  -matchcommand [list [namespace which my] DirMatchCommand] \
	  -textvariable [my varname dir] \
	  -values [lmap n $list {file nativename $n}]]
	pack $dirbox -fill x -expand 1 -padx 1.5p -pady 1.5p

	# Check that the user has a known home directory
	try {
	    homedir 1
	} trap {TCL VALUE PATH HOMELESS} {} {
	    $w.toolbar.home state disabled
	}

	bind $dirbox <<MatchSelected>> \
	  [namespace code {my ChangeDir [normalize [%W get]]}]
	bind $dirbox <<MismatchSelected>> \
	  [namespace code {my ChangeDir [normalize [%W get]]}]
	bind $dirbox <<ComboboxSelected>> \
	  [namespace code {my ChangeDir [filename [%W get]]}]
	bind $w <F6> [list focus $dirbox]
	return $win
    }

    method ControlArea {win} {
	my variable w
	ttk::frame $win
	ttk::label $win.fnlab -anchor e -text [mc Location]:
	variable location [ttk::matchbox $win.fnent \
	  -textvariable [my varname text] -validate key \
	  -validatecommand [list [namespace which my] FileValidate %P %d %i %S] \
	  -matchcommand [list [namespace which my] FileMatchCommand]]
	ttk::label $win.ftlab -anchor e -text [mc Filter]:
	variable filter [ttk::matchbox $win.ftent]
	ttk::button $win.openbutton -width 0 \
	  -command [list [namespace which my] Done]
	ttk::button $win.cancbutton -width 0 -text [mc Cancel] \
	  -command [list [namespace which my] Cancel]
	variable types [::tk::FDGetFileTypes $options(-filetypes)]
	if {[llength $types] == 0} {
	    set options(-filetypes) [list [list [mc {All files}] *]]
	    set types [::tk::FDGetFileTypes $options(-filetypes)]
	}
	$win.ftent configure -values [lmap n $types {lindex $n 0}]
	set select 0
	if {$options(-typevariable) ne ""} {
	    upvar #0 $options(-typevariable) type
	    if {[info exists type]} {
		set select [lsearch -exact -index 0 $options(-filetypes) $type]
		if {$select < 0} {$win.ftent set $type}
	    }
	}
	if {$select >= 0} {$win.ftent current $select}
	grid $win.fnlab $win.fnent $win.openbutton -sticky ew -padx 2p -pady 2p
	grid $win.ftlab $win.ftent $win.cancbutton -sticky ew -padx 2p
	grid columnconfigure $win $win.fnent -weight 1

	bind $filter <<ComboboxSelected>> [list [namespace which my] Filter]
	bind $filter <Return> [list [namespace which my] Filter]
	bind $w <F7> [list focus $win.fnent]

	return $win
    }

    method ButtonReload {} {
	my variable dirlist
	if {$dirlist ne ""} {$dirlist reload}
	next
    }

    method ButtonUp {} {
	my variable cwd
	my ChangeDir [file dirname $cwd]
    }

    method ButtonPrev {} {
	my variable pos
	if {$pos > 0} {
	    my TrailPos [incr pos -1]
	}
    }

    method ButtonNext {} {
	my variable trail pos
	if {$pos < [llength $trail] - 1} {
	    my TrailPos [incr pos]
	}
    }

    method ButtonOptions {} {
	my variable w prefs opt font
	destroy $w.optdlg
	set dlg [toplevel $w.optdlg]
	wm transient $dlg $w
	place [ttk::frame $dlg.bg] -relwidth 1 -relheight 1
	wm title $dlg [mc "View Display Style"]
	set width0 [font measure $font 0]

	array set opt $prefs
	set var [namespace which -variable opt]

	# The msgcat package will take care of adding the ampersand
	tk::AmpWidget ttk::label $dlg.l1 -text [mc "View mode"]: -anchor e
	tk::AmpWidget ttk::radiobutton $dlg.compact \
	  -text [mc "Compact"] -variable ${var}(details) -value 0
	tk::AmpWidget ttk::radiobutton $dlg.details \
	  -text [mc "Details"] -variable ${var}(details) -value 1
	grid $dlg.l1 $dlg.compact - -sticky w -padx 2p -pady 1p
	grid x $dlg.details - -sticky w -padx 2p -pady 1p
	bind $dlg.l1 <<AltUnderlined>> [list focus $dlg.compact]

	tk::AmpWidget ttk::label $dlg.l2 -text [mc "Sorting"]: -anchor e
	set keys {name size inode mtime ctime atime uid gid}
	set values [list [mc Name] [mc Size] [mc Inode] [mc Modified] \
	   [mc Changed] [mc Accessed] [mc Owner] [mc Group]]
	set width [expr {fit([fontwidth $font {*}$values], $width0)}]
	ttk::combobox $dlg.sort -state readonly -width $width -values $values
	$dlg.sort current \
	  [expr {max([lsearch -exact $keys [dict get $prefs sort]], 0)}]
	tk::AmpWidget ttk::checkbutton $dlg.reverse \
	  -text [mc "Reverse"] -variable ${var}(reverse)
	grid $dlg.l2 $dlg.sort $dlg.reverse -sticky w -padx 2p -pady 5p
	bind $dlg.l2 <<AltUnderlined>> [list focus $dlg.sort]

	tk::AmpWidget ttk::label $dlg.l3 -text [mc "View options"]: -anchor e
	tk::AmpWidget ttk::checkbutton $dlg.split \
	  -text [mc "Separate Folders"] -variable ${var}(duopane)
	tk::AmpWidget ttk::checkbutton $dlg.dirfirst \
	  -text [mc "Folders First"] -variable ${var}(mixed) \
	  -onvalue 0 -offvalue 1
	tk::AmpWidget ttk::checkbutton $dlg.hidden \
	  -text [mc "Show Hidden Files"] -variable ${var}(hidden)
	grid $dlg.l3 $dlg.split - -sticky w -padx 2p -pady 1p
	grid x $dlg.dirfirst - -sticky w -padx 2p -pady 1p
	grid x $dlg.hidden - -sticky w -padx 2p -pady 1p
	bind $dlg.l3 <<AltUnderlined>> [list focus $dlg.split]

	ttk::frame $dlg.f4
	tk::AmpWidget ttk::label $dlg.l4 \
	  -text [mc "Detailed information to show"]: -anchor e
	checklist $dlg.col
	foreach {id str} {
	    name Name size Size inode Inode
	    mtime Modified ctime Changed atime Accessed
	    mode Permissions uid Owner gid Group
	} {
	    if {$id in {name}} {set state disabled} else {set state normal}
	    $dlg.col add -id $id -text [mc $str] -state $state
	}
	$dlg.col selection set $opt(columns)

	grid $dlg.l4 -in $dlg.f4 -sticky w
	grid $dlg.col -in $dlg.f4 -sticky ew
	grid $dlg.f4 - - -padx 2p -pady {10p 1p}
	bind $dlg.l4 <<AltUnderlined>> [list tk::TabToWindow $dlg.col]

	set f [ttk::frame $dlg.buttons]
	
	set width [expr {
	    fit([fontwidth $font [mc OK] [mc Apply] [mc Cancel]], $width0)
	}]
	ttk::button $f.ok -text [mc OK] -width $width \
	  -command [list [namespace which my] OptionsDone $dlg commit]
	ttk::button $f.apply -text [mc Apply] -width $width \
	  -command [list [namespace which my] OptionsDone $dlg apply]
	ttk::button $f.cancel -text [mc Cancel] -width $width \
	  -command [list [namespace which my] OptionsDone $dlg cancel]
	pack $f.cancel $f.apply $f.ok -side right -padx 4p -pady 4p
	grid $f - - -sticky e -padx 0 -pady {10p 0}
	bind $dlg <Return> [list $f.ok invoke]
	bind $dlg <Escape> [list $f.cancel invoke]

	grid $dlg.l1 $dlg.l2 $dlg.l3 -sticky e

	tk::PlaceWindow $dlg widget $w
	wm transient $dlg $w
	wm resizable $dlg 0 0

	bind $dlg <Alt-Key> [list ::tk::AltKeyInDialog $dlg %A]
    }

    method OptionsDone {dlg action} {
	my variable prefs opt lst
	if {$action in {apply commit}} {
	    #set opt(details) [$dlg.mode current]
	    set keys {name size inode mtime ctime atime uid gid}
	    set opt(sort) [lindex $keys [$dlg.sort current]]
	    #set opt(reverse) [$dlg.order current]
	    set opt(columns) [$dlg.col selection]
	    set steps {}
	    dict for {key val} $prefs {
		if {$opt($key) == $val} continue
		switch $key {
		    duopane - details {
			lappend steps Reconfigure Filter
		    }
		    sort - reverse {
			lappend steps Sort
			continue
		    }
		    hidden - mixed {
			lappend steps Filter
		    }
		    columns {
			lappend steps Show
		    }
		}
		dict set prefs $key $opt($key)
	    }
	    if {"Reconfigure" in $steps} {
		my Reconfigure
	    }
	    if {"Sort" in $steps} {
		my Sort $opt(sort) $opt(reverse)
	    } elseif {"Filter" in $steps} {
		my Filter
	    }
	    if {"Show" in $steps && $opt(details)} {
		$lst columns [lrange $opt(columns) 1 end]
	    }
	    preferences {*}$prefs
	}
	if {$action in {commit cancel}} {destroy $dlg}
    }

    method Reconfigure {} {
	my variable w pw lst list prefs cwd dirlist
	set panes [$pw panes]
	if {[dict get $prefs duopane]} {
	    if {"$pw.dir" ni $panes} {
		set dirlist [dirlist $pw.dir]
		$pw.dir set $cwd
		# Insert fails when there are no existing panes (pre 8.6.14)
		$pw add $pw.dir
		$pw insert 0 $pw.dir -weight 0
		bind $dirlist <<ListboxSelect>> \
		  [namespace code {my ChangeDir [%W get]}]
	    }
	} else {
	    if {"$pw.dir" in $panes} {
		$pw forget $pw.dir
		destroy $pw.dir
	    }
	    set dirlist ""
	}
	if {[dict get $prefs details]} {
	    if {"$pw.icons" in $panes} {
		$pw forget $pw.icons
		destroy $pw.icons
	    }
	    if {"$pw.files" ni $panes} {
		set lst [my CreateFileList $pw.files]
		$lst set $list
	    }
	} else {
	    if {"$pw.files" in $panes} {
		$pw forget $pw.files
		destroy $pw.files
	    }
	    if {"$pw.icons" ni $panes} {
		set lst [my CreateIconList $pw.icons]
		$lst set $list
	    }
	}
	# Make sure the tab traversal order is correct: dirlist first
	if {$dirlist ne ""} {
	    raise $lst $dirlist
	}
	bind $lst <<ListboxSelect>> \
	  [namespace code {my SelectFiles [%W selection]}]
	bind $lst <Double-1> [list [namespace which my] Done]
	$pw insert end $lst
    }

    method Watch {event} {
	my variable cwd list lst fd watch prefs
	switch [dict get $event event] {
	    create - movedto {
		# New file
		try {
		    if {[dict exists $event path]} {
			set path [dict get $event path]
		    } else {
			set path $cwd
		    }
		    set file $path/[dict get $event name]
    		    set stat [stat $file]
		} trap POSIX {err} {
		    # Ignore file access problems
		    return
		}
		# Check if movedto overwrites an existing file
		set x [lsearch -index 0 -exact $list $file]
		if {$x >= 0} {
		    lset list $x $stat
		    $lst itemconfigure $stat
		} else {
		    lappend list $stat
		    $lst add [list $stat]
		}
		my Filter
	    }
	    delete - movedfrom {
		# File no longer exists
		set file [dict get $event path]/[dict get $event name]
		# Some files only exist for an instant, for example: sqlite3
		# journal files. They may already be gone before they can be
		# inventoried. 
		set x [lsearch -index 0 -exact $list $file]
		if {$x >= 0} {
		    # Unshare the list for better performance
		    set list [lreplace $list[set list {}] $x $x]
		    $lst delete [list $file]
		}
	    }
	    modify - closewrite - attrib {
		# File has changed
		set path [dict get $event path]/[dict get $event name]
		try {
		    set stat [stat $path]
		} trap POSIX {} {
		    # Ignore file access problems
		    return
		}
		set x [lsearch -index 0 -exact $list $path]
		if {$x >= 0} {
		    lset list $x $stat
		    $lst itemconfigure $stat
		    my Filter
		}
	    }
	    deleteself - moveself {
		# Yikes! - The current directory has disappeared.
		set path [dict get $event path]
		while {![file exists $path]} {
		    set path [file dirname $path]
		}
		my ChangeDir $path
		# Pop up a warning message (as dolphin does)?
		# "Current location changed, "%s" is no longer accessible."
	    }
	}
    }

    method SelectFiles {list} {
	my variable text location
	if {[llength $list]} {
	    set text [file tail [lindex $list 0]]
	    $location icursor end
	}
    }

    method DirMatchCommand {str} {
	my variable cwd
	return [dirmatchcommand $cwd $str]
    }

    method FileMatchCommand {str} {
	my variable cwd
	return [filematchcommand $cwd $str]
    }

    method FileValidate {str action index ch} {
	my variable list lst
	set x [lsearch -index 1 -exact $list $str]
	if {$x >= 0} {
	    $lst selection set [list [lindex $list $x 0]]
	} else {
	    $lst selection set {}
	}
	return true
    }

    method ChangeDir {dir} {
	my variable w cwd pos trail text
	if {$dir ne $cwd} {
	    try {
		# Make sure the path is a directory and it is accessible
		file stat $dir/.
		set text ""
		set cwd $dir
		set trail [lrange $trail 0 $pos]
		lappend trail $cwd
		my TrailPos [incr pos]
	    } trap POSIX {- err} {
		posixerror $w [dict get $err -errorcode] \
		  {Cannot change to the directory "%s"} [file nativename $dir]
	    }
	}
    }

    method TrailPos {index} {
	my variable cwd trail pos toolbar dirbox dirlist
	set pos $index
	set cwd [lindex $trail $pos]
	if {$dirlist ne "" && [$dirlist get] ne $cwd} {
	    catch {$dirlist set $cwd}
	}
	$dirbox set [file nativename $cwd]
	$dirbox icursor end
	$dirbox xview moveto 1
	$dirbox validate
	if {[file dirname $cwd] ne $cwd} {
	    $toolbar.up state !disabled
	} else {
	    $toolbar.up state disabled
	}
	if {$pos > 0} {
	    $toolbar.prev state !disabled
	} else {
	    $toolbar.prev state disabled
	}
	if {$pos < [llength $trail] - 1} {
	    $toolbar.next state !disabled
	} else {
	    $toolbar.next state disabled
	}
	my ReloadDir
    }

    method ReloadDir {} {
	my variable lst list cwd w fd watch
	try {
	    set add 1
	    dict for {id path} $watch {
		if {$path eq $cwd} {
		    set add 0
		} else {
		    fswatch remove $fd $id
		    dict unset watch $id
		}
	    }
	    if {$add} {
		set id [fswatch add $fd $cwd \
		  {create delete move modify attrib deleteself moveself}]
		dict set watch $id $cwd
	    }
	    set list [ls $cwd]
	    $lst set $list
	    my Filter
	} trap POSIX {- err} {
	    posixerror $w [dict get $err -errorcode] \
	      {Cannot change to the directory "%s"} [file nativename $cwd]
	}
    }

    method Sort {type {reverse 0}} {
	my variable prefs list
	if {[dict get $prefs sort] ne $type || [dict get $prefs reverse] != $reverse} {
	    dict set prefs sort $type
	    dict set prefs reverse $reverse
	    my Filter
	}
    }

    method Filter {} {
	my variable prefs list lst filter types
	set x [$filter current]
	if {$x < 0} {
	    set match [$filter get]
	} else {
	    set match [lindex $types $x 1]
	}
	if {"*" ni $match} {
	    set tmp [lsearch -all -inline -exact -index 2 -not $list directory]
	    set rc {}
	    foreach pat $match {
		lappend rc {*}[lsearch -all -inline -index 1 $tmp $pat]
	    }
	    if {[dict get $prefs duopane]} {
		set tmp {}
	    } else {
		set tmp [lsearch -all -inline -exact -index 2 $list directory]
	    }
	} elseif {[dict get $prefs duopane]} {
	    set rc [lsearch -all -inline -exact -index 2 -not $list directory]
	    set tmp {}
	} elseif {![dict get $prefs mixed]} {
	    set rc [lsearch -all -inline -exact -index 2 -not $list directory]
	    set tmp [lsearch -all -inline -exact -index 2 $list directory]
	} else {
	    set rc $list
	    set tmp {}
	}

	# In general $tmp holds the directories and $rc the files.
	# Only when everything is mixed, $rc holds both
	if {![dict get $prefs hidden]} {
	    set tmp [lsearch -all -inline -exact -index 12 -integer $tmp 0]
	    set rc [lsearch -all -inline -exact -index 12 -integer $rc 0]
	}

	if {[dict get $prefs duopane]} {
	    set rc [sort $rc $prefs]
	} elseif {[dict get $prefs mixed]} {
	    set rc [sort [concat $tmp $rc] $prefs]
	} else {
	    set rc [concat [sort $tmp $prefs] [sort $rc $prefs]]
	}

	$lst show [lmap n $rc {lindex $n 0}]

	set type [dict get $prefs sort]
	set reverse [dict get $prefs reverse]
	if {$type eq "name"} {set type #0}
	$lst configure -sort $type -reverse $reverse
    }

    method Missing {name} {
	if {[file exists $name]} {
	    return 0
	} else {
	    my variable w
	    protect $w {
		tk_messageBox -type ok -icon warning -parent $w \
		  -message [mc {File "%s" does not exist.} \
		  [file nativename $name]]
	    }
	    return 1
	}
    }

    method Done {name} {
	if {[file isdirectory $name]} {
	    my ChangeDir $name
	    return -code return
	}
    }

    method Cancel {} {
	my destroy
    }
}

oo::class create ::ttk::fsdialog::multiple {
    method MultipleInit {} {
	# Keep track of the specified files in a list of lists. Each sublist
	# contains a start and end index, followed by the full file path, if
	# there is a match
	variable split {}
    }

    method ControlArea {win} {
	my variable location
	next $win
	# A name picked from the match list should not replace everything
	bind $location <<Pick>> [list [namespace which my] Pick %d]
	return $win
    }

    method FileMatchCommand {str} {
	my variable cwd split location
	set index [$location index insert]
	set x [lsearch -index 0 -integer -bisect $split $index]
	if {$x < 0} return
	lassign [lindex $split $x] i1 i2
	if {$index <= $i2 + 1} {
	    set name [string range $str $i1 $i2]
	    # Should already selected files be omitted?
	    # Pass the list through the filter? KDialog doesn't.
	    return [filematchcommand $cwd $name]
	}
    }

    method Pick {str} {
	my variable split location text
	set index [$location index insert]
	set x [lsearch -index 0 -integer -bisect $split $index]
	lassign [lindex $split $x] i1 i2 path quote
	# Only unselect when there are no duplicates
	if {[llength [lsearch -all -exact -index 2 $split $path]] == 1} {
	    my Unselect $path
	}
	set path [my Select $str]
	# Should quotes always be added (or when there's more than 1 name)?
	if {!$quote && [regexp {[ \\"]} $str]} {
	    set q 1
	    set str [format {"%s"} [regsub -all {"} $str {\"}]]
	} else {
	    set q 0
	}
	set d [expr {[string length $str] - ($i2 + 1 - $i1) - $q}]
	set text [string replace $text $i1 $i2 $str]
	lset split $x [list [incr i1 $q] [incr i2 $d] $path [incr quote $q]]
	# Place the cursor after the closing quote, if any
	$location icursor [expr {[incr index $d] + $q}]
	incr d $q
	while {[incr x] < [llength $split]} {
	    lassign [lindex $split $x] i1 i2
	    lset split $x 0 [incr i1 $d]
	    lset split $x 1 [incr i2 $d]
	}
    }

    method SelectMode {} {
	return extended
    }

    method Select {name} {
	my variable cwd list lst
	if {[lsearch -index 1 -exact $list $name] >= 0} {
	    set path [file join $cwd $name]
	    $lst selection add [list $path]
	    return $path
	}
    }

    method Unselect {path} {
	my variable lst
	if {$path ne ""} {$lst selection remove [list $path]}
    }

    method Append {var name {path ""}} {
	upvar 1 $var str
	if {$str ne ""} {append str " "}
	set esc [regsub -all {"} $name {\"}]
	set i1 [string length [append str {"}]]
	set i2 [expr {[string length [append str $esc]] - 1}]
	append str {"}
	return [list $i1 $i2 $path 1]
    }

    method SelectFiles {list} {
	my variable text split location
	if {[focus] eq $location} return
	if {[llength $list] == 1} {
	    set path [lindex $list 0]
	    set str [file tail $path]
	    if {[regexp {[ "]} $str]} {
		set str {}
		set split [list [my Append str [file tail $path] $path]]
	    } else {
		set end [expr {[string length $str] - 1}]
		set split [list [list 0 $end $path 0]]
	    }
	} else {
	    set str {}
	    set selection {}
	    set split [lmap n $split {
		set path [lindex $n 2]
		if {$path ni $list} continue
		lappend selection $path
		my Append str [file tail $path] $path
	    }]
	    foreach path $list {
		if {$path ni $selection} {
		    lappend split [my Append str [file tail $path] $path]
		}
	    }
	}
	set text $str
	$location icursor end
    }

    method SpecialChar {ch str quote} {
	if {!$quote && $str eq "" || $ch eq "\n"} {return 1}
	if {[string index [regsub -all {\\.} $str {}] end] eq "\\"} {
	    # Special character has been escaped
	    return 0
	}
	# Space inside quotes is just a space
	if {$quote && $ch eq " "} {return 0}
	return 1
    }

    method FileSplit {str} {
	my variable lst
	# Ignore any escaped characters
	regsub -all {\\.} $str xx esc
	# Try to make sense of the double quotes
	set rc {}
	set open 0
	set x 0
	set i1 0
	foreach n [split $esc {"}] {
	    set l [string length $n]
	    incr x $l
	    if {$open} {
		if {[string is space [string index $esc [expr {$x + 1}]]]} {
		    set i2 [expr {$x - 1}]
		    lappend rc [list $i1 $i2 "" 1]
		    set i1 [expr {$x + 1}]
		    set open 0
		}
	    } else {
		# Unquoted string
		if {[string is space [string index $n end]]} {
		    set i2 [expr {$x - 1}]
		    foreach s [split [string range $esc $i1 $i2]] {
			set i2 [expr {$i1 + [string length $s] - 1}]
			if {$i2 >= $i1} {
			    lappend rc [list $i1 $i2 "" 0]
			}
			set i1 [expr {$i2 + 2}]
		    }
		    set open 1
		    set i1 [expr {$x + 1}]
		}
	    }
	    incr x
	}
	foreach s [split [string range $esc $i1 end]] {
	    set i2 [expr {$i1 + [string length $s] - 1}]
	    if {$i2 >= $i1} {
		lappend rc [list $i1 $i2 "" 0]
	    }
	    set i1 [expr {$i2 + 2}]
	}
	set x 0
	$lst selection set [lmap n $rc {
	    lassign $n i1 i2
	    set path [my Select [string range $str $i1 $i2]]
	    try {
		if {$path eq ""} continue
		lset rc $x 2 $path
		set path
	    } finally {
		incr x
	    }
	}]
	return $rc
    }

    method FileValidate {str action index ch} {
	my variable split
	if {$action >= 0 && ![regexp {[ \\"]} $ch]} {
	    # The inserted/deleted text does not contain any special characters
	    set x [lsearch -index 0 -integer -bisect $split $index]
	    if {$x >= 0} {
		lassign [lindex $split $x] i1 i2 path
		if {$index <= $i2 + 1} {
		    set l [string length $ch]
		    if {$action} {
			# Insert prevalidation
		    } else {
			# Delete prevalidation
			set l [expr {-$l}]
		    }
		    lset split $x 1 [incr i2 $l]
		    set sel [my Select [string range $str $i1 $i2]]
		    if {$sel ne $path} {my Unselect $path}
		    lset split $x 2 $sel
		    while {[incr x] < [llength $split]} {
			lassign [lindex $split $x] i1 i2
			lset split $x 0 [incr i1 $l]
			lset split $x 1 [incr i2 $l]
		    }
		    return true
		}
	    }
	}
	# Reparse the string into file names
	set split [my FileSplit $str]
	return true
    }

    method ChangeDir {dir} {
	my variable text split
	next $dir
	if {$text eq ""} {set split {}}
    }

    method Done {} {
	my variable cwd text split result
	if {[llength $split] == 0} return
	set list {}
	foreach n $split {
	    lassign $n i1 i2 path
	    # Skip empty chunks
	    if {$i2 < $i1} continue
	    if {$path eq ""} {
		set path [file join $cwd [string range $text $i1 $i2]]
	    }
	    # Skip duplicates
	    if {$path in $list} continue
	    # Make sure the path is not a directory
	    nextto chooseFile $path
	    # Check that the file exists
	    if {[my Missing $path]} return
	    lappend list $path
	}
	set result $list
	my destroy
    }
}

::tk::Megawidget create ::ttk::fsdialog::getOpenFile \
  ::ttk::fsdialog::chooseFile {
    method GetSpecs {} {
	set specs [next]
	set x [lsearch -index 0 -exact $specs -title]
	lset specs $x 3 [mc Open]
	set x [lsearch -index 0 -exact $specs -confirmoverwrite]
	return [lreplace $specs $x $x]
    }

    method Create {} {
	my variable options
	if {$options(-multiple)} {
	    oo::objdefine [self] mixin multiple
	    my MultipleInit
	}
	next
    }

    method ControlArea {win} {
	next $win
	$win.openbutton configure -text [mc Open]
	return $win
    }

    method Done {} {
	my variable cwd text result
	if {$text eq ""} return
	set name [file join $cwd $text]
	# Handle directories
	nextto chooseFile $name
	# Check that the file exists
	if {[my Missing $name]} return
	set result $name
	my destroy
    }
}

::tk::Megawidget create ::ttk::fsdialog::getSaveFile \
  ::ttk::fsdialog::chooseFile {
    method GetSpecs {} {
	set specs [next]
	set x [lsearch -index 0 -exact $specs -title]
	lset specs $x 3 [mc "Save As"]
	set x [lsearch -index 0 -exact $specs -multiple]
	return [lreplace $specs $x $x]
    }

    method ControlArea {win} {
	next $win
	$win.openbutton configure -text [mc Save]
	return $win
    }

    method Done {} {
	my variable cwd text result options
	if {$text eq ""} return
	set name [file join $cwd $text]
	# Handle directories
	nextto chooseFile $name
	if {$options(-confirmoverwrite) && [file exists $name]} {
	    my variable w
	    set answer [protect $w {
		tk_messageBox -type yesno -icon warning -parent $w \
		  -message [mc {File "%s" already exists.\
		  Do you want to overwrite it?} [file nativename $name]]
	    }]
	    if {$answer ne "yes"} return
	}
	set result $name
	my destroy
    }
}

namespace import -force ::ttk::fsdialog::*

package provide fsdialog 3.0
