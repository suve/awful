unit functions_arith;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_Set(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Add(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Sub(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Mul(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Div(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Mod(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Pow(DoReturn:Boolean; Arg:Array of PValue):PValue;


implementation

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

Type TArithFunc = Function(A,B:PValue):PValue;

Function F_Arith(Arith:TArithFunc; DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=Arith(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (DoReturn) then begin
      If (Arg[0]^.Lev >= CurLev)
         then Exit(Arg[0])
         else Exit(CopyVal(Arg[0]))
      end else begin 
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NIL)
      end
   end;

Function F_Set(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_Arith(@ValSet, DoReturn, Arg)) end;

Function F_Add(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_Arith(@ValAdd, DoReturn, Arg)) end;

Function F_Sub(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_Arith(@ValSub, DoReturn, Arg)) end;

Function F_Mul(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_Arith(@ValMul, DoReturn, Arg)) end;

Function F_Div(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_Arith(@ValDiv, DoReturn, Arg)) end;

Function F_Mod(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_Arith(@ValMod, DoReturn, Arg)) end;

Function F_Pow(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_Arith(@ValPow, DoReturn, Arg)) end;

end.
