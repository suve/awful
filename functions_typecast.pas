unit functions_typecast;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_mkint(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkhex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkoct(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkbin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkflo(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mklog(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkstr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkutf(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses Values_Typecast;

Procedure Register(Const FT:PFunTrie);
   begin
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

end.
