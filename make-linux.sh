#!/bin/sh

set -x

if [ "$1" == "clean" ]; then
    rm -f logfmon *.o y.tab.c lex.yy.c y.tab.h *~
    exit
fi

CC="gcc"
CFLAGS="-I- -I. -I/usr/local/include $CFLAGS -D_LARGEFILE_SOURCE \
        -Wall -W -Wmissing-prototypes -Wmissing-declarations \
        -Wshadow -Wpointer-arith -Wcast-qual -Wsign-compare"
LDFLAGS="-L/usr/local/lib"
LIBS="-lm -lpthread"

YACC="bison -d -y"
LEX="lex"

[ ! -f y.tab.c ] && $YACC parse.y
[ ! -f lex.yy.c ] && $LEX lex.l

SRCS=`echo *.c| sed -e s'/event.c//'`
for i in $SRCS; do
    [ ! -f ${i%.c}.o ] && $CC $CFLAGS -c $i -o ${i%.c}.o
done

$CC $LDFLAGS -o logfmon $LIBS *.o
