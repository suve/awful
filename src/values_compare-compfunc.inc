begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit((A^.Int^) __OPERATOR__ (B^.Int^));
            
            VT_FLO:
               Exit((A^.Int^) __OPERATOR__ Trunc(B^.Flo^));
            
            VT_STR:
               Exit((A^.Int^) __OPERATOR__ StrToNum(B^.Str^,A^.Typ));
            
            VT_UTF:
               Exit((A^.Int^) __OPERATOR__ B^.Utf^.ToInt(IntBase(A^.Typ)));
            
            VT_CHR:
               Exit((A^.Int^) __OPERATOR__ StrToNum(GetRefdChar(B^.Chr),A^.Typ));
            
            VT_BOO:
               Exit((A^.Int^) __OPERATOR__ BoolToInt(B^.Boo^));
         end;
      
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit((A^.Flo^) __OPERATOR__ TFloat(B^.Int^));
            
            VT_FLO:
               Exit((A^.Flo^) __OPERATOR__ (B^.Flo^));
            
            VT_STR:
               Exit((A^.Flo^) __OPERATOR__ StrToReal(B^.Str^));
            
            VT_UTF:
               Exit((A^.Flo^) __OPERATOR__ B^.Utf^.ToFloat());
            
            VT_CHR:
               Exit((A^.Flo^) __OPERATOR__ StrToReal(GetRefdChar(B^.Chr)));
            
            VT_BOO:
               Exit((A^.Flo^) __OPERATOR__ TFloat(BoolToInt(B^.Boo^)));
         end;
      
      VT_STR:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(StrToNum(A^.Str^,B^.Typ) __OPERATOR__ (B^.Int^));
            
            VT_FLO:
               Exit(StrToReal(A^.Str^) __OPERATOR__ (B^.Flo^));
            
            VT_STR:
               Exit((A^.Str^) __OPERATOR__ (B^.Str^));
            
            VT_UTF:
               Exit(B^.Utf^.Compare(A^.Str^) __STR_UTF__ );
            
            VT_CHR:
               Exit((A^.Str^) __OPERATOR__ GetRefdChar(B^.Chr));
            
            VT_BOO:
               Exit(BoolToInt(StrToBoolDef(A^.Str^,FALSE)) __OPERATOR__ BoolToInt(B^.Boo^));
         end;
      
      VT_CHR:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(StrToNum(GetRefdChar(A^.Chr),B^.Typ) __OPERATOR__ (B^.Int^));
            
            VT_FLO:
               Exit(StrToReal(GetRefdChar(A^.Chr)) __OPERATOR__ (B^.Flo^));
            
            VT_STR:
               Exit(GetRefdChar(A^.Chr) __OPERATOR__ (B^.Str^));
            
            VT_UTF:
               Exit(B^.Utf^.Compare(GetRefdChar(A^.Chr)) __STR_UTF__ );
            
            VT_CHR:
               Exit(GetRefdChar(A^.Chr) __OPERATOR__ GetRefdChar(B^.Chr));
            
            VT_BOO:
               Exit(BoolToInt(StrToBoolDef(GetRefdChar(A^.Chr),FALSE)) __OPERATOR__ BoolToInt(B^.Boo^));
         end;
      
      VT_UTF:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(A^.Utf^.ToInt(IntBase(B^.Typ)) __OPERATOR__ B^.Int^);
            
            VT_FLO:
               Exit(A^.Utf^.ToFloat() __OPERATOR__ B^.Flo^);
            
            VT_STR:
               Exit(A^.Utf^.Compare(B^.Str^) __UTF_STR__ );
            
            VT_UTF:
               Exit(A^.Utf^.Compare(PUTF(B^.Ptr)) __UTF_UTF__ );
            
            VT_CHR:
               Exit(A^.Utf^.Compare(GetRefdChar(B^.Chr)) __UTF_STR__ );
            
            VT_BOO:
               Exit(BoolToInt(StrToBoolDef(A^.Utf^.ToAnsiString(),FALSE)) __OPERATOR__ BoolToInt(B^.Boo^));
         end;
      
      VT_BOO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(BoolToInt(A^.Boo^) __OPERATOR__ (B^.Int^));
            
            VT_FLO:
               Exit(BoolToInt(A^.Boo^) __OPERATOR__ Trunc(B^.Flo^));
            
            VT_STR:
               Exit(BoolToInt(A^.Boo^) __OPERATOR__ BoolToInt(StrToBoolDef(B^.Str^,FALSE)));
            
            VT_UTF:
               Exit(BoolToInt(A^.Boo^) __OPERATOR__ BoolToInt(StrToBoolDef(B^.Utf^.ToAnsiString(),FALSE)));
            
            VT_CHR:
               Exit(BoolToInt(A^.Boo^) __OPERATOR__ BoolToInt(StrToBoolDef(GetRefdChar(B^.Chr),FALSE)));
            
            VT_BOO:
               Exit(BoolToInt(A^.Boo^) __OPERATOR__ BoolToInt(B^.Boo^));
         end;
   end;
   Exit(False)
