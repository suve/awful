unit functions_arith;

{$INCLUDE defines.inc} 

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_Set(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Add(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Sub(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Mul(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Div(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Mod(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Pow(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Values_Arith;

Procedure Register(Const FT:PFunTrie);
   begin
      FT^.SetVal('set',MkFunc(@F_Set,REF_MODIF));   FT^.SetVal('=',MkFunc(@F_Set,REF_MODIF));
      FT^.SetVal('add',MkFunc(@F_Add,REF_MODIF));   FT^.SetVal('+',MkFunc(@F_Add,REF_MODIF));
      FT^.SetVal('sub',MkFunc(@F_Sub,REF_MODIF));   FT^.SetVal('-',MkFunc(@F_Sub,REF_MODIF));
      FT^.SetVal('mul',MkFunc(@F_Mul,REF_MODIF));   FT^.SetVal('*',MkFunc(@F_Mul,REF_MODIF));
      FT^.SetVal('div',MkFunc(@F_Div,REF_MODIF));   FT^.SetVal('/',MkFunc(@F_Div,REF_MODIF));
      FT^.SetVal('mod',MkFunc(@F_Mod,REF_MODIF));   FT^.SetVal('%',MkFunc(@F_Mod,REF_MODIF));
      FT^.SetVal('pow',MkFunc(@F_Pow,REF_MODIF));   FT^.SetVal('^',MkFunc(@F_Pow,REF_MODIF))
   end;

// Pointer to arithmetic procedure
Type TArithProc = Procedure(Const A,B:PValue);

Function F_Arith(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Arith:TArithProc):PValue; 
   Var C:LongWord; 
   begin
      // If no args, return NIL (or nothing, if not DoReturn)
      If (Length(Arg^)=0) then begin
         If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
       
      (* If more than one arg provided, go through args pairs      *
       * starting from the rightmost, to the leftmost.             *
       *                                                           *
       * Perform arith on arg pair, then free right arg if needed. *)
      If (Length(Arg^)>1) then
         For C:=High(Arg^) downto 1 do begin
            Arith(Arg^[C-1],Arg^[C]);
            FreeIfTemp(Arg^[C])
         end;
      
      // Check if we should return value
      If (DoReturn) then begin
         
         // Check if leftmost arg was a temporary value.
         If (IsTempVal(Arg^[0]))
            then Exit(Arg^[0])          // If yes, reuse it.
            else Exit(CopyVal(Arg^[0])) // Otherwise, return a temporary copy.
         
      end else begin 
         
         // Not returning a value. Free leftmost arg if needed and leave
         FreeIfTemp(Arg^[0]);
         Exit(NIL)
      end
   end;

Function F_Set(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(DoReturn, Arg, @ValSet)) end;

Function F_Add(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(DoReturn, Arg, @ValAdd)) end;

Function F_Sub(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(DoReturn, Arg, @ValSub)) end;

Function F_Mul(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(DoReturn, Arg, @ValMul)) end;

Function F_Div(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(DoReturn, Arg, @ValDiv)) end;

Function F_Mod(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(DoReturn, Arg, @ValMod)) end;

Function F_Pow(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Arith(DoReturn, Arg, @ValPow)) end;

end.
