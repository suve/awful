unit functions_typecast;

{$INCLUDE defines.inc}

interface
   uses Values;

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
   FT^.SetVal('mkflo',MkFunc(@F_mkflo,REF_MODIF)); FT^.SetVal('mkfloat',MkFunc(@F_mkflo,REF_MODIF));
   FT^.SetVal('mklog',MkFunc(@F_mklog,REF_MODIF)); FT^.SetVal('mkbool',MkFunc(@F_mklog,REF_MODIF));
   FT^.SetVal('mkstr',MkFunc(@F_mkstr,REF_MODIF)); FT^.SetVal('mkstring',MkFunc(@F_mkstr,REF_MODIF));
   FT^.SetVal('mkutf',MkFunc(@F_mkutf,REF_MODIF)); FT^.SetVal('mkutf8',MkFunc(@F_mkutf,REF_MODIF));
   end;

Type TTypecastFunc = Function(Const V:PValue):PValue;

Function F_Typecast(Const DoReturn:Boolean;   Const Arg:PArrPVal;
                    Const ValType:TValueType; Const Typecast:TTypecastFunc
                   ):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(ValType)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> ValType) then begin
          V:=Typecast(Arg^[C]); 
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> ValType) then begin
         V:=Typecast(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>ValType) then begin
         V:=Typecast(Arg^[0]); 
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
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
