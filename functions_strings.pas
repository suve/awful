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
Function F_StrRPos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SubStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DelStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_InsertStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_ReplaceStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_ReverseStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_WriteStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_WriteStr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Chr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Ord_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Chr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Ord(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Explode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Implode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Perc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function UTF8_Char(Code:LongWord):ShortString;
Function UTF8_Ord(Const Chr:ShortString):LongInt;

implementation
   uses SysUtils, StrUtils, StringUtils,
        FileHandling, EmptyFunc,
        Values_Arith, Values_Typecast, Convert;


Procedure Register(Const FT:PFunTrie);
   begin
   // Char functions
   FT^.SetVal('chr',MkFunc(@F_chr));
   FT^.SetVal('chru',MkFunc(@F_chr_UTF8));
   FT^.SetVal('ord',MkFunc(@F_ord));
   FT^.SetVal('ordu',MkFunc(@F_ord_UTF8));
   // String manipulation functions
   FT^.SetVal('str-trim',MkFunc(@F_Trim));
   FT^.SetVal('str-letrim',MkFunc(@F_TrimLeft));
   FT^.SetVal('str-ritrim',MkFunc(@F_TrimRight));
   FT^.SetVal('str-upper',MkFunc(@F_UpperCase));
   FT^.SetVal('str-lower',MkFunc(@F_LowerCase));
   FT^.SetVal('str-bytes',MkFunc(@F_StrBts));
   FT^.SetVal('str-len',MkFunc(@F_StrLen));
   FT^.SetVal('str-pos',MkFunc(@F_StrPos));
   FT^.SetVal('str-rpos',MkFunc(@F_StrRPos));
   FT^.SetVal('str-sub',MkFunc(@F_SubStr));
   FT^.SetVal('str-del',MkFunc(@F_DelStr));
   FT^.SetVal('str-ins',MkFunc(@F_InsertStr));
   FT^.SetVal('str-replace',MkFunc(@F_ReplaceStr));
   FT^.SetVal('str-rev',MkFunc(@F_ReverseStr));
   // String <- -> Array utils
   FT^.SetVal('str-explode',MkFunc(@F_Explode));
   FT^.SetVal('explode-str',MkFunc(@F_Explode));
   FT^.SetVal('str-implode',MkFunc(@F_Implode));
   FT^.SetVal('implode-str',MkFunc(@F_Implode));
   // Utils
   FT^.SetVal('str-write',MkFunc(@F_WriteStr));
   FT^.SetVal('str-writeu',MkFunc(@F_WriteStr_UTF8));
   FT^.SetVal('utf8-write',MkFunc(@F_WriteStr_UTF8));
   FT^.SetVal('perc',MkFunc(@F_Perc));
   end;

Const UTF8_Mask:Array[2..6] of Byte =
      (%11000000, %11100000, %11110000, %11111000, %11111100);

Function UTF8_Char(Code:LongWord):ShortString;
   Var Bit:Array[0..31] of Byte; C:LongInt; S:ShortString;
   
   Function MakeChar(Const Mask:Byte;Max,Min:LongInt):Char;
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

Function UTF8_Ord(Const Chr:ShortString):LongInt;
   
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

Function ASCII_Ord(Const Str:ShortString):LongInt;
   begin If (Length(Str)>0) then Exit(Ord(Str[0])) else Exit(0) end;

Type TChrFunc = Function(Code:LongWord):ShortString;
Type TOrdFunc = Function(Const Str:ShortString):LongInt;

Type TTransformID = (TID_Trim, TID_TrimLe, TID_TrimRi, TID_Upper, TID_Lower);

Function F_TransformStr(Const DoReturn:Boolean; Const Arg:PArrPVal; Const funID:TTransformID):PValue;
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
   begin Exit(F_TransformStr(DoReturn, Arg, TID_Trim)) end;

Function F_TrimLeft(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(DoReturn, Arg, TID_TrimLe)) end;

Function F_TrimRight(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(DoReturn, Arg, TID_TrimRi)) end;

Function F_UpperCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(DoReturn, Arg, TID_Upper)) end;

Function F_LowerCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_TransformStr(DoReturn, Arg, TID_Lower)) end;

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
   If (Arg^[1]^.Typ = VT_UTF) then begin
      If (Arg^[0]^.Typ = VT_UTF) then P:=PUTF(Arg^[1]^.Ptr)^.SearchLeft(PUTF(Arg^[0]^.Ptr))
                                 else P:=PUTF(Arg^[1]^.Ptr)^.SearchLeft(ValAsStr(Arg^[0]))
      end else
      P:=Pos(ValAsStr(Arg^[0]),ValAsStr(Arg^[1]));
   For C:=1 downto 0 do If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   Exit(NewVal(VT_INT,P))
   end;

Function F_StrRPos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; P:QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)<2) then Exit(NewVal(VT_INT,0));
   If (Length(Arg^)>2) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[1]^.Typ = VT_UTF) then begin
      If (Arg^[0]^.Typ = VT_UTF) then P:=PUTF(Arg^[1]^.Ptr)^.SearchRight(PUTF(Arg^[0]^.Ptr))
                                 else P:=PUTF(Arg^[1]^.Ptr)^.SearchRight(ValAsStr(Arg^[0]))
      end else
      P:=RPos(ValAsStr(Arg^[0]),ValAsStr(Arg^[1]));
   For C:=1 downto 0 do If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   Exit(NewVal(VT_INT,P))
   end;

Function F_SubStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongInt; I:Array[1..2] of QInt; V:PValue;
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
             If (C=2) then i[C]:=$7FFFFFFF else i[C]:=1;
   If (Arg^[0]^.Typ = VT_STR) then V:=NewVal(VT_STR,Copy(PStr(Arg^[0]^.Ptr)^,i[1],i[2])) else
   If (Arg^[0]^.Typ = VT_UTF) then V:=NewVal(VT_UTF,PUTF(Arg^[0]^.Ptr)^.SubStr(i[1],i[2])) else
                              {el} V:=NewVal(VT_STR,Copy(ValAsStr(Arg^[0]),i[1],i[2]));
   For C:=2 downto 0 do
       If (Length(Arg^)>C) and (Arg^[C]^.Lev >= CurLev)
          then FreeVal(Arg^[C]);
   Exit(V)
   end;

Function F_DelStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongInt; V:PValue; I:Array[1..2] of QInt; 
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
   Var C:LongWord; Idx : LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      F_(False,Arg); Exit(EmptyVal(VT_STR))
      end;
   If (Length(Arg^) > 2)
      then Idx := ValAsInt(Arg^[2])
      else Idx := 1;
   If (Arg^[0]^.Typ = VT_UTF) then begin
      Result := CopyVal(Arg^[0]);
      If (Arg^[1]^.Typ = VT_UTF)
         then PUTF(Result^.Ptr)^.Insert(PUTF(Arg^[1]^.Ptr),Idx)
         else PUTF(Result^.Ptr)^.Insert(ValAsStr(Arg^[1]),Idx)
      end else begin
      Result := NewVal(VT_STR, ValAsStr(Arg^[0]));
      Insert(ValAsStr(Arg^[1]), PStr(Result^.Ptr)^, Idx)
      end;
   For C:=0 to High(Arg^) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
   end;

Function F_ReplaceStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      F_(False,Arg); Exit(EmptyVal(VT_STR))
      end;
   If(Arg^[0]^.Typ = VT_UTF) then begin
      Result := CopyVal(Arg^[0]);
      If (Length(Arg^) > 2) then begin
         If (Arg^[1]^.Typ = VT_UTF)
            then If (Arg^[2]^.Typ = VT_UTF)
                     then PUTF(Result^.Ptr)^.Replace(PUTF(Arg^[1]^.Ptr), PUTF(Arg^[2]^.Ptr))
                     else PUTF(Result^.Ptr)^.Replace(PUTF(Arg^[1]^.Ptr), ValAsStr(Arg^[2]))
            else If (Arg^[2]^.Typ = VT_UTF)
                     then PUTF(Result^.Ptr)^.Replace(ValAsStr(Arg^[1]), PUTF(Arg^[2]^.Ptr))
                     else PUTF(Result^.Ptr)^.Replace(ValAsStr(Arg^[1]), ValAsStr(Arg^[2]))
         end else begin
         If (Arg^[2]^.Typ = VT_UTF)
            then PUTF(Result^.Ptr)^.Replace(PUTF(Arg^[1]^.Ptr), '')
            else PUTF(Result^.Ptr)^.Replace(ValAsStr(Arg^[1]), '')
         end
      end else begin
      Result := ValToStr(Arg^[0]);
      If (Length(Arg^) > 2)
         then PStr(Result^.Ptr)^ := StringReplace(PStr(Result^.Ptr)^, ValAsStr(Arg^[1]), ValAsStr(Arg^[2]), [rfReplaceAll])
         else PStr(Result^.Ptr)^ := StringReplace(PStr(Result^.Ptr)^, ValAsStr(Arg^[1]), '', [rfReplaceAll])
      end;
   For C:=0 to High(Arg^) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
   end;

Function F_MakeCharacter(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TChrFunc):PValue;
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

Function F_MakeOrdinal(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TOrdFunc):PValue;
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
   begin Exit(F_MakeCharacter(DoReturn, Arg, @ASCII_Char)) end;

Function F_Chr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_MakeCharacter(DoReturn, Arg, @UTF8_Char)) end;

Function F_Ord(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_MakeOrdinal(DoReturn, Arg, @ASCII_Ord)) end;

Function F_Ord_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_MakeOrdinal(DoReturn, Arg, @UTF8_Ord)) end;

Function F_ReverseStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
   If (Arg^[0]^.Typ = VT_UTF) then begin
      Result := CopyVal(Arg^[0]);
      PUTF(Result^.Ptr)^.Reverse()
      end else Result := NewVal(VT_STR, ReverseString(ValAsStr(Arg^[0])));
   F_(False, Arg)
   end;

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
         S:=Convert.IntToStr(Trunc(PFloat(V^.Ptr)^))+'%';
         FreeVal(V)
         end else begin
         If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
            then V:=CopyVal(Arg^[0]) else V:=ValToInt(Arg^[0]);
         I:=PQInt(V^.Ptr); (I^)*=100; ValDiv(V,Arg^[1]);
         S:=Convert.IntToStr(PQInt(V^.Ptr)^)+'%';
         FreeVal(V)
         end
      end else begin
      If (Arg^[0]^.Typ = VT_FLO)
         then S:=Convert.IntToStr(Trunc(100*PFloat(Arg^[0]^.Ptr)^))+'%'
         else S:=Convert.IntToStr(Trunc(100*ValAsFlo(Arg^[0])))+'%';
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
             VT_HEX: WriteStr(Tmp, Convert.HexToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_OCT: WriteStr(Tmp, Convert.OctToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_BIN: WriteStr(Tmp, Convert.BinToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_FLO: WriteStr(Tmp, Convert.FloatToStr(PFloat(Arg^[C]^.Ptr)^));
             VT_BOO: WriteStr(Tmp, PBoolean(Arg^[C]^.Ptr)^);
             VT_STR: WriteStr(Tmp, PAnsiString(Arg^[C]^.Ptr)^);
             VT_UTF: WriteStr(Tmp, PUTF(Arg^[C]^.Ptr)^.ToAnsiString());
             VT_ARR: WriteStr(Tmp, 'array(',PArray(Arg^[C]^.Ptr)^.Count,')');
             VT_DIC: WriteStr(Tmp, 'dict(',PDict(Arg^[C]^.Ptr)^.Count,')');
             VT_FIL: WriteStr(Tmp, 'file(',PFileHandle(Arg^[C]^.Ptr)^.Pth,')');
             else WriteStr(Tmp, '(',Arg^[C]^.Typ,')');
             end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
          Str += Tmp
          end;
   Exit(NewVal(VT_STR, Str))
   end;

Function F_WriteStr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var U:PUTF;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   Result := F_WriteStr(True, Arg);
   New(U, Create(PStr(Result^.Ptr)^));
   Dispose(PStr(Result^.Ptr));
   Result^.Typ := VT_UTF; Result^.Ptr := U
   end;

Function F_Explode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var FPCArray : StringUtils.AnsiStringArray; Arr:PArray;
       Delim : AnsiString; C : LongWord; ValType : TValueType;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_ARR));
   
   Result := EmptyVal(VT_ARR);
   Arr := PArray(Result^.Ptr);
   
   If (Length(Arg^) > 1)
      then Delim := ValAsStr(Arg^[1])
      else Delim := ',';
   
   If (Arg^[0]^.Typ = VT_UTF)
      then ValType := VT_UTF
      else ValType := VT_STR;
   
   FPCArray := ExplodeString(ValAsStr(Arg^[0]), Delim);
   If (Length(FPCArray) > 0) then
      For C:=Low(FPCArray) to High(FPCArray) do
         Arr^.SetVal(C, NewVal(ValType, FPCArray[C]));
   
   F_(False, Arg)
   end;

Function F_Implode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Str, Delim : AnsiString; C : LongWord;
       Arr:PArray; AEA:TArray.TEntryArr;
       Dict:PDict; DEA:TDict.TEntryArr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
   
   If (Length(Arg^) > 1)
      then Delim := ValAsStr(Arg^[1])
      else Delim := ',';
   
   If (Arg^[0]^.Typ = VT_ARR) then begin
      Arr := PArray(Arg^[0]^.Ptr);
      If (Arr^.Count > 0) then begin
         AEA := Arr^.ToArray();
         Str := ValAsStr(AEA[0].Val);
         For C:=1 to (Arr^.Count - 1) do Str := Str + Delim + ValAsStr(AEA[C].Val)
         end else
         Str := ''
      end else
   If (Arg^[0]^.Typ = VT_DIC) then begin
      Dict := PDict(Arg^[0]^.Ptr);
      If (Dict^.Count > 0) then begin
         DEA := Dict^.ToArray();
         Str := ValAsStr(DEA[0].Val);
         For C:=1 to (Dict^.Count - 1) do Str := Str + Delim + ValAsStr(DEA[C].Val)
         end else
         Str := ''
      end else begin
      Str := ValAsStr(Arg^[0])
      end;
   
   F_(False, Arg);
   Exit(NewVal(VT_STR, Str))
   end;

end.
