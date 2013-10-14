unit functions_arrdict;

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_array(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_array_count(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_array_empty(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_array_flush(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_array_print(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_dict(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_dict_nextkey(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_dict_keys(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_dict_values(DoReturn:Boolean; Arg:Array of PValue):PValue;

implementation
   uses EmptyFunc;

Procedure Register(FT:PFunTrie);
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
   end;


Function F_array(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; T:PValTree; A,V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   A:=EmptyVal(VT_ARR); T:=PValTree(A^.Ptr);
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do begin
          If (Arg[C]^.Lev >= CurLev)
             then V:=Arg[C]
             else V:=CopyVal(Arg[C]);
          T^.SetValNaive(C,V)
          end;
   T^.Rebalance();
   Exit(A)
   end;

Function F_dict(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; T:PValTrie; Key:AnsiString; A,V,oV:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   A:=EmptyVal(VT_DIC); T:=PValTrie(A^.Ptr);
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If ((C mod 2)=0) then begin
             If (Arg[C]^.Typ <> VT_STR) then begin
                V:=ValToStr(Arg[C]); Key:=PStr(V^.Ptr)^; FreeVal(V)
                end else Key:=PStr(Arg[C]^.Ptr)^;
             If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
             end else begin
             If (Arg[C]^.Lev >= CurLev)
                then V:=Arg[C]
                else V:=CopyVal(Arg[C]);
             If (T^.IsVal(Key)) then begin oV:=T^.GetVal(Key); FreeVal(oV) end;
                T^.SetVal(Key, V)
             end;
   If ((Length(Arg) mod 2) = 1) then begin
      If (T^.IsVal(Key)) then begin oV:=T^.GetVal(Key); FreeVal(oV) end;
      T^.SetVal(Key, NilVal)
      end;
   Exit(A)
   end;

Function F_array_count(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C,R:LongWord;
   begin R:=0;
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_ARR) then R += PValTree(Arg[C]^.Ptr)^.Count else
          If (Arg[C]^.Typ = VT_DIC) then R += PValTrie(Arg[C]^.Ptr)^.Count;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_INT,R))
   end;

Function F_array_empty(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C : LongWord; B:Boolean;
   begin B:=False;
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_ARR) then B:=(B or (Not PValTree(Arg[C]^.Ptr)^.Empty)) else
          If (Arg[C]^.Typ = VT_DIC) then B:=(B or (Not PValTrie(Arg[C]^.Ptr)^.Empty));
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_dict_nextkey(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; T:PValTrie; K:AnsiString; V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>=3) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)>=2) then begin
      If (Arg[1]^.Typ = VT_STR) then K:=PStr(Arg[1]^.Ptr)^
         else begin
         V:=ValToStr(Arg[1]); K:=PStr(V^.Ptr)^;
         FreeVal(V) end;
      If (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1])
      end else K:='';
   If (Length(Arg)>=1) then begin
      If (Arg[0]^.Typ <> VT_DIC) then begin
         If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
         Exit(NilVal()) end;
      T:=PValTrie(Arg[0]^.Ptr); K:=T^.NextKey(K);
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_STR,K))
      end;
   Exit(NilVal())
   end;

Function F_dict_keys(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C,D,I:LongWord; R :PValue; Arr:PValTree; Dic:PValTrie; DEA:TValTrie.TEntryArr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   R:=EmptyVal(VT_ARR); Arr:=PValTree(R^.Ptr); I:=0;
   If (Length(Arg)>0) then For C:=Low(Arg) to High(Arg) do begin
      If (Arg[C]^.Typ = VT_DIC) then begin
         Dic := PValTrie(Arg[C]^.Ptr); DEA := Dic^.ToArray();
         If (Not Dic^.Empty()) then
            For D:=Low(DEA) to High(DEA) do begin
                Arr^.SetValNaive(I, NewVal(VT_STR, DEA[D].Key));
                I += 1 end
         end;
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end;
   Arr^.Rebalance();
   Exit(R)
   end;

Function F_dict_values(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C,D,I:LongWord; R :PValue; Arr:PValTree; Dic:PValTrie; DEA:TValTrie.TEntryArr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   R:=EmptyVal(VT_ARR); Arr:=PValTree(R^.Ptr); I:=0;
   If (Length(Arg)>0) then For C:=Low(Arg) to High(Arg) do begin
      If (Arg[C]^.Typ = VT_DIC) then begin
         Dic := PValTrie(Arg[C]^.Ptr); DEA := Dic^.ToArray();
         If (Not Dic^.Empty()) then
            For D:=Low(DEA) to High(DEA) do begin
                Arr^.SetValNaive(I, CopyVal(DEA[D].Val));
                I += 1 end
         end;
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end;
   Arr^.Rebalance();
   Exit(R)
   end;

Function F_array_flush(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C,I,R:LongWord;
       Arr:PValTree; AEA:TValTree.TEntryArr;
       Dic:PValTrie; DEA:TValTrie.TEntryArr;
   begin R:=0;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_ARR) then begin
             Arr:=PValTree(Arg[C]^.Ptr); 
             If (Not Arr^.Empty()) then begin
                AEA:=Arr^.ToArray(); Arr^.Flush(); R += Length(AEA);
                For I:=Low(AEA) to High(AEA) do
                    FreeVal(AEA[I].Val)
             end end;
          If (Arg[C]^.Typ = VT_DIC) then begin
             Dic:=PValTrie(Arg[C]^.Ptr); 
             If (Not Dic^.Empty()) then begin
                DEA:=Dic^.ToArray(); Dic^.Flush(); R += Length(DEA);
                For I:=Low(DEA) to High(DEA) do
                    FreeVal(DEA[I].Val)
             end end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_INT,R)) else Exit(NIL)
   end;

Function F_array_print(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C,I:LongWord; R:Boolean; V:PValue; S:AnsiString;
       Arr:PValTree; AEA:TValTree.TEntryArr;
       Dic:PValTrie; DEA:TValTrie.TEntryArr;
   begin R:=False;
   If (Length(Arg) >= 2) then begin
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
      If (Arg[1]^.Typ <> VT_BOO) then begin
         V:=ValToBoo(Arg[1]); R:=PBool(V^.Ptr)^; FreeVal(V)
         end else R:=PBool(Arg[1]^.Ptr)^;
      If (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1])
      end;
   If (Length(Arg) > 0) then begin
       If (Arg[0]^.Typ = VT_ARR) then begin
          S:='array(';
          Arr:=PValTree(Arg[0]^.Ptr); 
          If (Not Arr^.Empty()) then begin
             AEA:=Arr^.ToArray(); 
             For I:=Low(AEA) to High(AEA) do begin
                 S += '[' + IntToStr(AEA[I].Key) + ']: ';
                 If (AEA[I].Val^.Typ <> VT_STR) then begin
                    V:=ValToStr(AEA[I].Val); S += PStr(V^.Ptr)^; FreeVal(V)
                    end else S += PStr(AEA[I].Val^.Ptr)^;
                 If (I < High(AEA)) then S += ', '
                 end;
          S += ')'
          end end;
       If (Arg[0]^.Typ = VT_DIC) then begin
          S := 'dict(';
          Dic:=PValTrie(Arg[0]^.Ptr); 
          If (Not Dic^.Empty()) then begin
             DEA:=Dic^.ToArray(); 
             For I:=Low(DEA) to High(DEA) do begin
                 S += '[' + DEA[I].Key +']: ';
                 If (DEA[I].Val^.Typ <> VT_STR) then begin
                    V:=ValToStr(DEA[I].Val); S += PStr(V^.Ptr)^; FreeVal(V)
                    end else S += PStr(DEA[I].Val^.Ptr)^;
                 If (I < High(DEA)) then S += ', '
                 end;
          S += ')'
          end end else S := '';
       If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0])
       end;
   If (R) then begin 
      If (DoReturn) then Exit(NewVal(VT_STR, S)) else Exit(NIL)
      end else begin
      Writeln(S); If DoReturn then Exit(NilVal()) else Exit(NIL)
      end
   end;

end.
