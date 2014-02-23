unit functions_strings;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);


Function F_Trim(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_TrimLeft(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_TrimRight(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_UpperCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_LowerCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_StrBts(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_StrLen(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_StrPos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_SubStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DelStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_InsertStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_WriteStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_WriteStr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Chr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Ord_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Chr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Ord(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Perc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function UTF8_Char(Code:LongWord):ShortString;
Function UTF8_Ord(Chr:ShortString):LongInt;

implementation
   uses Values_Arith, UnicodeStrings, SysUtils, EmptyFunc;


Procedure Register(Const FT:PFunTrie);
   begin
   // Char functions
   FT^.SetVal('chr',@F_chr);
   FT^.SetVal('chru',@F_chr_UTF8);
   FT^.SetVal('ord',@F_ord);
   FT^.SetVal('ordu',@F_ord_UTF8);
   // String manipulation functions
   FT^.SetVal('str-trim',@F_Trim);
   FT^.SetVal('str-letrim',@F_TrimLeft);
   FT^.SetVal('str-ritrim',@F_TrimRight);
   FT^.SetVal('str-upper',@F_UpperCase);
   FT^.SetVal('str-lower',@F_LowerCase);
   FT^.SetVal('str-bytes',@F_StrBts);
   FT^.SetVal('str-len',@F_StrLen);
   FT^.SetVal('str-pos',@F_StrPos);
   FT^.SetVal('str-sub',@F_SubStr);
   FT^.SetVal('str-del',@F_DelStr);
   FT^.SetVal('str-ins',@F_InsertStr);
   // Utils
   FT^.SetVal('str-write',@F_WriteStr);
   FT^.SetVal('str-writeu',@F_WriteStr_UTF8);
   FT^.SetVal('utf8-write',@F_WriteStr_UTF8);
   FT^.SetVal('perc',@F_Perc);
   end;

Const UTF8_Mask:Array[2..6] of Byte =
      (%11000000, %11100000, %11110000, %11111000, %11111100);

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
   Exit(S)
   end;

Function UTF8_Ord(Chr:ShortString):LongInt;
   
   Function Bitmask(Val,Mask:Byte):Boolean; Inline;
      begin Exit((Val and Mask) = Mask) end;
   
   Var C,L,O:LongWord;
   begin
   If (Length(Chr) = 0) then Exit(-1);
   If (Ord(Chr[1]) < 128) then Exit(Ord(Chr[1]));
   L := 0; O := 0;
   For C:=6 downto 2 do
       If (Bitmask(Ord(Chr[1]), UTF8_Mask[C])) then begin
          O := (Ord(Chr[1]) and (Not UTF8_Mask[C]));
          L := C; Break
          end;
   If (L = 0) then Exit(-1) else O := (O * %100000);
   If (Length(Chr) >= 2) then O := O + (Ord(Chr[2]) and %00111111);
   For C:=3 to L do begin
       If (Length(Chr) < C) then Exit(-1);
       If ((Ord(Chr[C]) < %10000000) or (Ord(Chr[C]) >= %11000000)) then Exit(-1);
       O := (O * %1000000) + (Ord(Chr[C]) and %00111111);
       end;
   Exit(O)
   end;

Function ASCII_Char(Code:LongWord):ShortString;
   begin Exit(Chr(Code)) end;

Function ASCII_Ord(Str:ShortString):LongInt;
   begin If (Length(Str)>0) then Exit(Ord(Str[0])) else Exit(0) end;

Type TChrFunc = Function(Code:LongWord):ShortString;
Type TOrdFunc = Function(Str:ShortString):LongInt;

Type TTransformID = (TID_Trim, TID_TrimLe, TID_TrimRi, TID_Upper, TID_Lower);

Function F_TransformStr(funID:TTransformID; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_UTF) then begin
      V := CopyVal(Arg^[0]);
      Case funID of
         TID_Trim:   PUTF(V^.Ptr)^.Trim();
         TID_TrimLe: PUTF(V^.Ptr)^.TrimLeft();
         TID_TrimRi: PUTF(V^.Ptr)^.TrimRight();
         TID_Upper:  PUTF(V^.Ptr)^.UpperCase();
         TID_Lower:  PUTF(V^.Ptr)^.LowerCase()
      end end else begin
      V:=ValToStr(Arg^[0]);
      Case funID of
         TID_Trim:   PStr(V^.Ptr)^ := Trim(PStr(V^.Ptr)^);
         TID_TrimLe: PStr(V^.Ptr)^ := TrimLeft(PStr(V^.Ptr)^);
         TID_TrimRi: PStr(V^.Ptr)^ := TrimRight(PStr(V^.Ptr)^);
         TID_Upper:  PStr(V^.Ptr)^ := UpperCase(PStr(V^.Ptr)^);
         TID_Lower:  PStr(V^.Ptr)^ := LowerCase(PStr(V^.Ptr)^)
      end end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(V)
   end;

Function F_Trim(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(TID_Trim, DoReturn, Arg)) end;

Function F_TrimLeft(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(TID_TrimLe, DoReturn, Arg)) end;

Function F_TrimRight(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(TID_TrimRi, DoReturn, Arg)) end;

Function F_UpperCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(TID_Upper, DoReturn, Arg)) end;

Function F_LowerCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(TID_Lower, DoReturn, Arg)) end;

Function F_StrBts(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; L:QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_UTF) then L:=PUTF(Arg^[0]^.Ptr)^.Bytes 
                              else L:=Length(ValAsStr(Arg^[0]));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_INT,L))
   end;

Function F_StrLen(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; L:QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_STR) then L:=Length(PStr(Arg^[0]^.Ptr)^) else
   If (Arg^[0]^.Typ = VT_UTF) then L:=PUTF(Arg^[0]^.Ptr)^.Len else
                              {el} L:=Length(ValAsStr(Arg^[0]));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_INT,L))
   end;

Function F_StrPos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; P:QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)<2) then Exit(NewVal(VT_INT,0));
   If (Length(Arg^)>2) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_UTF) then begin
      If (Arg^[1]^.Typ = VT_UTF) then P:=PUTF(Arg^[0]^.Ptr)^.Search(PUTF(Arg^[1]^.Ptr))
                                 else P:=PUTF(Arg^[0]^.Ptr)^.Search(ValAsStr(Arg^[1]))
      end else
      P:=Pos(ValAsStr(Arg^[1]),ValAsStr(Arg^[0]));
   For C:=1 downto 0 do If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   Exit(NewVal(VT_INT,P))
   end;

Function F_SubStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; I:Array[1..2] of QInt; V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
   If (Length(Arg^)>3) then
      For C:=High(Arg^) downto 3 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   For C:=2 downto 1 do
       If (Length(Arg^)>C) then begin
          If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ<= VT_BIN)
             then i[C]:=PQInt(Arg^[C]^.Ptr)^
             else i[C]:=ValAsInt(Arg^[C])
          end else
             If (C=2) then i[C]:=High(QInt) else i[C]:=1;
   If (Arg^[0]^.Typ = VT_STR) then V:=NewVal(VT_STR,Copy(PStr(Arg^[0]^.Ptr)^,i[1],i[2])) else
   If (Arg^[0]^.Typ = VT_UTF) then V:=NewVal(VT_UTF,PUTF(Arg^[0]^.Ptr)^.SubStr(i[1],i[2])) else
                              {el} V:=NewVal(VT_STR,Copy(ValAsStr(Arg^[0]),i[1],i[2]));
   For C:=2 downto 0 do
       If (Length(Arg^)>C) and (Arg^[C]^.Lev >= CurLev)
          then FreeVal(Arg^[C]);
   Exit(V)
   end;

Function F_DelStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; I:Array[1..2] of QInt; 
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
   If (Length(Arg^)>3) then
      For C:=High(Arg^) downto 3 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   For C:=2 downto 1 do
       If (Length(Arg^)>C) then begin
          If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ<= VT_BIN)
             then i[C]:=PQInt(Arg^[C]^.Ptr)^
             else i[C]:=ValAsInt(Arg^[C]);
            end else
             If (C=2) then i[C]:=High(QInt) else i[C]:=1;
   If (Arg^[0]^.Typ = VT_UTF) then begin
      V:=CopyVal(Arg^[0]); PUTF(V^.Ptr)^.Delete(i[1],i[2])
      end else begin
      If (Arg^[0]^.Typ = VT_STR)
         then V:=CopyVal(Arg^[0])
         else V:=ValToStr(Arg^[0]);
      Delete(PStr(V^.Ptr)^,i[1],i[2])
      end;
   For C:=2 downto 0 do
       If (Length(Arg^)>C) and (Arg^[C]^.Lev >= CurLev)
          then FreeVal(Arg^[C]);
   Exit(V)
   end;

Function F_InsertStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; Idx : LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      F_(False,Arg); Exit(EmptyVal(VT_STR))
      end;
   If (Length(Arg^) > 2)
      then Idx := ValAsInt(Arg^[2])
      else Idx := 1;
   If (Arg^[0]^.Typ = VT_UTF) then begin
      V := CopyVal(Arg^[0]);
      If (Arg^[1]^.Typ = VT_UTF)
         then PUTF(V^.Ptr)^.Insert(PUTF(Arg^[1]^.Ptr),Idx)
         else PUTF(V^.Ptr)^.Insert(ValAsStr(Arg^[1]),Idx)
      end else begin
      V := NewVal(VT_STR, ValAsStr(Arg^[0]));
      Insert(ValAsStr(Arg^[1]), PStr(V^.Ptr)^, Idx)
      end;
   For C:=0 to High(Arg^) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   Exit(V)
   end;

Function F_MakeCharacter(Func:TChrFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; Inline;
   Var C:LongWord; V:PValue; 
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NilVal());
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   V := NewVal(VT_STR, Func(ValAsInt(Arg^[0])));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(V)
   end;

Function F_MakeOrdinal(Func:TOrdFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; Inline;
   Var C:LongWord; V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NilVal());
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   V := NewVal(VT_INT, Func(ValAsStr(Arg^[0])));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(V)
   end;

Function F_Chr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_MakeCharacter(@ASCII_Char, DoReturn, Arg)) end;

Function F_Chr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_MakeCharacter(@UTF8_Char, DoReturn, Arg)) end;

Function F_Ord(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_MakeOrdinal(@ASCII_Ord, DoReturn, Arg)) end;

Function F_Ord_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_MakeOrdinal(@UTF8_Ord, DoReturn, Arg)) end;

Function F_Perc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; I:PQInt; S:AnsiString; D:PFloat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_STR,'0%')) else S:='';
   If (Length(Arg^)>2) then
      For C:=High(Arg^) downto 2 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Length(Arg^)>=2) then begin
      If (Arg^[0]^.Typ = VT_FLO) then begin
         V:=CopyVal(Arg^[0]); D:=PFloat(V^.Ptr); (D^)*=100; ValDiv(V,Arg^[1]);
         S:=Values.IntToStr(Trunc(PFloat(V^.Ptr)^))+'%';
         FreeVal(V)
         end else begin
         If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
            then V:=CopyVal(Arg^[0]) else V:=ValToInt(Arg^[0]);
         I:=PQInt(V^.Ptr); (I^)*=100; ValDiv(V,Arg^[1]);
         S:=Values.IntToStr(PQInt(V^.Ptr)^)+'%';
         FreeVal(V)
         end
      end else begin
      If (Arg^[0]^.Typ = VT_FLO)
         then S:=Values.IntToStr(Trunc(100*PFloat(Arg^[0]^.Ptr)^))+'%'
         else S:=Values.IntToStr(Trunc(100*ValAsFlo(Arg^[0])))+'%';
      end;
   If (Length(Arg^) >= 2) and (Arg^[1]^.Lev >= CurLev) then FreeVal(Arg^[1]);
   If (Length(Arg^) >= 1) and (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_WriteStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Str,Tmp:TStr; C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   Str := ''; Tmp := '';
   If (Length(Arg^) > 0) then
      For C:=Low(Arg^) to High(Arg^) do begin
          Case Arg^[C]^.Typ of
             VT_NIL: WriteStr(Tmp, '{NIL}');
             VT_NEW: WriteStr(Tmp, '{NEW}');
             VT_PTR: WriteStr(Tmp, '{PTR}');
             VT_INT: WriteStr(Tmp, PQInt(Arg^[C]^.Ptr)^);
             VT_HEX: WriteStr(Tmp, Values.HexToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_OCT: WriteStr(Tmp, Values.OctToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_BIN: WriteStr(Tmp, Values.BinToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_FLO: WriteStr(Tmp, Values.FloatToStr(PFloat(Arg^[C]^.Ptr)^));
             VT_BOO: WriteStr(Tmp, PBoolean(Arg^[C]^.Ptr)^);
             VT_STR: WriteStr(Tmp, PAnsiString(Arg^[C]^.Ptr)^);
             VT_UTF: WriteStr(Tmp, PUTF(Arg^[C]^.Ptr)^.ToAnsiString());
             VT_ARR: WriteStr(Tmp, 'array(',PArray(Arg^[C]^.Ptr)^.Count,')');
             VT_DIC: WriteStr(Tmp, 'dict(',PDict(Arg^[C]^.Ptr)^.Count,')');
             VT_FIL: WriteStr(Tmp, 'file(',PFileVal(Arg^[C]^.Ptr)^.Pth,')');
             else WriteStr(Tmp, '(',Arg^[C]^.Typ,')');
             end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
          Str += Tmp
          end;
   Exit(NewVal(VT_STR, Str))
   end;

Function F_WriteStr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var V:PValue; U:PUTF8String;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   V := F_WriteStr(True, Arg);
   New(U, Create(PStr(V^.Ptr)^));
   Dispose(PStr(V^.Ptr));
   V^.Typ := VT_UTF; V^.Ptr := U;
   Exit(V)
   end;

end.
