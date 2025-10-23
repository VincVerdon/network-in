# The file command has some methods that have changed dramatically from
# Tcl 8 to 9. Loading this file in Tcl 8.6 makes the command behave the
# same as it does in 9.0.
# When the file is loaded from within a namespace, a modified file command
# is created in that namespace. This effectively only changes the file
# command when used from the namespace. When loaded from within the global
# namespace, the original file command is modified. This may adversely
# affect other packages.

if {[dict exists [namespace ensemble configure file -map] home]} return

namespace eval file {
    if {[namespace parent] ne "::"} {
	# Replacement only for the parent namespace
	# Create an alias to the standard file command for use by the ensemble
	interp alias {} [namespace current]::file {} file
    } elseif {[namespace which file] ne "[namespace current]::file"} {
	# Move the original file command into the current namespace, so we
	# can still use it to implement the replacement
	rename file file
    }
    # Create a version of the file command that works the same as Tcl 9.0
    namespace ensemble create -map {
	atime {filenamearg atime}
	attributes {filenamearg attributes}
	channels {file channels}
	copy {filenameargs copy}
       	delete {filenameargs delete}
       	dirname dirname
	executable {filenamearg executable} 
	exists {filenamearg exists}
	extension {file extension}
	home home
	isdirectory {filenamearg isdirectory}
	isfile {filenamearg isfile} 
	join filejoin
	link {filenameargs link} 
	lstat {filestat lstat}
	mkdir {filenameargs mkdir}
	mtime {filenamearg mtime}
       	nativename nativename
	normalize normalize
	owned {filenamearg owned}
	pathtype pathtype
	readable {filenamearg readable}
	readlink {filenamearg readlink}
	rename {filenameargs rename}
	rootname {file rootname}
	separator {file separator}
       	size {filenamearg size}
	split filesplit
	stat {filestat stat}
	system {filenamearg system}
	tail filetail
	tempdir tempdir
	tempfile {file tempfile}
       	tildeexpand tildeexpand
	type {filenamearg type}
	volumes {file volumes}
	writable {filenamearg writable}
    }

    proc protect {name} {
	return [regsub {^~} $name {./&}]
    }

    proc filenamearg {cmd file args} {
	tailcall file $cmd [protect $file] {*}$args
    }

    proc filenameargs {cmd args} {
	set opt 1
	set args [lmap arg $args {
	    if {$opt && [string index $arg 0] eq "-"} {
		if {$arg eq "--"} {set opt 0}
		set arg
	    } else {
		set opt 0
		protect $arg
	    }
	}]
	tailcall file $cmd {*}$args
    }

    proc dirname {name} {
	tailcall file dirname [filejoin . $name]
    }

    proc home {{user ""}} {
	tailcall file normalize ~$user
    }

    proc filejoin {args} {
	set rc ""
	foreach arg $args {
	    if {[pathtype $arg] ne "relative"} {
		set rc $arg
	    } elseif {[string index $rc end] in {/ ""}} {
		append rc [string trimright $arg /]
	    } else {
		append rc / [string trimright $arg /]
	    }
	}
	return [regsub -all //+ $rc /]
    }

    proc nativename {name} {
	if {[string index $name 0] ne "~"} {
	    tailcall file nativename $name
	} else {
	    tailcall regsub {^\./} [file nativename [protect $name]] {}
	}
    }

    proc normalize {name} {
	tailcall file normalize [filejoin [pwd] $name]
    }

    proc pathtype {name} {
	if {[string index $name 0] eq "~"} {
	    return relative
	} else {
	    tailcall file pathtype $name
	}
    }

    proc filesplit {name} {
	return [lmap part [file split $name] {regsub {^\./} $part {}}]
    }

    proc filestat {cmd name {var ""}} {
	if {[llength [info level 0]] > 3} {
	    tailcall file $cmd [protect $name] $var
	} else {
	    file $cmd [protect $name] stat
	    return [array get stat]
	}
    }

    proc filetail {name} {
	set rc [file tail [filejoin . $name]]
	return [regsub {^./} $rc {}]
    }

    proc tempdir {{template tcl}} {
	close [file tempfile name]
	file delete $name
	set tmpdir [file dirname $name]
	while 1 {
	    set rnd [binary format I [expr {int(rand() * 0x100000000)}]]
	    set str [string range [binary encode base64 $rnd]]
	    if {[string is alnum $str]} {
		set name [filejoin $tmpdir [string cat $template _ $str]]
		if {![catch {file mkdir $name}]} {
		    file attributes $name -permissions go-rwx
		    break
		}
	    }
	}
	return $name
    }

    proc tildeexpand {name} {
	if {[string index $name 0] eq "~"} {
	    tailcall file normalize $name
	} else {
	    return $name
	}
    }
}
