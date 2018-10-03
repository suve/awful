unit functions_boole;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Impl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses EmptyFunc, Values_Typecast;

Procedure Register(Const FT:PFunTrie);
   begin
      FT^.SetVal('not',MkFunc(@F_not));    FT^.SetVal('!',MkFunc(@F_Not));
      FT^.SetVal('and',MkFunc(@F_and));    FT^.SetVal('&&',MkFunc(@F_and));
      FT^.SetVal('xor',MkFunc(@F_xor));    FT^.SetVal('^^',MkFunc(@F_xor));
      FT^.SetVal('or' ,MkFunc(@F_or));     FT^.SetVal('??',MkFunc(@F_or));
      FT^.SetVal('impl',MkFunc(@F_impl));  FT^.SetVal('->',MkFunc(@F_impl));
   end;

Function F_Not(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
      // If no retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If no args, return TRUE
      If (Length(Arg^) = 0) then Exit(NewVal(VT_BOO, True));
      
      // Free all the excessive args
      If (Length(Arg^)>1) then 
          For C:=High(Arg^) downto 1 do
             FreeIfTemp(Arg^[C]);
      
      // Create result value
      If (Arg^[0]^.Typ = VT_BOO)
         then Result := NewVal(VT_BOO, Not Arg^[0]^.Boo^)
         else Result := NewVal(VT_BOO, Not ValAsBoo(Arg^[0]));
      
      // Free arg0 if needed
      FreeIfTemp(Arg^[0])
   end;

Type TBooleanFunc = Function(Const A,B:Boolean):Boolean;

Function AND_func(Const A,B:Boolean):Boolean; Inline; begin Result:=A and B end;
Function XOR_func(Const A,B:Boolean):Boolean; Inline; begin Result:=A xor B end;
Function OR_func(Const A,B:Boolean):Boolean; Inline; begin Result:=A or B end;

Function F_Boolean(Const DoReturn:Boolean; Const Arg:PArrPVal; Const BoolFunc:TBooleanFunc; Const Initial:Boolean):PValue;
   Var C:LongWord;
   begin 
      // If no retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If no args, return FALSE 
      If (Length(Arg^) = 0) then Exit(NewVal(VT_BOO, False));
      
      Result := NewVal(VT_BOO, Initial); // Set initial result
      If (Length(Arg^) >= 1) then 
         For C:=High(Arg^) downto Low(Arg^) do begin
            
            // Perform boolean opeartion on argument and temporary value
            If (Arg^[C]^.Typ = VT_BOO)
               then Result^.Boo^ := BoolFunc(Result^.Boo^, PBool(Arg^[C]^.Ptr)^)
               else Result^.Boo^ := BoolFunc(Result^.Boo^, ValAsBoo(Arg^[C]));
            
            // Free arg if needed
            FreeIfTemp(Arg^[C])
         end;
   end;

Function F_And(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Boolean(DoReturn, Arg, @AND_func, True)) end;

Function F_Xor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Boolean(DoReturn, Arg, @XOR_func, False)) end;

Function F_Or(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Boolean(DoReturn, Arg, @OR_func, False)) end;

// Logical implication. Why did I even implement this?
Function F_Impl(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; p,q:Boolean;
   begin
      // If no retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If no args, return FALSE 
      If (Length(Arg^) = 0) then Exit(NewVal(VT_BOO, False));
      
      // Assign boolcast of rightmost arg to p
      C := High(Arg^);
      If (Arg^[C]^.Typ = VT_BOO)
         then p:=Arg^[C]^.Boo^
         else p:=ValAsBoo(Arg^[C]);
      
      // Free arg if needed
      FreeIfTemp(Arg^[C]);
      
      // Go through rest of args and perform implications on the way
      For C:=High(Arg^)-1 downto Low(Arg^) do begin
         q := p;
         If (Arg^[C]^.Typ = VT_BOO)
            then p:=Arg^[C]^.Boo^
            else p:=ValAsBoo(Arg^[C]);
         p := (not p) or q;
         FreeIfTemp(Arg^[C])
      end;
      
      // Return value
      Exit(NewVal(VT_BOO,p))
   end;

end.
