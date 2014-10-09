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
               Result^.Boo^ := A^.Boo^ __BITWISE__ (B^.Int^ <> 0);
            
            VT_FLO:
               Result^.Boo^ := A^.Boo^ __BITWISE__ (Abs(B^.Flo^)>=1.0);
            
            VT_STR:
               Result^.Boo^ := A^.Boo^ __BITWISE__ StrToBoolDef(B^.Str^, FALSE);
            
            VT_UTF:
               Result^.Boo^ := A^.Boo^ __BITWISE__ StrToBoolDef(B^.Utf^.ToAnsiString(), FALSE);
            
            VT_BOO:
               Result^.Boo^ := A^.Boo^ __BITWISE__ B^.Boo^;
            
            VT_ARR:
               Result^.Boo^ := A^.Boo^ __BITWISE__ (B^.Arr^.Count <> 0);
            
            VT_DIC:
               Result^.Boo^ := A^.Boo^ __BITWISE__ (B^.Dic^.Count <> 0);
            
         end;
      
      VT_ARR:
         If (B^.Typ = VT_ARR) then Bitwise_Array(A^.Arr, B^.Arr, @__BITFUNC__, Result^.Arr);
      
      VT_DIC:
         If (B^.Typ = VT_DIC) then Bitwise_Dict(A^.Dic, B^.Dic, @__BITFUNC__, Result^.Dic);
      
   end;
