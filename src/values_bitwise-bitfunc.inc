begin
   Result := EmptyVal(A^.Typ);
   
   Case(A^.Typ) of
   
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
         
            VT_INT .. VT_BIN:
               Result^.Int^ := A^.Int^ __BITWISE__ B^.Int^;
            
            VT_FLO:
               Result^.Int^ := A^.Int^ __BITWISE__ Trunc(B^.Flo^);
            
            VT_STR:
               Result^.Int^ := A^.Int^ __BITWISE__ StrToNum(B^.Str^, A^.Typ);
            
            VT_UTF:
               Result^.Int^ := A^.Int^ __BITWISE__ B^.Utf^.ToInt(IntBase(A^.Typ));
            
            VT_CHR:
               Result^.Int^ := A^.Int^ __BITWISE__ StrToNum(GetRefdChar(B^.Chr), A^.Typ);
            
            VT_BOO:
               Result^.Int^ := A^.Int^ __BITWISE__ BoolToInt(B^.Boo^);
            
            VT_ARR:
               Result^.Int^ := A^.Int^ __BITWISE__ B^.Arr^.Count;
               
            VT_DIC:
               Result^.Int^ := A^.Int^ __BITWISE__ B^.Dic^.Count;
            
         end;
      
      VT_FLO:
         Case (B^.Typ) of
         
            VT_INT .. VT_BIN:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ B^.Int^;
            
            VT_FLO:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ Trunc(B^.Flo^);
            
            VT_STR:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ Trunc(StrToReal(B^.Str^));
            
            VT_UTF:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ Trunc(B^.Utf^.ToFloat());
            
            VT_CHR:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ Trunc(StrToReal(GetRefdChar(B^.Chr)));
            
            VT_BOO:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ BoolToInt(B^.Boo^);
            
            VT_ARR:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ B^.Arr^.Count;
            
            VT_DIC:
               Result^.Flo^ := Trunc(A^.Flo^) __BITWISE__ B^.Dic^.Count;
            
         end;
      
      VT_BOO:
         Case(B^.Typ) of
            
            VT_INT .. VT_BIN:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ (B^.Int^ <> 0);
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ B^.Int^) <> 0;
               {$ENDIF}
            
            VT_FLO:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ (Abs(B^.Flo^)>=1.0);
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ Trunc(B^.Flo^)) <> 0;
               {$ENDIF}
            
            VT_STR:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ StrToBoolDef(B^.Str^, FALSE);
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ StrToInt(B^.Str^)) <> 0;
               {$ENDIF}
            
            VT_UTF:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ StrToBoolDef(B^.Utf^.ToAnsiString(), FALSE);
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ StrToInt(B^.Utf^.ToAnsiString())) <> 0;
               {$ENDIF}
            
            VT_CHR:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ StrToBoolDef(GetRefdChar(B^.Chr), FALSE);
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ StrToInt(GetRefdChar(B^.Chr))) <> 0;
               {$ENDIF}
            
            VT_BOO:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ B^.Boo^;
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ BoolToInt(B^.Boo^)) <> 0;
               {$ENDIF}
            
            VT_ARR:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ (B^.Arr^.Count <> 0);
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ B^.Arr^.Count) <> 0;
               {$ENDIF}
            
            VT_DIC:
               {$IFNDEF BOOL_FROM_INT}
               Result^.Boo^ := A^.Boo^ __BITWISE__ (B^.Dic^.Count <> 0);
               {$ELSE}
               Result^.Boo^ := (BoolToInt(A^.Boo^) __BITWISE__ B^.Dic^.Count) <> 0;
               {$ENDIF}
            
         end;
      
      VT_ARR:
         If (B^.Typ = VT_ARR) then Bitwise_Array(A^.Arr, B^.Arr, @__BITFUNC__, Result^.Arr);
      
      VT_DIC:
         If (B^.Typ = VT_DIC) then Bitwise_Dict(A^.Dic, B^.Dic, @__BITFUNC__, Result^.Dic);
      
   end;
