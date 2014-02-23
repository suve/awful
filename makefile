DEFINES = '{$$MODE OBJFPC} {$$COPERATORS ON} {$$INLINE ON} {$$MACRO ON}'
FLAGS = -Xs -XX -OG3

normal:
	echo $(DEFINES) > defines.inc
	fpc $(FLAGS) awful.pas   

cgi:
	echo $(DEFINES) '{$$DEFINE CGI}' > defines.inc
	fpc $(FLAGS) awful.pas -o'awful-cgi'

clean:
	rm *.o
	rm *.ppu


