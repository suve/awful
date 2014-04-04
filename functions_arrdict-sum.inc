Var C,I:LongWord; Sum : __FPC_TYPE__;
    AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
begin 
If (Not DoReturn) then Exit(F_(False, Arg)) else Sum := 0;
If (Length(Arg^)>0) then
   For C:=0 to High(Arg^) do begin
      If (Arg^[C]^.Typ = VT_ARR) then begin
         If (Not PArray(Arg^[C]^.Ptr)^.Empty) then begin
            AEA:=PArray(Arg^[C]^.Ptr)^.ToArray();
            For I:=0 to High(AEA) do
               Sum += __CAST_FUNC__ (AEA[I].Val)
         end end else
      If (Arg^[C]^.Typ = VT_DIC) then begin
         If (Not PDict(Arg^[C]^.Ptr)^.Empty) then begin
            DEA:=PDict(Arg^[C]^.Ptr)^.ToArray();
            For I:=0 to High(DEA) do
               Sum += __CAST_FUNC__ (DEA[I].Val)
         end end;
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
Exit(NewVal(__AWFUL_TYPE__, Sum))
