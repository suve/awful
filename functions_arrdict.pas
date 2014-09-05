unit functions_arrdict;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_array(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_array_count(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_empty(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_array_qsort(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_array_min(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_max(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_array_intSum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_fltSum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_array_contains_eq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_contains_seq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_array_flush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_print(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_dict_nextkey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_dict_keys(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_dict_values(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses Values_Compare, Values_Typecast,
        Convert, FileHandling,
        EmptyFunc, Globals;

Type TCompareFunc = Function(Const A,B:PValue):Boolean;

Procedure Register(Const FT:PFunTrie);
   begin
   // array functions, bitches!
   FT^.SetVal('arr',MkFunc(@F_array));
   FT^.SetVal('arr-min',MkFunc(@F_array_min));
   FT^.SetVal('arr-max',MkFunc(@F_array_max));
   FT^.SetVal('arr-qsort',MkFunc(@F_array_qsort,REF_MODIF));
   // dict funtions
   FT^.SetVal('dict',MkFunc(@F_dict));
   FT^.SetVal('dict-keys',MkFunc(@F_dict_keys));
   FT^.SetVal('dict-values',MkFunc(@F_dict_values));
   FT^.SetVal('dict-nextkey',MkFunc(@F_dict_nextkey));
   // arr+dic functions
   FT^.SetVal( 'arr-isum',MkFunc(@F_array_intSum));
   FT^.SetVal('dict-isum',MkFunc(@F_array_intSum));
   FT^.SetVal( 'arr-fsum',MkFunc(@F_array_fltSum));
   FT^.SetVal('dict-fsum',MkFunc(@F_array_fltSum));
   FT^.SetVal( 'arr-flush',MkFunc(@F_array_flush,REF_MODIF));
   FT^.SetVal('dict-flush',MkFunc(@F_array_flush,REF_MODIF));
   FT^.SetVal( 'arr-count',MkFunc(@F_array_count));
   FT^.SetVal('dict-count',MkFunc(@F_array_count));
   FT^.SetVal( 'arr-empty',MkFunc(@F_array_empty));
   FT^.SetVal('dict-empty',MkFunc(@F_array_empty));
   FT^.SetVal( 'arr-print',MkFunc(@F_array_print));
   FT^.SetVal('dict-print',MkFunc(@F_array_print));
   FT^.SetVal( 'arr-contains',MkFunc(@F_array_contains_eq));
   FT^.SetVal('dict-contains',MkFunc(@F_array_contains_eq));
   FT^.SetVal( 'arr-contains-seq',MkFunc(@F_array_contains_seq));
   FT^.SetVal('dict-contains-seq',MkFunc(@F_array_contains_seq));
   end;


Function F_array(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; T:PArray; A,V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   A:=EmptyVal(VT_ARR); T:=PArray(A^.Ptr);
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do begin
          If (Arg^[C]^.Lev >= CurLev)
             then V:=Arg^[C]
             else V:=CopyVal(Arg^[C]);
          T^.SetVal(C,V)
          end;
   Exit(A)
   end;

Function F_dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; T:PDict; Key:AnsiString; A,V,oV:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   A:=EmptyVal(VT_DIC); T:=PDict(A^.Ptr);
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If ((C mod 2)=0) then begin
             If (Arg^[C]^.Typ = VT_STR)
                then Key:=PStr(Arg^[C]^.Ptr)^
                else Key:=ValAsStr(Arg^[C]);
             If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
             end else begin
             If (Arg^[C]^.Lev >= CurLev)
                then V:=Arg^[C]
                else V:=CopyVal(Arg^[C]);
             If (T^.IsVal(Key)) then begin oV:=T^.GetVal(Key); FreeVal(oV) end;
                T^.SetVal(Key, V)
             end;
   If ((Length(Arg^) mod 2) = 1) then begin
      If (T^.IsVal(Key)) then begin oV:=T^.GetVal(Key); FreeVal(oV) end;
      T^.SetVal(Key, NilVal)
      end;
   Exit(A)
   end;

Function F_array_count(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,R:LongWord;
   begin R:=0;
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=High(Arg^) downto Low(Arg^) do begin
          If (Arg^[C]^.Typ = VT_ARR) then R += PArray(Arg^[C]^.Ptr)^.Count else
          If (Arg^[C]^.Typ = VT_DIC) then R += PDict(Arg^[C]^.Ptr)^.Count;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   Exit(NewVal(VT_INT,R))
   end;

Function F_array_empty(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C : LongWord; B:Boolean;
   begin B:=False;
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=High(Arg^) downto Low(Arg^) do begin
          If (Arg^[C]^.Typ = VT_ARR) then B:=(B or (PArray(Arg^[C]^.Ptr)^.Empty)) else
          If (Arg^[C]^.Typ = VT_DIC) then B:=(B or (PDict(Arg^[C]^.Ptr)^.Empty));
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_dict_nextkey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; T:PDict; K:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>=3) then
      For C:=High(Arg^) downto 2 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Length(Arg^)>=2) then begin
      If (Arg^[1]^.Typ = VT_STR)
         then K:=PStr(Arg^[1]^.Ptr)^
         else K:=ValAsStr(Arg^[1]);
      If (Arg^[1]^.Lev >= CurLev) then FreeVal(Arg^[1])
      end else K:='';
   If (Length(Arg^)>=1) then begin
      If (Arg^[0]^.Typ <> VT_DIC) then begin
         If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
         Exit(NilVal()) end;
      T:=PDict(Arg^[0]^.Ptr); K:=T^.NextKey(K);
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(NewVal(VT_STR,K))
      end;
   Exit(NilVal())
   end;

Function F_dict_keys(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,D,I:LongWord; R :PValue; Arr:PArray; Dic:PDict; DEA:TDict.TEntryArr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   R:=EmptyVal(VT_ARR); Arr:=PArray(R^.Ptr); I:=0;
   If (Length(Arg^)>0) then For C:=Low(Arg^) to High(Arg^) do begin
      If (Arg^[C]^.Typ = VT_DIC) then begin
         Dic := PDict(Arg^[C]^.Ptr); DEA := Dic^.ToArray();
         If (Not Dic^.Empty()) then
            For D:=Low(DEA) to High(DEA) do begin
                Arr^.SetVal(I, NewVal(VT_STR, DEA[D].Key));
                I += 1 end
         end;
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   Exit(R)
   end;

Function F_dict_values(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,D,I:LongWord; R :PValue; Arr:PArray; Dic:PDict; DEA:TDict.TEntryArr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   R:=EmptyVal(VT_ARR); Arr:=PArray(R^.Ptr); I:=0;
   If (Length(Arg^)>0) then For C:=Low(Arg^) to High(Arg^) do begin
      If (Arg^[C]^.Typ = VT_DIC) then begin
         Dic := PDict(Arg^[C]^.Ptr); DEA := Dic^.ToArray();
         If (Not Dic^.Empty()) then
            For D:=Low(DEA) to High(DEA) do begin
                Arr^.SetVal(I, CopyVal(DEA[D].Val));
                I += 1 end
         end;
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   Exit(R)
   end;

Function F_array_flush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,I,R:LongWord;
       Arr:PArray; AEA:TArray.TEntryArr;
       Dic:PDict; DEA:TDict.TEntryArr;
   begin R:=0;
   If (Length(Arg^)>0) then
      For C:=High(Arg^) downto Low(Arg^) do begin
          If (Arg^[C]^.Typ = VT_ARR) then begin
             Arr:=PArray(Arg^[C]^.Ptr); 
             If (Not Arr^.Empty()) then begin
                AEA:=Arr^.ToArray(); Arr^.Flush(); R += Length(AEA);
                For I:=Low(AEA) to High(AEA) do
                    FreeVal(AEA[I].Val)
             end end;
          If (Arg^[C]^.Typ = VT_DIC) then begin
             Dic:=PDict(Arg^[C]^.Ptr); 
             If (Not Dic^.Empty()) then begin
                DEA:=Dic^.ToArray(); Dic^.Flush(); R += Length(DEA);
                For I:=Low(DEA) to High(DEA) do
                    FreeVal(DEA[I].Val)
             end end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_INT,R)) else Exit(NIL)
   end;

Function F_array_contains(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Cmpr:TCompareFunc):PValue; Inline;
   Var C,I,Lo,Hi:LongInt; Cont:Array of TBool; Res:Boolean;
       Arr:PArray; AEA:TArray.TEntryArr;
       Dic:PDict; DEA:TDict.TEntryArr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) < 2) then begin
      F_(False, Arg); Exit(NewVal(VT_BOO, False))
      end;
   SetLength(Cont, Length(Arg^));
   For C:=1 to High(Arg^) do Cont[C]:=False;
   If (Arg^[0]^.Typ = VT_ARR) then begin
      Arr:=PArray(Arg^[0]^.Ptr); AEA:=Arr^.ToArray();
      Lo:=Low(AEA); Hi:=High(AEA);
      For C:=1 to High(Arg^) do
          For I:=Lo to Hi do 
              If (Cmpr(Arg^[C], AEA[I].Val)) then begin
                 Cont[C] := True; Break
                 end;
      end else
   If (Arg^[0]^.Typ = VT_DIC) then begin
      Dic:=PDict(Arg^[0]^.Ptr); DEA:=Dic^.ToArray();
      Lo:=Low(DEA); Hi:=High(DEA);
      For C:=1 to High(Arg^) do
          For I:=Lo to Hi do 
              If (Cmpr(Arg^[C], DEA[I].Val)) then begin
                 Cont[C] := True; Break
                 end;
      end;
   F_(False, Arg); Res := True;
   For C:=1 to High(Arg^) do Res := Res and Cont[C];
   Exit(NewVal(VT_BOO, Res))
   end;

Function F_array_contains_eq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_array_contains(DoReturn, Arg, @Values_Compare.ValEq)) end;

Function F_array_contains_seq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_array_contains(DoReturn, Arg, @Values_Compare.ValSeq)) end;

Function qsort(Var Arr:TArray.TEntryArr; Const Min,Max:QWord):QWord;
   Var Piv,Pos:QWord; pivval : PValue;
   begin
   Pos := Min; Piv := Max; pivval := Arr[Max].Val; Result := 0;
   While (Pos <> Piv) do
      If (ValGt(Arr[Pos].Val,pivval)) then begin
         Arr[Piv].Val := Arr[Pos].Val;
         Piv -= 1; Result += 3;
         Arr[Pos].Val := Arr[Piv].Val;
         Arr[Piv].Val := pivval
         end else Pos += 1;
   
   If ((Pos - Min) > 1) then Result += qsort(Arr,Min,Pos-1);
   If ((Max - Pos) > 1) then Result += qsort(Arr,Pos+1,Max)
   end;

Function F_array_qsort(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,I,Cnt:LongWord; Swp:QWord; Arr:PArray; Ent:TArray.TEntryArr;
   begin Swp := 0;
   If (Length(Arg^) > 0) then
      For C:=0 to High(Arg^) do begin
         If (Arg^[C]^.Typ = VT_ARR) then begin
            Arr := PArray(Arg^[C]^.Ptr);
            Cnt := Arr^.Count;
            If (Cnt > 0) then begin
               Ent := Arr^.ToArray();
               Swp += qsort(Ent,0,Cnt-1);
               For I:=0 to (Cnt-1) do
                  Arr^.SetVal(Ent[I].Key,Ent[I].Val)
               end end;
         If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
   If (DoReturn) then Exit(NewVal(VT_INT, Swp))
                 else Exit(NIL)
   end;

Function F_array_edgy(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Cmpr:TCompareFunc):PValue;
   
   Function Fork(Const Condition:Boolean; Const TrueVal,FalseVal:LongWord):LongWord; Inline;
      begin If (Condition) then Result:=TrueVal else Result:=FalseVal end;
   
   Var Ent:TArray.TEntryArr; C,I,Cnt:LongWord; V:PValue; Arr:PArray;
   begin 
   If (Not DoReturn) then Exit(F_(DoReturn, Arg)) else V := NIL;
   If (Length(Arg^) > 0) then
      For C:=0 to High(Arg^) do
         If (Arg^[C]^.Typ = VT_ARR) then begin
            Arr := PArray(Arg^[C]^.Ptr);
            Cnt := Arr^.Count;
            If (Cnt > 0) then begin
               Ent := Arr^.ToArray();
               If (V = NIL) then V:=Ent[0].Val;
               For I:=Fork(V=NIL,1,0) to (Cnt-1) do
                  If (Cmpr(Ent[I].Val,V)) then V:=Ent[I].Val
            end end;
   If (V <> NIL) then V := CopyVal(V); F_(False, Arg);
   Exit(V)
   end;

Function F_array_min(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_array_edgy(DoReturn, Arg, @ValLt)) end;
   
Function F_array_max(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_array_edgy(DoReturn, Arg, @ValGt)) end;

Function F_array_intSum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FPC_TYPE__   := QInt     }
   {$DEFINE __AWFUL_TYPE__ := VT_INT   }
   {$DEFINE __CAST_FUNC__  := ValAsInt }
   
   {$INCLUDE functions_arrdict-sum.inc}
   
   {$UNDEF __FPC_TYPE__   }
   {$UNDEF __AWFUL_TYPE__ }
   {$UNDEF __CAST_FUNC__  }
   end;

Function F_array_fltSum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FPC_TYPE__   := TFloat   }
   {$DEFINE __AWFUL_TYPE__ := VT_FLO   }
   {$DEFINE __CAST_FUNC__  := ValAsFlo }
   
   {$INCLUDE functions_arrdict-sum.inc}
   
   {$UNDEF __FPC_TYPE__   }
   {$UNDEF __AWFUL_TYPE__ }
   {$UNDEF __CAST_FUNC__  }
   end;

Function ValueToPrintable(Const V:PValue):AnsiString;
   Var Arr:PArray; AEA:TArray.TEntryArr;
       Dic:PDict; DEA:TDict.TEntryArr;
       Idx:LongWord;
   begin Case (V^.Typ) of
   VT_ARR: begin
      Result:='array(';
      Arr:=PArray(V^.Ptr); 
      If (Not Arr^.Empty()) then begin
         AEA:=Arr^.ToArray(); 
         For Idx:=Low(AEA) to High(AEA) do begin
             Result += '[' + IntToStr(AEA[Idx].Key) + ']: ';
             Result += ValueToPrintable(AEA[Idx].Val);
             If (Idx < High(AEA)) then Result += ', '
         end end;
      Result += ')'
      end;
   VT_DIC: begin
      Result := 'dict(';
      Dic:=PDict(V^.Ptr); 
      If (Not Dic^.Empty()) then begin
         DEA:=Dic^.ToArray(); 
         For Idx:=Low(DEA) to High(DEA) do begin
             Result += '[' + DEA[Idx].Key +']: ';
             Result += ValueToPrintable(DEA[Idx].Val);
             If (Idx < High(DEA)) then Result += ', '
         end end;
      Result += ')'
      end;
   VT_FIL:
      Result := 'file('+PFileHandle(V^.Ptr)^.Pth+')';
   VT_NIL:
      Result := '{NIL}';
   else
      Result := ValAsStr(V)
   end end;

Function F_array_print(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Raw:Boolean; Str:AnsiString;
   begin 
   If (Length(Arg^) > 0) then begin
      If (Length(Arg^) >= 2)
         then Raw := ValAsBoo(Arg^[1])
         else Raw := False;
      If (Arg^[0]^.Typ = VT_ARR) or (Arg^[0]^.Typ = VT_DIC)
         then Str := ValueToPrintable(Arg^[0])
         else Str := ''
      end else begin
      Raw := False;
      Str := ''
      end;
   If (Raw) then begin
      If (DoReturn) then Result := NewVal(VT_STR,Str)
                    else Result := NIL
      end else begin
      If (DoReturn) then Result := NewVal(VT_INT,Length(Str))
                    else Result := NIL;
      Writeln(StdOut, Str)
      end;
   F_(False,Arg)
   end;

end.
