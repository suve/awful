unit emptyfunc;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation

Procedure Register(Const FT:PFunTrie);
   begin
   //FT^.SetVal('', @F_);
   FT^.SetVal('nil', MkFunc(@F_))
   end;

Function F_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^) > 0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NilVal) else Exit(NIL)
   end;

end.
