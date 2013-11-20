unit functions_bitwise;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_Not(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_And(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Xor(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Or(DoReturn:Boolean; Arg:Array of PValue):PValue;


implementation
   uses EmptyFunc;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('bwnot',@F_not);    FT^.SetVal('b!',@F_Not);
   FT^.SetVal('bwand',@F_and);    FT^.SetVal('b&',@F_and);
   FT^.SetVal('bwxor',@F_xor);    FT^.SetVal('b^',@F_xor);
   FT^.SetVal('bwor' ,@F_or);     FT^.SetVal('b|',@F_or);
   end;

Function F_Not(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal) else Exit(NIL) end;
   If (Length(Arg)>1) then 
       For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then begin
      V:=ValNot(Arg[0]);
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(V)
      end else begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NIL)
      end
   end;

Function F_And(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Not DoReturn) or (Length(Arg)<2)
      then Exit(F_(DoReturn, Arg));
   For C:=High(Arg) downto 1 do begin
       V:=ValAnd(Arg[C-1], Arg[C]);
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
       Arg[C] := V
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(V)
   end;

Function F_Xor(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Not DoReturn) or (Length(Arg)<2)
      then Exit(F_(DoReturn, Arg));
   For C:=High(Arg) downto 1 do begin
       V:=ValXor(Arg[C-1], Arg[C]);
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
       Arg[C] := V
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(V)
   end;

Function F_Or(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Not DoReturn) or (Length(Arg)<2)
      then Exit(F_(DoReturn, Arg));
   For C:=High(Arg) downto 1 do begin
       V:=ValOr(Arg[C-1], Arg[C]);
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
       Arg[C] := V
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(V)
   end;

end.
