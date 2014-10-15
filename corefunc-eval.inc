For T:=E^.Num downto 0 do
   Case (E^.Tok[T]^.Typ) of 
      
      TK_CONS, TK_LITE: begin
         {$IFDEF REF_MODIF}
            E^.Arg[T]:=CopyVal(E^.Tok[T]^.Val)
         {$ELSE}
            E^.Arg[T]:=E^.Tok[T]^.Val
         {$ENDIF}
      end;
      
      TK_REFE {$IFNDEF REF_MODIF} , TK_VARI {$ENDIF} : begin
         {$INCLUDE corefunc-tkvar.inc }
      end;
      
      {$IFDEF REF_MODIF}
      TK_VARI: begin
         {$INCLUDE corefunc-tkvar.inc }
         E^.Arg[T] := CopyVal(E^.Arg[T])
      end;
      {$ENDIF}
      
      TK_AREF {$IFNDEF REF_MODIF} , TK_AVAL {$ENDIF} : begin
         {$INCLUDE corefunc-tkarr.inc }
      end;
      
      {$IFDEF REF_MODIF}
      TK_AVAL: begin
         {$INCLUDE corefunc-tkarr.inc }
         E^.Arg[T]:=CopyVal(E^.Arg[T])
      end;
      {$ENDIF}
      
      TK_AFLY: begin
         V:=Eval(RETURN_VALUE_YES, E^.Tok[T]^.atk^.Exp); E^.Arg[T]:=V;
         
         For I:=Low(E^.Tok[T]^.atk^.Ind) to High(E^.Tok[T]^.atk^.Ind) do
            E^.Arg[T]:=GetArr(E^.Arg[T], E^.Tok[T]^.atk^.Ind[I], Tp);
         
         E^.Arg[T]:=CopyVal(E^.Arg[T]); FreeVal(V)
      end;
      
      TK_EXPR: begin
         E^.Arg[T]:=Eval(RETURN_VALUE_YES, E^.Tok[T]^.Exp)
      end
   end;
