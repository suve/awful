unit functions_bitwise;

{$INCLUDE defines.inc} {$INLINE ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_Not(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_And(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Xor(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Or(DoReturn:Boolean; Arg:PArrPVal):PValue;


implementation
   uses Values_Bitwise, EmptyFunc;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('bwnot',@F_not);    FT^.SetVal('b!',@F_Not);
   FT^.SetVal('bwand',@F_and);    FT^.SetVal('b&',@F_and);
   FT^.SetVal('bwxor',@F_xor);    FT^.SetVal('b^',@F_xor);
   FT^.SetVal('bwor' ,@F_or);     FT^.SetVal('b?',@F_or);
   end;

Function F_Not(DoReturn:Boolean; Arg:PArrPVal):PValue;
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

Type TBitwiseFunc = Function(A,B:PValue):PValue;

Function F_Bitwise(Bitwise:TBitwiseFunc; DoReturn:Boolean; Arg:PArrPVal):PValue; Inline;
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

Function F_And(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(@ValAnd, DoReturn, Arg)) end;

Function F_Xor(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(@ValXor, DoReturn, Arg)) end;

Function F_Or(DoReturn:Boolean; Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(@ValOr, DoReturn, Arg)) end;

end.
