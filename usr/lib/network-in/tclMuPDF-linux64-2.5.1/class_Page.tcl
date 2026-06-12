#  class_Page.tcl
#
#  class  mupdf::Page    extends class mupdf::Page_C  (implemented in C)
#  plus
#         mudf::imagepattern command.

#  - Constructor
#  The direct constructor is rarely used.
#  Usually a new Page is created starting from a Doc object
#    set pageObj [$docObj getpage _n_]
#   Note that if page _n_ is already opened, the previous method returns the same
#    pageObj
#
#  - Destructor
#     $pageObj destroy
#     $pageObj close        ;# alias for "$pageObj destroy"
#
#  - Methods
#    $pageObj pagenumber                             (* inherithed from Page_C *)
#    $pageObj size                                   (* inherithed from Page_C *)
#    $pageObj savePNG _filename_ ....                (* inherithed from Page_C *)
#    $pageObj saveImage _tkImage_ ....               (* inherithed from Page_C *)
#    $pageObj blocks                                 (* inherithed from Page_C *)
#    $pageObj lines                                  (* inherithed from Page_C *)
#    $pageObj text                                   (* inherithed from Page_C *)
#
#    $pageObj images list  ...                       (* inherithed from Page_C *)
#    $pageObj images extract  ...                    (* inherithed from Page_C *)
#
#    $pageObj addimage ...                           (* inherithed from Page_C *)
#
#    $pageObj annots                                 (* inherithed from Page_C *)
#    $pageObj annot create _type_ .....              (* inherithed from Page_C *)
#    $pageObj annot ?get? _annotID_                  (* inherithed from Page_C *)
#    $pageObj annot ?get? _annotID_ -option          (* inherithed from Page_C *)
#    $pageObj annot ?set? _annotID_ -option value ...(* inherithed from Page_C *)
#    $pageObj annot flatten _annotID_ ...            (* inherithed from Page_C *)
#    $pageObj annot delete _annotID_ ...             (* inherithed from Page_C *)

# Command for setting the filename pattern of the extracted images
# ( see above $pageObj images extract ... )
#
#   mupdf::imagepattern
#   mupdf::imagepattern _newPattern_



oo::class create mupdf::Page {
    superclass mupdf::Page_C
    # has-component publisher .. see constructor
    
    variable -append DocRef 

    constructor {docRef pageNum} {       
        set DocRef  $docRef

         # create a publisher component and delegate some methods
        publisher create [self]::publisher
        oo::objdefine [self]  forward events     [self]::publisher events
        oo::objdefine [self]  forward register   [self]::publisher register
        oo::objdefine [self]  forward unregister [self]::publisher unregister

		 # when DocRef is destroyed, then destroy this page        
        $DocRef register !destroyed [self]  [list [self] destroy]                

        next $DocRef $pageNum
    }

    destructor {
        $DocRef unregister * [self]
        if { [info object isa object [self]::publisher] } {
            [self]::publisher destroy
        }
       next
    }
    
    method close {} {
        my destroy
    }
    
    method docref {} {
        return $DocRef
    }
}

 # add common methods to mupdf::Page 
oo::objdefine mupdf::Page { mixin mupdf::COMMON_TYPEMETHODS }



 ##
 ##  mupdf::imagepattern
 ##
namespace eval mupdf {

    variable _IMG_PATTERN_SYMBOLS "pPiI"  ;#  CONSTANT
    variable _IMG_PATTERN  ""
    variable _IMG_POSITIONAL_PATTERN ""

    proc __positional_pattern { format symbols } {
        set rexpr "%(\[0-9\]*)(\[$symbols\])" ;# if symbols is "ABC" --> %([0-9]*)([ABC])
        set format [regsub -all $rexpr $format  {%\20\1d}]
      
        set symPos 1
        foreach sym [split $symbols ""] {
             # replace "%S"  with "%i$""   ;#   S is the symbol, i is its position
            set format [regsub -all "%${sym}" $format "%${symPos}\$"]   
            incr symPos
        }
        return $format 
    }

    proc __used_symbols { pattern symbols } {
        set usedSymbols ""
        set rexpr "%\[0-9\]*(\[$symbols\])" ;# if symbols is "ABC" --> %[0-9]*([ABC])
        foreach {match sym} [regexp -all -inline $rexpr $pattern] {
            if { [string first $sym $usedSymbols] == -1 } {
                append usedSymbols $sym
            }
        }
        return $usedSymbols
    }

    proc _used_symbols {pattern}  {
        variable _IMG_PATTERN_SYMBOLS
        __used_symbols $pattern ${_IMG_PATTERN_SYMBOLS}
    }

    proc _positional_pattern {pattern}  {
        variable _IMG_PATTERN_SYMBOLS
        __positional_pattern $pattern ${_IMG_PATTERN_SYMBOLS}
    }

    proc imagepattern {args} {
        variable _IMG_PATTERN
        switch -- [llength $args] {
            0 { return ${_IMG_PATTERN} }
            1 {
                variable _IMG_POSITIONAL_PATTERN
                variable _IMG_USED_SYMBOLS

                set pattern [lindex $args 0]        
                set _IMG_PATTERN $pattern        
                set _IMG_USED_SYMBOLS  [_used_symbols ${_IMG_PATTERN}]
                set _IMG_POSITIONAL_PATTERN [_positional_pattern ${_IMG_PATTERN}]                    
            }
            default {
                set myName [lindex [info level 0] 0]
                error "wrong # args: must be: $myName ?pattern?"
            }            
        }    
    
    }
    
    imagepattern "IM-%4p"
}
