unit values_compare;

{$INCLUDE defines.inc}

interface
   uses Values;

Function ValSeq(Const A,B:PValue):Boolean;
Function ValSNeq(Const A,B:PValue):Boolean;
Function ValEq(Const A,B:PValue):Boolean;
Function ValNeq(Const A,B:PValue):Boolean;
Function ValGt(Const A,B:PValue):Boolean;
Function ValGe(Const A,B:PValue):Boolean;
Function ValLt(Const A,B:PValue):Boolean;
Function ValLe(Const A,B:PValue):Boolean;

implementation
   uses SysUtils;

Function ValSeq(Const A,B:PValue):Boolean;
   begin
   If (A^.Typ <> B^.Typ) then Exit(False);
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Exit((PQInt(A^.Ptr)^) = (PQInt(B^.Ptr)^));
      VT_FLO:
         Exit((PFloat(A^.Ptr)^) = (PFloat(B^.Ptr)^));
      VT_STR:
         Exit((PStr(A^.Ptr)^) = (PStr(B^.Ptr)^));
      VT_UTF:
         Exit(PUTF(A^.Ptr)^.Compare(PUTF(B^.Ptr)) = 0);
      VT_BOO:
         Exit((PBool(A^.Ptr)^) = (PBool(B^.Ptr)^));
      VT_NIL: 
         Exit(B^.Typ = VT_NIL)
      else Exit(False)
   end end;

Function ValSNeq(Const A,B:PValue):Boolean;
   begin Exit(Not ValSeq(A,B)) end;

Function ValEq(Const A,B:PValue):Boolean;
   begin
   Case (A^.Typ) of
      VT_INT .. VT_BIN:
         Case (B^.Typ) of
            VT_INT.. VT_BIN:
               Exit((PQInt(A^.Ptr)^) = (PQInt(B^.Ptr)^));
            VT_FLO:
               Exit((PQInt(A^.Ptr)^) = Trunc(PFloat(B^.Ptr)^));
            VT_STR:
               Exit((PQInt(A^.Ptr)^) = StrToNum(PStr(B^.Ptr)^,A^.Typ));
            VT_UTF:
               Exit((PQInt(A^.Ptr)^) = PUTF(B^.Ptr)^.ToInt(IntBase(A^.Typ)));
            VT_BOO:
               Exit((PQInt(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_FLO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(Trunc(PFloat(A^.Ptr)^) = (PQInt(B^.Ptr)^));
            VT_FLO:
               Exit((PFloat(A^.Ptr)^) = (PFloat(B^.Ptr)^));
            VT_STR:
               Exit((PFloat(A^.Ptr)^) = StrToReal(PStr(B^.Ptr)^));
            VT_UTF:
               Exit((PFloat(A^.Ptr)^) = PUTF(B^.Ptr)^.ToFloat());
            VT_BOO:
               Exit(Trunc(PFloat(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_STR:
         Case  (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(StrToNum(PStr(A^.Ptr)^,B^.Typ) = (PQInt(B^.Ptr)^));
            VT_FLO:
               Exit(StrToReal(PStr(A^.Ptr)^) = (PFloat(B^.Ptr)^));
            VT_STR:
               Exit((PStr(A^.Ptr)^) = (PStr(B^.Ptr)^));
            VT_UTF:
               Exit(PUTF(B^.Ptr)^.Equals(PStr(A^.Ptr)^));
            VT_BOO:
               Exit(StrToBoolDef(PStr(A^.Ptr)^,FALSE) = (PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_UTF:
         Case  (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit(PUTF(A^.Ptr)^.ToInt(IntBase(B^.Typ)) = (PQInt(B^.Ptr)^));
            VT_FLO:
               Exit(PUTF(A^.Ptr)^.ToFloat() = (PFloat(B^.Ptr)^));
            VT_STR:
               Exit(PUTF(A^.Ptr)^.Equals(PStr(B^.Ptr)^));
            VT_UTF:
               Exit(PUTF(A^.Ptr)^.Equals(PUTF(B^.Ptr)));
            VT_BOO:
               Exit(StrToBoolDef(PUTF(A^.Ptr)^.ToAnsiString(),FALSE) = (PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_BOO:
         Case (B^.Typ) of
            VT_INT .. VT_BIN:
               Exit((PBool(A^.Ptr)^) = (PQInt(B^.Ptr)^ <> 0));
            VT_FLO:
               Exit((PBool(A^.Ptr)^) = (Abs(PFloat(B^.Ptr)^) >= 1.0));
            VT_STR:
               Exit((PBool(A^.Ptr)^) = StrToBoolDef(PStr(B^.Ptr)^,FALSE));
            VT_UTF:
               Exit((PBool(A^.Ptr)^) = StrToBoolDef(PUTF(B^.Ptr)^.ToAnsiString(),FALSE));
            VT_BOO:
               Exit((PBool(A^.Ptr)^) = (PBool(B^.Ptr)^));
            else
               Exit(False)
         end;
      VT_NIL:
         Exit(B^.Typ = VT_NIL)
      else
         Exit(False)
   end end;

Function ValNeq(Const A,B:PValue):Boolean;
   begin Exit(Not ValEq(A,B)) end;

Function ValGt(Const A,B:PValue):Boolean;
   begin
   {$DEFINE __OPERATOR__ := > }
   {$DEFINE __STR_UTF__  := = -1}
   {$DEFINE __UTF_STR__  := = +1}
   {$DEFINE __UTF_UTF__  := = +1}
   
   {$INCLUDE values_comparefunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

Function ValGe(Const A,B:PValue):Boolean;
   begin
   {$DEFINE __OPERATOR__ := >= }
   {$DEFINE __STR_UTF__  := <= 0}
   {$DEFINE __UTF_STR__  := >= 0}
   {$DEFINE __UTF_UTF__  := >= 0}
   
   {$INCLUDE values_comparefunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

Function ValLt(Const A,B:PValue):Boolean;
   begin
   {$DEFINE __OPERATOR__ := < }
   {$DEFINE __STR_UTF__  := = +1}
   {$DEFINE __UTF_STR__  := = -1}
   {$DEFINE __UTF_UTF__  := = -1}
   
   {$INCLUDE values_comparefunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

Function ValLe(Const A,B:PValue):Boolean;
   begin
   {$DEFINE __OPERATOR__ := <= }
   {$DEFINE __STR_UTF__  := >= 0}
   {$DEFINE __UTF_STR__  := <= 0}
   {$DEFINE __UTF_UTF__  := <= 0}
   
   {$INCLUDE values_comparefunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

end.
