unit functions_bitwise;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_ExtractBits(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses FileHandling, Values_Bitwise, Values_Typecast, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('bwnot',MkFunc(@F_not));    FT^.SetVal('b!',MkFunc(@F_Not));
   FT^.SetVal('bwand',MkFunc(@F_and));    FT^.SetVal('b&',MkFunc(@F_and));
   FT^.SetVal('bwxor',MkFunc(@F_xor));    FT^.SetVal('b^',MkFunc(@F_xor));
   FT^.SetVal('bwor' ,MkFunc(@F_or));     FT^.SetVal('b?',MkFunc(@F_or));
   FT^.SetVal('extract-bits' ,MkFunc(@F_ExtractBits))
   end;

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(NilVal) else Exit(NIL) end;
   If (Length(Arg^)>1) then 
       For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then begin
      V:=ValNot(Arg^[0]);
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(V)
      end else begin
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(NIL)
      end
   end;

Type TBitwiseFunc = Function(Const A,B:PValue):PValue;

Function F_Bitwise(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Bitwise:TBitwiseFunc):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Not DoReturn) or (Length(Arg^)<2)
      then Exit(F_(DoReturn, Arg));
   For C:=High(Arg^) downto 1 do begin
       V:=Bitwise(Arg^[C-1], Arg^[C]);
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
       Arg^[C] := V
       end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(V)
   end;

Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValAnd)) end;

Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValXor)) end;

Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValOr)) end;


Function F_ExtractBits(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var B,OffB,OffA:LongWord; 
       ByteArray : ^Byte; BA:Array of Byte; ByteLen : LongWord; 
       BegBit, EndBit : QInt;
   begin
   If (Not DoReturn) then Exit(F_(False,Arg));
   If (Length(Arg^) = 0) then Exit(F_(True,Arg));
   
   If (Arg^[0]^.Typ = VT_NIL) then begin
      F_(False, Arg);
      Exit(EmptyVal(VT_BIN))
      end;
   
   ByteArray := Arg^[0]^.Ptr;
   Case (Arg^[0]^.Typ) of
      
      VT_INT .. VT_BIN: 
         ByteLen := Sizeof(QInt);
      
      VT_FLO:
         ByteLen := Sizeof(TFloat);
      
      VT_BOO:
         ByteLen := Sizeof(TBool);
      
      VT_STR:
         begin
         offB := Length(PStr(Arg^[0]^.Ptr)^);
         SetLength(BA,offB);
         For offA:=1 to offB do
            {$IFDEF ENDIAN_LITTLE}
            BA[offB - offA] := Ord(PStr(Arg^[0]^.Ptr)^[offA]);
            {$ELSE}
            BA[offA-1] := Ord(PStr(Arg^[0]^.Ptr)^[offA]);
            {$ENDIF}
         ByteArray := @BA[0];
         ByteLen := offB;
         end;
      
      VT_UTF:
         ByteLen := SizeOf(TUTF);
      
      VT_ARR:
         ByteLen := SizeOf(TArr);
      
      VT_DIC:
         ByteLen := SizeOf(TDict);
      
      VT_FIL:
         ByteLen := SizeOf(TFileHandle);
      
      end;
   
   If (Length(Arg^) > 1) then begin
      BegBit := ValAsInt(Arg^[1]);
      If (Length(Arg^) > 2)
         then EndBit := ValAsInt(Arg^[2])
         else EndBit := BegBit + SizeOf(QInt)*8;
      end else begin
      BegBit := 0;
      EndBit := SizeOf(QInt)*8;
      end;
   
   If (BegBit < 0) then BegBit := 0;
   If (EndBit < 0) then EndBit := 0;
   If (EndBit >= ByteLen*8) then EndBit := (ByteLen*8)-1;
   
   EndBit := ((ByteLen*8)-1) - EndBit;
   BegBit := ((ByteLen*8)-1) - BegBit;
   
   If (EndBit < 0) then EndBit := 0;
   If (BegBit < 0) then BegBit := 0;
   
   Result := EmptyVal(VT_BIN);
   For B:=EndBit to BegBit do begin
      {$IF     DEFINED(ENDIAN_LITTLE)}{$NOTE Little endian code compiled.}
      OffA := ByteLen - 1 - (B div 8);
      {$ELSEIF DEFINED(ENDIAN_BIG)   }{$NOTE Big endian code compiled.}
      OffA := B div 8;
      {$ELSE}
      {$FATAL Unable to determine endianness.}
      {$ENDIF}
      OffB := B mod 8;
      PQInt(Result^.Ptr)^ *= 2;
      If ((ByteArray[offA] and (1 shl (7-offB))) <> 0)
         then PQInt(Result^.Ptr)^ += 1;
   end;
   
   F_(False,Arg)
   end;

end.
