If (T < L) then Tp:=E^.Arg[T+1]^.Typ
           else Tp:=VT_NIL;

atk := PArrTk(E^.Tok[T]^.Ptr);
E^.Arg[T]:=GetVar(PStr(atk^.Ptr), VT_DIC);

For I:=Low(atk^.Ind) to High(atk^.Ind) do
    E^.Arg[T]:=GetArr(E^.Arg[T], atk^.Ind[I], Tp);
