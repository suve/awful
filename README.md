== _awful_

An ugly, general purpose script language, with an interpreter written in Object Pascal.
Licensed under zlib with acknowledgement (see LICENSE.txt).



Gute Gott, warum?
---------------
Because I was bored and needed something to occupy my brain with.
Also, because it seemed a nice challenge, and because it eventually proved very fun.

I tried to clean up the source somewhat before making the project open to see, 
but since I didn't make it all in time, some parts of the code may be really hard to read
(shoutout to the spaghetti-like parser). Well, hopefully all will get cleaned up with time.



Documentation
---------------
All available documentation is currently hosted on my [homepage wiki](http://svgames.pl/wiki).



Building
---------------
To compile, you are going to need Free Pascal Compiler 2.6.2 or newer.
_awful_ does not use any additional libraries and should successfully compile using just what's bundled with the compiler.

To build, just run make. I add `make clean` there because FPC sometimes crashes when it tries to recompile a file 
that is identical source-wise, but just has different compiler symbols defined at time of build. 
```
cd awful
make
make clean
make cgi
```


Running
---------------
If scriptname is ommitted (or -- is used), script file is read from stdin.
```
awful [-e errfile] [-o outfile] [-i infile] scriptfile [param] [...]

-e (-E)   File to redirect stderr to. File is overwritten (appended to).
-o (-O)   File to redirect stdout to. File is overwritten (appended to).
-i        File to use instead of stdin.
```
