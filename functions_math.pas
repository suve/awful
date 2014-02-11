unit functions_math;

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_abs(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_sgn(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_ceil(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_floor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_round(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_trunc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_frac(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_cos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_sin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_tan(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_ctg(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_sqrt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_log(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_gcd(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_lcm(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_newt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_hypotenuse(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses EmptyFunc, Math;

Procedure Register(Const FT:PFunTrie);
   begin
   // Trigonometry
   FT^.SetVal('cos', @F_cos);
   FT^.SetVal('sin', @F_sin);
   FT^.SetVal('tan', @F_tan);
   FT^.SetVal('ctg', @F_ctg);
   // Positive-negative
   FT^.SetVal('abs', @F_abs);
   FT^.SetVal('sgn', @F_sgn);
   // Rounding
   FT^.SetVal('ceil', @F_ceil);
   FT^.SetVal('floor', @F_floor);
   FT^.SetVal('round', @F_round);
   FT^.SetVal('trunc', @F_trunc);
   FT^.SetVal('frac', @F_frac);
   // Built-in calc
   FT^.SetVal('sqrt', @F_Sqrt);
   FT^.SetVal('log', @F_Log);
   // Own algo calc
   FT^.SetVal('gcd', @F_gcd);
   FT^.SetVal('lcm', @F_lcm);
   FT^.SetVal('newt', @F_newt);
   FT^.SetVal('hypotenuse', @F_hypotenuse)
   end;

Type TFloatToFloatFunc = Function(V:TFloat):TFloat;
     TFloatToIntFunc = Function(V:TFloat):QInt;
     TIntIntToIntFunc = Function(A,B:QInt):QInt;

Function myCos(V:TFloat):TFloat; begin Exit(Cos(V)) end;
Function mySin(V:TFloat):TFloat; begin Exit(Sin(V)) end;
Function myTan(V:TFloat):TFloat; begin Exit(Tan(V)) end;
Function myCtg(V:TFloat):TFloat; begin Exit(Cot(V)) end;

Function myCeil(V:TFloat):QInt; begin Exit(Ceil(V)) end;
Function myFloor(V:TFloat):QInt; begin Exit(Floor(V)) end;
Function myRound(V:TFloat):QInt; begin Exit(Round(V)) end;
Function myTrunc(V:TFloat):QInt; begin Exit(Trunc(V)) end;

Function F_sqrt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; F:TFLoat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_FLO,0.0));
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO) then begin
      F:=Sqrt(PFloat(Arg^[0]^.Ptr)^)
      end else
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then F:=Sqrt(PQInt(Arg^[0]^.Ptr)^)
      else F:=Sqrt(ValAsFlo(Arg^[0]));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_FLO,F))
   end;

Function F_log(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; Base,Number:TFloat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(NilVal);
   If (Length(Arg^) = 1) then begin
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then
         Number:=Ln(PQInt(Arg^[0]^.Ptr)^) else
      If (Arg^[0]^.Typ = VT_FLO)
         then Number:=Ln(PFloat(Arg^[0]^.Ptr)^)
         else Number:=Ln(ValAsFlo(Arg^[0]));
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(NewVal(VT_FLO, Number))
      end;
      
   For C:=2 to High(Arg^) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   
   For C:=0 to 1 do begin
       Base := Number;
       If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN) then
          Number:=PQInt(Arg^[C]^.Ptr)^ else
       If (Arg^[C]^.Typ = VT_FLO)
          then Number:=PFloat(Arg^[C]^.Ptr)^
          else Number:=ValAsFlo(Arg^[C]);
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
       end;
   
   Exit(NewVal(VT_FLO, LogN(Base, Number)))
   end;

Function F_abs(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_INT));
   If (Length(Arg^)>1) then
      For C:=1 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then R:=NewVal(Arg^[0]^.Typ, Abs(PQInt(Arg^[0]^.Ptr)^)) else
   If (Arg^[0]^.Typ = VT_FLO)
      then R:=NewVal(Arg^[0]^.Typ, Abs(PFloat(Arg^[0]^.Ptr)^)) else
      {else} begin
      R:=ValToFlo(Arg^[0]); PFloat(R^.Ptr)^ := Abs(PFloat(R^.Ptr)^)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(R)   
   end;

Function F_sgn(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_INT));
   If (Length(Arg^)>1) then
      For C:=1 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then R:=NewVal(Arg^[0]^.Typ, LongInt(Sign(PQInt(Arg^[0]^.Ptr)^))) else
   If (Arg^[0]^.Typ = VT_FLO)
      then R:=NewVal(VT_INT, LongInt(Sign(PFloat(Arg^[0]^.Ptr)^)))
      else R:=NewVal(VT_INT, LongInt(Sign(ValAsInt(Arg^[0]))));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(R)   
   end;

Function F_trigonometric(Func:TFloatToFloatFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; Inline;
   Var C:LongWord; R:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_FLO));
   If (Length(Arg^)>1) then
      For C:=1 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then R:=NewVal(VT_FLO, Func(PQInt(Arg^[0]^.Ptr)^ / 180 * Pi)) else
   If (Arg^[0]^.Typ = VT_FLO)
      then R:=NewVal(VT_FLO, Func(PFloat(Arg^[0]^.Ptr)^)) else
      {else} begin
      R:=ValToFlo(Arg^[0]); PFloat(R^.Ptr)^ := Func(PFloat(R^.Ptr)^)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(R)   
   end;

Function F_cos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(@myCos, DoReturn, Arg)) end;

Function F_sin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(@mySin, DoReturn, Arg)) end;
   
Function F_tan(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(@myTan, DoReturn, Arg)) end;
   
Function F_ctg(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(@myCtg, DoReturn, Arg)) end;

Function F_rounding(Func:TFloatToIntFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; Inline;
   Var C:LongWord; R:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_INT));
   If (Length(Arg^)>1) then
      For C:=1 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then R:=CopyVal(Arg^[0]) else
   If (Arg^[0]^.Typ = VT_FLO)
      then R:=NewVal(VT_INT, Func(PFloat(Arg^[0]^.Ptr)^))
      else R:=NewVal(VT_INT, Func(ValAsFlo(Arg^[0])));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(R)   
   end;

Function F_ceil(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(@myCeil, DoReturn, Arg)) end;

Function F_floor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(@myFloor, DoReturn, Arg)) end;

Function F_round(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(@myRound, DoReturn, Arg)) end;

Function F_trunc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(@myTrunc, DoReturn, Arg)) end;

Function F_frac(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; Inline;
   Var C:LongWord; R:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_FLO));
   If (Length(Arg^)>1) then
      For C:=1 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then R:=EmptyVal(VT_FLO) else
   If (Arg^[0]^.Typ = VT_FLO)
      then R:=NewVal(VT_FLO, Frac(PFloat(Arg^[0]^.Ptr)^))
      else R:=NewVal(VT_FLO, Frac(ValAsFlo(Arg^[0])));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(R)   
   end;

Function GreatestCommonDivisor(A,B:QInt):QInt;
   Var T:QInt;
   begin
   While (B<>0) do begin
      T := A; A := B;
      B := T mod B
      end;
   Exit(Abs(A))
   end;

Function LeastCommonMultiple(A,B:QInt):QInt;
   begin Exit(Abs(A*B div GreatestCommonDivisor(A,B))) end;

Function NewtonsSymbol(A,B:QInt):QInt;
   Var i,Product:QInt;
   begin
   A:=Abs(A); B:=Abs(B);
   If (B = 0) or (B = A) then Exit(1);
   If (B < 0) or (B > A) then Exit(0);
   If (B > (A div 2)) then B := A - B;
   
   A := A - B; i := 2; Product := 1;
   While (i <= B) do begin
      Product := Product * (A+i);
      Product := Product div i;
      i += 1
      end;
   
   Exit((A+1) * Product)
   end;

Function F_commons(Func:TIntIntToIntFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; Inline;
   Var C:LongWord; Int:Array[0..1] of QInt;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(NewVal(VT_INT, 1))
      end;
   
   If (Length(Arg^) > 2) then
      For C:=2 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   
   For C:=0 to 1 do begin
      If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN)
         then Int[C]:=PQInt(Arg^[C]^.Ptr)^
         else Int[C]:=ValAsInt(Arg^[C]);
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   
   Exit(NewVal(VT_INT, Func(Int[0],Int[1])))
   end;

Function F_gcd(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_commons(@GreatestCommonDivisor, DoReturn, Arg)) end;

Function F_lcm(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_commons(@LeastCommonMultiple, DoReturn, Arg)) end;

Function F_newt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_commons(@NewtonsSymbol, DoReturn, Arg)) end;

Function F_hypotenuse(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; Flt:Array[0..1] of TFloat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(EmptyVal(VT_FLO))
      end;
   
   If (Length(Arg^) > 2) then
      For C:=2 to High(Arg^) do 
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   
   For C:=0 to 1 do begin
      If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN)
         then Flt[C]:=PQInt(Arg^[C]^.Ptr)^ else
      If (Arg^[C]^.Typ = VT_FLO)
         then Flt[C]:=PFloat(Arg^[C]^.Ptr)^
         else Flt[C]:=ValAsFlo(Arg^[C]);
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   
   If (Flt[0] = 0.0) then Exit(EmptyVal(VT_FLO));
   Exit(NewVal(VT_FLO, Abs(Flt[0]) * Sqrt(1 + Sqr(Flt[1] / Flt[0]))))
   end;

end.
