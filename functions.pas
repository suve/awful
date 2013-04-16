unit functions;

interface
   uses Values;

//Var Quit:Boolean = FALSE;

Procedure Register(FT:PFunTrie);

Function F_(Arg:Array of PValue):PValue;

Function F_Write(Arg:Array of PValue):PValue;
Function F_Writeln(Arg:Array of PValue):PValue;

Function F_Set(Arg:Array of PValue):PValue;
Function F_Add(Arg:Array of PValue):PValue;
Function F_Sub(Arg:Array of PValue):PValue;
Function F_Mul(Arg:Array of PValue):PValue;
Function F_Div(Arg:Array of PValue):PValue;
Function F_Mod(Arg:Array of PValue):PValue;
Function F_Pow(Arg:Array of PValue):PValue;

implementation

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('',@F_);
   FT^.SetVal('write',@F_Write);
   FT^.SetVal('writeln',@F_Writeln);
   FT^.SetVal('set',@F_Set);
   FT^.SetVal('add',@F_Add);
   FT^.SetVal('sub',@F_Sub);
   FT^.SetVal('mul',@F_Mul);
   FT^.SetVal('div',@F_Div);
   FT^.SetVal('mod',@F_Mod);
   FT^.SetVal('pow',@F_Pow);
   end;

Function F_(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)=0) then Exit();
   For C:=Low(Arg) to High(Arg) do
       If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   Exit(NilVal)
   end;

Function F_Write(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)=0) then Exit();
   For C:=Low(Arg) to High(Arg) do begin
       Case Arg[C]^.Typ of
          VT_NIL: Write('&#191;nilvar?');
          VT_INT: Write(PQInt(Arg[C]^.Ptr)^);
          VT_HEX: Write(HexToStr(PQInt(Arg[C]^.Ptr)^));
          VT_OCT: Write(OctToStr(PQInt(Arg[C]^.Ptr)^));
          VT_BIN: Write(BinToStr(PQInt(Arg[C]^.Ptr)^));
          VT_FLO: Write(PDouble(Arg[C]^.Ptr)^:0:RealPrec);
          VT_BOO: Write(PBoolean(Arg[C]^.Ptr)^);
          VT_STR: Write(PAnsiString(Arg[C]^.Ptr)^);
          end;
       If (Arg[C]^.Tmp) then FreeVal(Arg[C])
       end;
   Exit(NilVal)
   end;

Function F_Writeln(Arg:Array of PValue):PValue;
   Var R:PValue;
   begin
   R:=F_Write(Arg);
   Writeln();
   Exit(R)
   end;

Function F_Set(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValSet(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Tmp) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Tmp) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Tmp) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Add(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValAdd(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Tmp) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Tmp) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Tmp) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Sub(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValSub(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Tmp) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Tmp) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Tmp) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Mul(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValMul(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Tmp) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Tmp) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Tmp) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Div(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValDiv(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Tmp) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Tmp) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Tmp) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Mod(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValMod(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Tmp) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Tmp) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Tmp) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Pow(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValPow(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Tmp) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Tmp) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Tmp) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

end.
