unit functions_compare;

{$MODE OBJFPC} {$COPERATORS ON} {$INLINE ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_Eq(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Seq(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Neq(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_SNeq(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Gt(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Ge(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Lt(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Le(DoReturn:Boolean; Arg:PArrPVal):PValue;


implementation
   uses Values_Compare, EmptyFunc;

Procedure Register(FT:PFunTrie);
   begin
   // Comparisons
   FT^.SetVal('eq',@F_Eq);     FT^.SetVal('==',@F_Eq);
   FT^.SetVal('neq',@F_NEq);   FT^.SetVal('!=',@F_NEq);   FT^.SetVal('<>',@F_NEq);
   FT^.SetVal('seq',@F_SEq);   FT^.SetVal('===',@F_SEq);  
   FT^.SetVal('sneq',@F_SNEq); FT^.SetVal('!==',@F_SNEq); 
   FT^.SetVal('gt',@F_gt);     FT^.SetVal('>',@F_Gt);
   FT^.SetVal('ge',@F_ge);     FT^.SetVal('>=',@F_Ge);
   FT^.SetVal('lt',@F_lt);     FT^.SetVal('<',@F_Lt);
   FT^.SetVal('le',@F_le);     FT^.SetVal('<=',@F_Le);
   end;

Type TCompareFunc = Function(A,B:PValue):Boolean;

Function F_Compare(CompareVals:TCompareFunc; DoReturn:Boolean; Arg:PArrPVal):PValue; Inline;
   Var C, F :LongWord; R:Boolean;
   begin R:=True;
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      If ((Length(Arg^) = 1) and (Arg^[0]^.Lev >= CurLev)) then FreeVal(Arg^[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   F := High(Arg^);
   For C:=(High(Arg^)-1) downto Low(Arg^) do begin
       R:=CompareVals(Arg^[C],Arg^[F]);
       If (Arg^[F]^.Lev >= CurLev) then FreeVal(Arg^[F]); F -= 1;
       If (Not R) then Break
       end;
   For C:=F downto 0 do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_Eq(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValEq, DoReturn, Arg)) end;

Function F_Neq(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValNeq, DoReturn, Arg)) end;

Function F_SEq(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValSeq, DoReturn, Arg)) end;

Function F_SNEq(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValSneq, DoReturn, Arg)) end;

Function F_Gt(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValGt, DoReturn, Arg)) end;

Function F_Ge(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValGe, DoReturn, Arg)) end;

Function F_Lt(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValLt, DoReturn, Arg)) end;

Function F_Le(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Compare(@ValLe, DoReturn, Arg)) end;

end.
