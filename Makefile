DEFINES = '{$$MODE OBJFPC} {$$COPERATORS ON} {$$TYPEDADDRESS ON} {$$INLINE ON} {$$MACRO ON}'
FLAGS += -vewn -Xs -XX -CX -OrG3
GPROF += -vewnh -gl -pg

PREFIX ?= /usr
DESTDIR ?= 

TESTS = $(addprefix test/,$(shell ls test/))


# -- variables end


.PHONY: all clean install test $(TESTS)

all: build/awful

clean:
	rm -rf build/ bin/

install: build/awful build/awful-cgi
	cp ./build/awful "$(DESTDIR)$(PREFIX)/bin/awful"
	cp ./build/awful-cgi "$(DESTDIR)$(PREFIX)/bin/awful-cgi"
	cp -p ./awful.man "$(DESTDIR)$(PREFIX)/share/man/man1/awful"

test: $(TESTS)


# -- PHONY targets end


bin/awful: build/awful
	mkdir -p bin/
	cp -a "$<" "$@"

bin/awful-cgi: build/awful-cgi
	mkdir -p bin/
	cp -a "$<" "$@"

build/awful: src/defines.inc src/gitsha.inc
	mkdir -p build/
	fpc $(FLAGS) src/awful.pas -o'build/awful'

build/awful-cgi: src/defines.inc src/gitsha.inc
	mkdir -p build/
	echo '{$$DEFINE CGI}' >> src/defines.inc
	fpc $(FLAGS) src/awful.pas -o'build/awful-cgi'

src/defines.inc:
	echo $(DEFINES) > src/defines.inc

src/gitsha.inc:
	echo "'`git rev-parse HEAD`'" > src/gitsha.inc

test/*: bin/awful
	bin/awful -i "$@/input.txt" -o "$@/result.txt" "$@/test.yuk"
	diff --ignore-trailing-space "$@/result.txt" "$@/output.txt"
