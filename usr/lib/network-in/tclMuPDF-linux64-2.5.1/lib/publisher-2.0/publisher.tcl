##  publisher.tcl

##  publisher - publisher-subscribers pattern
##
##  Copyright (c) 2012-2020 <Irrational Numbers> : <aldo.w.buratti@gmail.com> 
##
##
## This library is free software; you can use, modify, and redistribute it
## for any purpose, provided that existing copyright notices are retained
## in all copies and that this notice is included verbatim in any
## distributions.
##
## This software is distributed WITHOUT ANY WARRANTY; without even the
## implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
##

#
# How to use 'publisher':
#   Read "publisher.txt" for detailed info.
#

package provide publisher 2.0

oo::class create publisher {
    variable myEvents myCallbacks 
        
    constructor {} {
        set myEvents {}
        array set myCallbacks {}
        # all publishers provide a "!destroyed" event
        my declare !destroyed
    }
    
    destructor {
        my notify !destroyed
    }
   
     # Publisher-side method
     #
     # Declare all the provided events.
     # NOTE: declaring an event twice, is not an error, it's only stupid.
     # On the subscribers-side, a subscribe can inspects all the provided events
     # with the 'events' method.
    method declare {args} {       
        eval lappend myEvents $args
         # remove duplicated events
        set myEvents [lsort -unique $myEvents]
    }

     # an invalid tag (subscriber-id) is a tag containing "glob" chars (*?)    
    method IsInvalidTag {tag} {
        expr [regexp -- {[*?]} $tag]
    }
    
     # Subscribers-side method
     #
     # register a callback for a given event.
     # 'tag' is simply an id denoting the caller (it should be used for unregister-ing).
     # 'tag' should not contain "glob" chars (?*)
    method register { ev tag callback } {        
        if { [lsearch -exact $myEvents $ev] == -1 } {
            error "event \"$ev\" not available"
        }
        if { [my IsInvalidTag $tag] } {
            error "tag \"$tag\" is not valid."        
        }        
        lappend myCallbacks($ev,$tag) $callback
    }
        
     # Subscribers-side method
     #
     # Unregister all the callbacks associated with a given tag
     #  for a single event or an evPattern.
     #  evPattern : event-name or "*"  (or any string with "glob" chars)
     #  tag: just a tag 
     # Notes:
     #  It's not an error if there's no registered event associated with tag.
     #  Raise an error if tag contains special glob chars (*?)
    method unregister {evPattern tag} {
        if { [my IsInvalidTag $tag] } {
            error "tag \"$tag\" contains disallowed chars."        
        }
        array unset myCallbacks $evPattern,$tag
    }

     # Publisher-side method
     #  
     # Send an event-notification to all subscribers.
     # The effect is to execute *synchronously* all the registered callbacks
     #  for that event.
     # Any error raised during the callback run is silently ignored.
    method notify {ev args} {         
        foreach { key hList } [array get myCallbacks $ev,*] {
            foreach func $hList {
              catch { uplevel #0 $func $args }
            }
        }
    }
    
     # Subscribers-side method
     #
     # events      --> lists all events
     # events *    --> lists all registered events with their tag and callback
     #                 e.g. {!ev1 tag1 {cb1 cb2} !ev1 tag2 cb3  !evX tagY cbZ }
     # events !a*  --> same as above, limited to events matching "!a*"    
    method events { {evPattern {}} } {
        if { $evPattern == {} } {
            return $myEvents
        }       
        set L {}
        foreach { key hList } [array get myCallbacks $evPattern,*] {
            lassign [split $key ","] ev tag
            lappend L $ev $tag $hList
        }
        return $L
    }
}
