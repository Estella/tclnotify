## libnotify shim in CriTcl

(Dunno what I'm calling this. Lnotify? Critnotify? Critballoon? Tcl notify-send? GNOME Balloons for CriTcl?)

### Usage

Source from your script. Use commands under "notify":

```tcl
notify sum-msg [summary char*] [message char*]
notify sum-msg-icon [summary char*] [message char*] [iconname char*]
notify sum-msg-icon-exp [summary char*] [message char*] [iconname char*] [expiry int]
notify initialise
notify uninitialise
```

Internal. You can use it, but don't be surprised if it conks you out. Should be more or less self-explanatory.
sum-msg(-icon(-exp)) - Send a notification balloon. Message is HTML-formatted char* data.

```tcl
notify send [summary char*] [message char*] ([iconname optional without expiry char*] [expiry optional int]
```

Send a notification balloon. Message is HTML-formatted char* data.

### Example script:

A server for issuing balloons is included. Syntax:

    telnet localhost 51001

    b <base64 encoded summary> <base64 encoded message>

Send balloon.

    q

Disconnect.

Default icon is the weechat icon. Change as needed.

Also included is an example script for using this example script. Fittingly, it is a weechat plugin script.
