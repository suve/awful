Var C,I:LongWord; Sum : __FPC_TYPE__;
    AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
begin
   // Bail out early if not returning a value
   If (Not DoReturn) then Exit(F_(False, Arg));
   
   Sum := 0; // Set initial sum to 0
   If (Length(Arg^)>0) then
      For C:=0 to High(Arg^) do begin
         
         // If argC is an array, go through all entries and add to sum
         If (Arg^[C]^.Typ = VT_ARR) then begin
            If (Not Arg^[C]^.Arr^.Empty) then begin
               AEA:=Arg^[C]^.Arr^.ToArray();
               For I:=0 to High(AEA) do
                  Sum += __CAST_FUNC__ (AEA[I].Val)
         end end else
         
         // If argC is a dictionary, go through all entries and add to sum
         If (Arg^[C]^.Typ = VT_DIC) then begin
            If (Not Arg^[C]^.Dic^.Empty) then begin
               DEA:=Arg^[C]^.Dic^.ToArray();
               For I:=0 to High(DEA) do
                  Sum += __CAST_FUNC__ (DEA[I].Val)
         end end;
         
         FreeIfTemp(Arg^[C])
      end;
   Exit(NewVal(__AWFUL_TYPE__, Sum))
