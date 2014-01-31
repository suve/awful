unit functions_datetime; 

{$INCLUDE defines.inc}

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
Function F_DateTime_Break(DoReturn:Boolean; Arg:PArrPVal):PValue;

Function F_DateTime_String(DoReturn:Boolean; Arg:PArrPVal):PValue;

implementation
   uses Values_Arith, SysUtils, EmptyFunc, CoreFunc, Globals;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('dt-start',@F_DateTime_Start);
   FT^.SetVal('dt-runstart',@F_DateTime_FileStart);
   FT^.SetVal('dt-now',@F_DateTime_Now);
   FT^.SetVal('dt-date',@F_DateTime_Date);
   FT^.SetVal('dt-time',@F_DateTime_Time);
   FT^.SetVal('dt-decode',@F_DateTime_Decode);
   FT^.SetVal('dt-encode',@F_DateTime_Encode);
   FT^.SetVal('dt-make',@F_DateTime_Make);
   FT^.SetVal('dt-break',@F_DateTime_Break);
   FT^.SetVal('dt-str',@F_DateTime_String);
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

Function F_DateTime_Break(DoReturn:Boolean; Arg:PArrPVal):PValue;
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
          begin { else - all non-code chars}
          If (Not Q) then begin Q:=True; R+='"' end;
          R+=S[P]
          end;
   If (Q) then Exit(R+'"') else Exit(R)
   end;

Function F_DateTime_String(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; dt:TDateTime; Str,Format:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   
   If (Length(Arg^) >= 1) then begin
      If (Length(Arg^) >= 2) then begin
         Format := dtf(ValAsStr(Arg^[0]));
         dt := ValAsFlo(Arg^[1])
         end else begin
         If (Arg^[0]^.Typ = VT_FLO) then begin
            Format := dtf_def;
            dt := PFloat(Arg^[0]^.Ptr)^;
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
   
   DateTimeToString(Str,Format,dt);
   Exit(NewVal(VT_STR,Str))
   end;


end.
