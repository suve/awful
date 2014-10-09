DEFINES = '{$$MODE OBJFPC} {$$COPERATORS ON} {$$TYPEDADDRESS ON} {$$INLINE ON} {$$MACRO ON}'
FLAGS = -vewn -Xs -XX -CX -OrG3
GPROF = -vewnh -gl -pg

normal:
	echo $(DEFINES) > defines.inc
	fpc $(FLAGS) awful.pas   

cgi:
	echo $(DEFINES) '{$$DEFINE CGI}' > defines.inc
	fpc $(FLAGS) awful.pas -o'awful-cgi'

gprof: 
	echo $(DEFINES) > defines.inc
	fpc $(GPROF) awful.pas

gprof-cgi:
	echo $(DEFINES) '{$$DEFINE CGI}' > defines.inc
	fpc $(GPROF) awful.pas -o'awful-cgi'

clean:
	rm *.o *.ppu *.a || echo 'Already clean!'

install:
	cp ./awful /usr/bin/awful
	cp ./awful-cgi /usr/bin/awful-cgi
	cp ./awful.man /usr/local/share/man/man1/awful
