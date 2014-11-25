If (T < E^.Num) 
   then
      If(E^.Arg[T+1]^.Typ <> VT_CHR)
         then E^.Arg[T]:=GetVar(E^.Tok[T]^.Nam, E^.Arg[T+1]^.Typ)
         else E^.Arg[T]:=GetVar(E^.Tok[T]^.Nam, E^.Arg[T+1]^.Chr^.Val^.Typ)
   else E^.Arg[T]:=GetVar(E^.Tok[T]^.Nam, VT_NIL);
