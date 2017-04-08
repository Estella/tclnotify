#!/usr/bin/env tclsh

set iconname "weechat"
set timeout 10500
set sound ""
if {[llength $::argv] != 0} {
 set sound [lindex $::argv 0]
}

# use /dev/dsp required for now

source notifyc.tcl

package require libnotify

set procsock ""

proc rn:rd {sock} {
  global procsock
  gets $sock comd
  set argv [split $comd " "]
  if {[string tolower [lindex $argv 0]] == "q"} {
   close $sock
   return
  }
  if {[string tolower [lindex $argv 0]] == "b"} {
   notify send [binary decode base64 [lindex $argv 1]] [binary decode base64 [lindex $argv 2]] $::iconname $::timeout
   if {$::sound != ""} {
    if {$procsock == ""} {
     set procsock [open "|ffmpeg -i $::sound -f oss /dev/dsp -loglevel error" r]; fileevent $procsock readable [list rn:closeprocess $procsock]
     return
    }
    if {[eof $procsock]} {
     set procsock [open "|ffmpeg -i $::sound -f oss /dev/dsp -loglevel error" r]; fileevent $procsock readable [list rn:closeprocess $procsock]
     return
    }
    return
   }
   return
  }
}

proc rn:closeprocess {proc} {
 global procsock
 close $proc
 set procsock ""
}

proc rn:accept {s a p} {
  chan configure $s -encoding utf-8 -buffering line
  chan event $s readable [list rn:rd $s]
}

socket -server rn:accept -myaddr 127.0.0.1 51001

vwait never
