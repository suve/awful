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
   uses SysUtils, Convert, Values_Typecast;

Type TCompareFunc = Function(Const A,B:PValue):Boolean;

Function CompareArrays(Const A,B:PArray; Const CompFunc:TCompareFunc):Boolean;
   {$DEFINE __TYPE__ := TArray }
   {$INCLUDE values_compare-arrdict.inc}
   {$UNDEF __TYPE__ }
   end;

Function CompareDicts(Const A,B:PDict; Const CompFunc:TCompareFunc):Boolean;
   {$DEFINE __TYPE__ := TDict }
   {$INCLUDE values_compare-arrdict.inc}
   {$UNDEF __TYPE__ }
   end;

Function CompareCharRefs(Const A,B:PValue):Boolean;
   begin
      If(A^.Chr^.Val^.Typ <> B^.Typ) then Exit(False);
      If(B^.Typ = VT_STR)
         then Exit(GetRefdChar(A^.Chr) = B^.Str^)
         else Exit(B^.Utf^.Equals(GetRefdChar(A^.Chr)))
   end;

Function ValSeq(Const A,B:PValue):Boolean;
   begin
      If (A^.Typ <> B^.Typ) then Exit(False);
      Case (A^.Typ) of
         VT_INT .. VT_BIN:
            Exit(A^.Int^ = B^.Int^);
         
         VT_FLO:
            Exit(A^.Flo^ = B^.Flo^);
         
         VT_STR:
            Exit(A^.Str^ = B^.Str^);
         
         VT_UTF:
            Exit(A^.Utf^.Compare(B^.Utf) = 0);
         
         VT_CHR:
            Exit(CompareCharRefs(A,B));
         
         VT_BOO:
            Exit(A^.Boo^ = B^.Boo^);
         
         VT_ARR:
            Exit(CompareArrays(A^.Arr, B^.Arr, @Values_Compare.ValSeq));
         
         VT_DIC:
            Exit(CompareDicts(A^.Dic, B^.Dic, @Values_Compare.ValSeq));
         
         VT_FIL:
            Exit(A^.Fil = B^.Fil);
         
         VT_NIL: 
            Exit(True)
         
         else
            Exit(False)
   end end;

Function ValSNeq(Const A,B:PValue):Boolean;
   begin Exit(Not ValSeq(A,B)) end;

Function ValEq(Const A,B:PValue):Boolean;
   begin
      Case (A^.Typ) of
         VT_INT .. VT_BIN:
            Case (B^.Typ) of
               VT_INT.. VT_BIN:
                  Exit(A^.Int^ = B^.Int^);
               
               VT_FLO:
                  Exit(A^.Int^ = Trunc(B^.Flo^));
                  
               VT_STR:
                  Exit(A^.Int^ = StrToNum(B^.Str^,A^.Typ));
               
               VT_UTF:
                  Exit(A^.Int^ = B^.Utf^.ToInt(IntBase(A^.Typ)));
               
               VT_CHR:
                  Exit(A^.Int^ = StrToNum(GetRefdChar(B^.Chr), A^.Typ));
               
               VT_BOO:
                  Exit(A^.Int^ = BoolToInt(B^.Boo^));
            end;
         
         VT_FLO:
            Case (B^.Typ) of
               VT_INT .. VT_BIN:
                  Exit(Trunc(A^.Flo^) = B^.Int^);
                  
               VT_FLO:
                  Exit(A^.Flo^ = B^.Flo^);
               
               VT_STR:
                  Exit(A^.Flo^ = StrToReal(B^.Str^));
               
               VT_UTF:
                  Exit(A^.Flo^ = B^.Utf^.ToFloat());
               
               VT_CHR:
                  Exit(A^.Flo^ = StrToReal(GetRefdChar(B^.Chr)));
               
               VT_BOO:
                  Exit(Trunc(A^.Flo^) = BoolToInt(B^.Boo^));
            end;
         
         VT_STR:
            Case  (B^.Typ) of
               VT_INT .. VT_BIN:
                  Exit(StrToNum(A^.Str^,B^.Typ) = B^.Int^);
               
               VT_FLO:
                  Exit(StrToReal(A^.Str^) = B^.Flo^);
               
               VT_STR:
                  Exit(A^.Str^ = B^.Str^);
               
               VT_UTF:
                  Exit(B^.Utf^.Equals(A^.Str^));
               
               VT_CHR:
                  Exit(A^.Str^ = GetRefdChar(B^.Chr));
               
               VT_BOO:
                  Exit(StrToBoolDef(A^.Str^,FALSE) = B^.Boo^);
            end;
         
         VT_CHR:
            Case  (B^.Typ) of
               VT_INT .. VT_BIN:
                  Exit(StrToNum(GetRefdChar(A^.Chr),B^.Typ) = B^.Int^);
               
               VT_FLO:
                  Exit(StrToReal(GetRefdChar(A^.Chr)) = B^.Flo^);
               
               VT_STR:
                  Exit(GetRefdChar(A^.Chr) = B^.Str^);
               
               VT_UTF:
                  Exit(B^.Utf^.Equals(GetRefdChar(A^.Chr)));
               
               VT_CHR:
                  Exit(GetRefdChar(A^.Chr) = GetRefdChar(B^.Chr));
               
               VT_BOO:
                  Exit(StrToBoolDef(GetRefdChar(A^.Chr),FALSE) = B^.Boo^);
            end;
         
         VT_UTF:
            Case  (B^.Typ) of
               VT_INT .. VT_BIN:
                  Exit(A^.Utf^.ToInt(IntBase(B^.Typ)) = B^.Int^);
               
               VT_FLO:
                  Exit(A^.Utf^.ToFloat() = B^.Flo^);
               
               VT_STR:
                  Exit(A^.Utf^.Equals(B^.Str^));
               
               VT_UTF:
                  Exit(A^.Utf^.Equals(B^.Utf));
               
               VT_CHR:
                  Exit(A^.Utf^.Equals(GetRefdChar(B^.Chr)));
               
               VT_BOO:
                  Exit(StrToBoolDef(A^.Utf^.ToAnsiString(),FALSE) = B^.Boo^);
            end;
         
         VT_BOO:
            Case (B^.Typ) of
               VT_INT .. VT_BIN:
                  Exit(A^.Boo^ = (B^.Int^ <> 0));
               
               VT_FLO:
                  Exit(A^.Boo^ = (Abs(B^.Flo^) >= 1.0));
               
               VT_STR:
                  Exit(A^.Boo^ = StrToBoolDef(B^.Str^,FALSE));
               
               VT_UTF:
                  Exit(A^.Boo^ = StrToBoolDef(B^.Utf^.ToAnsiString(),FALSE));
               
               VT_CHR:
                  Exit(A^.Boo^ = StrToBoolDef(GetRefdChar(B^.Chr),FALSE));
               
               VT_BOO:
                  Exit(A^.Boo^ = B^.Boo^);
            end;
         
         VT_NIL:
            Exit(B^.Typ = VT_NIL)
      end;
      Exit(False)
   end;

Function ValNeq(Const A,B:PValue):Boolean;
   begin Exit(Not ValEq(A,B)) end;

Function ValGt(Const A,B:PValue):Boolean;
   {$DEFINE __OPERATOR__ := > }
   {$DEFINE __STR_UTF__  := = -1}
   {$DEFINE __UTF_STR__  := = +1}
   {$DEFINE __UTF_UTF__  := = +1}
   
   {$INCLUDE values_compare-compfunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

Function ValGe(Const A,B:PValue):Boolean;
   {$DEFINE __OPERATOR__ := >= }
   {$DEFINE __STR_UTF__  := <= 0}
   {$DEFINE __UTF_STR__  := >= 0}
   {$DEFINE __UTF_UTF__  := >= 0}
   
   {$INCLUDE values_compare-compfunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

Function ValLt(Const A,B:PValue):Boolean;
   {$DEFINE __OPERATOR__ := < }
   {$DEFINE __STR_UTF__  := = +1}
   {$DEFINE __UTF_STR__  := = -1}
   {$DEFINE __UTF_UTF__  := = -1}
   
   {$INCLUDE values_compare-compfunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

Function ValLe(Const A,B:PValue):Boolean;
   {$DEFINE __OPERATOR__ := <= }
   {$DEFINE __STR_UTF__  := >= 0}
   {$DEFINE __UTF_STR__  := <= 0}
   {$DEFINE __UTF_UTF__  := <= 0}
   
   {$INCLUDE values_compare-compfunc.inc}
   
   {$UNDEF __OPERATOR__}
   {$UNDEF __STR_UTF__}
   {$UNDEF __UTF_STR__}
   {$UNDEF __UTF_UTF__}
   end;

end.
