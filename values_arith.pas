unit values_arith;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure ValSet(Const A,B:PValue);
Procedure ValAdd(Const A,B:PValue);
Procedure ValSub(Const A,B:PValue);
Procedure ValMul(Const A,B:PValue);
Procedure ValDiv(Const A,B:PValue);
Procedure ValMod(Const A,B:PValue);
Procedure ValPow(Const A,B:PValue);

implementation
   uses SysUtils, Math, Convert;

Procedure ValSet_ArrDict(Const A,B:PValue);
   Var AArr,BArr:PArray; AEntA,BEntA:TArray.TEntryArr;
       ADict,BDict:PDict;  AEntD,BEntD:TDict.TEntryArr;
       iA, iB, kI : QInt; kS:TStr;
   begin
   Case (A^.Typ) of
      VT_ARR:
         begin
         AArr:=PArr(A^.Ptr); AEntA := AArr^.ToArray();
         Case (B^.Typ) of
            VT_ARR:
               begin
               BArr:=PArr(B^.Ptr); BEntA := BArr^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEntA)) and (iB < Length(BEntA)) do
                  Case CompareValue(AEntA[iA].Key, BEntA[iB].Key) of
                     -1: iA += 1;
                      0: begin ValSet(AEntA[iA].Val, BEntA[iB].Val); iA += 1; iB += 1 end;
                     +1: begin AArr^.SetVal(BEntA[iB].Key, CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1 end
                     end;
               While (iB < Length(BEntA)) do begin
                  AArr^.SetVal(BEntA[iB].Key, CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1
                  end
               end;
            VT_DICT:
               begin
               BDict:=PDict(B^.Ptr); BEntD := BDict^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEntA)) and (iB < Length(BEntD)) do begin
                  kI:=StrToInt(BEntD[iB].Key);
                  Case CompareValue(AEntA[iA].Key, kI) of
                     -1: iA += 1;
                      0: begin ValSet(AEntA[iA].Val, BEntD[iB].Val); iA += 1; iB += 1 end;
                     +1: begin AArr^.SetVal(kI, CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1 end
                  end end;
               While (iB < Length(BEntD)) do begin
                  AArr^.SetVal(StrToInt(BEntD[iB].Key), CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1
                  end
               end
            else begin
               iA := 0;
               While (iA < Length(AEntA)) do begin
                  ValSet(AEntA[iA].Val, B);
                  iA += 1
               end end
         end end;
      VT_DIC:
         begin
         ADict:=PDict(A^.Ptr); AEntD := ADict^.ToArray();
         Case (B^.Typ) of
            VT_ARR:
               begin
               BArr:=PArr(B^.Ptr); BEntA := BArr^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEntD)) and (iB < Length(BEntA)) do begin
                  kS:=IntToStr(BEntA[iB].Key);
                  Case CompareStr(AEntD[iA].Key, kS) of
                     -1: iA += 1;
                      0: begin ValSet(AEntD[iA].Val, BEntA[iB].Val); iA += 1; iB += 1 end;
                     +1: begin ADict^.SetVal(kS, CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1 end
                  end end;
               While (iB < Length(BEntA)) do begin
                  ADict^.SetVal(IntToStr(BEntA[iB].Key), CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1
                  end
               end;
            VT_DICT:
               begin
               BDict:=PDict(B^.Ptr); BEntD := BDict^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEntD)) and (iB < Length(BEntD)) do
                  Case CompareStr(AEntD[iA].Key, BEntD[iB].Key) of
                     -1: iA += 1;
                      0: begin ValSet(AEntD[iA].Val, BEntD[iB].Val); iA += 1; iB += 1 end;
                     +1: begin ADict^.SetVal(BEntD[iB].Key, CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1 end
                     end;
               While (iB < Length(BEntD)) do begin
                  ADict^.SetVal(BEntD[iB].Key, CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1
                  end
               end;
            else begin
               iA := 0;
               While (iA < Length(AEntD)) do begin
                  ValSet(AEntD[iA].Val, B);
                  iA += 1
               end end
         end end
   end end;

Type TArithProc = Procedure(Const A,B:PValue);

Procedure ValArith_ArrDict(Proc:TArithProc;A,B:PValue);
   Var AArr,BArr:PArray;  EntA:TArray.TEntryArr;
       ADict,BDict:PDict; EntD:TDict.TEntryArr;
       idx, kI : QInt; kS : AnsiString;
   begin
   Case (A^.Typ) of
      VT_ARR:
         begin
         AArr := PArr(A^.Ptr); EntA := AArr^.ToArray(); idx := 0;
         Case (B^.Typ) of
            VT_ARR:
               begin
               BArr := PArr(B^.Ptr);
               While (idx < Length(EntA)) do begin
                  If (BArr^.IsVal(EntA[idx].Key))
                     then Proc(EntA[idx].Val, BArr^.GetVal(EntA[idx].Key));
                  idx += 1
               end end;
            VT_DIC:
               begin
               BDict := PDict(B^.Ptr);
               While (idx < Length(EntA)) do begin
                  kS := IntToStr(EntA[idx].Key);
                  If (BDict^.IsVal(kS))
                     then Proc(EntA[idx].Val, BDict^.GetVal(kS));
                  idx += 1
               end end
            else begin
               While (idx < Length(EntA)) do begin
                  Proc(EntA[idx].Val, B);
                  idx += 1
               end end
         end end;
      VT_DIC:
         begin
         ADict := PDict(A^.Ptr); EntD := ADict^.ToArray();
         Case (B^.Typ) of
            VT_ARR:
               begin
               BArr := PArr(B^.Ptr);
               While (idx < Length(EntD)) do begin
                  kI := StrToInt(EntD[idx].Key);
                  If (BArr^.IsVal(kI))
                     then Proc(EntD[idx].Val, BArr^.GetVal(kI));
                  idx += 1
               end end;
            VT_DIC:
               begin
               BDict := PDict(B^.Ptr);
               While (idx < Length(EntD)) do begin
                  If (BDict^.IsVal(EntD[idx].Key))
                     then Proc(EntD[idx].Val, BDict^.GetVal(EntD[idx].Key));
                  idx += 1
               end end
            else begin
               While (idx < Length(EntA)) do begin
                  Proc(EntA[idx].Val, B);
                  idx += 1
               end end
         end end
   end end;

{$DEFINE __I__ := PQInt (A^.Ptr)^ }
{$DEFINE __F__ := PFloat(A^.Ptr)^ }
{$DEFINE __S__ := PStr  (A^.Ptr)^ }
{$DEFINE __L__ := PBool (A^.Ptr)^ }
{$DEFINE __U__ := PUTF  (A^.Ptr)^ }

Procedure ValSet(Const A,B:PValue);
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __I__:=(PQInt(B^.Ptr)^);
            VT_FLO:
               __I__:=Trunc((PFloat(B^.Ptr)^));
            VT_STR:
               __I__:=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_UTF:
               __I__:=PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ));
            VT_ARR:
               __I__:=PArray(B^.Ptr)^.Count;
            VT_DIC:
               __I__:=PDict(B^.Ptr)^.Count;
            VT_BOO:
               __I__:=BoolToInt(PBool(B^.Ptr)^);
            else
               __I__:= 0
         end;
      VT_FLO: 
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __F__:=(PQInt(B^.Ptr)^);
            VT_FLO:
               __F__:=(PFloat(B^.Ptr)^);
            VT_STR:
               __F__:=StrToReal(PStr(B^.Ptr)^);
            VT_UTF:
               __F__:=PUTF(B^.Ptr)^.ToFloat();
            VT_ARR:
               __F__:=PArray(B^.Ptr)^.Count;
            VT_DIC:
               __F__:=PDict(B^.Ptr)^.Count;
            VT_BOO:
               __F__:=BoolToInt(PBool(B^.Ptr)^);
            else
               __F__:=0.0
         end;
      VT_STR:
         Case (B^.Typ) of
            VT_INT:
               __S__:=IntToStr(PQInt(B^.Ptr)^);
            VT_HEX:
               __S__:=HexToStr(PQInt(B^.Ptr)^);
            VT_OCT:
               __S__:=OctToStr(PQInt(B^.Ptr)^);
            VT_BIN:
               __S__:=BinToStr(PQInt(B^.Ptr)^);
            VT_FLO:
               __S__:=FloatToStr(PFloat(B^.Ptr)^);
            VT_STR:
               __S__:=(PStr(B^.Ptr)^);
            VT_UTF:
               __S__:=PUTF(B^.Ptr)^.ToAnsiString();
            VT_ARR:
               __S__:=IntToStr(PArray(B^.Ptr)^.Count);
            VT_DIC:
               __S__:=IntToStr(PDict(B^.Ptr)^.Count);
            VT_BOO:
               If (PBoolean(B^.Ptr)^) then __S__:='TRUE' else __S__:='FALSE';
            else
               __S__:=''
         end;
      VT_UTF:
         Case (B^.Typ) of
            VT_INT:
               __U__.SetTo(IntToStr(PQInt(B^.Ptr)^));
            VT_HEX:
               __U__.SetTo(HexToStr(PQInt(B^.Ptr)^));
            VT_OCT:
               __U__.SetTo(OctToStr(PQInt(B^.Ptr)^));
            VT_BIN:
               __U__.SetTo(BinToStr(PQInt(B^.Ptr)^));
            VT_FLO:
               __U__.SetTo(FloatToStr(PFloat(B^.Ptr)^));
            VT_STR:
               __U__.SetTo(PStr(B^.Ptr)^);
            VT_UTF:
               __U__.SetTo(PUTF(B^.Ptr));
            VT_ARR:
               __U__.SetTo(IntToStr(PArray(B^.Ptr)^.Count));
            VT_DIC:
               __U__.SetTo(IntToStr(PDict(B^.Ptr)^.Count));
            VT_BOO:
               If (PBoolean(B^.Ptr)^) then __U__.SetTo('TRUE') else __U__.SetTo('FALSE');
            else
               __U__.Clear()
         end;
      VT_BOO: 
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               __L__:=(PQInt(B^.Ptr)^<>0);
            VT_FLO:
               __L__:=(Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               __L__:=StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_UTF:
               __L__:=StrToBoolDef(PUTF(B^.Ptr)^.ToAnsiString(),FALSE);
            VT_ARR:
               __L__:=(Not PArray(B^.Ptr)^.Empty);
            VT_DIC:
               __L__:=(Not PDict(B^.Ptr)^.Empty);
            VT_BOO:
               __L__:=(PBool(B^.Ptr)^);
            else
               __L__:=FALSE
         end;
      VT_ARR: ValSet_ArrDict(A,B);
      VT_DIC: ValSet_ArrDict(A,B);
      VT_FIL:
         If (B^.Typ = VT_FIL) then A^.Ptr := B^.Ptr
   end end;


Procedure ValAdd(Const A,B:PValue);
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __I__+=(PQInt(B^.Ptr)^);
            VT_FLO:
               __I__:=Trunc(__I__+(PFloat(B^.Ptr)^));
            VT_STR:
               __I__+=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_UTF:
               __I__+=PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ));
            VT_BOO:
               If (PBool(B^.Ptr)^) then __I__+=1;
            VT_ARR:
               __I__+=PArr(B^.Ptr)^.Count;
            VT_DIC:
               __I__+=PDict(B^.Ptr)^.Count;
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __F__+=(PQInt(B^.Ptr)^);
            VT_FLO:
               __F__+=(PFloat(B^.Ptr)^);
            VT_STR:
               __F__+=StrToReal(PStr(B^.Ptr)^);
            VT_UTF:
               __F__+=PUTF(B^.Ptr)^.ToFloat();
            VT_BOO:
               If (PBool(B^.Ptr)^) then __F__+=1;
            VT_ARR:
               __F__+=PArr(B^.Ptr)^.Count;
            VT_DIC:
               __F__+=PDict(B^.Ptr)^.Count;
         end;
      VT_STR:
         Case (B^.Typ) of
            VT_INT:
               __S__+=IntToStr(PQInt(B^.Ptr)^);
            VT_HEX:
               __S__+=HexToStr(PQInt(B^.Ptr)^);
            VT_OCT:
               __S__+=OctToStr(PQInt(B^.Ptr)^);
            VT_BIN:
               __S__+=BinToStr(PQInt(B^.Ptr)^);
            VT_FLO:
               __S__+=FloatToStr(PFloat(B^.Ptr)^);
            VT_STR:
               __S__+=(PStr(B^.Ptr)^);
            VT_UTF:
               __S__+=PUTF(B^.Ptr)^.ToAnsiString();
            VT_BOO:
               If (PBool(B^.Ptr)^) then __S__+='TRUE' else __S__+='FALSE'
         end;
      VT_UTF:
         Case (B^.Typ) of
            VT_INT:
               __U__.Append(IntToStr(PQInt(B^.Ptr)^));
            VT_HEX:
               __U__.Append(HexToStr(PQInt(B^.Ptr)^));
            VT_OCT:
               __U__.Append(OctToStr(PQInt(B^.Ptr)^));
            VT_BIN:
               __U__.Append(BinToStr(PQInt(B^.Ptr)^));
            VT_FLO:
               __U__.Append(FloatToStr(PFloat(B^.Ptr)^));
            VT_STR:
               __U__.Append(PStr(B^.Ptr)^);
            VT_UTF:
               __U__.Append(PUTF(B^.Ptr));
            VT_ARR:
               __U__.Append(IntToStr(PArray(B^.Ptr)^.Count));
            VT_DIC:
               __U__.Append(IntToStr(PDict(B^.Ptr)^.Count));
            VT_BOO:
               If (PBoolean(B^.Ptr)^) then __U__.Append('TRUE') else __U__.Append('FALSE');
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               __L__:=__L__ or (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               __L__:=__L__ or (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               __L__:=__L__ or StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_UTF:
               __L__:=__L__ or StrToBoolDef(PUTF(B^.Ptr)^.ToAnsiString(),FALSE);
            VT_BOO:
               __L__:=__L__ or (PBool(B^.Ptr)^);
            VT_ARR:
               __L__:=__L__ or (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               __L__:=__L__ or (Not PDict(B^.Ptr)^.Empty);
         end;
      VT_ARR: ValArith_ArrDict(@ValAdd,A,B);
      VT_DIC: ValArith_ArrDict(@ValAdd,A,B);
   end end;


Procedure ValSub(Const A,B:PValue);
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __I__-=(PQInt(B^.Ptr)^);
            VT_FLO:
               __I__:=Trunc(__I__-(PFloat(B^.Ptr)^));
            VT_STR:
               __I__-=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_UTF:
               __I__-=PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ));
            VT_BOO:
               If (PBool(B^.Ptr)^) then __I__-=1;
            VT_ARR:
               __I__-=PArr(B^.Ptr)^.Count;
            VT_DIC:
               __I__-=PDict(B^.Ptr)^.Count;
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __F__-=(PQInt(B^.Ptr)^);
            VT_FLO:
               __F__-=(PFloat(B^.Ptr)^);
            VT_STR:
               __F__-=StrToReal(PStr(B^.Ptr)^);
            VT_UTF:
               __F__-=PUTF(B^.Ptr)^.ToFloat();
            VT_BOO:
               If (PBool(B^.Ptr)^) then __F__-=1;
            VT_ARR:
               __F__-=PArr(B^.Ptr)^.Count;
            VT_DIC:
               __F__-=PDict(B^.Ptr)^.Count;
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               __L__:=__L__ xor (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               __L__:=__L__ xor (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               __L__:=__L__ xor StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_UTF:
               __L__:=__L__ xor StrToBoolDef(PUTF(B^.Ptr)^.ToAnsiString,FALSE);
            VT_BOO:
               __L__:=__L__ xor (PBool(B^.Ptr)^);
            VT_ARR:
               __L__:=__L__ xor (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               __L__:=__L__ xor (Not PDict(B^.Ptr)^.Empty);
         end;
      VT_ARR: ValArith_ArrDict(@ValSub,A,B);
      VT_DIC: ValArith_ArrDict(@ValSub,A,B);
   end end;


Procedure ValMul(Const A,B:PValue);
   Var C,T,O:LongInt;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __I__*=(PQInt(B^.Ptr)^);
            VT_FLO:
               __I__:=Trunc(__I__*(PFloat(B^.Ptr)^));
            VT_STR:
               __I__*=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_UTF:
               __I__*=PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ));
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then __I__:=0;
            VT_ARR:
               __I__*=PArr(B^.Ptr)^.Count;
            VT_DIC:
               __I__*=PDict(B^.Ptr)^.Count;
            else
               __I__:=0
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __F__*=(PQInt(B^.Ptr)^);
            VT_FLO:
               __F__*=(PFloat(B^.Ptr)^);
            VT_STR:
               __F__*=StrToReal(PStr(B^.Ptr)^);
            VT_UTF:
               __F__*=PUTF(B^.Ptr)^.ToFloat();
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then __F__:=0.0;
            VT_ARR:
               __F__*=PArr(B^.Ptr)^.Count;
            VT_DIC:
               __F__*=PDict(B^.Ptr)^.Count;
            else
               __F__:=0.0
         end;
      VT_STR:
         begin
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               T:=(PQInt(B^.Ptr)^);
            VT_FLO:
               T:=Trunc(PFloat(B^.Ptr)^);
            VT_STR:
               Exit();
            VT_UTF:
               Exit();
            VT_BOO:
               T:=BoolToInt(PBool(B^.Ptr)^);
            VT_ARR:
               T:=PArr(B^.Ptr)^.Count;
            VT_DIC:
               T:=PArr(B^.Ptr)^.Count;
            else 
               T:=0
            end;
         If (T <= 0) then begin __S__:=''; Exit() end;
         O := Length(__S__); T *= O; SetLength(__S__, T);
         For C:=(O+1) to T do __S__[C] := __S__[C-O]
         end;
      VT_UTF:
         begin
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               T:=(PQInt(B^.Ptr)^);
            VT_FLO:
               T:=Trunc(PFloat(B^.Ptr)^);
            VT_STR:
               Exit();
            VT_UTF:
               Exit();
            VT_BOO:
               T:=BoolToInt(PBool(B^.Ptr)^);
            VT_ARR:
               T:=PArr(B^.Ptr)^.Count;
            VT_DIC:
               T:=PArr(B^.Ptr)^.Count;
            else 
               T:=0
            end;
         If (T <= 0) then __U__.Clear()
                     else __U__.Multiply(T)
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               __L__:=__L__ and (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               __L__:=__L__ and (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               __L__:=__L__ and StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_UTF:
               __L__:=__L__ and StrToBoolDef(PUTF(B^.Ptr)^.ToAnsiString,FALSE);
            VT_BOO:
               __L__:=__L__ and (PBool(B^.Ptr)^);
            VT_ARR:
               __L__:=__L__ and (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               __L__:=__L__ and (Not PDict(B^.Ptr)^.Empty);
         end;
      VT_ARR: ValArith_ArrDict(@ValMul,A,B);
      VT_DIC: ValArith_ArrDict(@ValMul,A,B);
   end end;


Procedure ValDiv(Const A,B:PValue);
   Var  tI:QInt; tF:TFloat;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^<>0) then __I__:=__I__ div (PQInt(B^.Ptr)^)
                                      else __I__:=0;
            VT_FLO:
               If (PFloat(B^.Ptr)^<>0.0) then __I__:=Trunc(__I__/(PFloat(B^.Ptr)^))
                                         else __I__:=0;
            VT_STR:
               begin
               tI:=StrToNum(PStr(B^.Ptr)^,A^.Typ);
               If (tI<>0) then __I__:=(__I__ div tI) else __I__:=0
               end;
            VT_UTF:
               begin
               tI:=PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ));
               If (tI<>0) then __I__:=(__I__ div tI) else __I__:=0
               end;
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then __I__:=0;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty) then __I__:=__I__ div PArr(B^.Ptr)^.Count
                                            else __I__:=0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty) then __I__:=__I__ div PDict(B^.Ptr)^.Count
                                             else __I__:=0;
            else
               __I__:=0
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^<>0) then __F__/=(PQInt(B^.Ptr)^)
                                      else __F__:=0.0;
            VT_FLO:
               If (PFloat(B^.Ptr)^<>0.0) then __F__/=(PFloat(B^.Ptr)^)
                                         else __F__:=0.0;
            VT_STR:
               begin
               tF:=StrToReal(PStr(B^.Ptr)^);
               If (tF<>0.0) then __F__/=tF else __F__:=0.0
               end;
            VT_UTF:
               begin
               tF:=PUTF(B^.Ptr)^.ToFloat();
               If (tF<>0.0) then __F__/=tF else __F__:=0.0
               end;
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then __F__:=0.0;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty) then __F__/=PArr(B^.Ptr)^.Count
                                            else __F__:=0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty) then __F__/=PDict(B^.Ptr)^.Count
                                             else __F__:=0;
            else
               __F__:=0.0
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               __L__:=__L__ xor (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               __L__:=__L__ xor (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               __L__:=__L__ xor StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_UTF:
               __L__:=__L__ xor StrToBoolDef(PUTF(B^.Ptr)^.ToAnsiString(),FALSE);
            VT_BOO:
               __L__:=__L__ xor (PBool(B^.Ptr)^);
            VT_ARR:
               __L__:=__L__ xor (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               __L__:=__L__ xor (Not PDict(B^.Ptr)^.Empty);
         end;
      VT_ARR: ValArith_ArrDict(@ValDiv,A,B);
      VT_DIC: ValArith_ArrDict(@ValDiv,A,B);
   end end;


Procedure ValMod(Const A,B:PValue);
   Var  tF:TFloat; tI:QInt;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^ <> 0)
                  then __I__:=__I__ mod (PQInt(B^.Ptr)^)
                  else __I__:=0;
            VT_FLO:
               If (PFloat(B^.Ptr)^ <> 0.0)
                  then __I__:=__I__ - Trunc(Trunc(__I__ / PFloat(B^.Ptr)^) * PFloat(B^.Ptr)^)
                  else __I__:=0;
            VT_STR: begin
               tI:=StrToNum(PStr(B^.Ptr)^,A^.Typ);
               If (tI <> 0) then __I__:=__I__ mod tI
                            else __I__:=0
               end;
            VT_UTF: begin
               tI:=PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ));
               If (tI <> 0) then __I__:=__I__ mod tI
                            else __I__:=0
               end;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty)
                  then __I__:=__I__ mod PArr(B^.Ptr)^.Count
                  else __I__:=0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty)
                  then __I__:=__I__ mod PDict(B^.Ptr)^.Count
                  else __I__:=0
            else
               __I__:=0
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^ <> 0) 
                  then __F__:=__F__ - (Trunc(__F__ / PQInt(B^.Ptr)^)*PQInt(B^.Ptr)^)
                  else __F__:=0.0;
            VT_FLO:
               If (PFloat(B^.Ptr)^ <> 0.0)
                  then __F__:=__F__ - (Trunc(__F__ / PFloat(B^.Ptr)^)*PFloat(B^.Ptr)^)
                  else __F__:=0.0;
            VT_STR:
               begin
               tF:=StrToReal(PStr(B^.Ptr)^);
               If (tF <> 0.0) then __F__:=__F__ - (Trunc(__F__ / tF) * tF)
                              else __F__:=0.0
               end;
            VT_UTF:
               begin
               tF:=PUTF(B^.Ptr)^.ToFloat();
               If (tF <> 0.0) then __F__:=__F__ - (Trunc(__F__ / tF) * tF)
                              else __F__:=0.0
               end;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty)
                  then __F__:=__F__ - (Trunc(__F__ / PArr(B^.Ptr)^.Count)*PArr(B^.Ptr)^.Count)
                  else __F__:=0.0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty)
                  then __F__:=__F__ - (Trunc(__F__ / PDict(B^.Ptr)^.Count)*PDict(B^.Ptr)^.Count)
                  else __F__:=0.0
            else
               __F__:=0.0
         end;
      VT_ARR: ValArith_ArrDict(@ValMod,A,B);
      VT_DIC: ValArith_ArrDict(@ValMod,A,B);
   end end;


Procedure ValPow(Const A,B:PValue);
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __I__:=Trunc(IntPower(__I__, PQInt(B^.Ptr)^));
            VT_FLO:
               __I__:=Trunc(Power(__I__, PFloat(B^.Ptr)^));
            VT_STR:
               __I__:=Trunc(IntPower(__I__, StrToNum(PStr(B^.Ptr)^,A^.Typ)));
            VT_UTF:
               __I__:=Trunc(IntPower(__I__, PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ))));
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then __I__:=1;
            VT_ARR:
               __I__:=Trunc(IntPower(__I__, PArr(B^.Ptr)^.Count));
            VT_DIC:
               __I__:=Trunc(IntPower(__I__, PDict(B^.Ptr)^.Count));
            else
               __I__:=1
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               __F__:=IntPower(__F__, PQInt(B^.Ptr)^);
            VT_FLO:
               __F__:=Power(__F__, PFloat(B^.Ptr)^);
            VT_STR:
               __F__:=Power(__F__, StrToReal(PStr(B^.Ptr)^));
            VT_UTF:
               __F__:=Power(__F__, PUTF(B^.Ptr)^.ToFloat());
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then __F__:=1.0;
            VT_ARR:
               __F__:=Power(__F__, PArr(B^.Ptr)^.Count);
            VT_DIC:
               __F__:=Power(__F__, PDict(B^.Ptr)^.Count);
            else
               __F__:=1.0
         end;
      VT_ARR: ValArith_ArrDict(@ValPow,A,B);
      VT_DIC: ValArith_ArrDict(@ValPow,A,B);
   end end;

end.
