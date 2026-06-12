# mupdf.tcl
#
# Startup utilities for the Tcl->MuPDF integration
#  Load sub-modules for all  the required Classes
#


namespace eval mupdf {
    variable _BaseDir
    set _BaseDir [file dirname [file normalize [info script]]]
    
    set ::auto_path [linsert $::auto_path 0 $_BaseDir/lib]
}

proc mupdf::_findDLL {dir pkgName} {
	set thisDir [file normalize ${dir}]

	set os $::tcl_platform(platform)
	switch -- $os {
		windows { set os win }
		unix    {
			switch -- $::tcl_platform(os) {
				Darwin { set os darwin }
				Linux  { set os linux  }
			}
		}
	}
	set majorVersion [lindex [split [package present Tcl] "."] 0]
	switch -- $majorVersion {
		8 {set vtag "86"}
		9 {set vtag "90"}
		default { error "tclMuPDF: Unsupported Tcl version" }
	}
    switch -- $pkgName {
      MuPDF -
      tkMuPDF {
        set libName "tkMuPDF"
      }
      tclMuPDF {
        set libName "tclMuPDF"
      }
      default {
        error "Unregistered package name \"$pkgName\""
      }
    }

	set tail_libFile ${libName}${vtag}[info sharedlibextension]
	 # try to guess the tcl-interpreter architecture (32/64 bit)
	set arch $::tcl_platform(pointerSize)
	switch -- $arch {
		4 { set arch x32  }
		8 { set arch x64 }
		default { error "${pkgName}: Unsupported architecture: Unexpected pointer-size $arch!!! "}
	}
	set dir_libFile [file join $thisDir ${os}-${arch}]
	if { ! [file isdirectory $dir_libFile ] } {
		error "${pkgName}: Unsupported platform ${os}-${arch}"
	}

	set full_libFile [file join $dir_libFile $tail_libFile]
    return $full_libFile
}

 #
 # basic module for publish/subscribe pattern
 #
package require publisher 2.0
  # helper for defining callbacks
proc oocallback {args} {
    linsert $args 0 [uplevel 1 [list self namespace]]::my
}


namespace eval mupdf {
	variable _classes
    variable _BaseDir

	proc classes {} {
		variable _classes
		return $_classes
	}

	proc classinfo {obj} {
		info object class $obj
	}

	oo::class create COMMON_TYPEMETHODS {
         # return the (sorted) list of current instances
    	method names {} {
        	lsort [info class instances [lindex [info level 0] 0]]    
    	}
	} 

     # create some basic classes whose implementation will be mostly written in C
     
	foreach clazz {Doc Page TextSearch} {
		lappend _classes [namespace current]::$clazz
		::oo::class create ${clazz}_C {
		    # Constructor and methods are written in C
        }
        uplevel #0 source [list [file join $_BaseDir class_${clazz}.tcl]]
	}
	unset clazz
}
