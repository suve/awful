unit functions_arrdict;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

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
        {$IFDEF CGI} Functions_stdio, {$ENDIF}
        Convert, Globals, EmptyFunc;

Type
   TCompareFunc = Function(Const A,B:PValue):Boolean;

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
   Var C:LongWord; V:PValue;
   begin
      // If not returning a value, simply free args and gtfo
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Create return value and push args inside
      Result := EmptyVal(VT_ARR);
      If (Length(Arg^) > 0) then
         For C:=Low(Arg^) to High(Arg^) do begin
            
            // Check if arg is temporary value
            If (Arg^[C]^.Lev >= CurLev)
               then V:=Arg^[C]           // If yes, reuse
               else V:=CopyVal(Arg^[C]); // Otherwise, make a copy
            
            // Add value to array
            Result^.Arr^.SetVal(C,V)
         end;
   end;

Function F_dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; Key:AnsiString; V,oV:PValue;
   begin
      // If not returning a value, simply free args and gtfo
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Create return value and push args inside
      Result := EmptyVal(VT_DIC);
      If (Length(Arg^) > 0) then begin
         For C:=Low(Arg^) to High(Arg^) do begin
            
            // Check arg parity
            If ((C mod 2)=0) then begin
            
               // First arg in pair contains key to insert value at
               If (Arg^[C]^.Typ = VT_STR)
                  then Key:=Arg^[C]^.Str^
                  else Key:=ValAsStr(Arg^[C]);
                  
               If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
               
            end else begin
               
               // Second arg in pair contains value to be inserted
               If (Arg^[C]^.Lev >= CurLev)
                  then V:=Arg^[C]
                  else V:=CopyVal(Arg^[C]);
               
               // If there was already a value at this key, free it
               If (Result^.Dic^.IsVal(Key)) then begin 
                  oV:=Result^.Dic^.GetVal(Key); FreeVal(oV)
               end;
               
               // Add value to dict at key
               Result^.Dic^.SetVal(Key, V)
            
            end
         end;
         
         // If odd number of args, use the last key and insert NIL there
         If ((Length(Arg^) mod 2) = 1) then begin
            
            // If already a value present, remove it
            If (Result^.Dic^.IsVal(Key)) then begin
               oV:=Result^.Dic^.GetVal(Key); FreeVal(oV)
            end;
            
            // Insert NIL at key
            Result^.Dic^.SetVal(Key, NilVal())
            end;
      end
   end;

Function F_array_count(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,R:LongWord;
   begin 
      // If not returning a value, free args and gtfo
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      R := 0; // Set initial count to 0
      If (Length(Arg^) > 0) then
         
         // Run through all the args
         For C:=High(Arg^) downto Low(Arg^) do begin
           
            // If array or dict, increase result-count
            If (Arg^[C]^.Typ = VT_ARR) then R += Arg^[C]^.Arr^.Count else
            If (Arg^[C]^.Typ = VT_DIC) then R += Arg^[C]^.Dic^.Count;
            
            // Free arg if needed
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
      // Return value
      Exit(NewVal(VT_INT,R))
   end;

Function F_array_empty(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C : LongWord; B:Boolean;
   begin
      // If not returning a value, free args and gtfo
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      B := TRUE; // Initial answer = TRUE
      If (Length(Arg^)>0) then
         
         // Run through all the args
         For C:=High(Arg^) downto Low(Arg^) do begin
            
            // If array or dict, perform logical AND on temp-result and arg-empty
            If (Arg^[C]^.Typ = VT_ARR) then B:=(B and Arg^[C]^.Arr^.Empty) else
            If (Arg^[C]^.Typ = VT_DIC) then B:=(B and Arg^[C]^.Dic^.Empty);
            
            // Free arg if needed
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
      // Return value
      Exit(NewVal(VT_BOO,B))
   end;

Function F_dict_nextkey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; K:AnsiString;
   begin
      // Not returning a value, free args and ignore
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Return NIL if no args provided
      If (Length(Arg^) = 0) then Exit(NilVal());
      
      // More than two args - uncecessary. Free them.
      If (Length(Arg^) >= 3) then
         For C:=High(Arg^) downto 2 do
             If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
      
      // Check if second arg is provided.
      If (Length(Arg^)>=2) then begin
         
         // If yes, extract key from arg
         If (Arg^[1]^.Typ = VT_STR)
            then K:=Arg^[1]^.Str^
            else K:=ValAsStr(Arg^[1]);
            
         // Free arg if needed
         If (Arg^[1]^.Lev >= CurLev) then FreeVal(Arg^[1])
         
      end else K:=''; // No second arg, default value to ''
      
      // First arg is not a dictionary - free if necessary and return NIL
      If (Arg^[0]^.Typ <> VT_DIC) then begin
         If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
         Exit(NilVal())
      end;
      
      // Get next key from dict
      K:=Arg^[0]^.Dic^.NextKey(K);
      
      // Free dict if needed
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      
      // Return value
      Exit(NewVal(VT_STR,K))
   end;

Function F_dict_keys(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,D,I:LongWord; DEA:TDict.TEntryArr;
   begin
      // Not returning a value = bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      Result := EmptyVal(VT_ARR); I:=0;
      If (Length(Arg^)>0) then
         For C:=Low(Arg^) to High(Arg^) do begin
            If (Arg^[C]^.Typ = VT_DIC) then
               If (Not Arg^[C]^.Dic^.Empty()) then begin
                  DEA := Arg^[C]^.Dic^.ToArray();
                  For D:=Low(DEA) to High(DEA) do begin
                     Result^.Arr^.SetVal(I, NewVal(VT_STR, DEA[D].Key));
                     I += 1
                  end
               end;
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end
   end;

Function F_dict_values(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,D,I:LongWord; DEA:TDict.TEntryArr;
   begin
      // Not returning a value? Bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      Result := EmptyVal(VT_ARR); I:=0;
      If (Length(Arg^)>0) then
         For C:=Low(Arg^) to High(Arg^) do begin
            If (Arg^[C]^.Typ = VT_DIC) then
               If (Not Arg^[C]^.Dic^.Empty()) then begin
                  DEA := Arg^[C]^.Dic^.ToArray();
                  For D:=Low(DEA) to High(DEA) do begin
                     Result^.Arr^.SetVal(I, CopyVal(DEA[D].Val));
                     I += 1
                  end
               end;
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end
   end;

Function F_array_flush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C, I, R : LongWord;
       AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
   begin
      R := 0; // Initial removed indices count = 0
      If (Length(Arg^)>0) then
         For C:=High(Arg^) downto Low(Arg^) do begin
         
            If (Arg^[C]^.Typ = VT_ARR) then begin
               If (Not Arg^[C]^.Arr^.Empty()) then begin
                  AEA:=Arg^[C]^.Arr^.ToArray(); Arg^[C]^.Arr^.Purge(); R += Length(AEA);
                  For I:=Low(AEA) to High(AEA) do
                     If (AEA[I].Val^.Lev >= CurLev) then FreeVal(AEA[I].Val)
               end
            
            end else
            If (Arg^[C]^.Typ = VT_DIC) then begin
               If (Not Arg^[C]^.Dic^.Empty()) then begin
                  DEA:=Arg^[C]^.Dic^.ToArray(); Arg^[C]^.Dic^.Purge(); R += Length(DEA);
                  For I:=Low(DEA) to High(DEA) do
                     If (DEA[I].Val^.Lev >= CurLev) then FreeVal(DEA[I].Val)
            end end;
            
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
      
      If (DoReturn)
         then Exit(NewVal(VT_INT,R))
         else Exit(NIL)
   end;

Function F_array_contains(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Cmpr:TCompareFunc):PValue; Inline;
   Var C,I,Lo,Hi:LongInt; Cont:Array of TBool; Res:Boolean;
       AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
   begin
      // If not returning a value, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If less than two args, free arg and return FALSE
      If (Length(Arg^) < 2) then begin
         F_(False, Arg); Exit(NewVal(VT_BOO, False))
      end;
      
      // Create an array descripting whether haystacks contains needles and fill it with FALSEs
      SetLength(Cont, Length(Arg^));
      For C:=1 to High(Arg^) do Cont[C]:=False;
      
      // If arg0 is array
      If (Arg^[0]^.Typ = VT_ARR) then begin
         AEA:=Arg^[0]^.Arr^.ToArray();
         Lo:=Low(AEA); Hi:=High(AEA);
         
         // We have the array entry list, go through needles and look for them
         For C:=1 to High(Arg^) do
            For I:=Lo to Hi do 
               If (Cmpr(Arg^[C], AEA[I].Val)) then begin
                  Cont[C] := True; Break
               end
         end else
      // If arg0 is dictionary
      If (Arg^[0]^.Typ = VT_DIC) then begin
         DEA:=Arg^[0]^.Dic^.ToArray();
         Lo:=Low(DEA); Hi:=High(DEA);
         
         // We have the dictionary entry list, go through needles and look for them
         For C:=1 to High(Arg^) do
            For I:=Lo to Hi do 
               If (Cmpr(Arg^[C], DEA[I].Val)) then begin
                  Cont[C] := True; Break
               end;
         end;
      
      // Free args if needed and set initial answer to TRUE
      F_(False, Arg); Res := True;
      
      // Go through contains-table and perform ANDs 
      For C:=1 to High(Arg^) do Res := Res and Cont[C];
      
      // Return value
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
   Var C,I,Cnt:LongWord; Swp:QWord; Ent:TArray.TEntryArr;
   begin
      Swp := 0; // Initial swap counter = 0
      If (Length(Arg^) > 0) then
         For C:=0 to High(Arg^) do begin
            If (Arg^[C]^.Typ = VT_ARR) then begin
               Cnt := Arg^[C]^.Arr^.Count;
               If (Cnt > 0) then begin
                  Ent := Arg^[C]^.Arr^.ToArray(); // Get entry array
                  Swp += qsort(Ent,0,Cnt-1);      // Perform quicksort
                  
                  For I:=0 to (Cnt-1) do                // Go through all entries
                     Arg^[C]^.Arr^.SetVal(Ent[I].Key,Ent[I].Val) // Insert I-th lowest value at I-th lowest key
               end end;
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
      
      If (DoReturn)
         then Exit(NewVal(VT_INT, Swp))
         else Exit(NIL)
   end;

Function F_array_edgy(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Cmpr:TCompareFunc):PValue;
   
   Function Fork(Const Condition:Boolean; Const TrueVal,FalseVal:LongWord):LongWord; Inline;
      begin If (Condition) then Result:=TrueVal else Result:=FalseVal end;
   
   Var C,I,Cnt:LongWord; Ent:TArray.TEntryArr; 
   begin 
      // If not returning a value, bail out early
      If (Not DoReturn) then Exit(F_(DoReturn, Arg));
      
      Result := NIL; // Just to make sure
      If (Length(Arg^) > 0) then
         For C:=0 to High(Arg^) do
            If (Arg^[C]^.Typ = VT_ARR) then begin
               Cnt := Arg^[C]^.Arr^.Count;
               If (Cnt > 0) then begin
                  Ent := Arg^[C]^.Arr^.ToArray(); // Get array of entries
                  If (Result = NIL) then Result:=Ent[0].Val; // If result is nil (first arr), assign entry0 to result
                  For I:=Fork(C > 0, 0, 1) to (Cnt-1) do // Go from entry1 if first arr or entry0 otherwise
                     If (Cmpr(Ent[I].Val,Result)) then Result:=Ent[I].Val // If entry is better than current result, assign
            end end;
            
      // Result now points to an entry in the arg-arrays, so we have to copy the value
      If (Result <> NIL)
         then Result := CopyVal(Result)
         else Result := NilVal(); 
         
      F_(False, Arg) // Free args before leaving
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
   Var AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
       Idx:LongWord;
   begin
      Case (V^.Typ) of
         
         VT_ARR: begin
            Result:='array(';
            If (Not V^.Arr^.Empty()) then begin
               AEA:=V^.Arr^.ToArray(); 
               For Idx:=Low(AEA) to High(AEA) do begin
                  Result += '[' + IntToStr(AEA[Idx].Key) + ']: ';
                  Result += ValueToPrintable(AEA[Idx].Val);
                  If (Idx < High(AEA)) then Result += ', '
            end end;
            Result += ')'
         end;
         
         VT_DIC: begin
            Result := 'dict(';
            If (Not V^.Dic^.Empty()) then begin
               DEA:=V^.Dic^.ToArray(); 
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
      // Analyse args
      If (Length(Arg^) > 0) then begin
         
         // If two or more args, RAW has been provided
         If (Length(Arg^) >= 2)
            then Raw := ValAsBoo(Arg^[1])
            else Raw := False;
         
         // Get string representation of array / dict
         If (Arg^[0]^.Typ = VT_ARR) or (Arg^[0]^.Typ = VT_DIC)
            then Str := ValueToPrintable(Arg^[0])
            else Str := ''
      
      end else begin
         // No args - use defaults
         Raw := False;
         Str := ''
      end;
      
      If (Raw) then begin
         // RAW - return raw string
         If (DoReturn)
            then Result := NewVal(VT_STR,Str)
            else Result := NIL
            
      end else begin
         
         // not raw - print string on stdout and return number of bytes
         {$IFDEF CGI}
            CGI_Writeln(Str);
         {$ELSE}
            Writeln(StdOut, Str);
         {$ENDIF}
         If (DoReturn)
            then Result := NewVal(VT_INT,Length(Str))
            else Result := NIL
      end;
      
      F_(False,Arg) // Free args before leaving
   end;

end.
