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
   uses SysUtils, FileHandling, Convert;

Function ValAsInt(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToInt(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF(V^.Ptr)^.ToInt(10));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      VT_FIL: Exit(BoolToInt(PFileHandle(V^.Ptr)^.arw in ['a','r','w']))
      else Exit(0)
   end end;

Function ValAsHex(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToHex(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF(V^.Ptr)^.ToInt(16));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      VT_FIL: Exit(BoolToInt(PFileHandle(V^.Ptr)^.arw in ['a','r','w']))
      else Exit(0)
   end end;

Function ValAsOct(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToOct(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF(V^.Ptr)^.ToInt(8));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      VT_FIL: Exit(BoolToInt(PFileHandle(V^.Ptr)^.arw in ['a','r','w']))
      else Exit(0)
   end end;

Function ValAsBin(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToBin(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF(V^.Ptr)^.ToInt(2));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      VT_FIL: Exit(BoolToInt(PFileHandle(V^.Ptr)^.arw in ['a','r','w']))
      else Exit(0)
   end end;

Function ValAsFlo(Const V:PValue):TFloat;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(PFloat(V^.Ptr)^);
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToReal(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF(V^.Ptr)^.ToFloat());
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      VT_FIL: Exit(BoolToInt(PFileHandle(V^.Ptr)^.arw in ['a','r','w']))
      else Exit(0.0)
   end end;

Function ValAsBoo(Const V:PValue):TBool;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit((PQInt(V^.Ptr)^)<>0);
      VT_FLO: Exit(Abs(PFloat(V^.Ptr)^)>=1.0);
      VT_BOO: Exit(PBoolean(V^.Ptr)^);
      VT_STR: Exit(StrToBoolDef(PStr(V^.Ptr)^,FALSE));
      VT_UTF: Exit(StrToBoolDef(PUTF(V^.Ptr)^.ToAnsiString,FALSE));
      VT_ARR: Exit(Not PArray(V^.Ptr)^.Empty());
      VT_DIC: Exit(Not PDict(V^.Ptr)^.Empty());
      VT_FIL: Exit(PFileHandle(V^.Ptr)^.arw in ['a','r','w'])
      else Exit(False)
   end end;

Function ValAsStr(Const V:PValue):TStr;
   begin
   Case V^.Typ of
      VT_INT: Exit(IntToStr(PQInt(V^.Ptr)^));
      VT_HEX: Exit(HexToStr(PQInt(V^.Ptr)^));
      VT_OCT: Exit(OctToStr(PQInt(V^.Ptr)^));
      VT_BIN: Exit(BinToStr(PQInt(V^.Ptr)^));
      VT_FLO: Exit(FloatToStr(PFloat(V^.Ptr)^));
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE)
                 then Exit('TRUE') else Exit('FALSE');
      VT_STR: Exit(PStr(V^.Ptr)^);
      VT_UTF: Exit(PUTF(V^.Ptr)^.ToAnsiString);
      VT_ARR: Exit('array('+IntToStr(PArray(V^.Ptr)^.Count)+')');
      VT_DIC: Exit('dict('+IntToStr(PDict(V^.Ptr)^.Count)+')');
      VT_FIL: Exit('file('+PFileHandle(V^.Ptr)^.Pth+')')
      else Exit('')
   end end;

Function ValToInt(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_INT); Result^.Lev:=CurLev;
   PQInt(Result^.Ptr)^:=ValAsInt(V); 
   end;

Function ValToHex(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_HEX); Result^.Lev:=CurLev;
   PQInt(Result^.Ptr)^:=ValAsHex(V)
   end;

Function ValToOct(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_OCT); Result^.Lev:=CurLev;
   PQInt(Result^.Ptr)^:=ValAsOct(V)
   end;

Function ValToBin(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_BIN); Result^.Lev:=CurLev;
   PQInt(Result^.Ptr)^:=ValAsBin(V)
   end;

Function ValToFlo(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_FLO); Result^.Lev:=CurLev;
   PFloat(Result^.Ptr)^:=ValAsFlo(V);
   end;

Function ValToBoo(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_BOO); Result^.Lev:=CurLev;
   PBool(Result^.Ptr)^:=ValAsBoo(V)
   end;

Function ValToStr(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_STR); Result^.Lev:=CurLev;
   PStr(Result^.Ptr)^:=ValAsStr(V)
   end;

Function ValToUTF(Const V:PValue):PValue;
   begin
   Result:=CreateVal(VT_UTF); Result^.Lev:=CurLev;
   PUTF(Result^.Ptr)^.SetTo(ValAsStr(V))
   end;

end.
