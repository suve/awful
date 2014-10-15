If (T < E^.Num) 
   then E^.Arg[T]:=GetVar(E^.Tok[T]^.Nam, E^.Arg[T+1]^.Typ)
   else E^.Arg[T]:=GetVar(E^.Tok[T]^.Nam, VT_NIL);
