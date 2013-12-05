unit functions_strings;

interface
   uses Values;

Procedure Register(FT:PFunTrie);


Function F_Trim(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_TrimLeft(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_TrimRight(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_UpperCase(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_LowerCase(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_StrLen(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_StrPos(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SubStr(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_DelStr(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_WriteStr(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_Chr_UTF8(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Chr(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Ord(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_Perc(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function UTF8_Char(Code:LongWord):ShortString;

implementation
   uses SysUtils, EmptyFunc;


Procedure Register(FT:PFunTrie);
   begin
   // Char functions
   FT^.SetVal('chr',@F_chr);
   FT^.SetVal('chru',@F_chr_UTF8);
   FT^.SetVal('ord',@F_ord);
   // String manipulation functions
   FT^.SetVal('str-trim',@F_Trim);
   FT^.SetVal('str-letrim',@F_TrimLeft);
   FT^.SetVal('str-ritrim',@F_TrimRight);
   FT^.SetVal('str-upper',@F_UpperCase);
   FT^.SetVal('str-lower',@F_LowerCase);
   FT^.SetVal('str-len',@F_StrLen);
   FT^.SetVal('str-pos',@F_StrPos);
   FT^.SetVal('str-sub',@F_SubStr);
   FT^.SetVal('str-del',@F_DelStr);
   // Utils
   FT^.SetVal('str-write',@F_WriteStr);
   FT^.SetVal('perc',@F_Perc);
   end;


Function UTF8_Char(Code:LongWord):ShortString;
   Var Bit:Array[0..31] of Byte; C:LongInt; S:ShortString;
   
   Function MakeChar(Mask:Byte;Max,Min:LongInt):Char;
      Var B:Byte;
      begin B:=0;
      While (Max > Min) do begin
         B += Bit[Max]; B *= 2; Max -= 1
         end;
      B := Mask + B + Bit[Max];
      Exit(Chr(B))
      end;
   
   begin 
   If (Code <= 127) then Exit(Chr(Code)) else S:='';
   For C:=0 to 31 do Bit[C]:=0; C:=0;
   While (Code > 0) do begin
      Bit[C]:=(Code mod 2);
      Code := Code div 2;
      C += 1
      end;
   If (C <= 11) then begin C:=05; S += MakeChar(%11000000,10,06) end else
   If (C <= 16) then begin C:=11; S += MakeChar(%11100000,15,12) end else
   If (C <= 21) then begin C:=17; S += MakeChar(%11110000,20,18) end else
   If (C <= 26) then begin C:=23; S += MakeChar(%11111000,25,24) end else
   If (C <= 31) then begin C:=29; S += MakeChar(%11111100,30,30) end;
   While (C > 0) do begin
      S += MakeChar(%10000000, C, C-5); C -= 6
      end;
   //For C:=1 to Length(S) do Write(BinToStr(Ord(S[C]),8),#32,HexToStr(Ord(S[C]),2),' | '); Writeln;
   Exit(S)
   end;


Function F_Trim(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=Trim(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=Trim(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_TrimLeft(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=TrimLeft(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=TrimLeft(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_TrimRight(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=TrimRight(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=TrimRight(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_UpperCase(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=UpperCase(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=UpperCase(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_LowerCase(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=LowerCase(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=LowerCase(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_StrLen(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; L:QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ<>VT_STR) then begin
      V:=ValToStr(Arg[0]); If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Arg[0]:=V end;
   L:=Length(PStr(Arg[0]^.Ptr)^);
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_INT,L))
   end;

Function F_StrPos(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; P:QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)<2) then Exit(NewVal(VT_INT,0));
   If (Length(Arg)>2) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   For C:=1 downto 0 do 
      If (Arg[C]^.Typ<>VT_STR) then begin
         V:=ValToStr(Arg[C]); If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
         Arg[C]:=V end;
   P:=Pos(PStr(Arg[0]^.Ptr)^,PStr(Arg[1]^.Ptr)^);
   For C:=1 downto 0 do If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,P))
   end;

Function F_SubStr(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; I:Array[1..2] of QInt; R:TStr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   If (Length(Arg)>3) then
      For C:=High(Arg) downto 3 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   For C:=2 downto 1 do
       If (Length(Arg)>C) then
          If (Arg[C]^.Typ >= VT_INT) and (Arg[C]^.Typ<= VT_BIN)
             then i[C]:=PQInt(Arg[C]^.Ptr)^
             else begin
             V:=ValToInt(Arg[C]); i[C]:=PQInt(V^.Ptr)^; FreeVal(V)
             end else
             If (C=2) then i[C]:=High(Integer) else i[C]:=1;
   If (Arg[0]^.Typ = VT_STR)
      then R:=Copy(PStr(Arg[0]^.Ptr)^,i[1],i[2]) 
      else begin
      V:=ValToStr(Arg[0]); R:=Copy(PStr(V^.Ptr)^,i[1],i[2]); 
      FreeVal(V) end;
   For C:=2 downto 0 do
       If (Length(Arg)>C) and (Arg[C]^.Lev >= CurLev)
          then FreeVal(Arg[C]);
   Exit(NewVal(VT_STR,R))
   end;

Function F_DelStr(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; I:Array[1..2] of QInt; 
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   If (Length(Arg)>3) then
      For C:=High(Arg) downto 3 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   For C:=2 downto 1 do
       If (Length(Arg)>C) then
          If (Arg[C]^.Typ >= VT_INT) and (Arg[C]^.Typ<= VT_BIN)
             then i[C]:=PQInt(Arg[C]^.Ptr)^
             else begin
             V:=ValToInt(Arg[C]); i[C]:=PQInt(V^.Ptr)^; FreeVal(V)
             end else
             If (C=2) then i[C]:=High(SizeInt) else i[C]:=1;
   If (Arg[0]^.Typ = VT_STR)
      then V:=CopyVal(Arg[0])
      else V:=ValToStr(Arg[0]);
   Delete(PStr(V^.Ptr)^,i[1],i[2]); 
   For C:=2 downto 0 do
       If (Length(Arg)>C) and (Arg[C]^.Lev >= CurLev)
          then FreeVal(Arg[C]);
   Exit(V)
   end;

Function F_Ord(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NilVal());
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR) then begin
      S:=PStr(Arg[0]^.Ptr)^;
      If (Length(S) = 0) then V:=NilVal()
                         else V:=NewVal(VT_INT, Ord(S[1]));
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(V)
   end;

Function F_Chr(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; I:QInt; F:TFloat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NilVal());
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN) then begin
      I:=PQInt(Arg[0]^.Ptr)^;
      V:=NewVal(VT_STR, Chr(I));
      end else
   If (Arg[0]^.Typ = VT_FLO) then begin
      F:=PFloat(Arg[0]^.Ptr)^;
      V:=NewVal(VT_STR, Chr(Trunc(F)));
      end else V:=NilVal();
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(V)
   end;

Function F_Chr_UTF8(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; I:QInt; F:TFloat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NilVal());
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN) then begin
      I:=PQInt(Arg[0]^.Ptr)^;
      V:=NewVal(VT_STR, UTF8_Char(I));
      end else
   If (Arg[0]^.Typ = VT_FLO) then begin
      F:=PFloat(Arg[0]^.Ptr)^;
      V:=NewVal(VT_STR, UTF8_Char(Trunc(F)));
      end else V:=NilVal();
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(V)
   end;

Function F_Perc(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; A,V:PValue; I:PQInt; S:AnsiString; D:PFloat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,'0%')) else S:='';
   If (Length(Arg)>2) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)>=2) then begin
      If (Arg[0]^.Typ = VT_FLO) then begin
         A:=CopyVal(Arg[0]); D:=PFloat(A^.Ptr); (D^)*=100;
         V:=ValDiv(A,Arg[1]); FreeVal(A);
         S:=Values.IntToStr(Trunc(PFloat(V^.Ptr)^))+'%';
         FreeVal(V)
         end else begin
         If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
            then A:=CopyVal(Arg[0]) else A:=ValToInt(Arg[0]);
         I:=PQInt(A^.Ptr); (I^)*=100;
         V:=ValDiv(A,Arg[1]); FreeVal(A);
         S:=Values.IntToStr(PQInt(V^.Ptr)^)+'%';
         FreeVal(V)
         end
      end else begin
      If (Arg[0]^.Typ = VT_FLO)
         then S:=Values.IntToStr(Trunc(100*PFloat(Arg[0]^.Ptr)^))+'%'
         else begin
         A:=ValToFlo(Arg[0]);
         S:=Values.IntToStr(Trunc(100*PFloat(A^.Ptr)^))+'%';
         FreeVal(A)
         end
      end;
   If (Length(Arg) >= 2) and (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
   If (Length(Arg) >= 1) and (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_WriteStr(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var Str,Tmp:TStr; C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   Str := ''; Tmp := '';
   If (Length(Arg) > 0) then
      For C:=Low(Arg) to High(Arg) do begin
          Case Arg[C]^.Typ of
             VT_NIL: WriteStr(Tmp, '{NIL}');
             VT_NEW: WriteStr(Tmp, '{NEW}');
             VT_PTR: WriteStr(Tmp, '{PTR}');
             VT_INT: WriteStr(Tmp, PQInt(Arg[C]^.Ptr)^);
             VT_HEX: WriteStr(Tmp, Values.HexToStr(PQInt(Arg[C]^.Ptr)^));
             VT_OCT: WriteStr(Tmp, Values.OctToStr(PQInt(Arg[C]^.Ptr)^));
             VT_BIN: WriteStr(Tmp, Values.BinToStr(PQInt(Arg[C]^.Ptr)^));
             VT_FLO: WriteStr(Tmp, Values.FloatToStr(PFloat(Arg[C]^.Ptr)^));
             VT_BOO: WriteStr(Tmp, PBoolean(Arg[C]^.Ptr)^);
             VT_STR: WriteStr(Tmp, PAnsiString(Arg[C]^.Ptr)^);
             VT_UTF: WriteStr(Tmp, '{UTF8}');
             VT_ARR: WriteStr(Tmp, 'array(',PArray(Arg[C]^.Ptr)^.Count,')');
             VT_DIC: WriteStr(Tmp, 'dict(',PDict(Arg[C]^.Ptr)^.Count,')');
             VT_FIL: WriteStr(Tmp, 'file(',PFileVal(Arg[C]^.Ptr)^.Pth,')');
             else WriteStr(Tmp, '(',Arg[C]^.Typ,')');
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
          Str += Tmp
          end;
   Exit(NewVal(VT_STR, Str))
   end;

end.
