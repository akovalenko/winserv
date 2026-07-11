package require winserv

winserv::startup
winserv::accept pause

proc open_sock {} {
    set ::chanfd [socket -server {echosvr} 12345]
}

open_sock
winserv::handle pause {catch {close $chanfd} }
winserv::handle continue {catch {open_sock} } 

proc echosvr {chan host port} {
    puts $chan "Hello, $host:$port! Glad to meet you. 
I was called like this: $::env(ServiceName) $::env(ServiceArgs)."
    close $chan
}

vwait forever
