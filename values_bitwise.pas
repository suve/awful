unit values_bitwise;

interface
   uses Values;

Function ValNot(A:PValue):PValue;
Function ValAnd(A,B:PValue):PValue;
Function ValXor(A,B:PValue):PValue;
Function ValOr(A,B:PValue):PValue;

implementation

Function ValNot(A:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat; C:LongWord;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=Not PQInt(A^.Ptr)^;
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=Not Trunc(PFloat(A^.Ptr)^);
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      For C:=1 to Length(S^) do S^[C] := Chr(Not Ord(S^[C]))
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=Not PBoolean(A^.Ptr)^;
      end;
   Exit(R)
   end;

Function ValAnd(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=I^ and PQInt(B^.Ptr)^ else
      If (B^.Typ = VT_FLO)
         then (I^):=I^ and Trunc(PFloat(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (I^):=I^ and StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then (I^):=I^ and Ord(PBool(B^.Ptr)^)
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^):=Trunc(D^) and PQInt(B^.Ptr)^ else
      If (B^.Typ = VT_FLO)
         then (D^):=Trunc(D^) and Trunc(PFloat(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (D^):=Trunc(D^) and Trunc(StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO)
         then (D^):=Trunc(D^) and Ord(PBool(B^.Ptr)^)
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      { LOL DUNNO }
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      If (B^.Typ = VT_BOO)
         then L^:=L^ and PBool(B^.Ptr)^
      end;
   Exit(R)
   end;

Function ValXor(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=I^ xor PQInt(B^.Ptr)^ else
      If (B^.Typ = VT_FLO)
         then (I^):=I^ xor Trunc(PFloat(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (I^):=I^ xor StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then (I^):=I^ xor Ord(PBool(B^.Ptr)^)
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^):=Trunc(D^) xor PQInt(B^.Ptr)^ else
      If (B^.Typ = VT_FLO)
         then (D^):=Trunc(D^) xor Trunc(PFloat(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (D^):=Trunc(D^) xor Trunc(StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO)
         then (D^):=Trunc(D^) xor Ord(PBool(B^.Ptr)^)
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      { LOL DUNNO }
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      If (B^.Typ = VT_BOO)
         then L^:=L^ xor PBool(B^.Ptr)^
      end;
   Exit(R)
   end;

Function ValOr(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=I^ or PQInt(B^.Ptr)^ else
      If (B^.Typ = VT_FLO)
         then (I^):=I^ or Trunc(PFloat(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (I^):=I^ or StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then (I^):=I^ or Ord(PBool(B^.Ptr)^)
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^):=Trunc(D^) or PQInt(B^.Ptr)^ else
      If (B^.Typ = VT_FLO)
         then (D^):=Trunc(D^) or Trunc(PFloat(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (D^):=Trunc(D^) or Trunc(StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO)
         then (D^):=Trunc(D^) or Ord(PBool(B^.Ptr)^)
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      { LOL DUNNO }
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      If (B^.Typ = VT_BOO)
         then L^:=L^ or PBool(B^.Ptr)^
      end;
   Exit(R)
   end;

end.
