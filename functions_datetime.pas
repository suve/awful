unit functions_datetime; {$MODE OBJFPC}

interface
   uses Values;

Const dtf_def = 'yyyy"-"mm"-"dd" "hh":"nn';

Procedure Register(FT:PFunTrie);

Function F_DateTime_Start(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_FileStart(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Now(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Date(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Time(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Encode(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Decode(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Make(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Day(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Month(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Year(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_DOW(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Hour(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Min(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_Sec(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_MS(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_DateTime_String(DoReturn:Boolean; Arg:PArrPVal):PValue;

implementation
   uses Values_Arith, SysUtils, EmptyFunc;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('datetime-start',@F_DateTime_Start);
   FT^.SetVal('datetime-filestart',@F_DateTime_FileStart);
   FT^.SetVal('datetime-now',@F_DateTime_Now);
   FT^.SetVal('datetime-date',@F_DateTime_Date);
   FT^.SetVal('datetime-time',@F_DateTime_Time);
   FT^.SetVal('datetime-decode',@F_DateTime_Decode);
   FT^.SetVal('datetime-encode',@F_DateTime_Encode);
   FT^.SetVal('datetime-make',@F_DateTime_Make);
   FT^.SetVal('datetime-year',@F_DateTime_Year);
   FT^.SetVal('datetime-month',@F_DateTime_Month);
   FT^.SetVal('datetime-day',@F_DateTime_Day);
   FT^.SetVal('datetime-dow',@F_DateTime_DOW);
   FT^.SetVal('datetime-hour',@F_DateTime_Hour);
   FT^.SetVal('datetime-min',@F_DateTime_Min);
   FT^.SetVal('datetime-sec',@F_DateTime_Sec);
   FT^.SetVal('datetime-ms',@F_DateTime_MS);
   FT^.SetVal('datetime-string',@F_DateTime_String);
   end;

Function F_DateTime_Start(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,GLOB_dt)) else Exit(NIL)
   end;

Function F_DateTime_FileStart(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,GLOB_sdt)) else Exit(NIL)
   end;

Function F_DateTime_Now(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Now())) else Exit(NIL)
   end;

Function F_DateTime_Date(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Date())) else Exit(NIL)
   end;

Function F_DateTime_Time(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_FLO,SysUtils.Time())) else Exit(NIL)
   end;

Function F_DateTime_Encode(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Const ARRLEN = 7; ARRHI = 6;
   Var C,H:LongWord; V:PValue;
       DT:Array[0..ARRHI] of LongInt; R:TDateTime;
   begin
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
   Try R:=SysUtils.EncodeDate(dt[0],dt[1],dt[2]);
       R+=SysUtils.EncodeTime(dt[3],dt[4],dt[5],dt[6]);
   Except Exit(NilVal) end;
   Exit(NewVal(VT_FLO,R))
   end;

Function F_DateTime_Make(DoReturn:Boolean; Arg:PArrPVal):PValue;
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

Function F_DateTime_Decode(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C,H:LongWord; V,T:PValue; dt:TDateTime; dec:Array[1..8] of Word;
   begin
   If (Length(Arg^)<2) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO,False)) else Exit(NIL) end;
   If (Length(Arg^)>9) then begin H:=8;
      For C:=High(Arg^) downto 9 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end else H:=High(Arg^);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   DecodeDateFully(dt,dec[1],dec[2],dec[3],dec[4]);
   DecodeTime(dt,dec[5],dec[6],dec[7],dec[8]);
   For C:=H downto 1 do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) 
       else begin
       T:=NewVal(VT_INT,dec[C]);
       ValSet(Arg^[C],T);
       FreeVal(T)
       end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO,True)) else Exit(NIL)
   end;


Function F_DateTime_Day(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeDate(dt,Y,M,D);
   Exit(NewVal(VT_INT,D))
   end;

Function F_DateTime_Month(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeDate(dt,Y,M,D);
   Exit(NewVal(VT_INT,M))
   end;

Function F_DateTime_Year(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeDate(dt,Y,M,D);
   Exit(NewVal(VT_INT,Y))
   end;

Function F_DateTime_DOW(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y,DOW:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeDateFully(dt,Y,M,D,DOW);
   Exit(NewVal(VT_INT,DOW))
   end;

Function F_DateTime_Hour(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,H))
   end;

Function F_DateTime_Min(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,M))
   end;

Function F_DateTime_Sec(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,S))
   end;

Function F_DateTime_ms(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,MS))
   end;

Function dtf(S:AnsiString):AnsiString;
   Var R:AnsiString; P:LongWord; Q:Boolean;
   begin
   R:=''; Q:=False;
   If (Length(S)=0) then Exit(dtf_def);
   For P:=1 to Length(S) do
       If (S[P]='d') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='d' end else
       If (S[P]='D') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='dd' end else
       If (S[P]='a') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='ddd' end else
       If (S[P]='A') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='dddd' end else
       If (S[P]='m') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='m' end else
       If (S[P]='M') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='mm' end else
       If (S[P]='o') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='mmm' end else
       If (S[P]='O') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='mmmm' end else
       If (S[P]='y') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='yy' end else
       If (S[P]='Y') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='yyyy' end else
       If (S[P]='h') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='h' end else
       If (S[P]='H') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='hh' end else
       If (S[P]='i') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='n' end else
       If (S[P]='I') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='nn' end else
       If (S[P]='s') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='s' end else
       If (S[P]='S') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='ss' end else
       If (S[P]='p') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='a/p' end else
       If (S[P]='P') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='am/pm' end else
       If (S[P]='z') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='z' end else
       If (S[P]='Z') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='zzz' end else
       If (S[P]='t') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='t' end else
       If (S[P]='T') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='tt' end else
          begin { else - all non-code chars}
          If (Not Q) then begin Q:=True; R+='"' end;
          R+=S[P]
          end;
   If (Q) then Exit(R+'"') else Exit(R)
   end;

Function F_DateTime_String(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; S,F:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) > 2) then
      For C:=High(Arg^) downto 2 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Length(Arg^) >= 2) and (Arg^[1]^.Typ = VT_STR)
      then F:=dtf(PStr(Arg^[1]^.Ptr)^)
      else F:=dtf_def;
   If (Length(Arg^) > 0) and (Arg^[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg^[0]^.Ptr)^) else
   If (Length(Arg^) > 0) then begin
      V:=ValToFlo(Arg^[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end else dt:=SysUtils.Now();
   If (Length(Arg^) >= 2) and (Arg^[1]^.Lev >= CurLev) then FreeVal(Arg^[1]);
   If (Length(Arg^) >= 1) and (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   DateTimeToString(S,F,dt);
   Exit(NewVal(VT_STR,S))
   end;


end.
