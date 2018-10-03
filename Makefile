DEFINES = '{$$MODE OBJFPC} {$$COPERATORS ON} {$$TYPEDADDRESS ON} {$$INLINE ON} {$$MACRO ON}'
FLAGS += -vewn -Xs -XX -CX -OrG3
GPROF += -vewnh -gl -pg

TESTS = $(addprefix test/,$(shell ls test/))

.PHONY: clean install test $(TESTS)

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

clean:
	rm -rf build/ bin/

install: build/awful build/awful-cgi
	cp ./build/awful /usr/bin/awful
	cp ./build/awful-cgi /usr/bin/awful-cgi
	cp ./awful.man /usr/local/share/man/man1/awful

test/*: bin/awful
	bin/awful -i "$@/input.txt" -o "$@/result.txt" "$@/test.yuk"
	diff --ignore-trailing-space "$@/result.txt" "$@/output.txt"

test: $(TESTS)
