unit functions_arith;

{$INCLUDE defines.inc} {$INLINE ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_Set(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Add(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Sub(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Mul(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Div(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Mod(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Pow(DoReturn:Boolean; Arg:PArrPVal):PValue;


implementation
   uses Values_Arith;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('set',@F_Set);   FT^.SetVal('=',@F_Set);
   FT^.SetVal('add',@F_Add);   FT^.SetVal('+',@F_Add);
   FT^.SetVal('sub',@F_Sub);   FT^.SetVal('-',@F_Sub);
   FT^.SetVal('mul',@F_Mul);   FT^.SetVal('*',@F_Mul);
   FT^.SetVal('div',@F_Div);   FT^.SetVal('/',@F_Div);
   FT^.SetVal('mod',@F_Mod);   FT^.SetVal('%',@F_Mod);
   FT^.SetVal('pow',@F_Pow);   FT^.SetVal('^',@F_Pow);
   end;

Type TArithProc = Procedure(A,B:PValue);

Function F_Arith(Arith:TArithProc; DoReturn:Boolean; Arg:PArrPVal):PValue; Inline;
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

Function F_Set(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValSet, DoReturn, Arg)) end;

Function F_Add(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValAdd, DoReturn, Arg)) end;

Function F_Sub(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValSub, DoReturn, Arg)) end;

Function F_Mul(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValMul, DoReturn, Arg)) end;

Function F_Div(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValDiv, DoReturn, Arg)) end;

Function F_Mod(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValMod, DoReturn, Arg)) end;

Function F_Pow(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Arith(@ValPow, DoReturn, Arg)) end;

end.
