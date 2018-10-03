unit functions_math;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

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

Function F_arccos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_arcsin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_arctan(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_arcctg(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_getAngle(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_sqrt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_log(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_gcd(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_lcm(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_newt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_hypotenuse(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_convertBase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Math, EmptyFunc, Values_Typecast, Convert;

Procedure Register(Const FT:PFunTrie);
   begin
      // Trigonometry
      FT^.SetVal('cos', MkFunc(@F_cos));
      FT^.SetVal('sin', MkFunc(@F_sin));
      FT^.SetVal('tan', MkFunc(@F_tan));
      FT^.SetVal('ctg', MkFunc(@F_ctg));
      
      // Cyclometry
      FT^.SetVal('arccos', MkFunc(@F_arccos));
      FT^.SetVal('arcsin', MkFunc(@F_arcsin));
      FT^.SetVal('arctan', MkFunc(@F_arctan));
      FT^.SetVal('arcctg', MkFunc(@F_arcctg));
      FT^.SetVal('get-angle', MkFunc(@F_getAngle));
      
      // Positive-negative
      FT^.SetVal('abs', MkFunc(@F_abs));
      FT^.SetVal('sgn', MkFunc(@F_sgn));
      
      // Rounding
      FT^.SetVal('ceil', MkFunc(@F_ceil));
      FT^.SetVal('floor', MkFunc(@F_floor));
      FT^.SetVal('round', MkFunc(@F_round));
      FT^.SetVal('trunc', MkFunc(@F_trunc));
      FT^.SetVal('frac', MkFunc(@F_frac));
      
      // Built-in calc
      FT^.SetVal('sqrt', MkFunc(@F_Sqrt));
      FT^.SetVal('log', MkFunc(@F_Log));
      
      // Own algo calc
      FT^.SetVal('gcd', MkFunc(@F_gcd));
      FT^.SetVal('lcm', MkFunc(@F_lcm));
      FT^.SetVal('newt', MkFunc(@F_newt));
      FT^.SetVal('hypotenuse', MkFunc(@F_hypotenuse));
      FT^.SetVal('convert-base', MkFunc(@F_convertBase))
   end;

Type
   TFloatToFloatFunc = Function(Const V:TFloat):TFloat;
   TFloatToIntFunc = Function(Const V:TFloat):QInt;
   TIntIntToIntFunc = Function(A,B:QInt):QInt;

Function myCos(Const V:TFloat):TFloat; Inline;
   begin Exit(Cos(V)) end; 
   
Function mySin(Const V:TFloat):TFloat; Inline;
   begin Exit(Sin(V)) end;
   
Function myTan(Const V:TFloat):TFloat; Inline;
   begin Exit(Tan(V)) end;
   
Function myCtg(Const V:TFloat):TFloat; Inline;
   begin Exit(Cot(V)) end;

Function myArcCos(Const V:TFloat):TFloat; Inline;
   begin Exit(ArcCos(V)) end; 
   
Function myArcSin(Const V:TFloat):TFloat; Inline;
   begin Exit(ArcSin(V)) end;
   
Function myArcTan(Const V:TFloat):TFloat; Inline;
   begin Exit(ArcTan(V)) end;
   
Function myArcCtg(Const V:TFloat):TFloat; Inline;
   begin Exit(ArcTan(1 / V)) end;

Function myCeil(Const V:TFloat):QInt;  Inline;
   begin Exit(Ceil(V)) end;
   
Function myFloor(Const V:TFloat):QInt; Inline;
   begin Exit(Floor(V)) end;
   
Function myTrunc(Const V:TFloat):QInt; Inline;
   begin Exit(Trunc(V)) end;

Function myRound(Const V:TFloat):QInt; Inline;
   begin 
      Case Sign(V) of
         
         -1: If (Frac(V) <= -0.5)
                then Exit(Floor(V))
                else Exit(Ceil(V));
                
          0: Exit(0);
          
         +1: If (Frac(V) >= +0.5)
                then Exit(Ceil(V))
                else Exit(Floor(V))
   end end;

Function F_sqrt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; F:TFLoat;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no arguments provided, return 0
      If (Length(Arg^)=0) then Exit(NewVal(VT_FLO,0.0));
      // If more than one arg provided, free them
      If (Length(Arg^)>1) then
         For C:=High(Arg^) downto 1 do
            FreeIfTemp(Arg^[C]);
      
      // If arg0 is float, get sqrt of float
      If (Arg^[0]^.Typ = VT_FLO) then begin
         F:=Sqrt(Arg^[0]^.Flo^)
         end else
      // If arg0 is int, get sqrt of int
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
         then F:=Sqrt(Arg^[0]^.Int^)
      // Otherwise, get sqrt of typecast-to-float
         else F:=Sqrt(ValAsFlo(Arg^[0]));
      
      // Free arg0 if needed and return value
      FreeIfTemp(Arg^[0]);
      Exit(NewVal(VT_FLO,F))
   end;

Function F_log(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; Base,Number:TFloat;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no argument provided, return Nilval
      If (Length(Arg^) = 0) then Exit(NilVal);
      
      // If only one arg provided, return natural logarithm
      If (Length(Arg^) = 1) then begin
         // If arg0 is int, get ln of int
         If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then
            Number:=Ln(Arg^[0]^.Int^) else
         // If arg0 is float, get ln of float
         If (Arg^[0]^.Typ = VT_FLO)
            then Number:=Ln(Arg^[0]^.Flo^)
         // Otherwise, get ln of typecast-to-float
            else Number:=Ln(ValAsFlo(Arg^[0]));
         
         // Free arg0 if needed and return value
         FreeIfTemp(Arg^[0]);
         Exit(NewVal(VT_FLO, Number))
      end;
      
      // If more than two args have been provided, free them
      For C:=2 to High(Arg^) do
          FreeIfTemp(Arg^[C]);
      
      For C:=0 to 1 do begin
         Base := Number; // When C=1 this will transfer Number to Base
         
         // If argC is int, put int into Number
         If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN) then
            Number:=Arg^[C]^.Int^ else
         // If argC if float, put float into Number
         If (Arg^[C]^.Typ = VT_FLO)
            then Number:=Arg^[C]^.Flo^
         // Otherwise put typecast-to-float into Number
            else Number:=ValAsFlo(Arg^[C]);
         // Free argC if needed
         FreeIfTemp(Arg^[C])
      end;
      
      // Return Base-based logarithm of Number (duh!)
      Exit(NewVal(VT_FLO, LogN(Base, Number)))
   end;

Function F_abs(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return 0 as default value
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_INT));
      
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then
         Result:=NewVal(Arg^[0]^.Typ, Abs(Arg^[0]^.Int^))
      else If (Arg^[0]^.Typ = VT_FLO) then
         Result:=NewVal(Arg^[0]^.Typ, Abs(Arg^[0]^.Flo^))
      else 
         Result:=NewVal(VT_FLO, Abs(ValAsFlo(Arg^[0])));
      
      F_(False, Arg) // Free args before leaving
   end;

Function F_sgn(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args provided, return 0 as default value
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_INT));
      
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then
         Result:=NewVal(Arg^[0]^.Typ, LongInt(Sign(Arg^[0]^.Int^))) 
      else If (Arg^[0]^.Typ = VT_FLO) then
         Result:=NewVal(VT_INT, LongInt(Sign(Arg^[0]^.Flo^)))
      else
         Result:=NewVal(VT_INT, LongInt(Sign(ValAsInt(Arg^[0]))));
      
      F_(False, Arg) // Free args before leaving  
   end;

Const
   CYCLOTRIGO_ALLOW_DEGREES = True;
   CYCLOTRIGO_ONLY_RADIANS = False;

Function F_cyclotrigo(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TFloatToFloatFunc; Const Degrees:Boolean):PValue; 
   Var Flt:TFloat;
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If any args provided, get floatval of first one
      If (Length(Arg^) > 0) then begin
         Flt := ValAsFlo(Arg^[0]);
         // If arg0 is int, treat floatval as degrees, not radians
         If (Degrees) and (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
            then Flt := Flt * Pi / 180;
         F_(False,Arg) // Free args
      end else Flt := 0.0; // Use 0 radians if no args provided
      
      // Invalid args may cause exceptions, so exception block
      Try
         Flt := Func(Flt);
         Result := NewVal(VT_FLO, Flt)
      Except
         Result := NilVal()
      end
   end;

Function F_trigonometric(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TFloatToFloatFunc):PValue; 
   begin Exit(F_cyclotrigo(DoReturn, Arg, Func, CYCLOTRIGO_ALLOW_DEGREES)) end;

Function F_cyclometric(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TFloatToFloatFunc):PValue; 
   begin Exit(F_cyclotrigo(DoReturn, Arg, Func, CYCLOTRIGO_ONLY_RADIANS)) end;

Function F_cos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(DoReturn, Arg, @myCos)) end;

Function F_sin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(DoReturn, Arg, @mySin)) end;
   
Function F_tan(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(DoReturn, Arg, @myTan)) end;
   
Function F_ctg(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_trigonometric(DoReturn, Arg, @myCtg)) end;

Function F_arccos(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_cyclometric(DoReturn, Arg, @myArcCos)) end;

Function F_arcsin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_cyclometric(DoReturn, Arg, @myArcSin)) end;
   
Function F_arctan(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_cyclometric(DoReturn, Arg, @myArcTan)) end;
   
Function F_arcctg(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_cyclometric(DoReturn, Arg, @myArcCtg)) end;

Function F_GetAngle(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var sinx, cosx, angle : Double;
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      If (Length(Arg^) >= 2) then begin
         sinx := ValAsFlo(Arg^[0]); // Get sin from arg0
         cosx := ValAsFlo(Arg^[1]); // Get cos from arg1
         Try
            // Calculate angle from sincos pair
            If (sinx > 0)
               then angle:=ArcCos(cosx)
               else angle:=2*Pi-ArcCos(cosx);
         Except
            Angle := -1; // Set to -1 on error
         end;
         Result := NewVal(VT_FLO, angle); // Create return value
      end else begin
         Result := NewVal(VT_FLO, -1) // Create -1 return value if less than 2 args provided
      end;
      F_(False, Arg) // Free args before leaving
   end;

Function F_rounding(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TFloatToIntFunc):PValue;
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      // Return 0 as default value if no args provided
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_INT));
      
      // Create return value based on value type
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then
         Result:=CopyVal(Arg^[0])
      else If (Arg^[0]^.Typ = VT_FLO) then
         Result:=NewVal(VT_INT, Func(Arg^[0]^.Flo^))
      else
         Result:=NewVal(VT_INT, Func(ValAsFlo(Arg^[0])));
      
      F_(False, Arg) // Free args before leaving
   end;

Function F_ceil(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(DoReturn, Arg, @myCeil)) end;

Function F_floor(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(DoReturn, Arg, @myFloor)) end;

Function F_round(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(DoReturn, Arg, @myRound)) end;

Function F_trunc(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_rounding(DoReturn, Arg, @myTrunc)) end;

Function F_frac(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; 
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      // Return 0.0 as default value if no args provided
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_FLO));
      
      // Create return value based on value type
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then
         Result:=EmptyVal(VT_FLO)
      else If (Arg^[0]^.Typ = VT_FLO) then
         Result:=NewVal(VT_FLO, Frac(Arg^[0]^.Flo^))
      else
         Result:=NewVal(VT_FLO, Frac(ValAsFlo(Arg^[0])));
         
      F_(False, Arg) // Free args before leaving 
   end;

Function GreatestCommonDivisor(A,B:QInt):QInt;
   Var T:QInt;
   begin
      While (B <> 0) do begin
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

Function F_commons(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TIntIntToIntFunc):PValue; 
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If less than two args provided, return 1 as default value
      If (Length(Arg^) < 2) then begin
         F_(False, Arg);
         Exit(NewVal(VT_INT, 1))
      end;
      
      // Create return value by calling Func() on int-typecasts and free args before leaving
      Result := NewVal(VT_INT, Func(ValAsInt(Arg^[0]), ValAsInt(Arg^[1])));
      F_(False, Arg)
   end;

Function F_gcd(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_commons(DoReturn, Arg, @GreatestCommonDivisor)) end;

Function F_lcm(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_commons(DoReturn, Arg, @LeastCommonMultiple)) end;

Function F_newt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_commons(DoReturn, Arg, @NewtonsSymbol)) end;

Function F_hypotenuse(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Return 0 if less than 2 args provided
      If (Length(Arg^) < 2) then begin
         F_(False, Arg);
         Exit(EmptyVal(VT_FLO))
      end;
      
      // Create return value from float-typecast of arg0
      Result := NewVal(VT_FLO, ValAsFlo(Arg^[0]));
      
      // If arg0 is non-zero, calculate hypotenuse
      If (Result^.Flo^ <> 0.0)
         then Result^.Flo^ := Abs(Result^.Flo^) * Sqrt(1 + Sqr(ValAsFlo(Arg^[1]) / Result^.Flo^))
         else Result^.Flo^ := ValAsFlo(Arg^[1]);
      
      F_(False, Arg) // Free args before leaving
   end;

Function F_convertBase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var OrgNum : TStr; OrgBase, ResBase : LongInt;
       Digit : Array of Word; DigNum : LongInt;
   
   Procedure LengthenNumber(Chg:LongInt);
      begin
         SetLength(Digit, DigNum + Chg);
         While (Chg > 0) do begin
            Digit[DigNum] := 0;
            DigNum += 1;
            Chg -= 1
         end
      end;
   
   Procedure AddToNumber(Val:LongInt);
      begin
         Digit[0] += Val;
         Val := 0;
         While (Val < DigNum) do begin
            If (Digit[Val] >= ResBase) then begin
               If (Val+1 >= DigNum) then LengthenNumber(+8);
               
               Digit[Val+1] += Digit[Val] div ResBase;
               Digit[Val] := Digit[Val] mod ResBase
               end;
            Val += 1
         end
      end;
   
   Procedure MultiplyNumber(Const Val:LongInt);
      Var P:LongInt;
      begin
         For P:=0 to (DigNum-1) do Digit[P] *= Val
      end;
   
   Function CharToNumber(Const Ch:Char):LongInt;
      begin
         If (Ch  <  #48) then Exit(-1);
         If (Ch <=  #57) then Exit(Ord(Ch)-48);
         If (Ch  <  #65) then Exit(-1);
         If (Ch <=  #90) then Exit(Ord(Ch)-65+10);
         If (Ch  <  #97) then Exit(-1);
         If (Ch <= #122) then Exit(Ord(Ch)-97+10);
         Exit(-1)
      end;
   
   Var P,D:LongInt;
   begin
      // If no retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args, return empty value
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
      
      OrgNum := ValAsStr(Arg^[0]); // Get original number from arg0
      If (Length(Arg^) >= 3) then begin
         OrgBase := ValAsInt(Arg^[1]); // Get original base from arg1
         ResBase := ValAsInt(Arg^[2])  // Get destination base from arg2
      end else begin
         If (Length(Arg^) >= 2)
            then OrgBase := ValAsInt(Arg^[1]) // Original base from arg1
            else OrgBase := 10;               // Default to 10 if no arg1
         ResBase := 10 // default to 10 because no arg2
      end;
      
      // Check base range
      If (OrgBase < 2) or (OrgBase > 36) or (ResBase < 2) or (ResBase > 36) then begin
         F_(False, Arg); Exit(EmptyVal(VT_STR))
      end;
      
      // Go through OrgNum and convert it to destination base
      SetLength(Digit,1); Digit[0] := 0; DigNum := 1;
      For P:=1 to Length(OrgNum) do begin
         D := CharToNumber(OrgNum[P]);
         If (D < 0) or (D > OrgBase) then Continue;
         MultiplyNumber(OrgBase);
         AddToNumber(D)
      end;
      
      // Set orgnum to empty string and construct result number
      OrgNum := '';
      P := (DigNum - 1); While (P > 0) and (Digit[P] = 0) do P -= 1;
      If (P >= 0) then begin
         For D:=P downto 0 do
            If (Digit[D] < 10)
               then OrgNum += Chr(48+Digit[D])
               else OrgNum += Chr(IfThen(HexCase(),65,97)-10+Digit[D])
         end else OrgNum := '0';
      
      // Construct result value and free args before leaving
      Result := NewVal(VT_STR, OrgNum);
      F_(False, Arg)
   end;

end.
