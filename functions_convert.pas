unit functions_convert;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;


Procedure Register(Const FT:PFunTrie);

Function F_BinaryPrefix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_MetricPrefix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses SysUtils, Values_Typecast, Emptyfunc;


Procedure Register(Const FT:PFunTrie);
   begin
      FT^.SetVal('binary-prefix',MkFunc(@F_BinaryPrefix));
      FT^.SetVal('metric-prefix',MkFunc(@F_MetricPrefix));
   end;

Function F_BinaryPrefix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const Prefix : Array[1..8] of ShortString = ('Ki','Mi','Gi','Ti','Pi','Ei','Zi','Yi');
   Var Val : TFloat; Minus : Boolean; Decimals, Prfx : LongInt;
   begin
      If(Not DoReturn) then Exit(F_(False, Arg));
      If(Length(Arg^) = 0) then Exit(NilVal());
      
      Val := ValAsFlo(Arg^[0]);
      If(Val < 0)
         then begin Minus := True; Val := Abs(Val) end
         else Minus := False;
      
      If(Length(Arg^) > 1)
         then Decimals := ValAsInt(Arg^[1])
         else Decimals := 2;
      
      If(Val >= 1024) then begin
         Prfx := 0;
         Repeat
            Val /= 1024;
            Prfx += 1
         Until (Val < 1024) or (Prfx >= 8);
         Result := NewVal(VT_STR, FloatToStrF(Val, ffFixed, Decimals, Decimals) + ' ' + Prefix[Prfx])
      end else
         Result := NewVal(VT_STR, SysUtils.IntToStr(Trunc(Val)) + ' ');
      
      If(Minus) then Result^.Str^ := '-' + Result^.Str^;
      F_(False, Arg)
   end;

Function F_MetricPrefix(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const Prefix : Array[-8..+8] of ShortString = (
            'y','z','a','f','p','n','μ','m',
            '',
            'k','M','G','T','P','E','Z','Y'
         );
   Var Val : TFloat; Minus : Boolean; Decimals, Prfx : LongInt;
   begin
      If(Not DoReturn) then Exit(F_(False, Arg));
      If(Length(Arg^) = 0) then Exit(NilVal());
      
      Val := ValAsFlo(Arg^[0]);
      If(Val < 0)
         then begin Minus := True; Val := Abs(Val) end
         else Minus := False;
      
      If(Length(Arg^) > 1)
         then Decimals := ValAsInt(Arg^[1])
         else Decimals := 3;
      
      Prfx := 0;
      If(Val >= 1) then begin
         While(Val >= 1000) and (Prfx < +8) do begin
            Val /= 1000;
            Prfx += 1
         end
      end else begin
         While(Val < 0.1) and (Prfx > -8) do begin
            Val *= 1000;
            Prfx -= 1
         end
      end;
      
      Result := NewVal(VT_STR, FloatToStrF(Val, ffFixed, Decimals, Decimals) + ' ' + Prefix[Prfx]);
      If(Minus) then Result^.Str^ := '-' + Result^.Str^;
      
      F_(False, Arg)
   end;

end.
