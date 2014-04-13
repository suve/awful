unit functions_datetime; 

{$INCLUDE defines.inc}

interface
   uses Values;

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
   uses SysUtils, Convert, Values_Arith, Values_Typecast,
        EmptyFunc, CoreFunc, Globals;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('dt-start',MkFunc(@F_DateTime_Start));
   FT^.SetVal('dt-runstart',MkFunc(@F_DateTime_FileStart));
   FT^.SetVal('dt-now',MkFunc(@F_DateTime_Now));
   FT^.SetVal('dt-date',MkFunc(@F_DateTime_Date));
   FT^.SetVal('dt-time',MkFunc(@F_DateTime_Time));
   FT^.SetVal('dt-decode',MkFunc(@F_DateTime_Decode));
   FT^.SetVal('dt-encode',MkFunc(@F_DateTime_Encode));
   FT^.SetVal('dt-make',MkFunc(@F_DateTime_Make));
   FT^.SetVal('dt-break',MkFunc(@F_DateTime_Break));
   FT^.SetVal('dt-to-unix',MkFunc(@F_DateTime_ToUnix));
   FT^.SetVal('dt-fr-unix',MkFunc(@F_DateTime_FromUnix));
   FT^.SetVal('dt-from-unix',MkFunc(@F_DateTime_FromUnix));
   FT^.SetVal('dt-str',MkFunc(@F_DateTime_String));
   end;

Function F_DateTime_Start(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,GLOB_dt)) else Exit(NIL)
   end;

Function F_DateTime_FileStart(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,GLOB_sdt)) else Exit(NIL)
   end;

Function F_DateTime_Now(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Now())) else Exit(NIL)
   end;

Function F_DateTime_Date(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Date())) else Exit(NIL)
   end;

Function F_DateTime_Time(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Time())) else Exit(NIL)
   end;

Function F_DateTime_Encode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const ARRLEN = 7; ARRHI = 6;
   Var C,H:LongWord; DT:Array[0..ARRHI] of LongInt; R:TDateTime;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>ARRLEN) then begin H:=ARRHI;
      For C:=High(Arg^) downto ARRLEN do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end else H:=High(Arg^);
   dt[0]:=1; dt[1]:=1; dt[2]:=1;
   dt[3]:=0; dt[4]:=0; dt[5]:=0; dt[6]:=0;
   For C:=H downto 0 do begin
       If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN) 
          then dt[C]:=PQInt(Arg^[C]^.Ptr)^
          else dt[C]:=ValAsInt(Arg^[C]);
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
       end;
   R := 0;
   Try R:=SysUtils.EncodeDate(dt[0],dt[1],dt[2]);
       R+=SysUtils.EncodeTime(dt[3],dt[4],dt[5],dt[6]);
   Except Exit(NilVal()) end;
   Exit(NewVal(VT_FLO,R))
   end;

Function F_DateTime_Make(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const ARRLEN = 5; ARRHI = 4;
   Var C,H:LongWord; V:PValue;
       dt:Array[0..ARRHI] of LongInt; R:TDateTime;
   begin R:=0;
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>ARRLEN) then begin H:=ARRHI;
      For C:=High(Arg^) downto ARRLEN do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end else H:=High(Arg^);
   For C:=0 to ARRHI do dt[C]:=0;
   For C:=H downto 0 do begin
       If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN) 
          then dt[C]:=PQInt(Arg^[C]^.Ptr)^
          else begin
          V:=ValToInt(Arg^[C]);
          dt[C]:=PQInt(V^.Ptr)^;
          FreeVal(V)
          end;
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
       end;
   R+=dt[4]; R/=1000; //Add milisecs
   R+=dt[3]; R/=60;   //Add secs
   R+=dt[2]; R/=60;   //Add mins
   R+=dt[1]; R/=24;   //Add hours
   R+=dt[0];          //Add days
   Exit(NewVal(VT_FLO,R))
   end;

Function F_DateTime_Decode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; D:PDict; dt:TDateTime; dec:Array[1..8] of Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) >= 1)
      then begin
      dt:=ValAsFlo(Arg^[0]);
      For C:=0 to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
      end else dt:=SysUtils.Now();
   
   DecodeDateFully(dt,dec[1],dec[2],dec[3],dec[4]);
   DecodeTime(dt,dec[5],dec[6],dec[7],dec[8]);
   
   V:=NewVal(VT_DIC); D:=PDict(V^.Ptr);
   D^.SetVal('y',NewVal(VT_INT,dec[1]));
   D^.SetVal('m',NewVal(VT_INT,dec[2]));
   D^.SetVal('d',NewVal(VT_INT,dec[3]));
   D^.SetVal('w',NewVal(VT_INT,((dec[4]+5) mod 7)+1));
   D^.SetVal('h',NewVal(VT_INT,dec[5]));
   D^.SetVal('i',NewVal(VT_INT,dec[6]));
   D^.SetVal('s',NewVal(VT_INT,dec[7]));
   D^.SetVal('z',NewVal(VT_INT,dec[8]));
   Exit(V)
   end;

Function F_DateTime_Break(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; D:PDict; dt:TDateTime; brk:Array[1..5] of QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) >= 1)
      then begin
      dt:=ValAsFlo(Arg^[0]);
      For C:=0 to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
      end else dt:=SysUtils.Now();
   
                          brk[1] := Trunc(dt); // Days
   dt := Frac(dt) *   24; brk[2] := Trunc(dt); // Hours
   dt := Frac(dt) *   60; brk[3] := Trunc(dt); // Minutes
   dt := Frac(dt) *   60; brk[4] := Trunc(dt); // Seconds
   dt := Frac(dt) * 1000; brk[5] := Trunc(dt); // ms             
   
   V:=NewVal(VT_DIC); D:=PDict(V^.Ptr);
   D^.SetVal('d',NewVal(VT_INT,brk[1]));
   D^.SetVal('h',NewVal(VT_INT,brk[2]));
   D^.SetVal('i',NewVal(VT_INT,brk[3]));
   D^.SetVal('s',NewVal(VT_INT,brk[4]));
   D^.SetVal('z',NewVal(VT_INT,brk[5]));
   Exit(V)
   end;

Const dt_UnixDiff = -62135769600 // Number of seconds between 0001-01-01 and 1970-01-01
                    +79200;      // Dunno. Const error, probably due to missing days in calendars et cetera

Function dt_ToUnix(Const dt:TDateTime):QInt;
   begin Result := Trunc(TimeStampToMSecs(DateTimeToTimeStamp(dt))/1000)+dt_UnixDiff end;

Function F_DateTime_ToUnix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var dt:TDateTime;
   begin
   If (Not DoReturn) then Exit(F_(False,Arg));
   If (Length(Arg^)>0) then dt:=ValAsFlo(Arg^[0])
                       else dt:=Now();
   
   F_(False,Arg); Exit(NewVal(VT_INT,dt_ToUnix(dt)))
   end;

Function F_DateTime_FromUnix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var dt:TDateTime; Stamp:QInt;
   begin
   If (Not DoReturn) then Exit(F_(False,Arg));
   If (Length(Arg^)>0) then Stamp:=ValAsInt(Arg^[0])
                       else Stamp:=0;
   
   dt := TimeStampToDateTime(MSecsToTimeStamp((Stamp-dt_UnixDiff)*1000));
   F_(False,Arg); Exit(NewVal(VT_FLO,dt))
   end;

Function dtf(Const S:AnsiString):AnsiString;
   Const dtf_Chr = 'dDaAmMoOyYhHiIsSzZpP';
   Const fpc_Chr : Array[1..Length(dtf_Chr)] of ShortString = (
            'd','dd','ddd','dddd','m','mm','mmm','mmmm',
            'yy','yyyy','h','hh','n','nn','s','ss',
            'z','zzz','a/p','am/pm'
            );
   Var R:AnsiString; P,X:LongWord; Q:Boolean;
   begin
   R:=''; Q:=False;
   If (Length(S)=0) then Exit(dtf_def);
   For P:=1 to Length(S) do begin
      X := Pos(S[P],dtf_Chr);
      If (X <> 0) then begin
         If (Q) then R+='"';
         R += fpc_Chr[X] + '"'; Q:=True
         end else begin
         If (S[P] <> '"') then begin
            If (Not Q) then begin Q:=True; R+='"' end;
            R += S[P]
            end else begin
            If (Q) then begin Q:=False; R+='"' end;
            R += '''"'''
            end
         end
      end;
   If (Q) then Exit(R+'"') else Exit(R)
   end;

Function dt_String(Const dt:TDateTime;Const Fmt:AnsiString):AnsiString;
   Var P,tmp:LongWord; NewFmt,Res:AnsiString;
   begin
   NewFmt:= '';
   For P:=1 to Length(Fmt) do
      Case (Fmt[P]) of
         'U':
            NewFmt += IntToStr(dt_ToUnix(dt));
         'w': begin
            tmp := DayOfWeek(dt)-1;
            If (tmp = 0) then tmp := 7;
            NewFmt += Chr(48 + tmp)
            end;
         else
            NewFmt += Fmt[P]
      end;
   DateTimeToString(Res,NewFmt,dt);
   Exit(Res)
   end;

Function F_DateTime_String(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; dt:TDateTime; Format:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   
   If (Length(Arg^) >= 1) then begin
      If (Length(Arg^) >= 2) then begin
         Format := dtf(ValAsStr(Arg^[0]));
         dt := ValAsFlo(Arg^[1])
         end else begin
         If (Arg^[0]^.Typ = VT_FLO) or ((Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)) then begin
            Format := dtf_def;
            dt := ValAsFlo(Arg^[0]);
            end else begin
            Format := dtf(ValAsStr(Arg^[0]));
            dt := SysUtils.Now()
            end;
         end;
      For C:=0 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
      end 
      else begin
      Format := dtf_def;
      dt := SysUtils.Now()
      end;
   
   Exit(NewVal(VT_STR,dt_String(dt,Format)))
   end;


end.
