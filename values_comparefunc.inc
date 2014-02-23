   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit((PQInt(A^.Ptr)^) __OPERATOR__ (PQInt(B^.Ptr)^));
            VT_FLO:
               Exit((PQInt(A^.Ptr)^) __OPERATOR__ Trunc(PFloat(B^.Ptr)^));
            VT_STR:
               Exit((PQInt(A^.Ptr)^) __OPERATOR__ StrToNum(PStr(B^.Ptr)^,A^.Typ));
            VT_UTF:
               Exit((PQInt(A^.Ptr)^) __OPERATOR__ PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ)));
            VT_BOO:
               Exit((PQInt(A^.Ptr)^) __OPERATOR__ BoolToInt(PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit((PFloat(A^.Ptr)^) __OPERATOR__ TFloat(PQInt(B^.Ptr)^));
            VT_FLO:
               Exit((PFloat(A^.Ptr)^) __OPERATOR__ (PFloat(B^.Ptr)^));
            VT_STR:
               Exit((PFloat(A^.Ptr)^) __OPERATOR__ StrToReal(PStr(B^.Ptr)^));
            VT_UTF:
               Exit((PFloat(A^.Ptr)^) __OPERATOR__ PUTF(B^.Ptr)^.ToFloat());
            VT_BOO:
               Exit((PFloat(A^.Ptr)^) __OPERATOR__ TFloat(BoolToInt(PBool(B^.Ptr)^)));
            else
               Exit(False)
         end;
      VT_STR:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(StrToNum(PStr(A^.Ptr)^,B^.Typ) __OPERATOR__ (PQInt(B^.Ptr)^));
            VT_FLO:
               Exit(StrToReal(PStr(A^.Ptr)^) __OPERATOR__ (PFloat(B^.Ptr)^));
            VT_STR:
               Exit((PStr(A^.Ptr)^) __OPERATOR__ (PStr(B^.Ptr)^));
            VT_UTF:
               Exit(PUTF(B^.Ptr)^.Compare(PStr(A^.Ptr)^) __STR_UTF__ );
            VT_BOO:
               Exit(BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) __OPERATOR__ BoolToInt(PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_UTF:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(PUTF(A^.Ptr)^.ToInt(IntBase(B^.Typ)) __OPERATOR__ PQInt(B^.Ptr)^);
            VT_FLO:
               Exit(PUTF(A^.Ptr)^.ToFloat() __OPERATOR__ PFloat(B^.Ptr)^);
            VT_STR:
               Exit(PUTF(A^.Ptr)^.Compare(PStr(B^.Ptr)^) __UTF_STR__ );
            VT_UTF:
               Exit(PUTF(A^.Ptr)^.Compare(PUTF(B^.Ptr)) __UTF_UTF__ );
            VT_BOO:
               Exit(BoolToInt(StrToBoolDef(PUTF(A^.Ptr)^.ToAnsiString(),FALSE)) __OPERATOR__ BoolToInt(PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_BOO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(BoolToInt(PBool(A^.Ptr)^) __OPERATOR__ (PQInt(B^.Ptr)^));
            VT_FLO:
               Exit(BoolToInt(PBool(A^.Ptr)^) __OPERATOR__ Trunc(PFloat(B^.Ptr)^));
            VT_STR:
               Exit(BoolToInt(PBool(A^.Ptr)^) __OPERATOR__ BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)));
            VT_UTF:
               Exit(BoolToInt(PBool(A^.Ptr)^) __OPERATOR__ BoolToInt(StrToBoolDef(PUTF(B^.Ptr)^.ToAnsiString(),FALSE)));
            VT_BOO:
               Exit(BoolToInt(PBool(A^.Ptr)^) __OPERATOR__ BoolToInt(PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      else
         Exit(False)
      end
