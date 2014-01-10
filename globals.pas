unit globals;

{$INCLUDE defines.inc}

interface

const VMAJOR = '0';
      VMINOR = '3';
      VBUGFX = '3';
      VREVISION = 30;
      VERSION = VMAJOR + '.' + VMINOR + '.' + VBUGFX;

Var GLOB_MS:Comp;  GLOB_dt:TDateTime;
    GLOB_SMS:Comp; GLOB_sdt:TDateTime;
    YukPath,YukName:AnsiString;

    YukStdOut, YukStdErr : ^System.Text;

implementation

end.
