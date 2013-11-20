unit functions_boole;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_Not(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_And(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Or(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Xor(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Impl(DoReturn:Boolean; Arg:Array of PValue):PValue;


implementation

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('not',@F_not);    FT^.SetVal('!',@F_Not);
   FT^.SetVal('and',@F_and);    FT^.SetVal('&&',@F_and);
   FT^.SetVal('xor',@F_xor);    FT^.SetVal('^^',@F_xor);
   FT^.SetVal('or' ,@F_or);     FT^.SetVal('||',@F_or);
   FT^.SetVal('impl',@F_impl);  FT^.SetVal('->',@F_impl);
   end;

Function F_Not(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, True)) else Exit(NIL) end;
   If (Length(Arg)>1) then 
       For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_BOO) then B:=PBool(Arg[0]^.Ptr)^
      else begin
      V:=ValToBoo(Arg[0]); B:=PBool(V^.Ptr)^; FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO,Not B)) else Exit(NIL)
   end;

Function F_And(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=True;
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg)>=1) then 
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B and (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B and (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Xor(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=False;
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg)>=1) then 
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B xor (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B xor (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Or(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=False;
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg)>=1) then 
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B or (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B or (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Impl(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; p,q:Boolean; V:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg)>=1) then 
      C := High(Arg);
      If (Arg[C]^.Typ = VT_BOO) then p:=(PBool(Arg[C]^.Ptr)^)
          else begin
          V:=ValToBoo(Arg[C]); p:=(PBool(Arg[C]^.Ptr)^); FreeVal(V)
          end;
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
      For C:=High(Arg)-1 downto Low(Arg) do begin
          q := p;
          If (Arg[C]^.Typ = VT_BOO) then p:=(PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); p:=(PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          p := (not p) or q;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,p)) else Exit(NilVal)
   end;

end.
