unit functions_typecast;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_is_nil(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_bool(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_is_int(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_hex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_oct(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_bin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_zahl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_is_float(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_number(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_is_ascii(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_utf8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_string(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_is_arr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_is_file(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_mkint(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkhex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkoct(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkbin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkflo(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mklog(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkstr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkutf(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Values_Typecast, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
      // Typecheck
      FT^.SetVal('is-nil'  ,MkFunc(@F_is_nil   ));
      FT^.SetVal('is-log'  ,MkFunc(@F_is_bool  ));   FT^.SetVal('is-bool'  ,MkFunc(@F_is_bool  ));
      FT^.SetVal('is-int'  ,MkFunc(@F_is_int   ));
      FT^.SetVal('is-hex'  ,MkFunc(@F_is_hex   ));
      FT^.SetVal('is-oct'  ,MkFunc(@F_is_oct   ));
      FT^.SetVal('is-bin'  ,MkFunc(@F_is_bin   ));
      FT^.SetVal('is-flo'  ,MkFunc(@F_is_float ));   FT^.SetVal('is-float' ,MkFunc(@F_is_float ));
      FT^.SetVal('is-zahl' ,MkFunc(@F_is_zahl  ));   FT^.SetVal('is-number',MkFunc(@F_is_number));
      FT^.SetVal('is-ascii',MkFunc(@F_is_ascii ));
      FT^.SetVal('is-utf'  ,MkFunc(@F_is_utf8  ));   FT^.SetVal('is-utf8'  ,MkFunc(@F_is_utf8  ));
      FT^.SetVal('is-str'  ,MkFunc(@F_is_string));   FT^.SetVal('is-string',MkFunc(@F_is_string));
      FT^.SetVal('is-arr'  ,MkFunc(@F_is_arr   ));
      FT^.SetVal('is-dict' ,MkFunc(@F_is_dict  ));
      FT^.SetVal('is-file' ,MkFunc(@F_is_file  ));
      // Typecast
      FT^.SetVal('mkint',MkFunc(@F_mkint,REF_MODIF));
      FT^.SetVal('mkhex',MkFunc(@F_mkhex,REF_MODIF));
      FT^.SetVal('mkoct',MkFunc(@F_mkoct,REF_MODIF));
      FT^.SetVal('mkbin',MkFunc(@F_mkbin,REF_MODIF));
      FT^.SetVal('mkflo',MkFunc(@F_mkflo,REF_MODIF)); FT^.SetVal('mkfloat' ,MkFunc(@F_mkflo,REF_MODIF));
      FT^.SetVal('mklog',MkFunc(@F_mklog,REF_MODIF)); FT^.SetVal('mkbool'  ,MkFunc(@F_mklog,REF_MODIF));
      FT^.SetVal('mkstr',MkFunc(@F_mkstr,REF_MODIF)); FT^.SetVal('mkstring',MkFunc(@F_mkstr,REF_MODIF));
      FT^.SetVal('mkutf',MkFunc(@F_mkutf,REF_MODIF)); FT^.SetVal('mkutf8'  ,MkFunc(@F_mkutf,REF_MODIF));
   end;

Type TTypecastFunc = Function(Const V:PValue):PValue;

Function F_Typecast(Const DoReturn:Boolean;   Const Arg:PArrPVal;
                    Const ValType:TValueType; Const Typecast:TTypecastFunc
                   ):PValue;
   
   Var C:LongWord; V:PValue;
   begin
      // If no args provided, return empty val of desired type
      If (Length(Arg^)=0) then begin
         If (DoReturn) then Exit(EmptyVal(ValType)) else Exit(NIL) end;
      
      // Go through args. If level >= CurLev, it's a temporary arg - free it right away.
      // Otherwise, get a typecast value and swap the internal pointers. Free temp var.
      For C:=High(Arg^) downto (Low(Arg^)+1) do
         If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
         If (Arg^[C]^.Typ <> ValType) then begin
            V:=Typecast(Arg^[C]); 
            SwapPtrs(Arg^[C],V); FreeVal(V)
         end;
      
      // If arg0 leve >= CurLev, it's a temporary var - try to reuse it
      If (Arg^[0]^.Lev >= CurLev) then begin
      
         // No retval expected, free arg0 and gtfo
         If (Not DoReturn) then begin
            FreeVal(Arg^[0]); Exit(NIL);
         end;
         
         // If arg0 needs to be typecast, create return value by casting and free arg0.
         // Otherwise, just reuse it.
         If (Arg^[0]^.Typ <> ValType) then begin
            Result := Typecast(Arg^[0]); FreeVal(Arg^[0])
         end else Result := Arg^[0];
         
      end else begin
      // arg0 is not temporary. Perform typecast if needed
         If (Arg^[0]^.Typ <> ValType) then begin
            V:=Typecast(Arg^[0]); 
            SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
         
         // Return copy of arg0, or nothing
         If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

Function F_mkint(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_INT, @ValToInt)) end;

Function F_mkhex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_HEX, @ValToHex)) end;

Function F_mkoct(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_OCT, @ValToOct)) end;

Function F_mkbin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_BIN, @ValToBin)) end;

Function F_mkflo(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_FLO, @ValToFlo)) end;

Function F_mklog(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_BOO, @ValToBoo)) end;

Function F_mkstr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_STR, @ValToStr)) end;

Function F_mkutf(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Typecast(DoReturn, Arg, VT_UTF, @ValToUTF)) end;

Type
   TValueTypeSet = Set of TValueType;

Function F_isType(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Tp:TValueTypeSet):PValue;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      If (Length(Arg^) > 0) then begin
         Result := NewVal(VT_BOO, (Arg^[0]^.Typ in Tp));
         F_(False, Arg)
      end else
         Result := NewVal(VT_BOO, False)
   end;

Function F_is_nil(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_NIL])) end;

Function F_is_bool(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_LOG])) end;

Function F_is_int(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_INT])) end;

Function F_is_hex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_HEX])) end;

Function F_is_oct(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_OCT])) end;

Function F_is_bin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_BIN])) end;

Function F_is_zahl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_INT, VT_BIN, VT_OCT, VT_HEX])) end;

Function F_is_float(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_FLO])) end;

Function F_is_number(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_INT, VT_BIN, VT_OCT, VT_HEX, VT_FLO])) end;

Function F_is_ascii(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_STR])) end;

Function F_is_utf8(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_UTF])) end;

Function F_is_string(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_STR, VT_UTF])) end;

Function F_is_arr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_ARR])) end;

Function F_is_dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_DIC])) end;

Function F_is_file(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_isType(DoReturn, Arg, [VT_FIL])) end;

end.
