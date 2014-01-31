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

Procedure ValSet_ArrDict(A,B:PValue);
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

Type TArithProc = Procedure(A,B:PValue);

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
               (L^):=(Abs(PFloat(B^.Ptr)^)>=1.0);
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
      VT_ARR: ValSet_ArrDict(A,B);
      VT_DIC: ValSet_ArrDict(A,B);
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
      VT_ARR: ValArith_ArrDict(@ValAdd,A,B);
      VT_DIC: ValArith_ArrDict(@ValAdd,A,B);
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
      VT_ARR: ValArith_ArrDict(@ValSub,A,B);
      VT_DIC: ValArith_ArrDict(@ValSub,A,B);
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
      VT_ARR: ValArith_ArrDict(@ValMul,A,B);
      VT_DIC: ValArith_ArrDict(@ValMul,A,B);
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
      VT_ARR: ValArith_ArrDict(@ValDiv,A,B);
      VT_DIC: ValArith_ArrDict(@ValDiv,A,B);
   end end;


Procedure ValMod(A,B:PValue);
   Var  I:PQInt; F:PFloat; tF:TFloat; tI:QInt;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         begin
         I:=PQInt(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^ <> 0)
                  then (I^):=I^ mod (PQInt(B^.Ptr)^)
                  else (I^):=0;
            VT_FLO:
               If (PFloat(B^.Ptr)^ <> 0.0)
                  then (I^):=I^ - Trunc(Trunc(I^ / PFloat(B^.Ptr)^) * PFloat(B^.Ptr)^)
                  else (I^):=0;
            VT_STR: begin
               tI:=StrToNum(PStr(B^.Ptr)^,A^.Typ);
               If (tI <> 0) then (I^):=I^ mod tI
                            else (I^):=0
               end;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty)
                  then (I^):=I^ mod PArr(B^.Ptr)^.Count
                  else (I^):=0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty)
                  then (I^):=I^ mod PDict(B^.Ptr)^.Count
                  else (I^):=0
            else
               (I^):=0
         end end;
      VT_FLO:
         begin
         F:=PFloat(A^.Ptr);
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (PQInt(B^.Ptr)^ <> 0) 
                  then (F^):=(F^) - (Trunc(F^ / PQInt(B^.Ptr)^)*PQInt(B^.Ptr)^)
                  else (F^):=0.0;
            VT_FLO:
               If (PFloat(B^.Ptr)^ <> 0.0)
                  then (F^):=(F^) - (Trunc(F^ / PFloat(B^.Ptr)^)*PFloat(B^.Ptr)^)
                  else (F^):=0.0;
            VT_STR:
               begin
               tF:=StrToReal(PStr(B^.Ptr)^);
               If (tF <> 0.0) then (F^):=(F^) - (Trunc(F^ / tF) * tF)
                              else (F^):=0.0
               end;
            VT_ARR:
               If (Not PArr(B^.Ptr)^.Empty)
                  then (F^):=(F^) - (Trunc(F^ / PArr(B^.Ptr)^.Count)*PArr(B^.Ptr)^.Count)
                  else (F^):=0.0;
            VT_DIC:
               If (Not PDict(B^.Ptr)^.Empty)
                  then (F^):=(F^) - (Trunc(F^ / PDict(B^.Ptr)^.Count)*PDict(B^.Ptr)^.Count)
                  else (F^):=0.0
            else
               (F^):=0.0
         end end;
      VT_ARR: ValArith_ArrDict(@ValMod,A,B);
      VT_DIC: ValArith_ArrDict(@ValMod,A,B);
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
      VT_ARR: ValArith_ArrDict(@ValPow,A,B);
      VT_DIC: ValArith_ArrDict(@ValPow,A,B);
   end end;

end.
