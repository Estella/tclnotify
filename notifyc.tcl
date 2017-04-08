#!/usr/bin/env critcl

package require critcl
package provide libnotify 0.1

if {![critcl::compiling]} {
  puts "Error: not compiling."
  exit 2
}

foreach flag [split [exec pkg-config --libs libnotify] " "] {
critcl::ldflags $flag
}

foreach flag [split [exec pkg-config --cflags libnotify] " "] {
critcl::cflags $flag
}

critcl::ccode {
#include "libnotify/notify.h"

}

# In Tcl, command "notify send" will take as arguments:
# summary,text message,text [icon,text timeout,int-milliseconds]

namespace eval notify {
 critcl::cproc ::notify::sum-msg {char* summary char* message} ok {

  NotifyNotification* nf = notify_notification_new(summary, message, 0);
  notify_notification_set_timeout(nf, NOTIFY_EXPIRES_DEFAULT);
  if (!notify_notification_show(nf, 0)) return 1; // TCL_ERROR
  return 0; // TCL_OK

 }

 critcl::cproc ::notify::sum-msg-icon {char* summary char* message char* iconname} ok {

  NotifyNotification* nf = notify_notification_new(summary, message, iconname);
  notify_notification_set_timeout(nf, NOTIFY_EXPIRES_DEFAULT);
  if (!notify_notification_show(nf, 0)) return 1; // TCL_ERROR
  return 0; // TCL_OK

 }

 critcl::cproc ::notify::sum-msg-icon-exp {char* summary char* message char* iconname int expiry} ok {

  NotifyNotification* nf = notify_notification_new(summary, message, iconname);
  notify_notification_set_timeout(nf, expiry);
  if (!notify_notification_show(nf, 0)) return 1; // TCL_ERROR
  return 0; // TCL_OK

 }

 critcl::cproc ::notify::initialise {} ok {
  return (!(int)notify_init("Tcl application"));
 }

 proc ::notify::send {summary message args} {
  set hasicon 0
  set hasexpiry 0
  if {[llength $args] == 1} {
   set hasicon 1
  }
  if {[llength $args] >= 2} {
   set hasicon 1
   set hasexpiry 1
  }
  ::notify::initialise
  if {$hasicon} {set iconname [lindex $args 0]}
  if {$hasexpiry} {set timeout [lindex $args 1]}
  if {$hasexpiry && $hasicon} {
   ::notify::sum-msg-icon-exp $summary $message $iconname $timeout
  } elseif {$hasicon} {
   ::notify::sum-msg-icon $summary $message $iconname
  } else {
   ::notify::sum-msg $summary $message
  }
  ::notify::uninitialise
 }

 critcl::cproc ::notify::uninitialise {} void {
  notify_uninit();
 }
 namespace export send initialise uninitialise sum-msg sum-msg-icon sum-msg-icon-exp
 namespace ensemble create
}

critcl::load
