unit emptyfunc;

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_(DoReturn:Boolean; Arg:PArrPVal):PValue;

implementation

Procedure Register(FT:PFunTrie);
   begin
   //FT^.SetVal('', @F_);
   FT^.SetVal('nil', @F_)
   end;

Function F_(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^) > 0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NilVal) else Exit(NIL)
   end;

end.
