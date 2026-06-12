#  class_TextSearch.tcl
#
#  class  mupdf::TextSearch  extends class mupdf::TextSearch_C  (implemented in C)
#

#  - Constructor
#  The following commands create a new TextSearch object acting on a given mupdf::Doc
#    mupdf::TextSearch new $doc
#    mupdf::TextSearch create id $doc
#
#  - Destructor
#     $searchObj destroy
#     
#     TextSearch objects are automatically destroyed when the related mupdf::Doc
#     is destroyed.
#
#  - Methods
#    $searchObj docref
#    $searchObj currpage ?pageNumber?
#    $searchObj find _searchStr_ ?-max _N_? ?-currpage true/false?

#  inherithed from TextSearch_C
#    $searchObj _pagesearch ....   (low-level method used by 'find' *hidden*)    



oo::class create mupdf::TextSearch {
    superclass mupdf::TextSearch_C
	# hide internal C methods
	unexport _pagesearch
		
    # has-component publisher .. see constructor	
    variable -append DocRef
    variable -append CurrPageNumber
    variable -append FromTop
    
    constructor {docRef args} {
        set DocRef $docRef
         # BugFix: Tcl8.6.4 returns an error if $docRef is NOT an object,
         # instead of returning 0 (false).
         # For this reason, do both things: catch the error and check if false
        try {
            set isDoc [info object isa typeof $docRef mupdf::Doc]
        } on error {} {
            set isDoc false        
        }
        if { ! $isDoc } {
            error "\"$docRef\" must be an instance of mupdf::Doc"        
        }                

        set CurrPageNumber 0
        set FromTop true

         # create a publisher component and delegate some methods
        publisher create [self]::publisher
        oo::objdefine [self]  forward events     [self]::publisher events
        oo::objdefine [self]  forward register   [self]::publisher register
        oo::objdefine [self]  forward unregister [self]::publisher unregister  

        $DocRef register !destroyed [self]  [list [self] destroy]

        next {*}$args ;# initialize TextSearch_C
    }

    destructor {
        catch {$DocRef unregister * [self]}

        if { [info object isa object [self]::publisher] } {
            [self]::publisher destroy
        }
       next
    }

    method docref {} {
        return $DocRef
    }

     # get/set the current search page
    method currpage {args} {
        switch -- [llength $args] {
            0 { 
                return $CurrPageNumber
            }
            1 {
                set pageNum [lindex $args 0]
                set lastPage [expr [$DocRef npages] -1]
                if { $pageNum < 0 || $pageNum > $lastPage } {
                    error "page-number must be between 0 and $lastPage"
                }
                set CurrPageNumber $pageNum
                set FromTop true
                return $CurrPageNumber            
            }
            default {
                error wrong # args: should be "[self] currpage ?pageNumber?"
            }
        }
    }    
    
    method find {searchStr args} {
         # default 
        set max_hits 10
        set currpageOnly false
        
    	set usage "[self] find _searchStr_  ?-max _N_? ?-currpageonly true/false?"

    	while { $args != {} } {
    		set args [lassign $args opt]
            if { [llength $args] == 0 } {
    		  error "wrong # args: missing value for the last options \"$opt\""                 
            }
    		set args [lassign $args value]
            
    		switch -- $opt {
    		 "-max" {
    			set max_hits $value
                 # this is an arbitrary limit
                if { $max_hits > 100 } {
                    error "value for \"${opt}\" must be between 1 and 100"
                }
              }
              "-currpageonly" {
                set currpageOnly $value              
                if { ! [string is boolean $currpageOnly] } {
                    error "value for \"${opt}\" must be a boolean value"
                }
              }
    		 default {
    		 	error "bad option \"$opt\": should be \"$usage\"" 
    		 }
    		}
    	}
        
         # the following method will also update CurrPageNumber and
         #  FromTop will be set to false (i.e. next search will continue from the current position
        set L [my _Extended_find $DocRef $CurrPageNumber $searchStr $FromTop $max_hits $currpageOnly]
        return $L
    }   


     # Look for $searchStr from the current search-position on the current page
     # ( unless $resumeFromTop is true).
     # If $currpageonly is true, the search is limited to the current page
     #  ( you can change it with $searchObj currpage _N_ )
     # else the search may continue on the next pages until $max_hits are found
     # (or no more pages exist!).
     # Side-effect: CurrentPageNumber may be changed, FromTop becomes false

     # MUMBLING.. : this method may open a lot of pages.
     # Since you cannot simply do a "$doc closeallpages" sinces there may be
     # somepages in use before, evaluate the convenience to check if a page was
     # opened ($doc isopenedpage $n) before calling ($doc getpage $n) ;
     # you could then close these 'new' pages (but please, don't close the 
     # last scanned page...it could be useful for more search ...)
     # .. Think it over ...
    method _Extended_find {doc pageNumber searchStr resumeFromTop max_hits currpageOnly} {
        if { $searchStr == {} } {
            error "undefined search string"
        }
    	set L {}
    	set nPages [$DocRef npages]
    	while { true } {
             # the following may fail if pageNumber is invalid  .. OK
    		set pageHandle [$doc getpage $pageNumber]
    		set rectList [my _pagesearch $pageHandle $searchStr $max_hits $resumeFromTop]
    		foreach rect $rectList {
    			lappend L [list $pageNumber $rect]
    		}
    		incr max_hits [expr {-[llength $rectList]}]

            if { $currpageOnly } break
            
            if { $max_hits == 0 } break
            
            if { $pageNumber+1 == $nPages } { break }
            
      		incr pageNumber
    		set resumeFromTop true
    	}
        set CurrPageNumber $pageNumber
        set FromTop false
    	return $L
    }
       
}

 # add common methods to mupdf::TextSearch 
oo::objdefine mupdf::TextSearch { mixin mupdf::COMMON_TYPEMETHODS }
