Var entA, entB : Values.__TYPE__.TEntryArr;
    idx : LongWord;
begin
   If (A^.Count <> B^.Count) then Exit(False);
   If (A^.Empty) then Exit(True);
   entA := A^.ToArray();
   entB := B^.ToArray();
   For idx:=0 to (A^.Count - 1) do begin
      If (entA[idx].Key <> entB[idx].Key) then Exit(False);
      If (Not CompFunc(entA[idx].Val, entB[idx].Val)) then Exit(False)
   end;
   Exit(True)
