unit values_arith;

interface
   uses Values;

Procedure ValSet(A,B:PValue);
Procedure ValAdd(A,B:PValue);
Procedure ValSub(A,B:PValue);
Procedure ValMul(A,B:PValue);
Procedure ValDiv(A,B:PValue);
Procedure ValMod(A,B:PValue);
Procedure ValPow(A,B:PValue);

implementation
   uses SysUtils, Math;

Procedure ValSet_Arr(A,B:PValue);
   Var AArr,BArr:PArray; AEnta,BEnta:TArray.TEntryArr;
       ADict,BDict:PDict;  AEntd,BEntd:TDict.TEntryArr;
       iA, iB, kI : QInt; kS:TStr;
   begin
   Case (A^.Typ) of
      VT_ARR:
         begin
         AArr:=PArr(A^.Ptr); AEnta := AArr^.ToArray();
         Case (B^.Typ) of
            VT_ARR:
               begin
               BArr:=PArr(B^.Ptr); BEnta := BArr^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEnta)) and (iB < Length(BEnta)) do
                  Case CompareValue(AEnta[iA].Key, BEnta[iB].Key) of
                     -1: iA += 1;
                      0: begin ValSet(AEnta[iA].Val, BEnta[iB].Val); iA += 1; iB += 1 end;
                     +1: begin AArr^.SetVal(BEnta[iB].Key, CopyVal(BEnta[iB].Val, A^.Lev)); iB += 1 end
                     end;
               While (iB < Length(BEnta)) do begin
                  AArr^.SetVal(BEnta[iB].Key, CopyVal(BEnta[iB].Val, A^.Lev)); iB += 1
                  end
               end;
            VT_DICT:
               begin
               BDict:=PDict(B^.Ptr); BEntd := BDict^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEnta)) and (iB < Length(BEntd)) do begin
                  kI:=StrToInt(BEntd[iB].Key);
                  Case CompareValue(AEnta[iA].Key, kI) of
                     -1: iA += 1;
                      0: begin ValSet(AEnta[iA].Val, BEntd[iB].Val); iA += 1; iB += 1 end;
                     +1: begin AArr^.SetVal(kI, CopyVal(BEntd[iB].Val, A^.Lev)); iB += 1 end
                  end end;
               While (iB < Length(BEntd)) do begin
                  AArr^.SetVal(StrToInt(BEntd[iB].Key), CopyVal(BEntd[iB].Val, A^.Lev)); iB += 1
                  end
               end;
         end end;
      VT_DIC:
         begin
         ADict:=PDict(A^.Ptr); AEntd := ADict^.ToArray();
         Case (B^.Typ) of
            VT_ARR:
               begin
               BArr:=PArr(B^.Ptr); BEnta := BArr^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEntd)) and (iB < Length(BEnta)) do begin
                  kS:=IntToStr(BEnta[iB].Key);
                  Case CompareStr(AEntd[iA].Key, kS) of
                     -1: iA += 1;
                      0: begin ValSet(AEntd[iA].Val, BEnta[iB].Val); iA += 1; iB += 1 end;
                     +1: begin ADict^.SetVal(kS, CopyVal(BEnta[iB].Val, A^.Lev)); iB += 1 end
                  end end;
               While (iB < Length(BEnta)) do begin
                  ADict^.SetVal(IntToStr(BEnta[iB].Key), CopyVal(BEnta[iB].Val, A^.Lev)); iB += 1
                  end
               end;
            VT_DICT:
               begin
               BDict:=PDict(B^.Ptr); BEntd := BDict^.ToArray();
               iA := 0; iB := 0;
               While (iA < Length(AEntd)) and (iB < Length(BEntd)) do
                  Case CompareStr(AEntd[iA].Key, BEntd[iB].Key) of
                     -1: iA += 1;
                      0: begin ValSet(AEntd[iA].Val, BEntd[iB].Val); iA += 1; iB += 1 end;
                     +1: begin ADict^.SetVal(BEntd[iB].Key, CopyVal(BEntd[iB].Val, A^.Lev)); iB += 1 end
                     end;
               While (iB < Length(BEntd)) do begin
                  ADict^.SetVal(BEntd[iB].Key, CopyVal(BEntd[iB].Val, A^.Lev)); iB += 1
                  end
               end;
         end end
   end end;

Procedure ValSet(A,B:PValue);
   Var I:PQInt; S:PStr; L:PBoolean; F:PFloat;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I := PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (I^):=(PQInt(B^.Ptr)^);
            VT_FLO:
               (I^):=Trunc((PFloat(B^.Ptr)^));
            VT_STR:
               (I^):=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_ARR:
               (I^):=PArray(B^.Ptr)^.Count;
            VT_DIC:
               (I^):=PDict(B^.Ptr)^.Count;
            VT_BOO:
               (I^):=BoolToInt(PBool(B^.Ptr)^);
            else
               (I^) := 0
         end end;
      VT_FLO: 
         begin
         F := PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (F^):=(PQInt(B^.Ptr)^);
            VT_FLO:
               (F^):=(PFloat(B^.Ptr)^);
            VT_STR:
               (F^):=StrToReal(PStr(B^.Ptr)^);
            VT_ARR:
               (F^):=PArray(B^.Ptr)^.Count;
            VT_DIC:
               (F^):=PDict(B^.Ptr)^.Count;
            VT_BOO:
               (F^):=BoolToInt(PBool(B^.Ptr)^);
            else
               (F^):=0.0
         end end;
      VT_STR:
         begin
         S:=PStr(A^.Ptr);
         Case (B^.Typ) of
            VT_INT:
               (S^):=IntToStr(PQInt(B^.Ptr)^);
            VT_HEX:
               (S^):=HexToStr(PQInt(B^.Ptr)^);
            VT_OCT:
               (S^):=OctToStr(PQInt(B^.Ptr)^);
            VT_BIN:
               (S^):=BinToStr(PQInt(B^.Ptr)^);
            VT_FLO:
               (S^):=FloatToStr(PFloat(B^.Ptr)^);
            VT_STR:
               (S^):=(PStr(B^.Ptr)^);
            VT_ARR:
               (S^):=IntToStr(PArray(B^.Ptr)^.Count);
            VT_DIC:
               (S^):=IntToStr(PDict(B^.Ptr)^.Count);
            VT_BOO:
               If (PBoolean(B^.Ptr)^) then (S^):='TRUE' else (S^):='FALSE';
            else
               (S^):=''
         end end;
      VT_BOO: 
         begin
         L:=PBool(A^.Ptr);
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               (L^):=(PQInt(B^.Ptr)^<>0);
            VT_FLO:
               (L^):=(PFloat(B^.Ptr)^<>0);
            VT_STR:
               (L^):=StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_ARR:
               (L^):=(Not PArray(B^.Ptr)^.Empty);
            VT_DIC:
               (L^):=(Not PDict(B^.Ptr)^.Empty);
            VT_BOO:
               (L^):=(PBool(B^.Ptr)^);
            else
               (L^):=FALSE
         end end;
      VT_ARR: ValSet_Arr(A,B);
      VT_DIC: ValSet_Arr(A,B);
   end end;


Procedure ValAdd(A,B:PValue);
   Var  I:PQInt; S:PStr; L:PBoolean; F:PFloat;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I:=PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (I^)+=(PQInt(B^.Ptr)^);
            VT_FLO:
               (I^):=Trunc((I^)+(PFloat(B^.Ptr)^));
            VT_STR:
               (I^)+=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_BOO:
               If (PBool(B^.Ptr)^) then (I^)+=1;
            VT_ARR:
               (I^)+=PArr(B^.Ptr)^.Count;
            VT_DIC:
               (I^)+=PDict(B^.Ptr)^.Count;
         end end;
      VT_FLO:
         begin
         F:=PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (F^)+=(PQInt(B^.Ptr)^);
            VT_FLO:
               (F^)+=(PFloat(B^.Ptr)^);
            VT_STR:
               (F^)+=StrToReal(PStr(B^.Ptr)^);
            VT_BOO:
               If (PBool(B^.Ptr)^) then (F^)+=1;
            VT_ARR:
               (F^)+=PArr(B^.Ptr)^.Count;
            VT_DIC:
               (F^)+=PDict(B^.Ptr)^.Count;
         end end;
      VT_STR:
         begin
         S:=PStr(A^.Ptr);
         Case (B^.Typ) of
            VT_INT:
               (S^)+=IntToStr(PQInt(B^.Ptr)^);
            VT_HEX:
               (S^)+=HexToStr(PQInt(B^.Ptr)^);
            VT_OCT:
               (S^)+=OctToStr(PQInt(B^.Ptr)^);
            VT_BIN:
               (S^)+=BinToStr(PQInt(B^.Ptr)^);
            VT_FLO:
               (S^)+=FloatToStr(PFloat(B^.Ptr)^);
            VT_STR:
               (S^)+=(PStr(B^.Ptr)^);
            VT_BOO:
               If (PBool(B^.Ptr)^) then (S^)+='TRUE' else (S^)+='FALSE'
         end end;
      VT_BOO:
         begin
         L:=PBool(A^.Ptr);
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               (L^):=(L^) or (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               (L^):=(L^) or (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               (L^):=(L^) or StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_BOO:
               (L^):=(L^) or (PBool(B^.Ptr)^);
            VT_ARR:
               (L^):=(L^) or (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               (L^):=(L^) or (Not PDict(B^.Ptr)^.Empty);
         end end;
   end end;


Procedure ValSub(A,B:PValue);
   Var  I:PQInt; L:PBoolean; F:PFloat;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I:=PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (I^)-=(PQInt(B^.Ptr)^);
            VT_FLO:
               (I^):=Trunc((I^)-(PFloat(B^.Ptr)^));
            VT_STR:
               (I^)-=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_BOO:
               If (PBool(B^.Ptr)^) then (I^)-=1;
            VT_ARR:
               (I^)-=PArr(B^.Ptr)^.Count;
            VT_DIC:
               (I^)-=PDict(B^.Ptr)^.Count;
         end end;
      VT_FLO:
         begin
         F:=PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (F^)-=(PQInt(B^.Ptr)^);
            VT_FLO:
               (F^)-=(PFloat(B^.Ptr)^);
            VT_STR:
               (F^)-=StrToReal(PStr(B^.Ptr)^);
            VT_BOO:
               If (PBool(B^.Ptr)^) then (F^)-=1;
            VT_ARR:
               (F^)-=PArr(B^.Ptr)^.Count;
            VT_DIC:
               (F^)-=PDict(B^.Ptr)^.Count;
         end end;
      VT_BOO:
         begin
         L:=PBool(A^.Ptr);
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               (L^):=(L^) xor (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               (L^):=(L^) xor (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               (L^):=(L^) xor StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_BOO:
               (L^):=(L^) xor (PBool(B^.Ptr)^);
            VT_ARR:
               (L^):=(L^) xor (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               (L^):=(L^) xor (Not PDict(B^.Ptr)^.Empty);
         end end;
   end end;


Procedure ValMul(A,B:PValue);
   Var  I:PQInt; S:PStr; L:PBoolean; F:PFloat; C,T,O:LongInt;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I:=PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (I^)*=(PQInt(B^.Ptr)^);
            VT_FLO:
               (I^):=Trunc((I^)*(PFloat(B^.Ptr)^));
            VT_STR:
               (I^)*=StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then (I^):=0;
            VT_ARR:
               (I^)*=PArr(B^.Ptr)^.Count;
            VT_DIC:
               (I^)*=PDict(B^.Ptr)^.Count;
            else
               (I^):=0
         end end;
      VT_FLO:
         begin
         F:=PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (F^)*=(PQInt(B^.Ptr)^);
            VT_FLO:
               (F^)*=(PFloat(B^.Ptr)^);
            VT_STR:
               (F^)*=StrToReal(PStr(B^.Ptr)^);
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then (F^):=0.0;
            VT_ARR:
               (F^)*=PArr(B^.Ptr)^.Count;
            VT_DIC:
               (F^)*=PDict(B^.Ptr)^.Count;
            else
               (F^):=0.0
         end end;
      VT_STR:
         begin
         S:=PStr(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               T:=(PQInt(B^.Ptr)^);
            VT_FLO:
               T:=Trunc(PFloat(B^.Ptr)^);
            VT_STR:
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
         If (T <= 0) then begin S^:=''; Exit() end;
         O := Length(S^); T *= O; SetLength(S^, T);
         For C:=(O+1) to T do S^[C] := S^[C-O]
         end;
      VT_BOO:
         begin
         L:=PBool(A^.Ptr);
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               (L^):=(L^) and (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               (L^):=(L^) and (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               (L^):=(L^) and StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_BOO:
               (L^):=(L^) and (PBool(B^.Ptr)^);
            VT_ARR:
               (L^):=(L^) and (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               (L^):=(L^) and (Not PDict(B^.Ptr)^.Empty);
         end end;
   end end;


Procedure ValDiv(A,B:PValue);
   Var  I:PQInt; L:PBoolean; F:PFloat; tI:QInt; tF:TFloat;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I:=PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^<>0) then (I^):=I^ div (PQInt(B^.Ptr)^)
                                      else (I^):=0;
            VT_FLO:
               If (PFloat(B^.Ptr)^<>0.0) then (I^):=Trunc((I^)/(PFloat(B^.Ptr)^))
                                         else (I^):=0;
            VT_STR:
               begin
               tI:=StrToNum(PStr(B^.Ptr)^,A^.Typ);
               If (tI<>0) then (I^):=(I^ div tI) else (I^):=0
               end;
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then (I^):=0;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty) then (I^):=I^ div PArr(B^.Ptr)^.Count
                                            else (I^):=0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty) then (I^):=I^ div PDict(B^.Ptr)^.Count
                                             else (I^):=0;
            else
               (I^):=0
         end end;
      VT_FLO:
         begin
         F:=PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^<>0) then (F^)/=(PQInt(B^.Ptr)^)
                                      else (F^):=0.0;
            VT_FLO:
               If (PFloat(B^.Ptr)^<>0.0) then (F^)/=(PFloat(B^.Ptr)^)
                                         else (F^):=0.0;
            VT_STR:
               begin
               tF:=StrToReal(PStr(B^.Ptr)^);
               If (tF<>0.0) then (F^)/=tF else (F^):=0.0
               end;
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then (F^):=0.0;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty) then (F^)/=PArr(B^.Ptr)^.Count
                                            else (F^):=0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty) then (F^)/=PDict(B^.Ptr)^.Count
                                             else (F^):=0;
            else
               (F^):=0.0
         end end;
      VT_BOO:
         begin
         L:=PBool(A^.Ptr);
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               (L^):=(L^) xor (PQInt(B^.Ptr)^<>0);
            VT_FLO:
               (L^):=(L^) xor (Abs(PFloat(B^.Ptr)^)>=1.0);
            VT_STR:
               (L^):=(L^) xor StrToBoolDef(PStr(B^.Ptr)^,FALSE);
            VT_BOO:
               (L^):=(L^) xor (PBool(B^.Ptr)^);
            VT_ARR:
               (L^):=(L^) xor (Not PArr(B^.Ptr)^.Empty);
            VT_DIC:
               (L^):=(L^) xor (Not PDict(B^.Ptr)^.Empty);
         end end;
   end end;


Procedure ValMod(A,B:PValue);
   Var  I:PQInt; F:PFloat; tF:TFloat;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I:=PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (I^):=I^ mod (PQInt(B^.Ptr)^);
            VT_FLO:
               begin
               tF:=I^; While (tF > PFloat(B^.Ptr)^) do tF -= PFloat(B^.Ptr)^;
               (I^):=Trunc(tF)
               end;
            VT_STR:
               (I^):=I^ mod StrToNum(PStr(B^.Ptr)^,A^.Typ);
            VT_ARR:
               (I^):=I^ mod PArr(B^.Ptr)^.Count;
            VT_DIC:
               (I^):=I^ mod PDict(B^.Ptr)^.Count;
            else
               (I^):=0
         end end;
      VT_FLO:
         begin
         F:=PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               While (F^ > PQInt(B^.Ptr)^) do (F^)-=PQInt(B^.Ptr)^;
            VT_FLO:
               While (F^ > PFloat(B^.Ptr)^) do (F^)-=PFloat(B^.Ptr)^;
            VT_STR:
               begin
               tF:=StrToReal(PStr(B^.Ptr)^);
               While (F^ > tF) do (F^)-=tF
               end;
            VT_ARR:
               While (F^ > PArr(B^.Ptr)^.Count) do (F^)-=PArr(B^.Ptr)^.Count;
            VT_DIC:
               While (F^ > PDict(B^.Ptr)^.Count) do (F^)-=PDict(B^.Ptr)^.Count;
            else
               (F^):=0.0
         end end;
   end end;


Procedure ValPow(A,B:PValue);
   Var  I:PQInt; F:PFloat; 
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I:=PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (I^):=Trunc(IntPower(I^, PQInt(B^.Ptr)^));
            VT_FLO:
               (I^):=Trunc(Power(I^, PFloat(B^.Ptr)^));
            VT_STR:
               (I^):=Trunc(IntPower(I^, StrToNum(PStr(B^.Ptr)^,A^.Typ)));
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then (I^):=1;
            VT_ARR:
               (I^):=Trunc(IntPower(I^, PArr(B^.Ptr)^.Count));
            VT_DIC:
               (I^):=Trunc(IntPower(I^, PDict(B^.Ptr)^.Count));
            else
               (I^):=1
         end end;
      VT_FLO:
         begin
         F:=PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               (F^):=IntPower(F^, PQInt(B^.Ptr)^);
            VT_FLO:
               (F^):=Power(F^, PFloat(B^.Ptr)^);
            VT_STR:
               (F^):=Power(F^, StrToReal(PStr(B^.Ptr)^));
            VT_BOO:
               If (Not PBool(B^.Ptr)^) then (F^):=1.0;
            VT_ARR:
               (F^):=Power(F^, PArr(B^.Ptr)^.Count);
            VT_DIC:
               (F^):=Power(F^, PDict(B^.Ptr)^.Count);
            else
               (F^):=1.0
         end end;
   end end;

end.
