"\
WinServ 1.11 (c) 2004-2006 Anton Kovalenko / Sw4me.com\n\
LICENSE: Do what you want with this software, but don't blame me.\n\
\n\
Available subcommands: \n\
  Getting this help\n\
    winserv help \n\
\n\
  Service installation and management.\n\
    winserv install <name> [service options] <command> [<arg> ...]\n\
    winserv configure <name> [service options] [ <command> [<arg> ...] ]\n\
    winserv uninstall <name>\n\
    winserv showconfig <name1> [<name2> ... ]\n\
\n\
  Change & examine current service status.\n\
    winserv start <name> [arguments]\n\
    winserv stop <name> [-nowait]\n\
    winserv pause <name> [-nowait]\n\
    winserv continue <name> [-nowait]\n\
    winserv usercontrol <name> -code <control code>\n\
    winserv paramchange <name>\n\
    winserv restart <name> [arguments]\n\
    winserv status <name1> [<name2> ... ]\n\
\n\
Service options:\n\
    -displayname <user-visible service name>\n\
    -description <description>\n\
    -binary <path & filename of the winserv executable>\n\
    -ipcmethod <blind, pipe or stdio>\n\
    -start <auto, demand or disabled>\n\
    -errorcontrol <ignore, normal, severe or critical>\n\
    -expand or -noexpand  \n\
    -interactive or -noninteractive\n\
    -loadordergroup <group>\n\
    -depends service1,service2,...\n\
    -user <user name>\n\
    -password <password>\n\
    -forceforeign  (enables certain operations on non-WinServ services)\n\
\n\
NOTE: The service name may be given in the form \\\\<MACHINE>\\<service>,\n\
   that means remote service <service> on the <MACHINE>. \n\
\n\
For more information, go http://www.sw4me.com/products/winserv \n\
\n\
"
