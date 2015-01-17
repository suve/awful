unit functions_strings;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

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
Function F_ReplaceStrAssoc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

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
        EmptyFunc,
        Values_Typecast, Convert;


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
      FT^.SetVal('str-replace-dict',MkFunc(@F_ReplaceStrAssoc));
      FT^.SetVal('str-replace-assoc',MkFunc(@F_ReplaceStrAssoc));
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

Const
   UTF8_Mask:Array[2..6] of Byte = (
      %11000000, %11100000, %11110000, %11111000, %11111100
   );

Function UTF8_Char(Code:LongWord):ShortString;
   Var Bit:Array[0..31] of Byte; C:LongInt;
   
   Function MakeChar(Const Mask:Byte;Max,Min:LongInt):Char;
      Var B:Byte;
      begin
         B:=0;
         While (Max > Min) do begin
            B += Bit[Max]; B *= 2; Max -= 1
         end;
         B := Mask + B + Bit[Max];
         Exit(Chr(B))
      end;
   
   begin 
      // If codepoint is below 128, return plain ASCII char.
      If (Code < 128) then Exit(Chr(Code));
      
      // Set bit array to zeroes. Then, fill it with consecutive bits of codepoint.
      For C:=0 to 31 do Bit[C]:=0; C:=0;
      While (Code > 0) do begin
         Bit[C]:=(Code mod 2);
         Code := Code div 2;
         C += 1
      end;
      
      (* Each continuation bytes introduces 6 bits, but the mask on the leading bit gets longer, *
       * consuming 1 bit - that's why the steps are 5 bits apart instead of 6.                   *)
      If (C <= 11) then begin C:=05; Result := MakeChar(UTF8_Mask[2],10,06) end else // Up to 11 bits =   two-char sequence
      If (C <= 16) then begin C:=11; Result := MakeChar(UTF8_Mask[3],15,12) end else // Up to 16 bits = three-char sequence
      If (C <= 21) then begin C:=17; Result := MakeChar(UTF8_Mask[4],20,18) end else // Up to 21 bits =  four-char sequence
      If (C <= 26) then begin C:=23; Result := MakeChar(UTF8_Mask[5],25,24) end else // Up to 26 bits =  five-char sequence
      If (C <= 31) then begin C:=29; Result := MakeChar(UTF8_Mask[6],30,30) end else // Up to 31 bits =   six-char sequence
         {else} Exit(''); // Sequences representable in UTF-8 end at 7FFFFFFF. 32bits being used means we hit >= 80000000.
      
      // Add continuation chars to leading byte
      While (C > 0) do begin
         Result += MakeChar(%10000000, C, C-5); C -= 6
      end
   end;

Function UTF8_Ord(Const Chr:ShortString):LongInt;
   
   Function Bitmask(Val,Mask:Byte):Boolean; Inline;
      begin Exit((Val and Mask) = Mask) end;
   
   Var C, L:LongWord;
   begin
      // Emptystring = return -1 to signal error
      If (Length(Chr) = 0) then Exit(-1);
      // First char below 128 = ordinary ASCII character
      If (Ord(Chr[1]) < 128) then Exit(Ord(Chr[1]));
      
      // Set length and ord to 0 and try to detect UTF-8 sequence length
      L := 0; Result := 0;
      For C:=6 downto 2 do
         (* Sequences are max 6-chars long. Well, 4, since Unicode currently ends at 10FFFF, *
          * but technically 6-chars is the limit. Check the first byte against the leading   * 
          * byte masks. If we got a fit, means we found the representation length.           *)
         If (Bitmask(Ord(Chr[1]), UTF8_Mask[C])) then begin
            If(Length(Chr) < C) then Exit(-1);              // If string is shorter than the leading byte suggests, error
            Result := (Ord(Chr[1]) and (Not UTF8_Mask[C])); // The leading byte holds 1-5 bits of codepoint, extract this
            L := C; Break                                   // Set length and break loop
         end;
      If (L = 0) then Exit(-1); // None of the masks matched. Clearly an error.
      
      // Go from char 2 to required length
      For C:=2 to L do begin
         // Check if valid continuation byte
         If ((Ord(Chr[C]) < %10000000) or (Ord(Chr[C]) > %10111111)) then Exit(-1);
         
         (* Multiply ord by 2^6 (because continuation bytes hold 6 bits of data), *
          * extract those 6 bits from the byte and add to resulting ord.          *)
         Result := (Result * %1000000) + (Ord(Chr[C]) and %00111111);
      end
   end;

Function ASCII_Char(Code:LongWord):ShortString;
   begin Exit(Chr(Code)) end;

Function ASCII_Ord(Const Str:ShortString):LongInt;
   begin If (Length(Str)>0) then Exit(Ord(Str[0])) else Exit(-1) end;

Type TChrFunc = Function(Code:LongWord):ShortString;
Type TOrdFunc = Function(Const Str:ShortString):LongInt;

Type TTransformID = (TID_Trim, TID_TrimLe, TID_TrimRi, TID_Upper, TID_Lower);

Function F_TransformStr(Const DoReturn:Boolean; Const Arg:PArrPVal; Const funID:TTransformID):PValue;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args provided, return emptystring
      If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
      
      // Check if arg0 is utfstring or asciistring 
      If (Arg^[0]^.Typ = VT_UTF) then begin
         Result := CopyVal(Arg^[0]);
         Case funID of  // utfstring transforms are done by calling the UTF object methods
            TID_Trim:   Result^.Utf^.Trim();
            TID_TrimLe: Result^.Utf^.TrimLeft();
            TID_TrimRi: Result^.Utf^.TrimRight();
            TID_Upper:  Result^.Utf^.UpperCase();
            TID_Lower:  Result^.Utf^.LowerCase()
      end end else begin
         Result := ValToStr(Arg^[0]);
         Case funID of  // asciistring transforms are done via functions
            TID_Trim:   Result^.Str^ := Trim(Result^.Str^);
            TID_TrimLe: Result^.Str^ := TrimLeft(Result^.Str^);
            TID_TrimRi: Result^.Str^ := TrimRight(Result^.Str^);
            TID_Upper:  Result^.Str^ := UpperCase(Result^.Str^);
            TID_Lower:  Result^.Str^ := LowerCase(Result^.Str^)
      end end;
      F_(False, Arg) // Free args before leaving
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
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args provided, return 0
      If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
      
      If (Arg^[0]^.Typ = VT_UTF)
         then Result := NewVal(VT_INT, Arg^[0]^.Utf^.Bytes)        // In utfstrings, byte size can be read via property
         else Result := NewVal(VT_INT, Length(ValAsStr(Arg^[0]))); // In asciistrings, length = size in bytes
         
      F_(False, Arg) // Free args before leaving
   end;

Function F_StrLen(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args provided, return 0
      If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
      
      If (Arg^[0]^.Typ = VT_UTF)
         then Result := NewVal(VT_INT, Arg^[0]^.Utf^.Len)
         else Result := NewVal(VT_INT, Length(ValAsStr(Arg^[0])));
         
      F_(False, Arg) // Free args before leaving
   end;

Function F_StrPos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // No retval expected = bail out without doing anything
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      If (Length(Arg^) > 2) then begin // Check if enough args provided
         If (Arg^[1]^.Typ = VT_UTF) then begin // If the haystack is UTF8, we need to lookup using utfstring object methods
            If (Arg^[0]^.Typ = VT_UTF)
               then Result := NewVal(VT_INT, Arg^[1]^.Utf^.SearchLeft(Arg^[0]^.Utf))      // Lookup UTF8 needle
               else Result := NewVal(VT_INT, Arg^[1]^.Utf^.SearchLeft(ValAsStr(Arg^[0]))) // Lookup asciistring-cast needle
         end else
            Result := NewVal(VT_INT, Pos(ValAsStr(Arg^[0]),ValAsStr(Arg^[1]))) // Perform lookup in asciistring-cast
      end else
         Result := NewVal(VT_INT, 0); // Not enough args, return 0 to signal error
         
      F_(False, Arg) // Free args before leaving
   end;

Function F_StrRPos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // No retval expected = bail out without doing anything
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      If (Length(Arg^) > 2) then begin // Check if enough args provided
         If (Arg^[1]^.Typ = VT_UTF) then begin // If the haystack is UTF8, we need to lookup using utfstring object methods
            If (Arg^[0]^.Typ = VT_UTF)
               then Result := NewVal(VT_INT, Arg^[1]^.Utf^.SearchRight(Arg^[0]^.Utf))      // Lookup UTF8 needle
               else Result := NewVal(VT_INT, Arg^[1]^.Utf^.SearchRight(ValAsStr(Arg^[0]))) // Lookup asciistring-cast needle
         end else
            Result := NewVal(VT_INT, RPos(ValAsStr(Arg^[0]),ValAsStr(Arg^[1]))) // Perform lookup in asciistring-cast
      end else
         Result := NewVal(VT_INT, 0); // Not enough args, return 0 to signal error
         
      F_(False, Arg) // Free args before leaving
   end;

Function F_SubStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Start, Len : QInt;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args, return empty string
      If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
      
      // Take provided Start / Length or use defaults
      Case (Length(Arg^)) of
         1: begin
            Start := 1; Len := $7FFFFFFF
         end;
         
         2: begin
            Start := ValAsInt(Arg^[1]); Len := $7FFFFFFF
         end;
         
         else begin
            Start := ValAsInt(Arg^[1]); Len := ValAsInt(Arg^[2])
         end
      end;
      
      // Create result value based on type of string provided
      If (Arg^[0]^.Typ = VT_STR) then
         Result:=NewVal(VT_STR, Copy(Arg^[0]^.Str^, Start, Len))
      else If (Arg^[0]^.Typ = VT_UTF) then
         Result:=NewVal(VT_UTF, Arg^[0]^.Utf^.SubStr(Start, Len))
      else
         Result:=NewVal(VT_STR, Copy(ValAsStr(Arg^[0]), Start, Len));
      
      F_(False, Arg) // Free args before leaving
   end;

Function F_DelStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Start, Len : QInt; 
   begin
      // If no retval expected, bail out and do nothing
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args provided, return empty string
      If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
      
      // Take provided Start / Length or use defaults
      Case (Length(Arg^)) of
         0: begin
            Start := 1; Len := $7FFFFFFF
         end;
         
         1: begin
            Start := ValAsInt(Arg^[1]); Len := $7FFFFFFF
         end;
         
         else begin
            Start := ValAsInt(Arg^[1]); Len := ValAsInt(Arg^[2])
         end
      end;
      
      // Based on arg0 type, create result value
      If (Arg^[0]^.Typ = VT_UTF) then begin
         Result:=CopyVal(Arg^[0]); Result^.Utf^.Delete(Start, Len)
      end else begin
         Result:=ValToStr(Arg^[0]);
         Delete(Result^.Str^, Start, Len)
      end;
      
      F_(False, Arg) // Kindly free args before leaving
   end;

Function F_InsertStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Idx : LongWord;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If not enough args, free them and return emptystring
      If (Length(Arg^) < 2) then begin
         F_(False,Arg); Exit(EmptyVal(VT_STR))
      end;
      
      // Take insert position from argument or use default
      If (Length(Arg^) > 2)
         then Idx := ValAsInt(Arg^[2])
         else Idx := 1;
      
      // Based on arg0 type, create result value
      If (Arg^[0]^.Typ = VT_UTF) then begin
         Result := CopyVal(Arg^[0]);
         If (Arg^[1]^.Typ = VT_UTF)
            then Result^.Utf^.Insert(Arg^[1]^.Utf, Idx)
            else Result^.Utf^.Insert(ValAsStr(Arg^[1]), Idx)
      end else begin
         Result := NewVal(VT_STR, ValAsStr(Arg^[0]));
         Insert(ValAsStr(Arg^[1]), Result^.Str^, Idx)
      end;
      
      F_(False, Arg) // Free args before leaving
   end;

Function F_ReplaceStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If less than two args provided, free args and return emptystring
      If (Length(Arg^) < 2) then begin
         F_(False,Arg); Exit(EmptyVal(VT_STR))
      end;
      
      // Check if arg0 is a UTF-string. If yes, we want the result to be UTF-string, too.
      If(Arg^[0]^.Typ = VT_UTF) then begin
         Result := CopyVal(Arg^[0]);
         
         If (Length(Arg^) > 2) then begin
            // Check type of arg1 and arg2 and call TUTF8String.Replace() accordingly.
            
            If (Arg^[1]^.Typ = VT_UTF) then
               If (Arg^[2]^.Typ = VT_UTF)
                  then Result^.Utf^.Replace(Arg^[1]^.Utf, Arg^[2]^.Utf)
                  else Result^.Utf^.Replace(Arg^[1]^.Utf, ValAsStr(Arg^[2]))
            else
               If (Arg^[2]^.Typ = VT_UTF)
                  then Result^.Utf^.Replace(ValAsStr(Arg^[1]), Arg^[2]^.Utf)
                  else Result^.Utf^.Replace(ValAsStr(Arg^[1]), ValAsStr(Arg^[2]))
         
         end else begin
            // Only two args, replace arg1 with emptystring
            If (Arg^[1]^.Typ = VT_UTF)
               then Result^.Utf^.Replace(Arg^[1]^.Utf, '')
               else Result^.Utf^.Replace(ValAsStr(Arg^[1]), '')
         end
      end else begin
         
         (* arg0 is not a UTF-string. Obtain asciistring-cast to use as result value, *
          * and perform StringReplace on the PValue string.                           *)
         Result := ValToStr(Arg^[0]);
         If (Length(Arg^) > 2)
            then Result^.Str^ := StringReplace(Result^.Str^, ValAsStr(Arg^[1]), ValAsStr(Arg^[2]), [rfReplaceAll])
            else Result^.Str^ := StringReplace(Result^.Str^, ValAsStr(Arg^[1]), '', [rfReplaceAll])
      end;
      F_(False, Arg) // Free args before leaving
   end;

Function F_ReplaceStrAssoc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; DEA : TDict.TEntryArr;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If less than two args provided, free args and return emptystring
      If (Length(Arg^) < 2) then begin
         F_(False,Arg); Exit(EmptyVal(VT_STR))
      end;
      
      // Check if arg1 is a dictionary. If not, nothing to do here.
      If(Arg^[1]^.Typ <> VT_DIC) then Exit(F_(True, Arg));
      
      // Check if arg0 is a UTF-string. If yes, we want the result to be UTF-string, too.
      If(Arg^[0]^.Typ = VT_UTF) then begin
         Result := CopyVal(Arg^[0]);
         
         If(Arg^[1]^.Dic^.Count > 0) then begin
            DEA := Arg^[1]^.Dic^.ToArray();
            For C:=0 to (Arg^[1]^.Dic^.Count - 1) do
               If(DEA[C].Val^.Typ = VT_UTF)
                  then Result^.Utf^.Replace(DEA[C].Key, DEA[C].Val^.Utf)
                  else Result^.Utf^.Replace(DEA[C].Key, ValAsStr(DEA[C].Val))
         end
      end else begin
         
         (* arg0 is not a UTF-string. Obtain asciistring-cast to use as result value, *
          * and perform StringReplace on the PValue string.                           *)
         Result := ValToStr(Arg^[0]);
         
         If(Arg^[1]^.Dic^.Count > 0) then begin
            DEA := Arg^[1]^.Dic^.ToArray();
            For C:=0 to (Arg^[1]^.Dic^.Count - 1) do
               Result^.Str^ := StringReplace(Result^.Str^, DEA[C].Key, ValAsStr(DEA[C].Val), [rfReplaceAll])
         end
      end;
      F_(False, Arg) // Free args before leaving
   end;

Function F_MakeCharacter(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TChrFunc):PValue;
   Var C:LongWord;
   begin
      // No retval expected, bail out without doing anything
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return nilval
      If (Length(Arg^)=0) then Exit(NilVal());
      
      // Create empty string as result. For every arg provided, construct char and append to result.
      Result := EmptyVal(VT_STR);
      For C:=Low(Arg^) to High(Arg^) do begin
         Result^.Str^ += Func(ValAsInt(Arg^[C]));
         FreeIfTemp(Arg^[C])
      end
   end;

Function F_MakeOrdinal(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TOrdFunc):PValue;
   begin
      // No retval expected, bail out without doing anything
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return nilval
      If (Length(Arg^)=0) then Exit(NilVal());
      
      Result := NewVal(VT_INT, Func(ValAsStr(Arg^[0])));
      F_(False, Arg) // Return args before leaving
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
      // If no retval expected, don't do anything and bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args, return empty string
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
      
      // If arg0 is utfstring, make a copy and reverse the copy
      If (Arg^[0]^.Typ = VT_UTF) then begin
         Result := CopyVal(Arg^[0]);
         PUTF(Result^.Ptr)^.Reverse()
      end else
      // arg0 is not utfstring, make a typecast to asciistring, reverse that and create result
         Result := NewVal(VT_STR, ReverseString(ValAsStr(Arg^[0])));
      
      F_(False, Arg) // Free args before leaving
   end;

Function F_Perc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Flt:TFloat;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args provided, bail out early
      If (Length(Arg^)=0) then Exit(NewVal(VT_STR,'0%'));
      
      Result := EmptyVal(VT_STR);
      Case(Length(Arg^)) of
      
         1: begin // Only one argument, treat it as float in 0.0 - 1.0 = 0% - 100% range
            Result^.Str^ := Convert.IntToStr(Trunc(100*ValAsFlo(Arg^[0])))+'%'
         end;
         
         2: begin // Two arguments, express arg0 as percentage of arg1
            Flt := ValAsFlo(Arg^[0]); Flt := Flt * 100 / ValAsFlo(Arg^[1]);
            Result^.Str^ := Convert.IntToStr(Trunc(Flt))+'%';
         end;
         
         else begin // Three arguments (or more), express arg0 as percentage of (arg1, arg2) range
            Flt := ValAsFlo(Arg^[1]);
            Flt := (ValAsFlo(Arg^[0]) - Flt) * 100 / (ValAsFlo(Arg^[2]) - Flt);
            Result^.Str^ := Convert.IntToStr(Trunc(Flt))+'%';
         end
      end;
      F_(False, Arg) // Free args before you go
   end;

Function F_WriteStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Str,Tmp:TStr; C:LongWord;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Set result string and tempstring to empty and go through args
      Str := ''; Tmp := ''; 
      If (Length(Arg^) > 0) then
         For C:=Low(Arg^) to High(Arg^) do begin
            
            // Write appropriate string representation of value into temporary string
            Case Arg^[C]^.Typ of
               VT_NIL: WriteStr(Tmp, '{NIL}');
               VT_NEW: WriteStr(Tmp, '{NEW}');
               VT_PTR: WriteStr(Tmp, '{PTR}');
               VT_INT: WriteStr(Tmp, Arg^[C]^.Int^);
               VT_HEX: WriteStr(Tmp, Convert.HexToStr(Arg^[C]^.Int^));
               VT_OCT: WriteStr(Tmp, Convert.OctToStr(Arg^[C]^.Int^));
               VT_BIN: WriteStr(Tmp, Convert.BinToStr(Arg^[C]^.Int^));
               VT_FLO: WriteStr(Tmp, Convert.FloatToStr(Arg^[C]^.Flo^));
               VT_BOO: WriteStr(Tmp, Arg^[C]^.Boo^);
               VT_STR: WriteStr(Tmp, Arg^[C]^.Str^);
               VT_UTF: WriteStr(Tmp, Arg^[C]^.Utf^.ToAnsiString());
               VT_ARR: WriteStr(Tmp, 'array(',Arg^[C]^.Arr^.Count,')');
               VT_DIC: WriteStr(Tmp, 'dict(', Arg^[C]^.Dic^.Count,')');
               VT_FIL: WriteStr(Tmp, 'file(', Arg^[C]^.Fil^.Pth,  ')');
               else WriteStr(Tmp, '(',Arg^[C]^.Typ,')');
            end;
            
            // Free arg if needed and add temporary string to result string
            FreeIfTemp(Arg^[C]); Str += Tmp
         end;
      Exit(NewVal(VT_STR, Str))
   end;

Function F_WriteStr_UTF8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var U:PUTF;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      Result := F_WriteStr(True, Arg); // Use F_WriteStr to get the string
      New(U, Create(Result^.Str^));    // Create UTF8-string from AnsiString inside Result value
      Dispose(Result^.Str);            // Free the Result AnsiString
      
      // Inject UTF-8 string into Result
      Result^.Typ := VT_UTF; Result^.Ptr := U 
   end;

Function F_Explode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var FPCArray : StringUtils.AnsiStringArray; 
       Delim : AnsiString; C : LongWord; ValType : TValueType;
   begin
      // If no retval expected, do nothing and bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return empty array
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_ARR));
      
      // Create empty array to put results in
      Result := EmptyVal(VT_ARR);
      
      // Decide what to use as delimiter
      If (Length(Arg^) > 1)
         then Delim := ValAsStr(Arg^[1])
         else Delim := ',';
      
      // Decide what type the resulting strings should be
      If (Arg^[0]^.Typ = VT_UTF)
         then ValType := VT_UTF
         else ValType := VT_STR;
      
      // Get native array by exploding native string
      FPCArray := ExplodeString(ValAsStr(Arg^[0]), Delim);
      
      // Go through native array and hurl things into awful-array
      If (Length(FPCArray) > 0) then
         For C:=Low(FPCArray) to High(FPCArray) do
            Result^.Arr^.SetVal(C, NewVal(ValType, FPCArray[C]));
      
      F_(False, Arg) // Free args before leaving
   end;

Function F_Implode(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Str, Delim : AnsiString; C : LongWord;
       AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
   begin
      // No retval expected, leave without doing anything
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return empty string
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
      
      // Decide what to use as glue
      If (Length(Arg^) > 1)
         then Delim := ValAsStr(Arg^[1])
         else Delim := ',';
      
      // Check if arg0 is an array
      If (Arg^[0]^.Typ = VT_ARR) then begin
         
         // Check if non-empty
         If (Arg^[0]^.Arr^.Count > 0) then begin
            
            // Get all array entries and go through them to create result string
            AEA := Arg^[0]^.Arr^.ToArray();
            Str := ValAsStr(AEA[0].Val);
            For C:=1 to (Arg^[0]^.Arr^.Count - 1) do Str := Str + Delim + ValAsStr(AEA[C].Val)
         end else
            Str := '' // empty array = empty result string
      end else
      
      // Check if arg0 is a dictionary
      If (Arg^[0]^.Typ = VT_DIC) then begin
         
         // Check if non-empty
         If (Arg^[0]^.Dic^.Count > 0) then begin
            
            // Get all dictionary entries and go through them to create result string
            DEA := Arg^[0]^.Dic^.ToArray();
            Str := ValAsStr(DEA[0].Val);
            For C:=1 to (Arg^[0]^.Dic^.Count - 1) do Str := Str + Delim + ValAsStr(DEA[C].Val)
         end else
            Str := '' // empty dict = empty result string
      
      end else
         Str := ValAsStr(Arg^[0]); // arg0 is neither array or dict
      
      F_(False, Arg); // Free args before leaving
      Exit(NewVal(VT_STR, Str))
   end;

end.
