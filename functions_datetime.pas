unit functions_datetime; 

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_DateTime_Start(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DateTime_FileStart(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DateTime_Now(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DateTime_Date(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DateTime_Time(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DateTime_Encode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DateTime_Decode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DateTime_Make(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DateTime_Break(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DateTime_String(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DateTime_ToUnix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DateTime_FromUnix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses SysUtils, DateUtils,
        Convert, Values_Typecast,
        EmptyFunc, CoreFunc, Globals;

Procedure Register(Const FT:PFunTrie);
   begin
      // Get interpreter/script start values
      FT^.SetVal('dt-start',MkFunc(@F_DateTime_Start));
      FT^.SetVal('dt-runstart',MkFunc(@F_DateTime_FileStart));
      // Get current values
      FT^.SetVal('dt-now',MkFunc(@F_DateTime_Now));
      FT^.SetVal('dt-date',MkFunc(@F_DateTime_Date));
      FT^.SetVal('dt-time',MkFunc(@F_DateTime_Time));
      // Construct/deconstruct DateTimes
      FT^.SetVal('dt-decode',MkFunc(@F_DateTime_Decode));
      FT^.SetVal('dt-encode',MkFunc(@F_DateTime_Encode));
      FT^.SetVal('dt-make',MkFunc(@F_DateTime_Make));
      FT^.SetVal('dt-break',MkFunc(@F_DateTime_Break));
      // Conversions with Unix Time
      FT^.SetVal('dt-to-unix',MkFunc(@F_DateTime_ToUnix));
      FT^.SetVal('dt-fr-unix',MkFunc(@F_DateTime_FromUnix));
      FT^.SetVal('dt-from-unix',MkFunc(@F_DateTime_FromUnix));
      // Converstions with strings
      FT^.SetVal('dt-str',MkFunc(@F_DateTime_String));
   end;

Function F_DateTime_Start(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_FLO,GLOB_dt)) else Exit(NIL)
   end;

Function F_DateTime_FileStart(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_FLO,GLOB_sdt)) else Exit(NIL)
   end;

Function F_DateTime_Now(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Now())) else Exit(NIL)
   end;

Function F_DateTime_Date(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Date())) else Exit(NIL)
   end;

Function F_DateTime_Time(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Time())) else Exit(NIL)
   end;

(* Helper function for F_DateTime_Encode and F_DateTime_Make.                                         *
 *                                                                                                    *
 * If arg0 is an array, fills array of values (dt) with values from arg0 array.                       *
 * If arg0 is a dict, fills dt with values taken from arg0 dict, using Key to map argnum to dict key. *
 * If arg0 is neither, fills dt with values from consecutive args.                                    *
 *                                                                                                    *
 * Does not free args. This should be done by the caller.                                             *)  
Procedure ExtractArgs(Const Arg:PArrPVal;Const Key:Array of ShortString;Var dt:Array of LongInt;Limit:LongInt);
   Var C:LongInt; V:PValue;
   begin
      Case(Arg^[0]^.Typ) of
         
         VT_ARR: begin
            For C:=0 to Limit do begin
               V := Arg^[0]^.Arr^.GetVal(C);
               If (V <> NIL) then dt[C] := ValAsInt(V)
            end
         end;
         
         VT_DIC: begin
            For C:=0 to Limit do begin
               V := Arg^[0]^.Dic^.GetVal(Key[C]);
               If (V <> NIL) then dt[C] := ValAsInt(V)
            end
         end;
         
         else begin 
            If (High(Arg^) < Limit) then Limit := High(Arg^);
            For C:=0 to Limit do dt[C] := ValAsInt(Arg^[C])
         end
      end
   end;

Function F_DateTime_Encode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const ARGS_MAX = 7;
   Var dt:Array[0..ARGS_MAX-1] of LongInt; Res:TDateTime;
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Set default values
      dt[0]:=1; dt[1]:=1; dt[2]:=1;
      dt[3]:=0; dt[4]:=0; dt[5]:=0; dt[6]:=0;
      
      // Extract args, if any, and free them
      If(Length(Arg^) > 0) then begin
         ExtractArgs(Arg,['y','m','d','h','i','s','z'], dt, ARGS_MAX-1);
         F_(False, Arg)
      end;
      
      Try // EncodeXYZ can throw exceptions on invalid arguments (e.g. 0 month)
         Res := SysUtils.EncodeDate(dt[0],dt[1],dt[2]);
         Res += SysUtils.EncodeTime(dt[3],dt[4],dt[5],dt[6]);
      Except
         Exit(NilVal())
      end;
      Exit(NewVal(VT_FLO, Res))
   end;

Function F_DateTime_Make(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const ARGS_MAX = 5;
   Var C:LongInt; dt:Array[0..ARGS_MAX-1] of LongInt; Res:TDateTime;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Fill array with zeroes as default values
      For C:=0 to (ARGS_MAX-1) do dt[C]:=0;
      
      // Extract args, if any, and free them
      If(Length(Arg^) > 0) then begin
         ExtractArgs(Arg,['d','h','i','s','z'], dt, ARGS_MAX-1);
         F_(False, Arg)
      end;
      
      // Construct result value and return
      Res:=dt[4]; Res/=1000; // Set to milisecs
      Res+=dt[3]; Res/=60;   // Add secs
      Res+=dt[2]; Res/=60;   // Add mins
      Res+=dt[1]; Res/=24;   // Add hours
      Res+=dt[0];            // Add days
      Exit(NewVal(VT_FLO, Res))
   end;

Function F_DateTime_Decode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var dt:TDateTime; dec:Array[1..8] of Word;
   begin
      // Free args and bail out if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If args provided, use arg0 as dt value; otherwise, default to Now()
      If (Length(Arg^) > 0) then begin
         dt:=ValAsFlo(Arg^[0]);
         F_(False, Arg)
      end else
         dt:=SysUtils.Now();
      
      DecodeDateFully(dt,dec[1],dec[2],dec[3],dec[4]); // year-mon-day-dow
      DecodeTime(dt,dec[5],dec[6],dec[7],dec[8]);      // hour-min-sec-msec
      
      Result:=NewVal(VT_DIC);
      Result^.Dic^.SetVal('y',NewVal(VT_INT,dec[1]));
      Result^.Dic^.SetVal('m',NewVal(VT_INT,dec[2]));
      Result^.Dic^.SetVal('d',NewVal(VT_INT,dec[3]));
      Result^.Dic^.SetVal('w',NewVal(VT_INT,((dec[4]+5) mod 7)+1)); // Convert DoW from 1=Sunday to 1=Monday
      Result^.Dic^.SetVal('h',NewVal(VT_INT,dec[5]));
      Result^.Dic^.SetVal('i',NewVal(VT_INT,dec[6]));
      Result^.Dic^.SetVal('s',NewVal(VT_INT,dec[7]));
      Result^.Dic^.SetVal('z',NewVal(VT_INT,dec[8]))
   end;

Function F_DateTime_Break(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var dt:TDateTime; brk:Array[1..5] of QInt;
   begin
      // Free args and bail out if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If args provided, use arg0 as dt value; otherwise, default to Now()
      If (Length(Arg^) > 0) then begin
         dt:=ValAsFlo(Arg^[0]);
         F_(False, Arg)
      end else
         dt:=SysUtils.Now();
      
                             brk[1] := Trunc(dt); // Days
      dt := Frac(dt) *   24; brk[2] := Trunc(dt); // Hours
      dt := Frac(dt) *   60; brk[3] := Trunc(dt); // Minutes
      dt := Frac(dt) *   60; brk[4] := Trunc(dt); // Seconds
      dt := Frac(dt) * 1000; brk[5] := Trunc(dt); // ms
      
      Result:=NewVal(VT_DIC);
      Result^.Dic^.SetVal('d',NewVal(VT_INT,brk[1]));
      Result^.Dic^.SetVal('h',NewVal(VT_INT,brk[2]));
      Result^.Dic^.SetVal('i',NewVal(VT_INT,brk[3]));
      Result^.Dic^.SetVal('s',NewVal(VT_INT,brk[4]));
      Result^.Dic^.SetVal('z',NewVal(VT_INT,brk[5]))
   end;

Function F_DateTime_ToUnix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // Bail out if no retval expected
      If (Not DoReturn) then Exit(F_(False,Arg));
      
      // Check if arg provided. If yes, use arg0 as DateTime and free args. Otherwise, use Now().
      If (Length(Arg^) > 0) then begin
         Result := NewVal(VT_INT, DateTimeToUnix(ValAsFlo(Arg^[0])));
         F_(False, Arg)
      end else
         Result := NewVal(VT_INT, DateTimeToUnix(Now()))
   end;

Function F_DateTime_FromUnix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // Bail out if no retval expected
      If (Not DoReturn) then Exit(F_(False,Arg));
      
      // Check if arg provided. If yes, use arg0 as Timestamp and free args. Otherwise, use 0
      If (Length(Arg^) > 0) then begin
         Result := NewVal(VT_FLO, UnixToDateTime(ValAsInt(Arg^[0])));
         F_(False, Arg)
      end else
         Result := NewVal(VT_FLO, UnixToDateTime(0));
   end;

Function dt_ToString(Const dt:TDateTime;Const Format:AnsiString):AnsiString;
   
   Function Fork(Const Condition:Boolean;Const TrueVal,FalseVal:ShortString):ShortString;
      begin If(Condition) then Exit(TrueVal); Exit(FalseVal) end;
   
   Var
      P:LongInt; Day,Mon,Year,DoW,Hour,Min,Sec,Mse:Word;
   begin
      DecodeDateFully(dt,Year,Mon,Day,DoW);
      DecodeTime(dt,Hour,Min,Sec,Mse);
      
      Result := '';
      For P:=1 to Length(Format) do
         Case(Format[P]) of
            
            // Day
            'd': Result += IntToStr(Day);
            'D': Result += IntToStr(Day,2);
            'a': Result += FormatSettings.ShortDayNames[DoW];
            'A': Result += FormatSettings.LongDayNames[DoW];
            
            // Month
            'm': Result += IntToStr(Mon);
            'M': Result += IntToStr(Mon,2);
            'o': Result += FormatSettings.ShortMonthNames[Mon];
            'O': Result += FormatSettings.LongMonthNames[Mon];
            
            // Year
            'y': Result += IntToStr(Year mod 100, 2);
            'Y': Result += IntToStr(Year, 4);
            
            // Hour
            'h': Result += IntToStr(Hour);
            'H': Result += IntToStr(Hour,2);
            'g': Result += IntToStr(Hour mod 12);
            'G': Result += IntToStr(Hour mod 12, 2);
            
            // Minutes
            'i': Result += IntToStr(Min);
            'I': Result += IntToStr(Min, 2);
            
            // Seconds
            's': Result += IntToStr(Sec);
            'S': Result += IntToStr(Sec,2);
            
            // Milliseconds
            'z': Result += IntToStr(Mse);
            'Z': Result += IntToStr(Mse,3);
            
            // Other
            'p': Result += Fork(IsPM(dt), 'pm', 'am');
            'P': Result += Fork(IsPM(dt), 'PM', 'AM');
            
            'w': Result += Chr((((DoW+5) mod 7)+1)+48); // Change from 1=Sunday to 1=Monday format (+48 = +'0')
            'W': Result += IntToStr(WeekOfTheYear(dt));
            
            'e': Result += IntToStr(DayOfTheYear(dt));
            
            'U': Result += IntToStr(DateTimeToUnix(dt));
            
            else // Unrecognized char; include it if it's not a letter
               If((Not (Format[P] in ['A'..'Z'])) and (Not (Format[P] in ['a'..'z'])))
                  then Result += Format[P]
         end;
   end;

Function F_DateTime_String(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var dt:TDateTime; Format:AnsiString;
   begin
      // If retval not expected, free args and bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Based on number of args, fill Format and dt with provided values, or use defaults
      Case (Length(Arg^)) of
         
         0: begin
            Format := dtf_def_yuk;
            dt := SysUtils.Now()
         end;
         
         1: begin // If arg0 is float or int, use it as DateTime. Otherwise, treat it as Format.
            If (Arg^[0]^.Typ = VT_FLO) or ((Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)) then begin
               Format := dtf_def_yuk;
               dt := ValAsFlo(Arg^[0]);
            end else begin
               Format := ValAsStr(Arg^[0]);
               dt := SysUtils.Now()
            end;
            If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0])
         end;
         
         // 2 or more args
         else begin 
            Format := ValAsStr(Arg^[0]);
            dt := ValAsFlo(Arg^[1]);
            F_(False, Arg)
         end
      end;
      
      Exit(NewVal(VT_STR,dt_ToString(dt,Format)))
   end;


end.
