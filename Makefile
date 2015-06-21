
ifdef DEBUG_VERBOSE
CDEFS += -DDEBUG_VERBOSE
endif




# CFLAGS=-Wall -ansi
# CFLAGS=-g -ggdb -g3 -ggdb3 -Wall -ansi
CFLAGS=-g -ggdb -g3 -ggdb3 -Wall -Werror $(CDEFS) #-Wimplicit-function-declaration

OBJECTS=model.o builtinproc.o read.o print.o eval.o scheme.o

.PHONY: clean

all: tags scheme1 scheme

scheme: $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS)
	# echo '(begin (load "lib/stdlib.scm") (load "864sch/hello-elf.scm"))' | ./scheme
	cd 864sch ; echo '(begin (load "../lib/stdlib.scm") (load "hello-elf.scm"))' | ../scheme ; cd ..
	readelf -e 864sch/hello
	864sch/hello

scheme1: scheme1.o
	$(CC) $(CFLAGS) -o $@ $<

test: scheme scheme1
	echo '(begin (load "test/regression/specialforms.scm"))' | ./scheme
	echo '(begin (load "test/regression/specialforms.scm"))' | ./scheme1

GPATH GRTAGS GSYMS GTAGS:
	gtags -v

TAGS:
	find . \! -type d \( -path \*/RCS -o -path \*/CVS -o -path \*/.svn -o -path \*/.git \) -prune -o -type f \( -name \*.cc -o -name \*.cxx -o -name \*.cpp -o -name \*.C -o -name \*.CC -o -name \*.c\+\+ -o -name \*.c -o -name \*.h \) | xargs etags -f TAGS

cscope.out:
	cscope -Rb 2>/dev/null

CTAGS:
	find . \! -type d \( -path \*/RCS -o -path \*/CVS -o -path \*/.svn -o -path \*/.git \) -prune -o -type f \( -name \*.cc -o -name \*.cxx -o -name \*.cpp -o -name \*.C -o -name \*.CC -o -name \*.c\+\+ -o -name \*.c -o -name \*.h \) | xargs ctags -f CTAGS

tags: GPATH GRTAGS GSYMS GTAGS TAGS cscope.out CTAGS

clean:
	rm -f scheme scheme1 *.o GPATH GRTAGS GSYMS GTAGS TAGS cscope.out CTAGS
