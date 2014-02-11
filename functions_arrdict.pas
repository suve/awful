unit functions_arrdict;

{$INCLUDE defines.inc} {$INLINE ON}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_array(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_count(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_empty(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_flush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_print(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_contains_eq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_array_contains_seq(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_dict_nextkey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_dict_keys(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_dict_values(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses Values_Compare, EmptyFunc, Globals;

Type TCompareFunc = Function(Const A,B:PValue):Boolean;

Procedure Register(Const FT:PFunTrie);
   begin
   // array functions, bitches!
   FT^.SetVal('arr',@F_array);
   // dict funtions
   FT^.SetVal('dict',@F_dict);
   FT^.SetVal('dict-keys',@F_dict_keys);
   FT^.SetVal('dict-values',@F_dict_values);
   FT^.SetVal('dict-nextkey',@F_dict_nextkey);
   // arr+dic functions
   FT^.SetVal('arr-flush',@F_array_flush); FT^.SetVal('dict-flush',@F_array_flush);
   FT^.SetVal('arr-count',@F_array_count); FT^.SetVal('dict-count',@F_array_count);
   FT^.SetVal('arr-empty',@F_array_empty); FT^.SetVal('dict-empty',@F_array_empty);
   FT^.SetVal('arr-print',@F_array_print); FT^.SetVal('dict-print',@F_array_print);
   FT^.SetVal('arr-contains',@F_array_contains_eq); FT^.SetVal('dict-contains',@F_array_contains_eq);
   FT^.SetVal('arr-contains-seq',@F_array_contains_seq); FT^.SetVal('dict-contains-seq',@F_array_contains_seq);
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

Function F_array_contains(Const DoReturn:Boolean; Const Arg:PArrPVal; Cmpr:TCompareFunc):PValue; Inline;
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
              If (ValEq(Arg^[C], AEA[I].Val)) then begin
                 Cont[C] := True; Break
                 end;
      end else
   If (Arg^[0]^.Typ = VT_DIC) then begin
      Dic:=PDict(Arg^[0]^.Ptr); DEA:=Dic^.ToArray();
      Lo:=Low(DEA); Hi:=High(DEA);
      For C:=1 to High(Arg^) do
          For I:=Lo to Hi do 
              If (ValEq(Arg^[C], DEA[I].Val)) then begin
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

Function F_array_print(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,I:LongWord; R:Boolean; S:AnsiString;
       Arr:PArray; AEA:TArray.TEntryArr;
       Dic:PDict; DEA:TDict.TEntryArr;
   begin R:=False;
   If (Length(Arg^) >= 2) then begin
      For C:=High(Arg^) downto 2 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
      If (Arg^[1]^.Typ = VT_BOO)
         then R:=PBool(Arg^[1]^.Ptr)^
         else R:=ValAsBoo(Arg^[1]);
      If (Arg^[1]^.Lev >= CurLev) then FreeVal(Arg^[1])
      end;
   If (Length(Arg^) > 0) then begin
       If (Arg^[0]^.Typ = VT_ARR) then begin
          S:='array(';
          Arr:=PArray(Arg^[0]^.Ptr); 
          If (Not Arr^.Empty()) then begin
             AEA:=Arr^.ToArray(); 
             For I:=Low(AEA) to High(AEA) do begin
                 S += '[' + IntToStr(AEA[I].Key) + ']: ';
                 If (AEA[I].Val^.Typ = VT_STR)
                    then S += PStr(AEA[I].Val^.Ptr)^
                    else S += ValAsStr(AEA[I].Val);
                 If (I < High(AEA)) then S += ', '
                 end;
          S += ')'
          end end else
       If (Arg^[0]^.Typ = VT_DIC) then begin
          S := 'dict(';
          Dic:=PDict(Arg^[0]^.Ptr); 
          If (Not Dic^.Empty()) then begin
             DEA:=Dic^.ToArray(); 
             For I:=Low(DEA) to High(DEA) do begin
                 S += '[' + DEA[I].Key +']: ';
                 If (DEA[I].Val^.Typ <> VT_STR)
                    then S += PStr(DEA[I].Val^.Ptr)^
                    else S += ValAsStr(DEA[I].Val);
                 If (I < High(DEA)) then S += ', '
                 end;
          S += ')'
          end end else WriteStr(S, '{', Arg^[0]^.Typ, '}');
       If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0])
       end;
   If (R) then begin 
      If (DoReturn) then Exit(NewVal(VT_STR, S)) else Exit(NIL)
      end else begin
      Writeln(StdOut, S); If DoReturn then Exit(NilVal()) else Exit(NIL)
      end
   end;

end.
