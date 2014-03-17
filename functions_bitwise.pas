unit functions_bitwise;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Values_Bitwise, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('bwnot',MkFunc(@F_not));    FT^.SetVal('b!',MkFunc(@F_Not));
   FT^.SetVal('bwand',MkFunc(@F_and));    FT^.SetVal('b&',MkFunc(@F_and));
   FT^.SetVal('bwxor',MkFunc(@F_xor));    FT^.SetVal('b^',MkFunc(@F_xor));
   FT^.SetVal('bwor' ,MkFunc(@F_or));     FT^.SetVal('b?',MkFunc(@F_or));
   end;

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
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

Type TBitwiseFunc = Function(Const A,B:PValue):PValue;

Function F_Bitwise(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Bitwise:TBitwiseFunc):PValue;
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

Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValAnd)) end;

Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValXor)) end;

Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Bitwise(DoReturn, Arg, @ValOr)) end;

end.
