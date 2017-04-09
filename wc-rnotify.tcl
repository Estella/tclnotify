#!/usr/bin/env tclsh
# Remote Notification Script v1.4
# by Gotisch <gotisch@gmail.com>
# See LICENSE.wc-rnotify.tcl - Ellenor Malik <janiceagnesjohnson@gmail.com>
#
# With help of this script you can make weechat create notification bubbles
# in ubuntu or any other distribution that supports libnotify.
#
# Changelog:
# 1.4
#		fixed problem with reserved characters preventing notification (see http://wiki.tcl.tk/1353) (thanks Ongy)
# 1.3
#       fixed yet more typos and a possible problem with notifications not showing when they should.
# 1.2
#       fixed small typo that prevented remote notification (thanks Jesse)
# 1.1
#       added setting: privmessage to customize notifications of messages in query
# 1.0
#       initial release
#
# How does it work?
#
# The script inside weechat will either call libnotify directly, or it will
# send the data to the "server" listening on a port which will call the
# libnotify executable and create the notification. This "remote" option
# is the main use of the script.
#
# Example 1:    Weechat runs on the local pc
#       /tcl load rnotify.tcl
#       and set the port
#       /set plugins.var.tcl.rnotify.port local
#
# Example 2:    Weechat runs on a remote pc and you login via ssh port you
#       want to use is 4321
#       sh location/of/rnotify.tcl 4321 & ssh -R 4321:localhost:4321 username@host
#       on server you start weechat (or resume screen or whatever).
#       Then inside weechat
#       /tcl load rnotify.tcl
#       and set the port
#       /set plugins.var.tcl.rnotify.port 4321
#
# General Syntax:
#       In weechat
#       /set plugins.var.tcl.rnotify.port <portnumber to send notifies to/ or local>
#       To get notifications for private messages set:
#       /set plugins.var.tcl.rnotify.privmessage [no(default)|all|inactive]
#           no - no notifications for private messages (besides on highlight)
#           all - notifications for all private messages
#           inactive - notifications only for messages that are not the currently active buffer
#       As script
#       rnotify.tcl <portnumber to listen on>
#       if no port is given it will listen on 1234.
#
# Requirements:
#       libnotify and critcl on the machine notifying
#
# Possible problems:
#       It could be other programs send data to the notify port when using remote
#       mode. This will then lead to the following: either break the script, or
#       make weird notification bubbles.

if {[namespace exists ::weechat]} {
	# We have been called inside weechat
	namespace eval weechat::script::rnotify {
		weechat::register "rnotify" {Gotisch gotisch@gmail.com} 2.0 {dual MIT and GPL3+} {Sends highlights to specialised daemon on local machine, optionally remote via SSH} {} {}
		proc highlight { data buffer date tags displayed highlight prefix message } {
			set tags [split $tags ","]
			set oldfix $prefix
			set message [string map {& &amp; < &lt; > &gt;} $message]
			if {[lsearch -exact $tags irc_action] != -1} {
				set nick_nick [lindex $tags [lsearch -regexp $tags {^nick_.+$}]]
				set nickfix [string range $nick_nick 5 end]
				set prefix $nickfix
			}
			set buffername [weechat::buffer_get_string $buffer short_name]
			set fullbuffername [weechat::buffer_get_string $buffer full_name]
			set bufthing [split $fullbuffername "."]
			if {[lindex $bufthing 0] == "irc"} {
				set ircnetwork [lindex $bufthing 1]
			} else {
				set ircnetwork [lindex $bufthing 0]
				append ircnetwork "."
				append ircnetwork [lindex $bufthing 1]
			}
			if {$buffername != $prefix} {
				set buffername [format "%s (in %s) on %s" $prefix $buffername $ircnetwork]
				if {$highlight == 0} { return $::weechat::WEECHAT_RC_OK }
			} else {
				if {![string equal -nocase [weechat::config_get_plugin privmessage] "all"]} {
					if {![string equal -nocase [weechat::config_get_plugin privmessage] "inactive"] || [string equal [weechat::buffer_get_string [weechat::current_buffer] short_name] $buffername]} {
						if {$highlight == 0} { return $::weechat::WEECHAT_RC_OK }
					}
				}
				set buffername [format "%s on %s" $prefix $ircnetwork]
			}
			if {[lsearch -exact $tags irc_action] != -1} {
				set message [format "%s %s" $oldfix $message]
			}
			notify $buffername $message
			return $::weechat::WEECHAT_RC_OK
		}
		proc notify {title text} {
			catch {
				set sock [socket -async localhost [weechat::config_get_plugin port]]
				puts $sock [format "b %s %s" [binary encode base64 $title] [binary encode base64 $text]]
				puts $sock "q"
				close $sock
			}
		}
		weechat::hook_print "" "irc_privmsg" "" 1 [namespace current]::highlight {}
	}
} else {
	# We probably have been called from the shell
	puts stdout "use included rnotifyd"
}
