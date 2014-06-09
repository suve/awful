If (T < L) 
   then E^.Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr),E^.Arg[T+1]^.Typ)
   else E^.Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr),VT_NIL);
