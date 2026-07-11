# Winserv 1.04 Introduction

### Command-line overview

The basic syntax for winserv invocation is the following:

    winserv subcommand service-name options [ args ...]

  
One notable exception to this rule is the *help*
subcommand that doesn't need any arguments (and ignores them, if any).
Some subcommands (showconfig, status) accept more than one service
name.  

##### winserv install *service-name* *service-options* *program* *args* ...

  
creates a service that runs *command* (any
executable) when started and stops when the program exits.
Command-line parameters for the command
may also be specified.  

##### winserv configure *service-name* *service-options* *program args ...*

  
modifies various parameters for the service in SCM and registry
databases. If the program is specified, it is stored in registry as a
new program to be started by this
winserv-based service.  

##### winserv uninstall *service-name*

  
marks a service for deletion. When it is stopped and all its handles
are closed, the service is removed from the SCM database.  

##### winserv showconfig *service-name1* *service-name2 ...*

  
shows the current service's parameters that may be modified with
the *configure* subcommand. Some parameters
make sense only for winserv-based services,
and they will not be shown for other services (see parameters
description below).  

##### winserv stop *service-name* *-nowait*

##### winserv pause *service-name* *-nowait*

##### winserv continue *service-name* *-nowait*

##### winserv usercontrol *service-name* -code *code*

  
These subcommands send control signals to the running service. *-nowait*
option means that the utility shouldn't wait until the service will
report an appropriate status for the request (stopped
for *stop*, paused
for *pause*, running
for *continue*).  

##### winserv start *service-name* *args ...*

  
Starts the service using the given
command-line arguments. If the service
is winserv-based, the arguments are stored
in the *ServiceArgs* environment variable.  

##### winserv restart *service-name* *args ...*

  
Restarts the service, i.e. stops it, waits for it to be stopped,
and then starts it with the arguments given.  

##### winserv status *service-name1* *service-name2 ...*

  
Prints out the current status of the services, one of: RUNNING, STOPPED,
PAUSED, START\_PENDING, PAUSE\_PENDING, CONTINUE\_PENDING,
STOP\_PENDING. The program's output is formatted like this:  

    Service: myservice
    Status: RUNNING
    Accepts: STOP

  
You see that the program prints the list of SCM control signals that
the service can accept now.  

### Service options

Using *install*
and *configure* subcommands, you can specify
parameters for the newly-created or configured
service. Some of the service options require an argument. Here is the
list of supported service options with arguments:  

  - \-displayname
    *user-visible display
    name of the service*  
  - \-description *the description of the service,
    usually one or two sentences*  
  - \-binary *pathname of winserv.exe, defaults to the
    invoked instance's pathname*  
  - \-ipcmethod *ipc method, one of: blind, pipe,
    stdio or qstdio*  
  - \-start *start mode, one of auto, demand
    or disabled*  
  - \-errorcontrol *error control mode, one of ignore,
    normal, severe or critical*  
  - \-\[no\]expand
  - \-\[non\]interactive
  - \-loadordergroup
    *load-order group name.
    See Platform SDK Documentation for details*  
  - \-depends *service1,service2... –
    comma-separated list of other
    services*  
  - \-user *the service will log on as this
    user*  
  - \-password *the user's password*

Winserv will refuse to set binary pathname and some
winserv-specific options
for non-winserv based services.
Use *-forceforeign* option to suppress this
behavior.  
  
Use *-expand* option to store the application's
command-line in registry as a REG\_EXPAND\_SZ
type of value. In this case, all references to environment variables
will be auto-expanded before starting
the application:  

    winserv install myappsrv -expand %SystemRoot%\MyApp.exe %ServiceArgs%

  
Note that you have to use -expand with %ServiceArgs% to pass
the service's command-line parameters
as extra arguments.
### IPC methods

Winserv can communicate with the underlying application or script
in three different ways, depending
on *-ipcmethod* option given
to *install*
or *configure* subcommands when the service
was installed:  

##### blind

It's the simpliest case, when the application is terminated with
TerminateProcess if the service is stopped. There is no way for
the application to do any cleanup, and it can't write to the event
log or accept pause/continue and other signals. This method must
be used only for 3rd-party
closed-source applications that don't have
any worthy data in memory that must be written on exit.  

##### stdio

Winserv forwards the SCM signals in the textual form to the
applications's standard input, and the application reports its state
on its standard output. The application can use special escape
sequences to write to the eventlog with specific level (error,
information, success, etc.), to signal its current status (paused,
running), to declare what SCM control codes it accepts.  
  
Any plain-text (escapeless) line from stdout
is just written to the event log at the information level, and any line
from stderr is written at the error level.  
  
This IPC method may be used for closed-source
application that doesn't know anything about winserv. In this case
you won't be able to terminate the application with SCM control code
(winserv stop); it must terminate by itself.  

##### qstdio

This method is similar to stdio, except that unescaped
plain-text strings aren't forwarded to the
event log. It may be useful if the application is too chatty.  

##### pipe

This method was designed especially
for non-console
[tclkits](http://wiki.tcl.tk/tclkit), where we don't have access
to normal stdin or stdout, but only to their emulation. The application
must open two named pipes on startup:  

    open \\\\.\\pipe\\winserv.scm.out.$service_name w+
    open \\\\.\\pipe\\winserv.scm.in.$service_name w+

  
and use the first one instead of stdout, and the second one instead
of stdin. In all other aspects this method is equivalent
to *stdio*.  
  
Don't change the order in which the pipes are opened\! If you do it,
the communication between winserv and the application can't
be established.  
  
If the named pipes are not opened after 30 seconds, winserv will
terminate the application.  

### Remote service management

You can prepend \\\\Machine\\ to the service name, thus specifying that
you want to manage a service on a named remote machine.
*For the subcommands that accept more than one service
in their arguments, the machine name may be specified for the first
service only*. All other services will be opened on that machine
automatically.  
  
When you aren't a domain administrator, it's typical situation when
you are able to access remote service control manager, but unable
to read remote registry database. Winserv will do the best it can. When
you use *winserv showconfig* to see
the service's parameters, most of them will be retrieved from
the service control manager, and the warning message will be printed
to let you know that the remote registry was inaccessible.  

### Winserv internals

If you want to write a winserv-based service
in a scripting language other than TCL, you may want to implement helper
modules, similar to TCL winserv support package. To do it, you have
to know what escape sequences winserv interprets when the application
writes to its standard output or the named pipe.  
  
Each string that winserv will parse must be terminated by a newline.
If you use escape sequences, you must put each sequence on a line
by itself.  
  

|           |                                                      |
| --------- | ---------------------------------------------------- |
| \\033 a   | **accept/deny control codes:**                       |
| \\033 a p | accept pause/continue control codes                  |
| \\033 a c | accept PARAMCHANGE                                   |
| \\033 a s | accept SHUTDOWN                                      |
| \\033 a n | accept NETBIND... codes                              |
| \\033 a r | reset; accept STOP and nothing more                  |
| \\033 a P | don't accept pause/continue                          |
| \\033 a C | don't accept PARAMCHANGE                             |
| \\033 a S | don't accept SHUTDOWN                                |
| \\033 a N | don't accept NETBIND... codes                        |
| \\033 s   | **set service status**                               |
| \\033 s p | the service is now paused                            |
| \\033 s P | the service is going to pause (PAUSE\_PENDING)       |
| \\033 s C | the service is going to continue (CONTINUE\_PENDING) |
| \\033 s r | the service is running                               |
| \\033 s S | the service is going to stop (STOP\_PENDING)         |
| \\033 e   | **add message to the event log:**                    |
| \\033 e i | at the information level                             |
| \\033 e e | at the error level                                   |
| \\033 e s | at the success level                                 |
| \\033 e w | at the warning level                                 |
| \\033 e a | at the audit/success level                           |
| \\033 e A | at the audit/failure level                           |

  
For eventlog escapes, the message that will be added must follow
the escape sequence on the same line. If the message contains embedded
newlines, they must be replaced with \\014 (form feed) control
character.  
  
When winserv receives a control code from the service manager, it sends
a line to the application's standard input. The line is just a name like
STOP or CONTINUE. You can get all possible names if you remove leading
SERVICE\_CONTROL\_ from macros used for the ControlService function.
For the user control codes (128–255),
one of CODE128..CODE255 will be sent.  
  
  
  

### Tcl-Specific notices

Porting [tclsvc](http://wiki.tcl.tk/tcsvc)-based applications to winserv
is easy. You should install a winserv support package at a place where
your interpreter can find it, and then add two lines of code at the
beginning of your script:  

    package require winserv
    winserv::startup

  
Note that it won't prevent your script from being run by \[tclsvc\]:
winserv support package checks *tcl\_service*
global varible and doesn't try to connect winserv if the variable
already exists.  
  
When running under winserv, *winserv::startup*
command sets the *tcl\_service*
and *tcl\_service\_winserv* global variables
to 1. It imports *eventlog* command into
the global namespace. This command is a
mostly-compatible (though less powerful)
replacement for the tclsvc's eventlog. It doesn't open the eventlog
directly; instead, it uses the active IPC method to  
pass messages to winserv.  
  
A lot of winserv-specific facilities become
available after winserv::startup.  

    winserv::accept ?[-]pause? ?[-]paramchange? ?[-]shutdown? ...

  
This command lets the application accept certain SCM control code
groups.If the dash precedes the group name, it means that this group
is not accepted any more.  

    winserv::accept reset

  
Use it to accept only the STOP code, as winserv does by default.  

    winserv::handle code script

  
This command defines a script to handle particular SCM control code
(STOP, PAUSE, CONTINUE, PARAMCHANGE, NETBINDADD, NETBINDREMOVE,
NETBINDDISABLE, NETBINDENABLE, as well
as user-defined codes CODE128..CODE255).  
  
For PAUSE and CONTINUE control codes the script can break or throw
an error to indicate that the service status wasn't really changed (so
it must leave running or paused, respectively).  
  
Use empty script argument to remove the handler.  
  

### Using winserv with console programs  

Unfortunately, applications for the console subsystem will almost always
require some modification to survive logoff. It's only 7 lines of C code
or so, and you can see src/tcl-nologoff.c
for an example.  
  
A lot of scripting language interpreters have a special variant
of executable in their Windows versions: the executable is linked
for the windows subsystem, not the console one, though it doesn't
provide GUI per se. I recommend to use this kind of interpreters
for your service, together with *-ipcmethod
pipe*.  
  
As of TCL (tclsh\*.exe console interpreter), nologoff.dll included
in the winserv support package takes care of making the interpreter
ready to survive logoff. Winserv::startup will load this dll. If you
use [freewrap](http://wiki.tcl.tk/freewrap) to create
a stand-alone executable, you should copy
this dll to the real filesystem and let the winserv support package know
where it is:  

    package require winserv
    set winserv::nologoff_dll c:/Unwrapped/nologoff.dll
    winserv::startup
