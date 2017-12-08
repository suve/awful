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
   uses SysUtils, Math, Convert, Values_Typecast;

Procedure ValSet_ArrDict(Const A,B:PValue);
   Var AEntA,BEntA:Values.TArray.TEntryArr;
       AEntD,BEntD:TDict.TEntryArr;
       iA, iB, kI : QInt; kS:TStr;
   begin
   Case (A^.Typ) of
         VT_ARR: begin
            AEntA := A^.Arr^.ToArray();
            Case (B^.Typ) of
            
               VT_ARR: begin
                  BEntA := B^.Arr^.ToArray();
                  iA := 0; iB := 0;
                  While (iA < Length(AEntA)) and (iB < Length(BEntA)) do
                     Case CompareValue(AEntA[iA].Key, BEntA[iB].Key) of
                        -1: iA += 1;
                         0: begin ValSet(AEntA[iA].Val, BEntA[iB].Val); iA += 1; iB += 1 end;
                        +1: begin A^.Arr^.SetVal(BEntA[iB].Key, CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1 end
                     end;
                  While (iB < Length(BEntA)) do begin
                     A^.Arr^.SetVal(BEntA[iB].Key, CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1
                  end
               end;
               
               VT_DICT:
                  begin
                  BEntD := B^.Dic^.ToArray();
                  iA := 0; iB := 0;
                  While (iA < Length(AEntA)) and (iB < Length(BEntD)) do begin
                     kI:=StrToInt(BEntD[iB].Key);
                     Case CompareValue(AEntA[iA].Key, kI) of
                        -1: iA += 1;
                         0: begin ValSet(AEntA[iA].Val, BEntD[iB].Val); iA += 1; iB += 1 end;
                        +1: begin A^.Arr^.SetVal(kI, CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1 end
                  end end;
                  While (iB < Length(BEntD)) do begin
                     A^.Arr^.SetVal(StrToInt(BEntD[iB].Key), CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1
                  end
               end
               
               else begin
                  iA := 0;
                  While (iA < Length(AEntA)) do begin
                     ValSet(AEntA[iA].Val, B);
                     iA += 1
                  end end
         end end;
         
         VT_DIC: begin
            AEntD := A^.Dic^.ToArray();
            Case (B^.Typ) of
            
               VT_ARR: begin
                  BEntA := B^.Arr^.ToArray();
                  iA := 0; iB := 0;
                  While (iA < Length(AEntD)) and (iB < Length(BEntA)) do begin
                     kS:=IntToStr(BEntA[iB].Key);
                     Case CompareStr(AEntD[iA].Key, kS) of
                        -1: iA += 1;
                         0: begin ValSet(AEntD[iA].Val, BEntA[iB].Val); iA += 1; iB += 1 end;
                        +1: begin A^.Dic^.SetVal(kS, CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1 end
                  end end;
                  While (iB < Length(BEntA)) do begin
                     A^.Dic^.SetVal(IntToStr(BEntA[iB].Key), CopyVal(BEntA[iB].Val, A^.Lev)); iB += 1
                  end
               end;
               
               VT_DICT: begin
                  BEntD := B^.Dic^.ToArray();
                  iA := 0; iB := 0;
                  While (iA < Length(AEntD)) and (iB < Length(BEntD)) do
                     Case CompareStr(AEntD[iA].Key, BEntD[iB].Key) of
                        -1: iA += 1;
                         0: begin ValSet(AEntD[iA].Val, BEntD[iB].Val); iA += 1; iB += 1 end;
                        +1: begin A^.Dic^.SetVal(BEntD[iB].Key, CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1 end
                        end;
                  While (iB < Length(BEntD)) do begin
                     A^.Dic^.SetVal(BEntD[iB].Key, CopyVal(BEntD[iB].Val, A^.Lev)); iB += 1
                  end
               end
               
               else begin
                  iA := 0;
                  While (iA < Length(AEntD)) do begin
                     ValSet(AEntD[iA].Val, B);
                     iA += 1
               end end
         end end
   end end;

Type TArithProc = Procedure(Const A,B:PValue);

Procedure ValArith_ArrDict(Const Proc:TArithProc; Const A,B:PValue);
   Var EntA:Values.TArray.TEntryArr; EntD:TDict.TEntryArr;
       idx, kI : QInt; kS : AnsiString;
   begin
   idx := 0;
   Case (A^.Typ) of
   
      VT_ARR: begin
         EntA := A^.Arr^.ToArray();
         Case (B^.Typ) of
            
            VT_ARR: begin
               While (idx < Length(EntA)) do begin
                  If (B^.Arr^.IsVal(EntA[idx].Key))
                     then Proc(EntA[idx].Val, B^.Arr^.GetVal(EntA[idx].Key));
                  idx += 1
            end end;
               
            VT_DIC: begin
               While (idx < Length(EntA)) do begin
                  kS := IntToStr(EntA[idx].Key);
                  If (B^.Dic^.IsVal(kS))
                     then Proc(EntA[idx].Val, B^.Dic^.GetVal(kS));
                  idx += 1
            end end
               
            else begin
               While (idx < Length(EntA)) do begin
                  Proc(EntA[idx].Val, B);
                  idx += 1
            end end
      end end;
      
      VT_DIC: begin
         EntD := A^.Dic^.ToArray();
         Case (B^.Typ) of
         
            VT_ARR: begin
               While (idx < Length(EntD)) do begin
                  kI := StrToInt(EntD[idx].Key);
                  If (B^.Arr^.IsVal(kI))
                     then Proc(EntD[idx].Val, B^.Arr^.GetVal(kI));
                  idx += 1
            end end;
            
            VT_DIC: begin
               While (idx < Length(EntD)) do begin
                  If (B^.Dic^.IsVal(EntD[idx].Key))
                     then Proc(EntD[idx].Val, B^.Dic^.GetVal(EntD[idx].Key));
                  idx += 1
            end end
            
            else begin
               While (idx < Length(EntD)) do begin
                  Proc(EntD[idx].Val, B);
                  idx += 1
            end end
      end end
   end end;

Procedure ValSet_Chr(Const Ch:PCharRef;Const V:PValue);
   Var Len : LongInt; Nstr:TStr;
   begin
      // Index 0 is always invalid
      If(Ch^.Idx = 0) then Exit;
      
      // Retrieve referenced value stringlen (or abort if not a string)
      If(Ch^.Val^.Typ = VT_STR)
         then Len := Length(Ch^.Val^.Str^)
      else If(Ch^.Val^.Typ = VT_UTF)
         then Len := Ch^.Val^.Utf^.Len
      else Exit;
      
      // Check if index within bounds
      If(Ch^.Idx > 0) then begin
         If(Ch^.Idx > Len) then Exit;
         Len := Ch^.Idx
      end else begin
         Len := Len + 1 + Ch^.Idx;
         If(Len < 1) then Exit
      end;
      
      // Modify referenced character
      If(Ch^.Val^.Typ = VT_STR) then begin
         Nstr := ValAsStr(V);
         If(Length(Nstr) > 0)
            then Ch^.Val^.Str^[Len] := Nstr[1]
      end else begin
         // For UTF-8 strings, we want to copy whole codepoint istead of just first byte
         If(V^.Typ = VT_UTF) then begin
            If(V^.Utf^.Len > 0)
               then Ch^.Val^.Utf^.Char[Len] := V^.Utf^.Char[Len]
         end else begin
            Nstr := ValAsStr(V);
            If(Length(Nstr) > 0)
               then Ch^.Val^.Utf^.Char[Len] := Nstr[1]
         end
      end
   end;

Procedure ValSet(Const A,B:PValue);
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               A^.Int^:=B^.Int^;
            VT_FLO:
               A^.Int^:=Trunc(B^.Flo^);
            VT_STR:
               A^.Int^:=StrToNum(B^.Str^,A^.Typ);
            VT_UTF:
               A^.Int^:=B^.Utf^.ToInt(IntBase(A^.Typ));
            VT_CHR:
               A^.Int^:=StrToNum(GetRefdChar(B^.Chr),A^.Typ);
            VT_ARR:
               A^.Int^:=PArray(B^.Ptr)^.Count;
            VT_DIC:
               A^.Int^:=B^.Dic^.Count;
            VT_BOO:
               A^.Int^:=BoolToInt(B^.Boo^);
            else
               A^.Int^:= 0
         end;
      VT_FLO: 
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               A^.Flo^:=B^.Int^;
            VT_FLO:
               A^.Flo^:=B^.Flo^;
            VT_STR:
               A^.Flo^:=StrToReal(B^.Str^);
            VT_UTF:
               A^.Flo^:=B^.Utf^.ToFloat();
            VT_CHR:
               A^.Flo^:=StrToReal(GetRefdChar(B^.Chr));
            VT_ARR:
               A^.Flo^:=B^.Arr^.Count;
            VT_DIC:
               A^.Flo^:=B^.Dic^.Count;
            VT_BOO:
               A^.Flo^:=BoolToInt(B^.Boo^);
            else
               A^.Flo^:=0.0
         end;
      VT_STR:
         Case (B^.Typ) of
            VT_INT:
               A^.Str^:=IntToStr(B^.Int^);
            VT_HEX:
               A^.Str^:=HexToStr(B^.Int^);
            VT_OCT:
               A^.Str^:=OctToStr(B^.Int^);
            VT_BIN:
               A^.Str^:=BinToStr(B^.Int^);
            VT_FLO:
               A^.Str^:=FloatToStr(B^.Flo^);
            VT_STR:
               A^.Str^:=B^.Str^;
            VT_UTF:
               A^.Str^:=B^.Utf^.ToAnsiString();
            VT_CHR:
               A^.Str^:=GetRefdChar(B^.Chr);
            VT_ARR:
               A^.Str^:=IntToStr(B^.Arr^.Count);
            VT_DIC:
               A^.Str^:=IntToStr(B^.Dic^.Count);
            VT_BOO:
               If (B^.Boo^) then A^.Str^:='TRUE' else A^.Str^:='FALSE';
            else
               A^.Str^:=''
         end;
      VT_UTF:
         Case (B^.Typ) of
            VT_INT:
               A^.Utf^.SetTo(IntToStr(B^.Int^));
            VT_HEX:
               A^.Utf^.SetTo(HexToStr(B^.Int^));
            VT_OCT:
               A^.Utf^.SetTo(OctToStr(B^.Int^));
            VT_BIN:
               A^.Utf^.SetTo(BinToStr(B^.Int^));
            VT_FLO:
               A^.Utf^.SetTo(FloatToStr(B^.Flo^));
            VT_STR:
               A^.Utf^.SetTo(B^.Str^);
            VT_UTF:
               A^.Utf^.SetTo(B^.Utf);
            VT_CHR:
               A^.Utf^.SetTo(GetRefdChar(B^.Chr));
            VT_ARR:
               A^.Utf^.SetTo(IntToStr(B^.Arr^.Count));
            VT_DIC:
               A^.Utf^.SetTo(IntToStr(B^.Dic^.Count));
            VT_BOO:
               If (B^.Boo^) then A^.Utf^.SetTo('TRUE') else A^.Utf^.SetTo('FALSE');
            else
               A^.Utf^.Clear()
         end;
      VT_CHR: ValSet_Chr(A^.Chr,B);
      VT_BOO: 
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               A^.Boo^:=(B^.Int^<>0);
            VT_FLO:
               A^.Boo^:=(Abs(B^.Flo^)>=1.0);
            VT_STR:
               A^.Boo^:=StrToBoolDef(B^.Str^,FALSE);
            VT_UTF:
               A^.Boo^:=StrToBoolDef(B^.Utf^.ToAnsiString(),FALSE);
            VT_CHR:
               A^.Boo^:=StrToBoolDef(GetRefdChar(B^.Chr),FALSE);
            VT_ARR:
               A^.Boo^:=(Not B^.Arr^.Empty);
            VT_DIC:
               A^.Boo^:=(Not B^.Dic^.Empty);
            VT_BOO:
               A^.Boo^:=B^.Boo^;
            else
               A^.Boo^:=FALSE
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
               A^.Int^+=B^.Int^;
            VT_FLO:
               A^.Int^:=Trunc(A^.Int^+B^.Flo^);
            VT_STR:
               A^.Int^+=StrToNum(B^.Str^,A^.Typ);
            VT_UTF:
               A^.Int^+=B^.Utf^.ToInt(IntBase(A^.Typ));
            VT_CHR:
               A^.Int^+=StrToNum(GetRefdChar(B^.Chr),A^.Typ);
            VT_BOO:
               If B^.Boo^ then A^.Int^+=1;
            VT_ARR:
               A^.Int^+=B^.Arr^.Count;
            VT_DIC:
               A^.Int^+=B^.Dic^.Count;
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               A^.Flo^+=B^.Int^;
            VT_FLO:
               A^.Flo^+=B^.Flo^;
            VT_STR:
               A^.Flo^+=StrToReal(B^.Str^);
            VT_UTF:
               A^.Flo^+=B^.Utf^.ToFloat();
            VT_CHR:
               A^.Flo^+=StrToReal(GetRefdChar(B^.Chr));
            VT_BOO:
               If B^.Boo^ then A^.Flo^+=1;
            VT_ARR:
               A^.Flo^+=B^.Arr^.Count;
            VT_DIC:
               A^.Flo^+=B^.Dic^.Count;
         end;
      VT_STR:
         Case (B^.Typ) of
            VT_INT:
               A^.Str^+=IntToStr(B^.Int^);
            VT_HEX:
               A^.Str^+=HexToStr(B^.Int^);
            VT_OCT:
               A^.Str^+=OctToStr(B^.Int^);
            VT_BIN:
               A^.Str^+=BinToStr(B^.Int^);
            VT_FLO:
               A^.Str^+=FloatToStr(B^.Flo^);
            VT_STR:
               A^.Str^+=B^.Str^;
            VT_UTF:
               A^.Str^+=B^.Utf^.ToAnsiString();
            VT_CHR:
               A^.Str^+=GetRefdChar(B^.Chr);
            VT_BOO:
               If B^.Boo^ then A^.Str^+='TRUE' else A^.Str^+='FALSE'
         end;
      VT_UTF:
         Case (B^.Typ) of
            VT_INT:
               A^.Utf^.Append(IntToStr(B^.Int^));
            VT_HEX:
               A^.Utf^.Append(HexToStr(B^.Int^));
            VT_OCT:
               A^.Utf^.Append(OctToStr(B^.Int^));
            VT_BIN:
               A^.Utf^.Append(BinToStr(B^.Int^));
            VT_FLO:
               A^.Utf^.Append(FloatToStr(B^.Flo^));
            VT_STR:
               A^.Utf^.Append(B^.Str^);
            VT_UTF:
               A^.Utf^.Append(B^.Utf);
            VT_CHR:
               A^.Utf^.Append(GetRefdChar(B^.Chr));
            VT_ARR:
               A^.Utf^.Append(IntToStr(B^.Arr^.Count));
            VT_DIC:
               A^.Utf^.Append(IntToStr(B^.Dic^.Count));
            VT_BOO:
               If (B^.Boo^) then A^.Utf^.Append('TRUE') else A^.Utf^.Append('FALSE');
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               A^.Boo^:=A^.Boo^ or (B^.Int^<>0);
            VT_FLO:
               A^.Boo^:=A^.Boo^ or (Abs(B^.Flo^)>=1.0);
            VT_STR:
               A^.Boo^:=A^.Boo^ or StrToBoolDef(B^.Str^,FALSE);
            VT_UTF:
               A^.Boo^:=A^.Boo^ or StrToBoolDef(B^.Utf^.ToAnsiString(),FALSE);
            VT_CHR:
               A^.Boo^:=A^.Boo^ or StrToBoolDef(GetRefdChar(B^.Chr),FALSE);
            VT_BOO:
               A^.Boo^:=A^.Boo^ or B^.Boo^;
            VT_ARR:
               A^.Boo^:=A^.Boo^ or (Not B^.Arr^.Empty);
            VT_DIC:
               A^.Boo^:=A^.Boo^ or (Not B^.Dic^.Empty);
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
               A^.Int^-=B^.Int^;
            VT_FLO:
               A^.Int^:=Trunc(A^.Int^-B^.Flo^);
            VT_STR:
               A^.Int^-=StrToNum(B^.Str^,A^.Typ);
            VT_UTF:
               A^.Int^-=B^.Utf^.ToInt(IntBase(A^.Typ));
            VT_CHR:
               A^.Int^-=StrToNum(GetRefdChar(B^.Chr),A^.Typ);
            VT_BOO:
               If B^.Boo^ then A^.Int^-=1;
            VT_ARR:
               A^.Int^-=B^.Arr^.Count;
            VT_DIC:
               A^.Int^-=B^.Dic^.Count;
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               A^.Flo^-=B^.Int^;
            VT_FLO:
               A^.Flo^-=B^.Flo^;
            VT_STR:
               A^.Flo^-=StrToReal(B^.Str^);
            VT_UTF:
               A^.Flo^-=B^.Utf^.ToFloat();
            VT_CHR:
               A^.Flo^-=StrToReal(GetRefdChar(B^.Chr));
            VT_BOO:
               If B^.Boo^ then A^.Flo^-=1;
            VT_ARR:
               A^.Flo^-=B^.Arr^.Count;
            VT_DIC:
               A^.Flo^-=B^.Dic^.Count;
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               A^.Boo^:=A^.Boo^ xor (B^.Int^<>0);
            VT_FLO:
               A^.Boo^:=A^.Boo^ xor (Abs(B^.Flo^)>=1.0);
            VT_STR:
               A^.Boo^:=A^.Boo^ xor StrToBoolDef(B^.Str^,FALSE);
            VT_UTF:
               A^.Boo^:=A^.Boo^ xor StrToBoolDef(B^.Utf^.ToAnsiString,FALSE);
            VT_CHR:
               A^.Boo^:=A^.Boo^ xor StrToBoolDef(GetRefdChar(B^.Chr),FALSE);
            VT_BOO:
               A^.Boo^:=A^.Boo^ xor B^.Boo^;
            VT_ARR:
               A^.Boo^:=A^.Boo^ xor (Not B^.Arr^.Empty);
            VT_DIC:
               A^.Boo^:=A^.Boo^ xor (Not B^.Dic^.Empty);
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
               A^.Int^*=B^.Int^;
            VT_FLO:
               A^.Int^:=Trunc(A^.Int^*B^.Flo^);
            VT_STR:
               A^.Int^*=StrToNum(B^.Str^,A^.Typ);
            VT_UTF:
               A^.Int^*=B^.Utf^.ToInt(IntBase(A^.Typ));
            VT_CHR:
               A^.Int^*=StrToNum(GetRefdChar(B^.Chr),A^.Typ);
            VT_BOO:
               If (Not B^.Boo^) then A^.Int^:=0;
            VT_ARR:
               A^.Int^*=B^.Arr^.Count;
            VT_DIC:
               A^.Int^*=B^.Dic^.Count;
            else
               A^.Int^:=0
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               A^.Flo^*=B^.Int^;
            VT_FLO:
               A^.Flo^*=B^.Flo^;
            VT_STR:
               A^.Flo^*=StrToReal(B^.Str^);
            VT_UTF:
               A^.Flo^*=B^.Utf^.ToFloat();
            VT_CHR:
               A^.Flo^*=StrToReal(GetRefdChar(B^.Chr));
            VT_BOO:
               If (Not B^.Boo^) then A^.Flo^:=0.0;
            VT_ARR:
               A^.Flo^*=B^.Arr^.Count;
            VT_DIC:
               A^.Flo^*=B^.Dic^.Count;
            else
               A^.Flo^:=0.0
         end;
      VT_STR:
         begin
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               T:=B^.Int^;
            VT_FLO:
               T:=Trunc(B^.Flo^);
            VT_STR:
               Exit();
            VT_UTF:
               Exit();
            VT_CHR:
               Exit();
            VT_BOO:
               T:=BoolToInt(B^.Boo^);
            VT_ARR:
               T:=B^.Arr^.Count;
            VT_DIC:
               T:=B^.Dic^.Count;
            else 
               T:=0
            end;
         If (T <= 0) then begin A^.Str^:=''; Exit() end;
         O := Length(A^.Str^); T *= O; SetLength(A^.Str^, T);
         For C:=(O+1) to T do A^.Str^[C] := A^.Str^[C-O]
         end;
      VT_UTF:
         begin
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               T:=B^.Int^;
            VT_FLO:
               T:=Trunc(B^.Flo^);
            VT_STR:
               Exit();
            VT_UTF:
               Exit();
            VT_CHR:
               Exit();
            VT_BOO:
               T:=BoolToInt(B^.Boo^);
            VT_ARR:
               T:=B^.Arr^.Count;
            VT_DIC:
               T:=B^.Dic^.Count;
            else 
               T:=0
            end;
         If (T <= 0) then A^.Utf^.Clear()
                     else A^.Utf^.Multiply(T)
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               A^.Boo^:=A^.Boo^ and (B^.Int^<>0);
            VT_FLO:
               A^.Boo^:=A^.Boo^ and (Abs(B^.Flo^)>=1.0);
            VT_STR:
               A^.Boo^:=A^.Boo^ and StrToBoolDef(B^.Str^,FALSE);
            VT_UTF:
               A^.Boo^:=A^.Boo^ and StrToBoolDef(B^.Utf^.ToAnsiString,FALSE);
            VT_CHR:
               A^.Boo^:=A^.Boo^ and StrToBoolDef(GetRefdChar(B^.Chr),FALSE);
            VT_BOO:
               A^.Boo^:=A^.Boo^ and B^.Boo^;
            VT_ARR:
               A^.Boo^:=A^.Boo^ and (Not B^.Arr^.Empty);
            VT_DIC:
               A^.Boo^:=A^.Boo^ and (Not B^.Dic^.Empty);
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
               If (B^.Int^<>0)
                  then A^.Int^:=A^.Int^ div B^.Int^
                  else A^.Int^:=0;
            
            VT_FLO:
               If (B^.Flo^<>0.0)
                  then A^.Int^:=Trunc(A^.Int^/B^.Flo^)
                  else A^.Int^:=0;
            
            VT_STR: begin
               tI:=StrToNum(B^.Str^,A^.Typ);
               If (tI<>0) then A^.Int^:=(A^.Int^ div tI) else A^.Int^:=0
            end;
            
            VT_UTF: begin
               tI:=B^.Utf^.ToInt(IntBase(A^.Typ));
               If (tI<>0) then A^.Int^:=(A^.Int^ div tI) else A^.Int^:=0
            end;
            
            VT_CHR: begin
               tI:=StrToNum(GetRefdChar(B^.Chr),A^.Typ);
               If (tI<>0) then A^.Int^:=(A^.Int^ div tI) else A^.Int^:=0
            end;
            
            VT_BOO:
               If (Not B^.Boo^) then A^.Int^:=0;
               
            VT_ARR:
               If (Not B^.Arr^.Empty)
                  then A^.Int^:=A^.Int^ div B^.Arr^.Count
                  else A^.Int^:=0;
            
            VT_DIC:
               If (Not B^.Dic^.Empty)
                  then A^.Int^:=A^.Int^ div B^.Dic^.Count
                  else A^.Int^:=0;
            
            else
               A^.Int^:=0
         end;
      VT_FLO:
         Case (B^.Typ) of
         
            VT_INT .. VT_BIN: 
               If (B^.Int^<>0)
                  then A^.Flo^/=B^.Int^
                  else A^.Flo^:=0.0;
            
            VT_FLO:
               If (B^.Flo^<>0.0)
                  then A^.Flo^/=B^.Flo^
                  else A^.Flo^:=0.0;
            
            VT_STR: begin
               tF:=StrToReal(B^.Str^);
               If (tF<>0.0) then A^.Flo^/=tF else A^.Flo^:=0.0
            end;
            
            VT_UTF: begin
               tF:=B^.Utf^.ToFloat();
               If (tF<>0.0) then A^.Flo^/=tF else A^.Flo^:=0.0
            end;
            
            VT_CHR: begin
               tF:=StrToReal(GetRefdChar(B^.Chr));
               If (tF<>0.0) then A^.Flo^/=tF else A^.Flo^:=0.0
            end;
            
            VT_BOO:
               If (Not B^.Boo^) then A^.Flo^:=0.0;
            
            VT_ARR:
               If (Not B^.Arr^.Empty)
                  then A^.Flo^/=B^.Arr^.Count
                  else A^.Flo^:=0;
            
            VT_DIC:
               If (Not B^.Dic^.Empty)
                  then A^.Flo^/=B^.Dic^.Count
                   else A^.Flo^:=0;
            
            else
               A^.Flo^:=0.0
         end;
      VT_BOO:
         Case (B^.Typ) of 
            VT_INT .. VT_BIN: 
               A^.Boo^:=A^.Boo^ xor (B^.Int^<>0);
            VT_FLO:
               A^.Boo^:=A^.Boo^ xor (Abs(B^.Flo^)>=1.0);
            VT_STR:
               A^.Boo^:=A^.Boo^ xor StrToBoolDef(B^.Str^,FALSE);
            VT_UTF:
               A^.Boo^:=A^.Boo^ xor StrToBoolDef(B^.Utf^.ToAnsiString(),FALSE);
            VT_CHR:
               A^.Boo^:=A^.Boo^ xor StrToBoolDef(GetRefdChar(B^.Chr),FALSE);
            VT_BOO:
               A^.Boo^:=A^.Boo^ xor B^.Boo^;
            VT_ARR:
               A^.Boo^:=A^.Boo^ xor (Not B^.Arr^.Empty);
            VT_DIC:
               A^.Boo^:=A^.Boo^ xor (Not B^.Dic^.Empty);
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
               If (B^.Int^ <> 0)
                  then A^.Int^:=A^.Int^ mod B^.Int^
                  else A^.Int^:=0;
            VT_FLO:
               If (B^.Flo^ <> 0.0)
                  then A^.Int^:=A^.Int^ - Trunc(Trunc(A^.Int^ / B^.Flo^) * B^.Flo^)
                  else A^.Int^:=0;
            VT_STR: begin
               tI:=StrToNum(B^.Str^,A^.Typ);
               If (tI <> 0) then A^.Int^:=A^.Int^ mod tI
                            else A^.Int^:=0
            end;
            VT_UTF: begin
               tI:=B^.Utf^.ToInt(IntBase(A^.Typ));
               If (tI <> 0) then A^.Int^:=A^.Int^ mod tI
                            else A^.Int^:=0
            end;
            VT_CHR: begin
               tI:=StrToNum(GetRefdChar(B^.Chr),A^.Typ);
               If (tI <> 0) then A^.Int^:=A^.Int^ mod tI
                            else A^.Int^:=0
            end;
            VT_ARR:
               If (Not B^.Arr^.Empty)
                  then A^.Int^:=A^.Int^ mod B^.Arr^.Count
                  else A^.Int^:=0;
            VT_DIC:
               If (Not B^.Dic^.Empty)
                  then A^.Int^:=A^.Int^ mod B^.Dic^.Count
                  else A^.Int^:=0
            else
               A^.Int^:=0
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               If (B^.Int^ <> 0) 
                  then A^.Flo^:=A^.Flo^ - (Trunc(A^.Flo^ / B^.Int^)*B^.Int^)
                  else A^.Flo^:=0.0;
            VT_FLO:
               If (B^.Flo^ <> 0.0)
                  then A^.Flo^:=A^.Flo^ - (Trunc(A^.Flo^ / B^.Flo^)*B^.Flo^)
                  else A^.Flo^:=0.0;
            VT_STR: begin
               tF:=StrToReal(B^.Str^);
               If (tF <> 0.0) then A^.Flo^:=A^.Flo^ - (Trunc(A^.Flo^ / tF) * tF)
                              else A^.Flo^:=0.0
            end;
            VT_UTF: begin
               tF:=B^.Utf^.ToFloat();
               If (tF <> 0.0) then A^.Flo^:=A^.Flo^ - (Trunc(A^.Flo^ / tF) * tF)
                              else A^.Flo^:=0.0
            end;
            VT_CHR: begin
               tF:=StrToReal(GetRefdChar(B^.Chr));
               If (tF <> 0.0) then A^.Flo^:=A^.Flo^ - (Trunc(A^.Flo^ / tF) * tF)
                              else A^.Flo^:=0.0
            end;
            VT_ARR:
               If (Not B^.Arr^.Empty)
                  then A^.Flo^:=A^.Flo^ - (Trunc(A^.Flo^ / B^.Arr^.Count)*B^.Arr^.Count)
                  else A^.Flo^:=0.0;
            VT_DIC:
               If (Not B^.Dic^.Empty)
                  then A^.Flo^:=A^.Flo^ - (Trunc(A^.Flo^ / B^.Dic^.Count)*B^.Dic^.Count)
                  else A^.Flo^:=0.0
            else
               A^.Flo^:=0.0
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
               A^.Int^:=Trunc(IntPower(A^.Int^, B^.Int^));
            VT_FLO:
               A^.Int^:=Trunc(Power(A^.Int^, B^.Flo^));
            VT_STR:
               A^.Int^:=Trunc(IntPower(A^.Int^, StrToNum(B^.Str^,A^.Typ)));
            VT_UTF:
               A^.Int^:=Trunc(IntPower(A^.Int^, B^.Utf^.ToInt(IntBase(A^.Typ))));
            VT_CHR:
               A^.Int^:=Trunc(IntPower(A^.Int^, StrToNum(GetRefdChar(B^.Chr),A^.Typ)));
            VT_BOO:
               If (Not B^.Boo^) then A^.Int^:=1;
            VT_ARR:
               A^.Int^:=Trunc(IntPower(A^.Int^, B^.Arr^.Count));
            VT_DIC:
               A^.Int^:=Trunc(IntPower(A^.Int^, B^.Dic^.Count));
            else
               A^.Int^:=1
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN: 
               A^.Flo^:=IntPower(A^.Flo^, B^.Int^);
            VT_FLO:
               A^.Flo^:=Power(A^.Flo^, B^.Flo^);
            VT_STR:
               A^.Flo^:=Power(A^.Flo^, StrToReal(B^.Str^));
            VT_UTF:
               A^.Flo^:=Power(A^.Flo^, B^.Utf^.ToFloat());
            VT_CHR:
               A^.Flo^:=Power(A^.Flo^, StrToReal(GetRefdChar(B^.Chr)));
            VT_BOO:
               If (Not B^.Boo^) then A^.Flo^:=1.0;
            VT_ARR:
               A^.Flo^:=Power(A^.Flo^, B^.Arr^.Count);
            VT_DIC:
               A^.Flo^:=Power(A^.Flo^, B^.Dic^.Count);
            else
               A^.Flo^:=1.0
         end;
      VT_ARR: ValArith_ArrDict(@ValPow,A,B);
      VT_DIC: ValArith_ArrDict(@ValPow,A,B);
   end end;

end.
