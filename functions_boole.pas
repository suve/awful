unit functions_boole;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Impl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('not',@F_not);    FT^.SetVal('!',@F_Not);
   FT^.SetVal('and',@F_and);    FT^.SetVal('&&',@F_and);
   FT^.SetVal('xor',@F_xor);    FT^.SetVal('^^',@F_xor);
   FT^.SetVal('or' ,@F_or);     FT^.SetVal('??',@F_or);
   FT^.SetVal('impl',@F_impl);  FT^.SetVal('->',@F_impl);
   end;

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; B:Boolean;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, True)) else Exit(NIL) end;
   If (Length(Arg^)>1) then 
       For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_BOO)
      then B:=PBool(Arg^[0]^.Ptr)^
      else B:=ValAsBoo(Arg^[0]);
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO,Not B)) else Exit(NIL)
   end;

Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; B:Boolean;
   begin B:=True;
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg^)>=1) then 
      For C:=High(Arg^) downto Low(Arg^) do begin
          If (Arg^[C]^.Typ = VT_BOO)
             then B:=(B) and (PBool(Arg^[C]^.Ptr)^)
             else B:=(B) and (ValAsBoo(Arg^[C]));
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; B:Boolean;
   begin B:=False;
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg^)>=1) then 
      For C:=High(Arg^) downto Low(Arg^) do begin
          If (Arg^[C]^.Typ = VT_BOO)
             then B:=(B) xor (PBool(Arg^[C]^.Ptr)^)
             else B:=(B) xor (ValAsBoo(Arg^[C]));
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; B:Boolean;
   begin B:=False;
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg^)>=1) then 
      For C:=High(Arg^) downto Low(Arg^) do begin
          If (Arg^[C]^.Typ = VT_BOO)
             then B:=(B) or (PBool(Arg^[C]^.Ptr)^)
             else B:=(B) or (ValAsBoo(Arg^[C]));
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Impl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; p,q:Boolean;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg^)>=1) then 
      C := High(Arg^);
      If (Arg^[C]^.Typ = VT_BOO)
          then p:=(PBool(Arg^[C]^.Ptr)^)
          else p:=ValAsBoo(Arg^[C]);
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
      For C:=High(Arg^)-1 downto Low(Arg^) do begin
          q := p;
          If (Arg^[C]^.Typ = VT_BOO)
             then p:=(PBool(Arg^[C]^.Ptr)^)
             else p:=(ValAsBoo(Arg^[C]));
          p := (not p) or q;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,p)) else Exit(NilVal)
   end;

end.
