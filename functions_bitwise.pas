unit functions_bitwise;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Shl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Shr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_ExtractBits(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Values_Bitwise, Values_Typecast, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
      FT^.SetVal('bwnot',MkFunc(@F_not));    FT^.SetVal('b!' ,MkFunc(@F_Not));
      FT^.SetVal('bwand',MkFunc(@F_and));    FT^.SetVal('b&' ,MkFunc(@F_and));
      FT^.SetVal('bwxor',MkFunc(@F_xor));    FT^.SetVal('b^' ,MkFunc(@F_xor));
      FT^.SetVal('bwor' ,MkFunc(@F_or));     FT^.SetVal('b?' ,MkFunc(@F_or));
      FT^.SetVal('shl'  ,MkFunc(@F_shl));    FT^.SetVal('b<<',MkFunc(@F_shl));
      FT^.SetVal('shr'  ,MkFunc(@F_shr));    FT^.SetVal('b>>',MkFunc(@F_shr));
      FT^.SetVal('extract-bits' ,MkFunc(@F_ExtractBits))
   end;

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
      // No args, check if DoReturn and return
      If (Length(Arg^)=0) then begin
         If (DoReturn) then Exit(NilVal) else Exit(NIL) end;
      
      // More than one arg, free them if needed
      If (Length(Arg^) > 1) then 
         For C:=High(Arg^) downto 1 do
            FreeIfTemp(Arg^[C]);
      
      // If returning a value, get NOT of arg0; else, set result to NIL
      If (DoReturn)
         then Result := ValNot(Arg^[0])
         else Result := NIL;
      
      // Be so kind and free arg0 if needed
      FreeIfTemp(Arg^[0])
   end;

Type TBitwiseFunc = Function(Const A,B:PValue):PValue;

Function F_Bitwise(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Bitwise:TBitwiseFunc):PValue;
   Var C:LongWord;
   begin
      // If less than two args, or not returning a value, bail out early
      If (Not DoReturn) or (Length(Arg^) < 2)
         then Exit(F_(DoReturn, Arg));
      
      // Go through arg pairs - argHigh and argHigh-1, downto arg1 and arg0
      For C:=High(Arg^) downto 1 do begin
         // Get result of bitwise operation on args
         Result := Bitwise(Arg^[C-1], Arg^[C]); 
         
         // Free argC if needed
         FreeIfTemp(Arg^[C]);
         
         // Insert result of bitwise operation into argC.
         // It will thus become the second argument for the next bitwise op.
         Arg^[C] := Result
      end;
      
      // Free arg0, since it wasn't freed by the above loop
      FreeIfTemp(Arg^[0])
   end;

Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValAnd)) end;

Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValXor)) end;

Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValOr)) end;

Function F_Shl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValShl)) end;

Function F_Shr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValShr)) end;

Function F_ExtractBits(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var B,OffB,OffA:LongWord; 
       ByteArray : PByte; BA:Array of Byte; ByteLen : LongWord; 
       BegBit, EndBit : QInt;
   begin
      // If not returning a value, bail out early, freeing args
      If (Not DoReturn) then Exit(F_(False,Arg));
      
      // If no args, return NilVal
      If (Length(Arg^) = 0) then Exit(NilVal());
      
      // If arg0 is NilVal, return all-zero value
      If (Arg^[0]^.Typ = VT_NIL) then begin
         F_(False, Arg);
         Exit(EmptyVal(VT_BIN))
      end;
      
      // Set ByteArray pointer to arg0 pointer
      ByteArray := Arg^[0]^.Ptr;
      Case (Arg^[0]^.Typ) of
         
         VT_INT .. VT_BIN: 
            ByteLen := Sizeof(QInt);
         
         VT_FLO:
            ByteLen := Sizeof(TFloat);
         
         VT_BOO:
            ByteLen := Sizeof(TBool);
         
         (* In case of strings, we do not want to go over the string's internal representation *
          * (which is compiler magic mumbo jumbo, since TStr = AnsiString), rather going over  *
          * the characters in the string. Which means, we have to copy the character data.     *)
         VT_STR: begin
            // Set helper array length
            offB := Length(PStr(Arg^[0]^.Ptr)^);
            SetLength(BA, offB);
            // Go through all characters
            For offA:=1 to offB do
               {$IFDEF ENDIAN_LITTLE}
                  {$NOTE Using little-endian stringchar copy code.}
                  // If little endian, we have to reverse characters, to match
                  // the reversed byte order of other types
                  BA[offB - offA] := Ord(Arg^[0]^.Str^[offA]);
               {$ELSE}
                  {$NOTE Using big-endian stringchar copy code.}
                  // On Big Endian we just copy everything as it goes.
                  BA[offA-1] := Ord(Arg^[0]^.Str^[offA]);
               {$ENDIF}
            // Set ByteArray pointer to our byte helper array and set bytelen
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
      
      // Based on args, or default values, decide the lowest and highest bit to extract
      If (Length(Arg^) > 1) then begin
         BegBit := ValAsInt(Arg^[1]);
         If (Length(Arg^) > 2)
            then EndBit := ValAsInt(Arg^[2])
            else EndBit := BegBit + SizeOf(QInt)*8;
      end else begin
         BegBit := 0;
         EndBit := SizeOf(QInt)*8;
      end;
      
      // Do some input sanitizing
      If (BegBit < 0) then BegBit := 0;
      If (EndBit < 0) then EndBit := 0;
      If (EndBit >= ByteLen*8) then EndBit := (ByteLen*8)-1;
      
      (* Bit numbers go from right to left,        *
       * but ByteArray indexes go the other way,   *
       * so we reverse the low/high bit values     *
       * from "bits from start" to "bits from end" *) 
      EndBit := ((ByteLen*8)-1) - EndBit;
      BegBit := ((ByteLen*8)-1) - BegBit;
      
      // Again, a sanity check
      If (EndBit < 0) then EndBit := 0;
      If (BegBit < 0) then BegBit := 0;
      
      // Allocate an all-zero value for result and go through all the bits to extract
      Result := EmptyVal(VT_BIN);
      For B:=EndBit to BegBit do begin
         {$IF     DEFINED(ENDIAN_LITTLE)}
            {$NOTE Little endian code compiled.}
            // On little endian platforms, we need to take the reversed byte order
            // when calculating which byte the B-th bit resides in
            OffA := ByteLen - 1 - (B div 8);
         {$ELSEIF DEFINED(ENDIAN_BIG)   }
            {$NOTE Big endian code compiled.}
            // On Big Endian everything is nice and fun, we just do a div
            OffA := B div 8;
         {$ELSE}
            // Neither little endian nor big endian. Wait, what?
            {$FATAL Unable to determine endianness.}
         {$ENDIF}
         // Calculate bit offset in byte (luckily the same regardless of endianness)
         OffB := B mod 8;
         
         // Multiply current result by 2 to make place at the lowest bit
         Result^.Int^ *= 2;
         If ((ByteArray[offA] and (1 shl (7-offB))) <> 0) // Check if bit is set
            then PQInt(Result^.Ptr)^ += 1 // If yes, set the lowest bit in returned value
      end;
      
      // Be ever so kind and pass args to the emptyfunc to free them
      F_(False,Arg)
   end;

end.
