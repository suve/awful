unit functions_compare;

{$INCLUDE defines.inc} 

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_Eq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Seq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Neq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SNeq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Gt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Ge(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Lt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Le(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Values_Compare, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
   // Comparisons
   FT^.SetVal('eq',MkFunc(@F_Eq));     FT^.SetVal('==',MkFunc(@F_Eq));
   FT^.SetVal('neq',MkFunc(@F_NEq));   FT^.SetVal('!=',MkFunc(@F_NEq));   FT^.SetVal('<>',MkFunc(@F_NEq));
   FT^.SetVal('seq',MkFunc(@F_SEq));   FT^.SetVal('===',MkFunc(@F_SEq));  
   FT^.SetVal('sneq',MkFunc(@F_SNEq)); FT^.SetVal('!==',MkFunc(@F_SNEq)); 
   FT^.SetVal('gt',MkFunc(@F_gt));     FT^.SetVal('>',MkFunc(@F_Gt));
   FT^.SetVal('ge',MkFunc(@F_ge));     FT^.SetVal('>=',MkFunc(@F_Ge));
   FT^.SetVal('lt',MkFunc(@F_lt));     FT^.SetVal('<',MkFunc(@F_Lt));
   FT^.SetVal('le',MkFunc(@F_le));     FT^.SetVal('<=',MkFunc(@F_Le));
   end;

Type TCompareFunc = Function(Const A,B:PValue):Boolean;

Function F_Compare(Const DoReturn:Boolean; Const Arg:PArrPVal; Const CompareFunc:TCompareFunc):PValue; Inline;
   Var C, F :LongWord; R:Boolean;
   begin R:=True;
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      If ((Length(Arg^) = 1) and (Arg^[0]^.Lev >= CurLev)) then FreeVal(Arg^[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   F := High(Arg^);
   For C:=(High(Arg^)-1) downto Low(Arg^) do begin
       R:=CompareFunc(Arg^[C],Arg^[F]);
       If (Arg^[F]^.Lev >= CurLev) then FreeVal(Arg^[F]); F -= 1;
       If (Not R) then Break
       end;
   For C:=F downto 0 do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_Eq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValEq)) end;

Function F_Neq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValNeq)) end;

Function F_SEq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValSeq)) end;

Function F_SNEq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValSneq)) end;

Function F_Gt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValGt)) end;

Function F_Ge(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValGe)) end;

Function F_Lt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValLt)) end;

Function F_Le(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Compare(DoReturn, Arg, @ValLe)) end;

end.
