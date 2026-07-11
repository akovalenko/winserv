ifdef USE_MINGW
UTIL_PREFIX=
CC=$(UTIL_PREFIX)gcc
MC=
RC=$(UTIL_PREFIX)windres
# __USE_MINGW_ANSI_STDIO=0: the code uses MSVC printf conventions
# (%s means a wide string inside wide-char formats); mingw-w64's C99
# replacements would treat %s as narrow and truncate every string.
CFLAGS=-Os -O2 -DUNICODE=1 -D__USE_MINGW_ANSI_STDIO=0 -fomit-frame-pointer -Wall -owinserv.exe
LDFLAGS=-ladvapi32 -luser32
else
CC=cl
MC=mc
RC=rc
CFLAGS=/MD /nologo /DUNICODE=1 /Osigy /GA /GF /Gm-
LDFLAGS=advapi32.lib user32.lib
endif

default: winserv.exe

%.rc:	%.mc
	$(MC) "$<"

%.res:  %.rc
	$(RC) "$<"

%.res.o: %.res
	$(RC) -o "$@" "$<"

ifdef USE_MINGW
RESREADY=messages.res.o
else
RESREADY=messages.res
endif

winserv.exe: winserv.c $(RESREADY) usage.h
	$(CC) $(CFLAGS) $(LDFLAGS) winserv.c $(RESREADY)
ifdef USE_MINGW
	$(UTIL_PREFIX)strip "$@"
endif
	cp -f winserv.exe ../winserv.exe

nologoff.dll: tcl-nologoff.c
	$(CC) $(CFLAGS) /LD tcl-nologoff.c /Fenologoff.dll \
	/link /EXPORT:Nologoff_Init
	cp -f nologoff.dll ../tcl/nologoff.dll

usage.h: usage.txt Makefile
	echo "\"\\" >"$@"
	perl -n -p -e 's/\\/\\\\/g;s/$$/\\n\\/' <"$<" >>"$@"
	echo "\"" >>"$@"

clean:
	-rm MSG*.bin *.obj *.exe *.dll *.lib *.exp *.res.o *.o

archive: ../winserv.exe
	$(MAKE) clean
	cd ../.. && zip -9r winserv.zip winserv

distclean: clean
	-rm usage.h *.res *.RES *.rc

.PHONY:	clean distclean archive
