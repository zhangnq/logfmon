# $Id$

.SUFFIXES: .c .o .y .h
.PHONY: clean regress index.html

PROG= logfmon
VERSION= 1.1

OS!= uname
REL!= uname -r

# This must be empty as OpenBSD includes it in default CFLAGS.
DEBUG=

FILEMON= kqueue
SRCS= logfmon.c log.c rules.c xmalloc.c file.c context.c \
      cache.c threads.c getln.c parse.y lex.c action.c event-${FILEMON}.c

YACC= yacc -d

CC= cc
CFLAGS+= -DBUILD="\"$(VERSION) ($(FILEMON))\""
.ifdef DEBUG
CFLAGS+= -g -ggdb -DDEBUG
LDFLAGS+= -Wl,-E
.endif
#CFLAGS+= -pedantic -std=c99
CFLAGS+= -Wno-long-long -Wall -W -Wnested-externs -Wformat=2
CFLAGS+= -Wmissing-prototypes -Wstrict-prototypes -Wmissing-declarations
CFLAGS+= -Wwrite-strings -Wshadow -Wpointer-arith -Wcast-qual -Wsign-compare
CFLAGS+= -Wundef -Wshadow -Wbad-function-cast -Winline -Wcast-align

PREFIX?= /usr/local
INSTALLBIN= install -g bin -o root -m 555
INSTALLMAN= install -g bin -o root -m 444

INCDIRS= -I- -I. -I/usr/local/include
LDFLAGS+= -L/usr/local/lib
LIBS= -lm
.if ${OS} == "OpenBSD" || ${OS} == "FreeBSD"
LDFLAGS+= -pthread
.else
LIBS+= -lpthread
.endif

.if ${OS} == "NetBSD"
CFLAGS+= -DNO_STRTONUM
SRCS+= compat/strtonum.c
.endif

OBJS= ${SRCS:S/.c/.o/:S/.y/.o/:S/.l/.o/}

DISTFILES= *.[chyl] GNUmakefile Makefile *.[1-9] README \
	`find examples regress compat rc.d -type f -and ! -path '*CVS*'`

CLEANFILES= ${PROG} *.o compat/*.o y.tab.c y.tab.h .depend \
	${PROG}-*.tar.gz *.[1-9].gz *~ *.ln ${PROG}.core

.c.o:
		${CC} ${CFLAGS} ${INCDIRS} -c ${.IMPSRC} -o ${.TARGET}

.y.o:
		${YACC} ${.IMPSRC}
		${CC} ${CFLAGS} ${INCDIRS} -c y.tab.c -o ${.TARGET}

all:		${PROG}

${PROG}:	${OBJS}
		${CC} ${LDFLAGS} -o ${PROG} ${LIBS} ${OBJS}

dist:		clean
		tar -zxc \
			-s '/.*/${PROG}-${VERSION}\/\0/' \
			-f ${PROG}-${VERSION}.tar.gz ${DISTFILES}

depend:
		mkdep ${CFLAGS} ${SRCS}

install:	all
		${INSTALLBIN} ${PROG} ${PREFIX}/sbin/${PROG}
		${INSTALLMAN} ${PROG}.8 ${PREFIX}/man/man8/
		${INSTALLMAN} ${PROG}.conf.5 ${PREFIX}/man/man5/

uninstall:
		rm -f ${PREFIX}/sbin/${PROG}
		rm -f ${PREFIX}/man/man8/${PROG}.8
		rm -f ${PREFIX}/man/man5/${PROG}.conf.5

clean:
		rm -f ${CLEANFILES}
