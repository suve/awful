unit globals;

{$INCLUDE defines.inc}

interface

const VMAJOR = '0';
      VMINOR = '4';
      VBUGFX = '0';
      VREVISION = 31;
      VERSION = VMAJOR + '.' + VMINOR + '.' + VBUGFX;

Var GLOB_MS:Comp;  GLOB_dt:TDateTime;
    GLOB_SMS:Comp; GLOB_sdt:TDateTime;
    YukPath,YukName:AnsiString;

implementation

end.
