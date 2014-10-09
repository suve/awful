unit values_typecast;

{$INCLUDE defines.inc}

interface
   uses Values;

Function ValAsBin(Const V:PValue):QInt;
Function ValAsOct(Const V:PValue):QInt;
Function ValAsInt(Const V:PValue):QInt;
Function ValAsHex(Const V:PValue):QInt;
Function ValAsFlo(Const V:PValue):TFloat;
Function ValAsBoo(Const V:PValue):TBool;
Function ValAsStr(Const V:PValue):TStr;

Function ValToInt(Const V:PValue):PValue;
Function ValToHex(Const V:PValue):PValue;
Function ValToOct(Const V:PValue):PValue;
Function ValToBin(Const V:PValue):PValue;
Function ValToFlo(Const V:PValue):PValue;
Function ValToBoo(Const V:PValue):PValue;
Function ValToStr(Const V:PValue):PValue;
Function ValToUTF(Const V:PValue):PValue;


implementation
   uses SysUtils, Convert;

Function ValAsInt(Const V:PValue):QInt;
   begin
      Case V^.Typ of
      
         VT_INT .. VT_BIN:
            Exit(V^.Int^);
         
         VT_FLO:
            Exit(Trunc(V^.Flo^));
         
         VT_BOO:
            Exit(BoolToInt(V^.Boo^));
         
         VT_STR:
            Exit(StrToInt(V^.Str^));
         
         VT_UTF:
            Exit(V^.Utf^.ToInt(10));
         
         VT_ARR:
            Exit(V^.Arr^.Count);
         
         VT_DIC:
            Exit(V^.Dic^.Count);
         
         VT_FIL:
            Exit(BoolToInt(V^.Fil^.arw in ['a','r','w']))
            
         else
            Exit(0)
   end end;

Function ValAsHex(Const V:PValue):QInt;
   begin
      Case V^.Typ of
      
         VT_INT .. VT_BIN: 
            Exit(V^.Int^);
            
         VT_FLO: 
            Exit(Trunc(V^.Flo^));
            
         VT_BOO: 
            Exit(BoolToInt(V^.Boo^));
            
         VT_STR: 
            Exit(StrToHex(V^.Str^));
            
         VT_UTF: 
            Exit(V^.Utf^.ToInt(16));
            
         VT_ARR: 
            Exit(V^.Arr^.Count);
            
         VT_DIC: 
            Exit(V^.Dic^.Count);
            
         VT_FIL: 
            Exit(BoolToInt(V^.Fil^.arw in ['a','r','w']))
         
         else
         Exit(0)
   end end;

Function ValAsOct(Const V:PValue):QInt;
   begin
      Case V^.Typ of
      
         VT_INT .. VT_BIN: 
            Exit(V^.Int^);
         
         VT_FLO:
            Exit(Trunc(V^.Flo^));
         
         VT_BOO:
            Exit(BoolToInt(V^.Boo^));
         
         VT_STR:
            Exit(StrToOct(V^.Str^));
         
         VT_UTF:
            Exit(V^.Utf^.ToInt(8));
         
         VT_ARR:
            Exit(V^.Arr^.Count);
         
         VT_DIC:
            Exit(V^.Dic^.Count);
         
         VT_FIL:
            Exit(BoolToInt(V^.Fil^.arw in ['a','r','w']))
         
         else
            Exit(0)
   end end;

Function ValAsBin(Const V:PValue):QInt;
   begin
      Case V^.Typ of
   
         VT_INT .. VT_BIN:
            Exit(V^.Int^);
         
         VT_FLO:
            Exit(Trunc(V^.Flo^));
         
         VT_BOO: 
            Exit(BoolToInt(V^.Boo^));
         
         VT_STR: 
            Exit(StrToBin(V^.Str^));
         
         VT_UTF: 
            Exit(V^.Utf^.ToInt(2));
         
         VT_ARR: 
            Exit(V^.Arr^.Count);
         
         VT_DIC: 
            Exit(V^.Dic^.Count);
         
         VT_FIL: 
            Exit(BoolToInt(V^.Fil^.arw in ['a','r','w']))
         
         else
         Exit(0)
   end end;

Function ValAsFlo(Const V:PValue):TFloat;
   begin
      Case V^.Typ of
         
         VT_INT .. VT_BIN: 
            Exit(V^.Int^);
         
         VT_FLO: 
            Exit(V^.Flo^);
         
         VT_BOO: 
            Exit(BoolToInt(V^.Boo^));
         
         VT_STR: 
            Exit(StrToReal(V^.Str^));
         
         VT_UTF: 
            Exit(V^.Utf^.ToFloat());
         
         VT_ARR: 
            Exit(V^.Arr^.Count);
         
         VT_DIC: 
            Exit(V^.Dic^.Count);
         
         VT_FIL: 
            Exit(BoolToInt(V^.Fil^.arw in ['a','r','w']))
         
         else
            Exit(0.0)
   end end;

Function ValAsBoo(Const V:PValue):TBool;
   begin
      Case V^.Typ of
   
         VT_INT .. VT_BIN:
            Exit((V^.Int^)<>0);
         
         VT_FLO:
            Exit(Abs(V^.Flo^)>=1.0);
         
         VT_BOO: 
            Exit(V^.Boo^);
         
         VT_STR: 
            Exit(StrToBoolDef(V^.Str^,FALSE));
         
         VT_UTF: 
            Exit(StrToBoolDef(V^.Utf^.ToAnsiString,FALSE));
         
         VT_ARR: 
            Exit(Not V^.Arr^.Empty());
         
         VT_DIC: 
            Exit(Not V^.Dic^.Empty());
         
         VT_FIL: 
            Exit(V^.Fil^.arw in ['a','r','w'])
         
         else
            Exit(False)
   end end;

Function ValAsStr(Const V:PValue):TStr;
   begin
      Case V^.Typ of
         
         VT_INT:
            Exit(IntToStr(V^.Int^));
         
         VT_HEX:
            Exit(HexToStr(V^.Int^));
         
         VT_OCT: 
            Exit(OctToStr(V^.Int^));
         
         VT_BIN:
            Exit(BinToStr(V^.Int^));
         
         VT_FLO:
            Exit(FloatToStr(V^.Flo^));
         
         VT_BOO:
            If (V^.Boo^ = TRUE)
               then Exit('TRUE')
               else Exit('FALSE');
         
         VT_STR:
            Exit(V^.Str^);
         
         VT_UTF: 
            Exit(V^.Utf^.ToAnsiString);
         
         VT_ARR:
            Exit('array('+IntToStr(V^.Arr^.Count)+')');
         
         VT_DIC: 
            Exit('dict('+IntToStr(V^.Dic^.Count)+')');
         
         VT_FIL:
            Exit('file('+V^.Fil^.Pth+')')
         
         else
            Exit('')
   end end;

Function ValToInt(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_INT); Result^.Lev:=CurLev;
      Result^.Int^ := ValAsInt(V); 
   end;

Function ValToHex(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_HEX); Result^.Lev:=CurLev;
      Result^.Int^ := ValAsHex(V)
   end;

Function ValToOct(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_OCT); Result^.Lev:=CurLev;
      Result^.Int^ := ValAsOct(V)
   end;

Function ValToBin(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_BIN); Result^.Lev:=CurLev;
      Result^.Int^ := ValAsBin(V)
   end;

Function ValToFlo(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_FLO); Result^.Lev:=CurLev;
      Result^.Flo^ := ValAsFlo(V);
   end;

Function ValToBoo(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_BOO); Result^.Lev:=CurLev;
      Result^.Boo^ := ValAsBoo(V)
   end;

Function ValToStr(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_STR); Result^.Lev:=CurLev;
      Result^.Str^ := ValAsStr(V)
   end;

Function ValToUTF(Const V:PValue):PValue;
   begin
      Result:=CreateVal(VT_UTF); Result^.Lev:=CurLev;
      Result^.Utf^.SetTo(ValAsStr(V))
   end;

end.
