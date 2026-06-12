#  class_Doc.tcl
#
#  Class  mupdf::Doc    extends class mupdf::Doc_C  (implemented in C)

#  - Constructor
#  The following commands create a new Doc object
#    mupdf::Doc new _filename_
#    mupdf::Doc create id _filename_
#    mupdf::open _filename_ ?-password _pswd_?"
#  The recommanded way is to call "mupdf::open"
#
#  - Destructor
#     $docObj destroy
#     $doc quit        ;# alias for "$docObj destroy"
#     $doc close       ;# save all changes and then quit.
#   When a document is destroyed, all its related objects (Page, TextSearch, ..)
#   are automatically destroyed.
#
#  - Methods
#    $docObj warnings                                (* inherithed from Doc_C *)
#    $docObj resetwarnings                           (* inherithed from Doc_C *)
#    $docObj wasrepaired                             (* inherithed from Doc_C *)
#
#    $docObj version                                 (* inherithed from Doc_C *)
#    $docObj fullname                                (* inherithed from Doc_C *)
#    $docObj authentication                          (* inherithed from Doc_C *)
#
#    $docObj opwd _password_ | ""                    (* inherithed from Doc_C *)
#    $docObj upwd _password_ | ""                    (* inherithed from Doc_C *)
#    $docObj removepassword
#
#    $docObj npages                                  (* inherithed from Doc_C *)
#    $docObj getpage _n_
#    $docObj ispageopened  _n_
#    $docObj openedpages
#    $docObj closepage _n_
#    $docObj closallpages
#
#    $docObj haschanges                              (* inherithed from Doc_C *)
#    $docObj export _filename_  ....
#
#    $docObj fields                                  (* inherithed from Doc_C *)
#    $docObj signatures                              (* inherithed from Doc_C *)
#    $docObj addsigfield _fieldname_  ....
#    $docObj field _fieldname_ ?_new_value_?
#    $docObj flatten _fieldname_ ?_fieldname_ ...?   (* inherithed from Doc_C *)
#    $docObj fieldattrib _fieldname_  ....           (* inherithed from Doc_C *)
#
#    $docObj portfolio ...                           (* inherithed from Doc_C *)
#    $docObj anchor _name_                           (* inherithed from Doc_C *)
#
#    $docObj grafts                                  (* inherithed from Doc_C *)
#    $docObj graft $pageObj
#    $docObj embed .... 
#
#    $docObj newsearch ...
#
#	 $docObj addpage ...
#	 $docObj deletepage ...
#	 $docObj deletepages ...
#	 $docObj movepage ...                               



oo::class create mupdf::Doc {
	superclass mupdf::Doc_C
	 # hide internal C methods
	unexport _RemoveGraftMap

	 # has-component publisher .. see constructor

	 # OpenedPages is a dictionary listing all the opened pages (pagenumber)
	 # with their pageObj.
	 # NOTE that there's a 1:1 relationship between page-numbers and page-objs,
	 #  so this dictionary could have been inverted (i.e exchanged keys with values)
	 
	variable -append OpenedPages
	variable -append RelatedDocs

	constructor {args} {
		set OpenedPages  [dict create]
		set RelatedDocs  [dict create]

		 # create a publisher component and delegate some methods
		publisher create [self]::publisher
		oo::objdefine [self]  forward events     [self]::publisher events
		oo::objdefine [self]  forward register   [self]::publisher register
		oo::objdefine [self]  forward unregister [self]::publisher unregister

		next {*}$args
	}

	destructor {
		# unregister itself from all RelatedDocs notifications ..
		foreach relatedDoc [dict keys $RelatedDocs] {
			$relatedDoc unregister * [self]
		}

		if { [info object isa object [self]::publisher] } {
			[self]::publisher destroy
		}
		next
	}

	method quit {} {
		my destroy
	}

	 # save file before destroyng
	method close {} {
		if { [my haschanges] } {
			set origFilename [my fullname]
			# NOTE: you cannot overwrite an opened file,
			#  therefore save it with a different name (tmpName)
			#  then close it (quit) and finally rename tmpName
			set tmpFilename "${origFilename}.TMP"
			my export $tmpFilename

			# since $origFilename is still used by [self],
			# a cmd like 'file rename ...' will ALWAYS fail.
			# Use 'file copy ..' and this will work unless $origFilename
			#  is locked by an external app. (e.g. Acrobat)
			#   ... this kind of error is exactly what we need to solve ..
			set res [catch {file copy -force -- $tmpFilename $origFilename} errmsg]
			file delete $tmpFilename
			if { $res } {
				 # in case of error, don't quit, propagate the error ..
				error $errmsg
			}
		}
		my quit
	}


	method _removeOpenedPageCb {pageObj} {
		 # do a reverse search, we have the value,, then look for its pagenumber
		 # note: thisis weird, becuse the page-number of an opened page may change
		 #  due to addpage/deletepage
		set pageNum -1
		dict for {k v} $OpenedPages { if {$v eq $pageObj} { set pageNum $k; break } }
		if { $k != -1 } {
			dict unset OpenedPages $pageNum
		}
	}

	method getpage {n} {
		if { [dict exists $OpenedPages $n] } {
			return [dict get $OpenedPages $n]
		}
		set page [mupdf::Page new [self] $n]
		# when this page id destroyed, call _removeOpenedpageCb
		$page register !destroyed [self]  [oocallback _removeOpenedPageCb $page]
		dict set OpenedPages $n $page
		return $page
	}

#NEW
	 # when adding/deleting a page, the OpenedPage dictionary should be updated.
	 # On addpage:
	 #  *before* adding the new page J, all the keys (pagenumeber) for the opened-pages
	 #  greater-equal than J should be incremented by +1
	 # On deletepage:
	 #  *after* deleting the page J, all the keys (pagenumber) for the opened-pages
	 #  greater-equal than J should be incremented by -1
	 #  NOTE: in this case the key=J (if present) was previosly removed.
	 #
	method _renumberOpenedPagesFrom {J incr} {
		dict map {k v} $OpenedPages { 
			if {$k >= $J} {incr k $incr}
			set v $v
			}
	}
	
	#
	# $pdf addpage _i_ ?-size dx dy?
	#  if i == "end" --> add after the last page
	#
	#  default size: A4 size (595.0x842.0)
	method addpage {args} {
		set idx [next {*}$args] ;# .. may raise error
		 # if it didn't fail, update OpenedPages
		set OpenedPages [my _renumberOpenedPagesFrom $idx +1]
		return [my getpage $idx]
	}

	 # $pdf deletepage _i_"
	method deletepage {args} {
		lassign $args idx
		if { [llength $args] != 1 } {
			# this is expected to fail, but doing so we get the error message
			next {*}$args
			# the following command will be never reached because
			# we expect the above command will raise an error
			error "unexpected behavior in deletepage method"
		}
		 # don't care if it's a good idx or a nonsense string (even an empty string)
		if { [my ispageopened $idx] } {
			[my getpage $idx] close ;# this will remove $idx from OpenedPages, too.
		}
		next {*}$args
		set OpenedPages [my _renumberOpenedPagesFrom $idx -1]
		return
	}

	 # $pdf deletepages i0 i1"	
	method deletepages {i0 i1} {
		set N [my npages]
		incr N -1
		if { ! [string is digit $i0] || $i0 < 0 || $i0 > $N } { error "page number i0 must be between 0 and $N" }

		if { ! [string is digit $i1] || $i1 < 0 || $i1 > $N } { error "page number i1 must be between 0 and $N" }

		for {set i $i0} {$i<=$i1} {incr i} {
			my deletepage $i0  ;# always delete page i0, following pages will shift ...
		}
	}

	 # $pdf movepage _from_ _to_
	method movepage {args} {
		lassign $args from to
		next {*}$args
		 # trivial case: if from == to, do nothing.
		if { $from == $to } return
		 # save and remove fromPage (if present)
		set savedPageObj ""
		if { [dict exists $OpenedPages $from] } {
			set savedPageObj [dict get $OpenedPages $from]
			set OpenedPages [dict remove $OpenedPages $from]
		}
		set OpenedPages [my _renumberOpenedPagesFrom $from -1]
		set OpenedPages [my _renumberOpenedPagesFrom $to   +1]
		if {$savedPageObj ne ""} {
			$savedPageObj close
			# we must recreate the opened page with the same name !
			mupdf::Page create $savedPageObj [self] $to
			# when this page id destroyed, call _removeOpenedpageCb
			$savedPageObj register !destroyed [self]  [oocallback _removeOpenedPageCb $savedPageObj]
			dict set OpenedPages $to $savedPageObj
		}
		return
	}

	method ispageopened {n} {
		dict exists $OpenedPages $n
	}

	method openedpages {} {
		return [dict keys $OpenedPages]
	}

	method closepage {n} {
		if { [dict exists $OpenedPages $n] } {
			set page [dict get $OpenedPages $n]
			$page destroy ;# this will invoke the _removeOpenedPageCb callbak
		}
	}

	method closeallpages {} {
		foreach page [dict values $OpenedPages] {
			$page destroy  ;# this will invoke the _removeOpenedPageCb callbak
		}
	}

	method removepassword {} {
		my opwd ""
		my upwd ""
	}

	method export {filename} {
		# allow to (try to) export in itself. (this works only in incremental mode)
		set filename [file normalize $filename]
		if { $filename ne [my fullname] } {
			if { $filename in [mupdf::documentnames] } {
				error "cannot overwrite an opened PDF-file"
			}
		}
		next $filename
	}

	 # $pdf field _fieldname_
	 # or
	 # $pdf field _fieldname_ _value_    
	method field {fieldname args} {
		set value [next $fieldname {*}$args]
		# if OK and args != {}  i.e. if we updated some fields, then update all the opened pages
		if { $args != {} } {
			foreach page [dict values $OpenedPages] {
				$page _update
			}
			return
		} else {
			return $value
		}
	}

	method flatten {args} {
		next {*}$args
		foreach page [dict values $OpenedPages] {
			$page _update
		}
	}

	method addsigfield {fieldname pageNum x0 y0 x1 y1} {
		next $fieldname $pageNum $x0 $y0 $x1 $y1
		if { [dict exists $OpenedPages $pageNum] } {
			set page [dict get $OpenedPages $pageNum]
			$page _update
		}
	}

	method _OnDestroyedRelatedDoc {relatedDoc mapID} {
		my _RemoveGraftMap $mapID
		dict unset RelatedDocs $relatedDoc
	}

	method graft {pageObj} {
		try {
			set relatedDoc [$pageObj docref]
		} on error {} {
			error "\"$pageObj\" must be a mupdf::Page"
		}

		set relatedDoc [$pageObj docref]
		set mapID "GMAP_$relatedDoc"
		set graftID [next $pageObj $mapID]
		# if everything is OK ..

		# when the relatedDoc will be closed, this mapID can be destroyed.
		if { ! [dict exists $RelatedDocs $relatedDoc] } {
			dict set RelatedDocs $relatedDoc 1
			$relatedDoc register !destroyed [self] [oocallback _OnDestroyedRelatedDoc $relatedDoc $mapID]
		}
		return $graftID
	}

	method embed {graftKey pageNum args} {
		next $graftKey $pageNum {*}$args  ;# may raise an error message
		if { [dict exists $OpenedPages $pageNum] } {
			set page [dict get $OpenedPages $pageNum]
			$page _update
		}
	}

	method newsearch {args} {
		mupdf::TextSearch new [self] {*}$args
	}

}

 # add common methods to mupdf::Doc
oo::objdefine mupdf::Doc { mixin mupdf::COMMON_TYPEMETHODS }


 # ---------------------------------------------------------------------------
 # Utilities
 # ---------------------------------------------------------------------------

 ##
 ##  mupdf::printwarnings
 ##
namespace eval mupdf {
	variable _PRINT_WARNINGS false

	proc printwarnings {args} {
		variable _PRINT_WARNINGS
		 # safe restore in case someone hacked this variable
		if { ![info exists _PRINT_WARNINGS] || ! [string is boolean ${_PRINT_WARNINGS}] } {
			puts "Warning: missing or bad value for mupdf::_PRINT_WARNINGS. restored to \"true\""
			set _PRINT_WARNINGS true
		}
		switch -- [llength $args] {
			0 { return ${_PRINT_WARNINGS} }
			1 {
				set val [lindex $args 0]
				if { $val eq ""  ||  ![string is boolean $val] } {
					error "expected boolean value but got \"$val\""
				}
				set _PRINT_WARNINGS $val
			}
			default {
				set myName [lindex [info level 0] 0]
				error "wrong # args: must be: $myName ?boolean?"
			}
		}
	}
}


proc mupdf::open {filename args} {
	set usage "mupdf::open filename ?-password pswd?"
	while { $args != {} } {
		set args [lassign $args arg]
		switch -- $arg {
		 "-password" {
		 	if { $args == {} } {
				error "wrong # args: should be \"$usage\"" 
			}
			set args [lassign $args password]
		 }
		 default {
		 	error "bad option \"$arg\": should be \"$usage\"" 
		 }
		}
	}

	set pdf [Doc new $filename]
	if { [info exists password] } {
		set status [$pdf _insertpassword $password]
	} else {
		if { [$pdf authentication] == "failed" } {
			if { [catch {package present Tk}] } {
				set askMethod [cli_passwordhelper]
			} else {
				set askMethod [tk_passwordhelper]		
			}
			try {
				set pswd [uplevel #0 $askMethod $filename]
			} on error e {
				$pdf destroy
				error $e
			}
			set status [$pdf _insertpassword $pswd]
		} else {
			set status true
		}
	}
	if { ! $status } {
		$pdf destroy
		return -code error -errorcode "MUPDF WRONGPASSWORD" "wrong password"
	}
	return $pdf
}

 # create a new empty PDF (0 pages)
 # return a pdfObj to be used in subsequent operations (addpage ....)
 # NOTE:
 # if filename is locked by another process, this command raise an error like the follwing:
 #   "error copying "..../Tpt_NoPage.pdf" to "..filename..": permission denied
 #
proc mupdf::new {filename} {
	if { [mupdf::isopen $filename] } {
		error "\"$filename\" is currently used by this process"
	}
	 # may fail if it's locked by anoter process
	variable _BaseDir
	file copy -force ${_BaseDir}/Tpt_NoPage.pdf $filename
	
	return [mupdf::open $filename]
}


  ## list all opened documents (as object-commnds)
proc mupdf::documents {} {
	mupdf::Doc names
}

  ## list all opened documents (as normalized fullnames)
  ## NOTE: "opened" means "opened by mupdf in this process"
proc mupdf::documentnames {} {
	set L {}
	foreach docObj [documents] {
		lappend L [$docObj fullname]
	}
	return $L 
}

  ## check if a given filename is a currently opened document
  ## NOTE: "opened" means "opened by mupdf in this process""
proc mupdf::isopen {filename} {
	 # NOTE: filenames returned by [documentnames] are normalized with the same
	 #  identical logic;
	 #  therefore it's enough to check if the "normalized names" are identical.
	expr {[file normalize $filename] in [documentnames]}
}

  ##  just for 1.x compatibility
proc mupdf::isobject {obj} {
	info object is object $obj
}



  ## -- utilities for password -----------------------------------------------

 ## === Internal procs. =======================================================
 ##  WARNING: these are internal and unsupported procs. 
 ##           Do not use them in your apps!
 ## ===========================================================================

namespace eval mupdf {
	variable _PasswordHelper
	variable _SerialNo
	
	set _PasswordHelper(cli,default) mupdf::_cli_askpassword
	set _PasswordHelper(tk,default)  mupdf::_tk_askpassword
	set _PasswordHelper(cli) $_PasswordHelper(cli,default)
	set _PasswordHelper(tk)  $_PasswordHelper(tk,default)

	set _SerialNo 0
}


proc mupdf::_newSerialNo {} {
	variable _SerialNo
	incr _SerialNo
}

proc mupdf::cli_passwordhelper {args} {
	_passwordhelper cli {*}$args
}
proc mupdf::tk_passwordhelper {args} {
	_passwordhelper tk {*}$args
}

   # get/set
proc mupdf::_passwordhelper {mode args} {
	# mode is cli or tk
	variable _PasswordHelper
	
	switch -- [llength $args] {
		0 { return $_PasswordHelper($mode) }
		1 {
			set cb [lindex $args 0]
			if { $cb == "" } {
				set _PasswordHelper($mode)  $_PasswordHelper($mode,default)
			} else {
				set _PasswordHelper($mode) $cb
			}
		}
		default {
			error "wrong # args: should be \"mupdf::${mode}_passwordhelper ?command?\""
		}
	}
}

 # very very simple
proc mupdf::_cli_askpassword {filename} {
	puts -nonewline stdout "Enter password for \"[file tail $filename]\":" ; flush stdout
	gets stdin
}

 # ask with timeout
proc mupdf::_cli_askpassword_timeout {timeout filename} {
 	set passGVarName "::mupdf::__TIMEOUT_[_newSerialNo]"
 	puts stdout "Enter pass for $filename ($timeout seconds):" ; flush stdout
 	 # set timeout and fileevent on stdin ;
 	 #  both the timeout and fileevent callback will set the ::PASS global variable
 	set afterID [after [expr {1000*$timeout}] [list set $passGVarName "none"] ]
	set oldCmd [fileevent stdin readable]
	fileevent stdin readable [list apply { {f gvarname} {
		upvar #0 $gvarname var
		set var [gets $f]
	}} stdin $passGVarName]
	vwait $passGVarName
	 # -- reset timeout and fileevent
	after cancel $afterID
	fileevent stdin readable $oldCmd
	
	 # get the result from the global variable, and unset it !
	set x [set $passGVarName]
	unset $passGVarName
	return $x
 }

 
proc mupdf::_tk_askpassword {filename} {
	 # to do:  center the window
	set uniqueID [_newSerialNo]
	set passGVarName "::mupdf::__PASS_${uniqueID}"

	set password ""
	set topW [toplevel .ask_${uniqueID} -padx 10 -pady 10]
	wm title $topW [file tail $filename]
	wm attributes $topW -topmost true
	label $topW.label -text "Enter password"
	entry $topW.entry -textvariable $passGVarName
	bind $topW.entry <Key-Return> {destroy [winfo toplevel %W]}
	pack $topW.label $topW.entry -side left 
	focus $topW.entry

	tkwait window $topW
	after 0 [list unset $passGVarName]
	return [set $passGVarName]
}

proc mupdf::_tk_askpassword:timeout {filename} {
	 # to do:  center the window
	set uniqueID [_newSerialNo]
	set passGVarName "::mupdf::__PASS_${uniqueID}"

	set password ""
	set topW [toplevel .ask_${uniqueID} -padx 10 -pady 10]
	wm title $topW [file tail $filename]
	wm attributes $topW -topmost true
	label $topW.label -text "Enter password"
	entry $topW.entry -textvariable $passGVarName
	bind $topW.entry <Key-Return> {destroy [winfo toplevel %W]}
	pack $topW.label $topW.entry -side left
	focus $topW.entry

	set afterID [after [expr {1000*$timeout}] [list destroy $topW] ]

	tkwait window $topW
	after 0 [list unset $passGVarName]
	return [set $passGVarName]
}
