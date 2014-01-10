unit functions_math;

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_sqrt(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_log(DoReturn:Boolean; Arg:PArrPVal):PValue;


implementation
   uses EmptyFunc, Math;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('sqrt', @F_Sqrt);
   FT^.SetVal('log', @F_Log);
   end;

Function F_sqrt(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; F:TFLoat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_FLO,0.0));
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_FLO) then begin
      F:=Sqrt(PFloat(Arg^[0]^.Ptr)^)
      end else
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then begin
      F:=Sqrt(PQInt(Arg^[0]^.Ptr)^)
      end else begin
      V:=ValToFlo(Arg^[0]);
      F:=Sqrt(PFLoat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_FLO,F))
   end;

Function F_log(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; B,N:TFloat; V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(NilVal);
   If (Length(Arg^) = 1) then begin
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN) then
         N:=Ln(PQInt(Arg^[0]^.Ptr)^) else
      If (Arg^[0]^.Typ = VT_FLO) then
         N:=Ln(PFloat(Arg^[0]^.Ptr)^)
         else begin
         V:=ValToFlo(Arg^[0]); N:=PFloat(V^.Ptr)^; FreeVal(V)
         end;
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Exit(NewVal(VT_FLO, N))
      end;
   C:=High(Arg^);
   If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN) then
      N:=Ln(PQInt(Arg^[C]^.Ptr)^) else
   If (Arg^[C]^.Typ = VT_FLO) then
      N:=Ln(PFloat(Arg^[C]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg^[C]); N:=PFloat(V^.Ptr)^; FreeVal(V)
      end;
   If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   For C:=High(Arg^)-1 downto Low(Arg^) do begin
       If (Arg^[C]^.Typ >= VT_INT) and (Arg^[C]^.Typ <= VT_BIN) then
          B:=Ln(PQInt(Arg^[C]^.Ptr)^) else
       If (Arg^[C]^.Typ = VT_FLO) then
          B:=Ln(PFloat(Arg^[C]^.Ptr)^)
          else begin
          V:=ValToFlo(Arg^[C]); B:=PFloat(V^.Ptr)^; FreeVal(V)
          end;
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
       N := Logn(B, N)
       end;
   Exit(NewVal(VT_FLO, N))
   end;

end.
