unit functions_arith;

{$INCLUDE defines.inc} 

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_Set(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Add(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Sub(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Mul(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Div(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Mod(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Pow(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Values_Arith;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('set',MkFunc(@F_Set,REF_MODIF));   FT^.SetVal('=',MkFunc(@F_Set,REF_MODIF));
   FT^.SetVal('add',MkFunc(@F_Add,REF_MODIF));   FT^.SetVal('+',MkFunc(@F_Add,REF_MODIF));
   FT^.SetVal('sub',MkFunc(@F_Sub,REF_MODIF));   FT^.SetVal('-',MkFunc(@F_Sub,REF_MODIF));
   FT^.SetVal('mul',MkFunc(@F_Mul,REF_MODIF));   FT^.SetVal('*',MkFunc(@F_Mul,REF_MODIF));
   FT^.SetVal('div',MkFunc(@F_Div,REF_MODIF));   FT^.SetVal('/',MkFunc(@F_Div,REF_MODIF));
   FT^.SetVal('mod',MkFunc(@F_Mod,REF_MODIF));   FT^.SetVal('%',MkFunc(@F_Mod,REF_MODIF));
   FT^.SetVal('pow',MkFunc(@F_Pow,REF_MODIF));   FT^.SetVal('^',MkFunc(@F_Pow,REF_MODIF))
   end;

Type TArithProc = Procedure(Const A,B:PValue);

Function F_Arith(Arith:TArithProc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; Inline;
   Var C:LongWord; 
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do begin
          Arith(Arg^[C-1],Arg^[C]);
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then begin
      If (Arg^[0]^.Lev >= CurLev)
         then Exit(Arg^[0])
         else Exit(CopyVal(Arg^[0]))
      end else begin 
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(NIL)
      end
   end;

Function F_Set(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValSet, DoReturn, Arg)) end;

Function F_Add(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValAdd, DoReturn, Arg)) end;

Function F_Sub(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValSub, DoReturn, Arg)) end;

Function F_Mul(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValMul, DoReturn, Arg)) end;

Function F_Div(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValDiv, DoReturn, Arg)) end;

Function F_Mod(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValMod, DoReturn, Arg)) end;

Function F_Pow(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValPow, DoReturn, Arg)) end;

end.
