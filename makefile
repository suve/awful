DEFINES = '{$$MODE OBJFPC} {$$COPERATORS ON}'
FLAGS = '-gl'

normal:
	echo $(DEFINES) > defines.inc
	fpc $(FLAGS) awful.pas   

cgi:
	echo $(DEFINES) '{$$DEFINE CGI}' > defines.inc
	fpc $(FLAGS) awful-cgi.pas   

clean:
	rm *.o
	rm *.ppu


