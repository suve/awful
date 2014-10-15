If (T < E^.Num)
   then Tp:=E^.Arg[T+1]^.Typ
   else Tp:=VT_NIL;

E^.Arg[T]:=GetVar(E^.Tok[T]^.atk^.Nam, VT_DIC);

For I:=Low(E^.Tok[T]^.atk^.Ind) to High(E^.Tok[T]^.atk^.Ind) do
   E^.Arg[T]:=GetArr(E^.Arg[T], E^.Tok[T]^.atk^.Ind[I], Tp);
