unit values_compare;

interface
   uses Values;

Function ValSeq(A,B:PValue):Boolean;
Function ValSNeq(A,B:PValue):Boolean;
Function ValEq(A,B:PValue):Boolean;
Function ValNeq(A,B:PValue):Boolean;
Function ValGt(A,B:PValue):Boolean;
Function ValGe(A,B:PValue):Boolean;
Function ValLt(A,B:PValue):Boolean;
Function ValLe(A,B:PValue):Boolean;

implementation
   uses SysUtils;

Function ValSeq(A,B:PValue):Boolean;
   begin
   If (A^.Typ <> B^.Typ) then Exit(False);
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then
      Exit((PQInt(A^.Ptr)^) = (PQInt(B^.Ptr)^)) else
   If (A^.Typ = VT_FLO) then
      Exit((PFloat(A^.Ptr)^) = (PFloat(B^.Ptr)^)) else
   If (A^.Typ = VT_STR) then
      Exit((PStr(A^.Ptr)^) = (PStr(B^.Ptr)^)) else
   If (A^.Typ = VT_BOO) then
      Exit((PBool(A^.Ptr)^) = (PBool(B^.Ptr)^)) else
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(True) else
      {else} Exit(False)
   end;

Function ValSNeq(A,B:PValue):Boolean;
   begin Exit(Not ValSeq(A,B)) end;

Function ValEq(A,B:PValue):Boolean;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PQInt(A^.Ptr)^) = (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PQInt(A^.Ptr)^) = Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PQInt(A^.Ptr)^) = StrToNum(PStr(B^.Ptr)^,A^.Typ)) else
      If (B^.Typ = VT_BOO) then
         Exit((PQInt(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(Trunc(PFloat(A^.Ptr)^) = (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PFloat(A^.Ptr)^) = (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PFloat(A^.Ptr)^) = StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit(Trunc(PFloat(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(StrToNum(PStr(A^.Ptr)^,B^.Typ) = (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(StrToReal(PStr(A^.Ptr)^) = (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PStr(A^.Ptr)^) = (PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit(StrToBoolDef(PStr(A^.Ptr)^,FALSE) = (PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PBool(A^.Ptr)^) = (PQInt(B^.Ptr)^ <> 0)) else
      If (B^.Typ = VT_FLO) then
         Exit((PBool(A^.Ptr)^) = (PFloat(B^.Ptr)^ <> 0.0)) else
      If (B^.Typ = VT_STR) then
         Exit((PBool(A^.Ptr)^) = StrToBoolDef(PStr(B^.Ptr)^,FALSE)) else
      If (B^.Typ = VT_BOO) then
         Exit((PBool(A^.Ptr)^) = (PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(True)
      else
      Exit(False)
   end;

Function ValNeq(A,B:PValue):Boolean;
   begin Exit(Not ValEq(A,B)) end;

Function ValGt(A,B:PValue):Boolean;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PQInt(A^.Ptr)^) > (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PQInt(A^.Ptr)^) > Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PQInt(A^.Ptr)^) > StrToNum(PStr(B^.Ptr)^,A^.Typ)) else
      If (B^.Typ = VT_BOO) then
         Exit((PQInt(A^.Ptr)^) > BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PFloat(A^.Ptr)^) > TFloat(PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PFloat(A^.Ptr)^) > (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PFloat(A^.Ptr)^) > StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit((PFloat(A^.Ptr)^) > TFloat(BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(StrToNum(PStr(A^.Ptr)^,B^.Typ) > (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(StrToReal(PStr(A^.Ptr)^) > (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PStr(A^.Ptr)^) > (PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) > BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(BoolToInt(PBool(A^.Ptr)^) > (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) > Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit(BoolToInt(PBool(A^.Ptr)^) > BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE))) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) > BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(False)
      else
      Exit(False)
   end;

Function ValGe(A,B:PValue):Boolean;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PQInt(A^.Ptr)^) >= (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PQInt(A^.Ptr)^) >= Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PQInt(A^.Ptr)^) >= StrToNum(PStr(B^.Ptr)^,A^.Typ)) else
      If (B^.Typ = VT_BOO) then
         Exit((PQInt(A^.Ptr)^) >= BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PFloat(A^.Ptr)^) >= TFloat(PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PFloat(A^.Ptr)^) >= (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PFloat(A^.Ptr)^) >= StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit((PFloat(A^.Ptr)^) >= TFloat(BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(StrToNum(PStr(A^.Ptr)^,B^.Typ) >= (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(StrToReal(PStr(A^.Ptr)^) >= (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PStr(A^.Ptr)^) >= (PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) >= BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(BoolToInt(PBool(A^.Ptr)^) >= (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) >= Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit(BoolToInt(PBool(A^.Ptr)^) >= BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE))) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) >= BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(True)
      else
      Exit(False)
   end;

Function ValLt(A,B:PValue):Boolean;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PQInt(A^.Ptr)^) < (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PQInt(A^.Ptr)^) < Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PQInt(A^.Ptr)^) < StrToNum(PStr(B^.Ptr)^,A^.Typ)) else
      If (B^.Typ = VT_BOO) then
         Exit((PQInt(A^.Ptr)^) < BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PFloat(A^.Ptr)^) < TFloat(PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PFloat(A^.Ptr)^) < (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PFloat(A^.Ptr)^) < StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit((PFloat(A^.Ptr)^) < TFloat(BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(StrToNum(PStr(A^.Ptr)^,B^.Typ) < (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(StrToReal(PStr(A^.Ptr)^) < (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PStr(A^.Ptr)^) < (PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) < BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(BoolToInt(PBool(A^.Ptr)^) < (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) < Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit(BoolToInt(PBool(A^.Ptr)^) < BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE))) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) < BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(False)
      else
      Exit(False)
   end;

Function ValLe(A,B:PValue):Boolean;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PQInt(A^.Ptr)^) <= (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PQInt(A^.Ptr)^) <= Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PQInt(A^.Ptr)^) <= StrToNum(PStr(B^.Ptr)^,A^.Typ)) else
      If (B^.Typ = VT_BOO) then
         Exit((PQInt(A^.Ptr)^) <= BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit((PFloat(A^.Ptr)^) <= TFloat(PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit((PFloat(A^.Ptr)^) <= (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PFloat(A^.Ptr)^) <= StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit((PFloat(A^.Ptr)^) <= TFloat(BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(StrToNum(PStr(A^.Ptr)^,B^.Typ) <= (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(StrToReal(PStr(A^.Ptr)^) <= (PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit((PStr(A^.Ptr)^) <= (PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) <= BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(BoolToInt(PBool(A^.Ptr)^) <= (PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) <= Trunc(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR) then
         Exit(BoolToInt(PBool(A^.Ptr)^) <= BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE))) else
      If (B^.Typ = VT_BOO) then
         Exit(BoolToInt(PBool(A^.Ptr)^) <= BoolToInt(PBool(B^.Ptr)^)) else
         {else} Exit(False)
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(False)
      else
      Exit(False)
   end;

end.
