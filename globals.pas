unit globals;

{$INCLUDE defines.inc}

interface
   uses Values;

const VMAJOR = '0';
      VMINOR = '4';
      VBUGFX = '1';
      VREVISION = 32;
      VERSION = VMAJOR + '.' + VMINOR + '.' + VBUGFX;

Var GLOB_MS:Comp;  GLOB_dt:TDateTime;
    GLOB_SMS:Comp; GLOB_sdt:TDateTime;
    YukPath,YukName:AnsiString;

Type TFileInfo = record
        Name : AnsiString;
        Cons : Array[0..1] of PValue
        end;

Var FileIncludes : Array of TFileInfo;
    ParamNum : LongWord;

Type TKeyVal = record
        Key, Val : AnsiString
        end;
     
     TKeyValArr = Array of TKeyVal;

{$IFDEF CGI}
Type TCookie = record
        Name, Value : AnsiString
        end;

Var Headers:TKeyValArr;
    Cookies:Array of TCookie;
{$ENDIF}

implementation

end.
