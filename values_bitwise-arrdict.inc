Var ent : __TYPE__.TEntryArr; idx : LongWord; V:PValue;
begin
   If(A^.Empty) then Exit;
   ent := A^.ToArray();
   For idx:=0 to (A^.Count - 1) do begin
      V := B^.GetVal(ent[idx].Key);
      If (V<>NIL)
         then Res^.SetVal(ent[idx].Key, Bitfunc(ent[idx].Val, V))
         else Res^.SetVal(ent[idx].Key, EmptyVal(ent[idx].Val^.Typ))
   end;
