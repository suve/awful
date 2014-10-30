unit globals;

{$INCLUDE defines.inc}

interface
   uses Values;

const
   VMAJOR = '0';
   VMINOR = '5';
   VBUGFX = '6-dev';
   VREVISION = 42;
   VERSION = VMAJOR + '.' + VMINOR + '.' + VBUGFX;
      
   FULLNAME = 'awful'
              {$IFDEF  CGI}+'-cgi' {$ENDIF}
              {$IFDEF FCGI}+'-fcgi'{$ENDIF}
              ;

   dtf_def_fpc = 'yyyy"-"mm"-"dd" "hh":"nn'; // default format for FPC's DateTimeToString()
   dtf_def_yuk = 'Y-M-D H:I';                // default format for awful's dt_ToString()

Var
   GLOB_MS:Comp;  GLOB_dt:TDateTime;
   GLOB_SMS:Comp; GLOB_sdt:TDateTime;
   
   YukPath,YukName:AnsiString;
   ScriptName:AnsiString;

Type
   TFileInclude = record
      Name : AnsiString;
      Cons : Array[0..1] of PValue
   end;

Var
   FileIncludes : Array of TFileInclude;
   FileHandles : Array of TFileHandle;
   ParamNum : LongWord;

Type
   TKeyVal = record
      Key, Val : AnsiString
   end;
     
   TKeyValArr = Array of TKeyVal;

{$IFDEF CGI}
Type
   TCookie = record
      Name, Value : AnsiString
   end;

Var
   Headers:TKeyValArr;
   Cookies:Array of TCookie;
{$ENDIF}

Function BuildNum():ShortString; Inline;


implementation

Function BuildNum():ShortString; Inline;
   Var D,T:ShortString;
   begin
      // Include compile date and time
      D:={$I %DATE%}; T:={$I %TIME%};
      //        Y    Y    Y    Y     /  M    M    D    D      /  H    H    M    M   
      Result := D[1]+D[2]+D[3]+D[4]+'/'+D[6]+D[7]+D[9]+D[10]+'/'+T[1]+T[2]+T[4]+T[5]
   end;

end.
