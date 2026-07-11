# Winserv interface to TCL
# 
# (c) 2004 Anton Kovalenko, http://www.sw4me.com
# LICENSE: Do what you want with this software, but don't blame me.
#
# This script-only TCL package lets you use the same TCL source
# for both tclsvc-based and winserv-based service.

# if we are not a tclsvc-based service
package provide winserv 1.0
package provide eventlog 2.00

namespace eval winserv {
    set nologoff_dll [file join [pwd] [file dirname [info script]] nologoff.dll]
}

proc winserv::init {} {
    global tcl_service tcl_service_winserv env
    variable sv_name 
    variable ipcs 
    variable nologoff_dll

    if {![llength [info commands ::console]]} { load $nologoff_dll }
    set tcl_service 1
    set tcl_service_winserv 1

    if {[info exists env(ServiceIpcMethod)]} {
	set ipc_method [string tolower $env(ServiceIpcMethod)]
    } else {
	set ipc_method blind
    }
    set sv_name $env(ServiceName)
    switch -- $ipc_method {
	qstdio -
	stdio {
	    set ipcs(out) stdout
	    set ipcs(in) stdin
	    set ipcs(any) 1
	}
	pipe {
	    set ipcs(out) [open \\\\.\\pipe\\winserv.scm.out.$sv_name w+]
	    set ipcs(in) [open \\\\.\\pipe\\winserv.scm.in.$sv_name w+]
	    set ipcs(any) 1
	}
	default {
	    set ipcs(any) 0
	}
    }
    if {$ipcs(any)} {
	fconfigure $ipcs(in) -blocking no -buffering line
	fconfigure $ipcs(out) -buffering line
	fileevent $ipcs(in) readable winserv::_reader
    }
    namespace eval :: {namespace import winserv::eventlog}
    set ::argv0 $sv_name
    # don't alter argv
    handle STOP ::exit
}

proc winserv::_reader {} {
    variable ipcs
    if {[gets $ipcs(in) sig]!=-1} { _raise $sig }	
}
namespace eval winserv {namespace export eventlog}
proc winserv::eventlog {args} {
    variable ipcs
    set ll [llength $args]
    array set opts {-level information}
    if {!($ll % 2)} {
	# even argc, the level was given
	array set opts [lrange $args 0 end-2]
	foreach {opts(-level) msg} [lrange $args end-1 end] break
    } else {
	array set opts [lrange $args 0 end-1]
	set msg  [lindex $args end]
    }
    set msg [join [split $msg "\n"] "\014"]
    switch -- $opts(-level) {
	error -
	information  -
	warning -
	success -
	audit/success {
	    set pch [string index $opts(-level) 0]
	}
	audit/failure {
	    set pch A
	}
	default {
	    set pch e
	}
    }
    if {$ipcs(any)} { puts $ipcs(out) "\033e$pch$msg" }
}

proc winserv::handle {sig {script {}}} {
    variable handlers
    set sig [string toupper $sig]
    if {$script==""} {
	unset -nocomplain handlers($sig)
    } else {
	set handlers($sig) $script
    }
}

proc winserv::_raise {sig} {
    variable handlers
    set sig [string toupper $sig]
    set err 0
    if {[info exists handlers($sig)]} {
	set err [catch {
	    namespace eval :: $handlers($sig)
	} msg] 
    }
    switch -- $sig {
	CONTINUE {
	    if {$err} { status paused } else { status running } 
	}
	PAUSE {
	    if {$err} { status running } else { status paused } 
	}
    }
}

proc winserv::accept {args} {
    variable ipcs
    if {![info exists ::tcl_service_winserv]} {return}
    foreach arg $args {
	set upcase 0
	if {[string match -* $arg]} {
	    set upcase 1
	    set arg [string range $arg 1 end]
	}
	switch -- [string tolower $arg] {
	    pause -
	    continue { set pch p }
	    paramchange { set pch c }
	    shutdown { set pch s }
	    netbind* { set pch n }
	    reset { set pch r }
	}
	if {$upcase} { set pch [string toupper $pch] }
	if {$ipcs(any)} {
	    puts $ipcs(out) "\033a$pch"
	}
    }
}

proc winserv::bgerror {msg} {
    eventlog error "Tcl error:\n$msg"
}

proc winserv::status {status} {
    variable ipcs
    switch -glob -- [string tolower $status] {
	paused { set pch p }
	pause*pending  {set pch P}
	continue*pending  {set pch C}
	running {set pch r}
	start*pending {set pch s}
	stop*pending {set pch S}
	default {set pch r}
    }
    if {$ipcs(any)} {
	puts $ipcs(out) "\033s$pch"
    }
}

proc winserv::startup {} {
    if {![info exists ::tcl_service]} {
	# check if there is a service-name
	if {[info exists ::env(ServiceName)]} {
	    # we are started by winserv
	    init
	}
    }
}
