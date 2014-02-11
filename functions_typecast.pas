unit functions_typecast;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_mkint(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkhex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkoct(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkbin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkflo(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mkstr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_mklog(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   //uses EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('mkint',@F_mkint);
   FT^.SetVal('mkhex',@F_mkhex);
   FT^.SetVal('mkoct',@F_mkoct);
   FT^.SetVal('mkbin',@F_mkbin);
   FT^.SetVal('mkflo',@F_mkflo); FT^.SetVal('mkfloat',@F_mkflo);
   FT^.SetVal('mkstr',@F_mkstr); FT^.SetVal('mkstring',@F_mkstr);
   FT^.SetVal('mklog',@F_mklog); FT^.SetVal('mkbool',@F_mklog);
   end;

Function F_mkint(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(VT_INT)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> VT_INT) then begin
          V:=ValToInt(Arg^[C]); 
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> VT_INT) then begin
         V:=ValToInt(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>VT_INT) then begin
         V:=ValToInt(Arg^[0]); 
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
      If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

Function F_mkhex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(VT_HEX)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> VT_Hex) then begin
          V:=ValToHex(Arg^[C]);
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> VT_Hex) then begin
         V:=ValToHex(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>VT_Hex) then begin
         V:=ValToHex(Arg^[0]); 
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
      If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

Function F_mkoct(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(VT_OCT)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> VT_OCT) then begin
          V:=ValToOct(Arg^[C]); 
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> VT_OCT) then begin
         V:=ValToOct(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>VT_OCT) then begin
         V:=ValToOct(Arg^[0]);
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
      If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

Function F_mkbin(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(VT_BIN)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> VT_BIN) then begin
          V:=ValToBin(Arg^[C]); 
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> VT_BIN) then begin
         V:=ValToBin(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>VT_BIN) then begin
         V:=ValToBin(Arg^[0]); 
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
      If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

Function F_mkflo(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(VT_FLO)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> VT_INT) then begin
          V:=ValToFlo(Arg^[C]); 
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> VT_FLO) then begin
         V:=ValToFlo(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>VT_FLO) then begin
         V:=ValToFlo(Arg^[0]); 
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
      If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

Function F_mkstr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(VT_STR)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> VT_STR) then begin
          V:=ValToStr(Arg^[C]);
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> VT_STR) then begin
         V:=ValToStr(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>VT_STR) then begin
         V:=ValToStr(Arg^[0]);
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
      If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

Function F_mklog(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg^)=0) then begin
      If (DoReturn) then Exit(EmptyVal(VT_BOO)) else Exit(NIL) end;
   For C:=High(Arg^) downto (Low(Arg^)+1) do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]) else
       If (Arg^[C]^.Typ <> VT_BOO) then begin
          V:=ValToBoo(Arg^[C]); 
          SwapPtrs(Arg^[C],V); FreeVal(V)
          end;
   If (Arg^[0]^.Lev >= CurLev) then begin
      If (Arg^[0]^.Typ <> VT_BOO) then begin
         V:=ValToBoo(Arg^[0]); FreeVal(Arg^[0])
         end else V:=Arg^[0];
      If (DoReturn) then Exit(V) else Exit(NIL)
      end else begin
      If (Arg^[0]^.Typ<>VT_BOO) then begin
         V:=ValToBoo(Arg^[0]);
         SwapPtrs(Arg^[0],V); FreeVal(V)
         end;
      If (DoReturn) then Exit(CopyVal(Arg^[0])) else Exit(NIL)
      end
   end;

end.
