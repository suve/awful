unit functions;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_FilePath(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_FileName(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_Sleep(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Ticks(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_FileTicks(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_Set(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Add(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Sub(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Mul(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Div(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Mod(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Pow(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_And(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Or(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Xor(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Not(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_Eq(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Seq(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Neq(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SNeq(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Gt(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Ge(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Lt(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Le(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_SetPrecision(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Perc(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_sqrt(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_fork(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_random(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_sizeof(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_typeof(DoReturn:Boolean; Arg:Array of PValue):PValue;

implementation
   uses SysUtils, EmptyFunc;

Procedure Register(FT:PFunTrie);
   begin
   // Arithmetics
   FT^.SetVal('set',@F_Set);   FT^.SetVal('=',@F_Set);
   FT^.SetVal('add',@F_Add);   FT^.SetVal('+',@F_Add);
   FT^.SetVal('sub',@F_Sub);   FT^.SetVal('-',@F_Sub);
   FT^.SetVal('mul',@F_Mul);   FT^.SetVal('*',@F_Mul);
   FT^.SetVal('div',@F_Div);   FT^.SetVal('/',@F_Div);
   FT^.SetVal('mod',@F_Mod);   FT^.SetVal('%',@F_Mod);
   FT^.SetVal('pow',@F_Pow);   FT^.SetVal('^',@F_Pow);
   // Comparisons
   FT^.SetVal('eq',@F_Eq);     FT^.SetVal('==',@F_Eq);
   FT^.SetVal('neq',@F_NEq);   FT^.SetVal('!=',@F_NEq);   FT^.SetVal('<>',@F_NEq);
   FT^.SetVal('seq',@F_SEq);   FT^.SetVal('===',@F_SEq);
   FT^.SetVal('sneq',@F_SNEq); FT^.SetVal('!==',@F_SNEq);
   FT^.SetVal('gt',@F_gt);     FT^.SetVal('>',@F_Gt);
   FT^.SetVal('ge',@F_ge);     FT^.SetVal('>=',@F_Ge);
   FT^.SetVal('lt',@F_lt);     FT^.SetVal('<',@F_Lt);
   FT^.SetVal('le',@F_le);     FT^.SetVal('<=',@F_Le);
   FT^.SetVal('not',@F_not);   FT^.SetVal('!',@F_Not);    //FT^.SetVal('~',@F_Not);
   FT^.SetVal('and',@F_and);   FT^.SetVal('&&',@F_and);
   FT^.SetVal('xor',@F_xor);   FT^.SetVal('^^',@F_xor);
   FT^.SetVal('or' ,@F_or);    FT^.SetVal('||',@F_or);
   // Loadsa shit
   FT^.SetVal('sleep',@F_Sleep);
   FT^.SetVal('ticks',@F_Ticks);
   FT^.SetVal('fileticks',@F_FileTicks);
   FT^.SetVal('filename',@F_FileName);
   FT^.SetVal('filepath',@F_FilePath);
   FT^.SetVal('floatprec',@F_SetPrecision);
   FT^.SetVal('perc',@F_Perc);
   FT^.SetVal('sqrt',@F_sqrt);
   FT^.SetVal('fork',@F_fork);
   FT^.SetVal('random',@F_random);
   FT^.SetVal('sizeof',@F_sizeof);
   FT^.SetVal('typeof',@F_typeof);
   end;

Function F_FilePath(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_STR,YukPath)) else Exit(NIL)
   end;

Function F_FileName(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_STR,ExtractFileName(YukPath))) else Exit(NIL)
   end;
   
Function F_Ticks(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; TS:Comp;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Not DoReturn) then Exit(NIL);
   TS:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   Exit(NewVal(VT_INT,Trunc(TS-GLOB_ms)))
   end;

Function F_FileTicks(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; TS:Comp;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Not DoReturn) then Exit(NIL);
   TS:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   Exit(NewVal(VT_INT,Trunc(TS-GLOB_sms)))
   end;

Function F_Sleep(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; Dur:LongWord;
       ms_st, ms_en : Comp;
   begin
   ms_st:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   If (Length(Arg)=0) then Dur:=1000
      else begin
      If (Length(Arg)>1) then
         For C:=High(Arg) downto 1 do
             If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
      If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
         then Dur:=PQInt(Arg[0]^.Ptr)^ else
      If (Arg[0]^.Typ = VT_FLO)
         then Dur:=Trunc(1000*PFloat(Arg[0]^.Ptr)^)
         else begin
         V:=ValToInt(Arg[0]);
         Dur:=PQInt(V^.Ptr)^;
         FreeVal(V)
         end;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0])
      end;
   SysUtils.Sleep(Dur);
   If (Not DoReturn) then Exit(NIL);
   ms_en:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   Exit(NewVal(VT_INT,Trunc(ms_en - ms_st)))
   end;

Function F_Set(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValSet(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Not DoReturn) then Exit(NIL);
   If (Arg[0]^.Lev >= CurLev) then Exit(Arg[0])
                              else Exit(CopyVal(Arg[0]))
   end;

Function F_Add(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValAdd(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Not DoReturn) then Exit(NIL);
   If (Arg[0]^.Lev >= CurLev) then Exit(Arg[0])
                              else Exit(CopyVal(Arg[0]))
   end;

Function F_Sub(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValSub(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Not DoReturn) then Exit(NIL);
   If (Arg[0]^.Lev >= CurLev) then Exit(Arg[0])
                              else Exit(CopyVal(Arg[0]))
   end;

Function F_Mul(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValMul(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Not DoReturn) then Exit(NIL);
   If (Arg[0]^.Lev >= CurLev) then Exit(Arg[0])
                              else Exit(CopyVal(Arg[0]))
   end;

Function F_Div(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValDiv(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Not DoReturn) then Exit(NIL);
   If (Arg[0]^.Lev >= CurLev) then Exit(Arg[0])
                              else Exit(CopyVal(Arg[0]))
   end;

Function F_Mod(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValMod(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Not DoReturn) then Exit(NIL);
   If (Arg[0]^.Lev >= CurLev) then Exit(Arg[0])
                              else Exit(CopyVal(Arg[0]))
   end;

Function F_Pow(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValPow(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Not DoReturn) then Exit(NIL);
   If (Arg[0]^.Lev >= CurLev) then Exit(Arg[0])
                              else Exit(CopyVal(Arg[0]))
   end;

Function F_Not(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, True)) else Exit(NIL) end;
   If (Length(Arg)>1) then 
       For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_BOO) then B:=PBool(Arg[0]^.Ptr)^
      else begin
      V:=ValToBoo(Arg[0]); B:=PBool(V^.Ptr)^; FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO,Not B)) else Exit(NIL)
   end;

Function F_And(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=True;
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg)>=1) then 
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B and (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B and (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Xor(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=False;
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg)>=1) then 
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B xor (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B xor (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Or(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=False;
   If (Length(Arg)=0) then begin
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL) end;
   If (Length(Arg)>=1) then 
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B or (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B or (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_BOO,B)) else Exit(NilVal)
   end;

Function F_Eq(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_NEq(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValNEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_SEq(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValSEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_SNEq(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValSNEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_Gt(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValGt(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_Ge(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValGe(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_Lt(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValLt(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_Le(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg) < 2) then begin
      If ((Length(Arg) = 1) and (Arg[0]^.Lev >= CurLev)) then FreeVal(Arg[0]);
      If (DoReturn) then Exit(NewVal(VT_BOO, False)) else Exit(NIL)
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValLe(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (DoReturn) then Exit(NewVal(VT_BOO, R)) else Exit(NilVal)
   end;

Function F_SetPrecision(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,Values.RealPrec));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
      then Values.RealPrec:=PQInt(Arg[0]^.Ptr)^
      else begin
      V:=ValToInt(Arg[0]);
      Values.RealPrec:=PQInt(V^.Ptr)^;
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (Not DoReturn) then Exit(NewVal(VT_INT,Values.RealPrec)) else Exit(NIL)
   end;

Function F_Perc(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; A,V:PValue; I:PQInt; S:AnsiString; D:PFloat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,'0%'));
   If (Length(Arg)>2) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)>=2) then begin
      If (Arg[0]^.Typ = VT_FLO) then begin
         A:=CopyVal(Arg[0]); D:=PFloat(A^.Ptr); (D^)*=100;
         V:=ValDiv(A,Arg[1]); FreeVal(A);
         S:=IntToStr(Trunc(PFloat(V^.Ptr)^))+'%';
         FreeVal(V)
         end else begin
         If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
            then A:=CopyVal(Arg[0]) else A:=ValToInt(Arg[0]);
         I:=PQInt(A^.Ptr); (I^)*=100;
         V:=ValDiv(A,Arg[1]); FreeVal(A);
         S:=IntToStr(PQInt(V^.Ptr)^)+'%';
         FreeVal(V)
         end
      end else begin
      If (Arg[0]^.Typ = VT_FLO)
         then S:=IntToStr(Trunc(100*PFloat(Arg[0]^.Ptr)^))+'%'
         else begin
         A:=ValToFlo(Arg[0]);
         S:=IntToStr(Trunc(100*PFloat(A^.Ptr)^))+'%';
         FreeVal(A)
         end
      end;
   If (Length(Arg) >= 2) and (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
   If (Length(Arg) >= 1) and (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_fork(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)>3) then For C:=High(Arg) downto 3 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_BOO) then begin
      R:=PBool(Arg[0]^.Ptr)^;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0])
      end else begin
      V:=ValToBoo(Arg[0]); R:=PBool(V^.Ptr)^;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      FreeVal(V)
      end;
   If (R) then begin
      If (Length(Arg)=1) then Exit(NewVal(VT_BOO,True));
      If (Length(Arg)>2) then If (Arg[2]^.Lev >= CurLev) then FreeVal(Arg[2]);
      If (Arg[1]^.Lev >= CurLev) then Exit(Arg[1]) else Exit(CopyVal(Arg[1]))
      end else begin
      If (Length(Arg)<3) then begin
         If (Length(Arg)=2) then If (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
         Exit(NewVal(VT_BOO,False))
         end;
      If (Arg[2]^.Lev >= CurLev) then Exit(Arg[2]) else Exit(CopyVal(Arg[2]))
      end
   end;

Function F_random(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; DH,DL:TFloat; IH,IL:QInt; Ch:Char;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>2) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)=2) then begin
      If (Arg[0]^.Typ = VT_FLO) then begin
         If (Arg[1]^.Typ <> VT_FLO) then begin
            V:=ValToFlo(Arg[1]);
            If (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
            Arg[1]:=V 
            end;
         If (PFloat(Arg[0]^.Ptr)^ <= PFloat(Arg[1]^.Ptr)^)
            then begin DL:=PFloat(Arg[0]^.Ptr)^; DH:=PFloat(Arg[1]^.Ptr)^ end
            else begin DL:=PFloat(Arg[1]^.Ptr)^; DH:=PFloat(Arg[0]^.Ptr)^ end;
         DH:=DL+((DH-DL)*System.Random());
         For C:=1 downto 0 do If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
         Exit(NewVal(VT_FLO,DH))
         end else begin
         For C:=1 downto 0 do
             If (Arg[C]^.Typ<VT_INT) or (Arg[C]^.Typ>VT_BIN) then begin
                V:=ValToInt(Arg[C]); If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
                Arg[C]:=V end;
         If (PQInt(Arg[0]^.Ptr)^ <= PQInt(Arg[1]^.Ptr)^)
            then begin IL:=PQInt(Arg[0]^.Ptr)^; IH:=PQInt(Arg[1]^.Ptr)^ end
            else begin IL:=PQInt(Arg[1]^.Ptr)^; IH:=PQInt(Arg[0]^.Ptr)^ end;
         IH:=IL+System.Random(IH-IL+1);
         V:=NewVal(Arg[0]^.Typ,IH);
         For C:=1 downto 0 do If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
         Exit(V)
      end end else
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Typ = VT_STR) then begin
         If (Length(PStr(Arg[0]^.Ptr)^)=0) then begin
            If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
            Exit(NewVal(VT_STR,''))
            end;
         Ch:=(PStr(Arg[0]^.Ptr)^)[1+Random(Length(PStr(Arg[0]^.Ptr)^))];
         If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
         Exit(NewVal(VT_STR,Ch))
         end else begin
         If (Arg[0]^.Typ < VT_INT) or (Arg[0]^.Typ > VT_BIN) then begin
            V:=ValToInt(Arg[0]); If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
            Arg[0]:=V end;
         IH:=Random(PQInt(Arg[0]^.Ptr)^);
         V:=NewVal(Arg[0]^.Typ,IH);
         If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
         Exit(V)
      end end else
      Exit(NewVal(VT_FLO,System.Random()))
   end;

Function F_sqrt(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; F:TFLoat;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_FLO,0.0));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO) then begin
      F:=Sqrt(PFloat(Arg[0]^.Ptr)^)
      end else
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN) then begin
      F:=Sqrt(PQInt(Arg[0]^.Ptr)^)
      end else begin
      V:=ValToFlo(Arg[0]);
      F:=Sqrt(PFLoat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_FLO,F))
   end;

Function F_sizeof(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; 
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ <> VT_STR) then begin
      V:=ValToStr(Arg[0]);
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Arg[0]:=V
      end;
   If (PStr(Arg[0]^.Ptr)^ = 'flo'   ) then C:=SizeOf(TFloat) else
   If (PStr(Arg[0]^.Ptr)^ = 'int'   ) then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'hex'   ) then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'oct'   ) then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'bin'   ) then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'str'   ) then C:=SizeOf(TStr) else
   If (PStr(Arg[0]^.Ptr)^ = 'log'   ) then C:=SizeOf(Bool) else
   If (PStr(Arg[0]^.Ptr)^ = 'float' ) then C:=SizeOf(TFloat) else
   If (PStr(Arg[0]^.Ptr)^ = 'string') then C:=SizeOf(TStr) else
   If (PStr(Arg[0]^.Ptr)^ = 'bool'  ) then C:=SizeOf(Bool) else
   If (PStr(Arg[0]^.Ptr)^ = 'arr'   ) then C:=SizeOf(TValTree) else
   If (PStr(Arg[0]^.Ptr)^ = 'array' ) then C:=SizeOf(TValTree) else
   If (PStr(Arg[0]^.Ptr)^ = 'dict'  ) then C:=SizeOf(TValTrie) else
      (* else *) C:=0;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_INT,C*8))
   end;

Function F_typeof(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Case (Arg[0]^.Typ) of
      VT_NIL: V:=NewVal(VT_STR, 'nil');
      VT_NEW: V:=NewVal(VT_STR, 'new');
      VT_BOO: V:=NewVal(VT_STR, 'bool');
      VT_BIN: V:=NewVal(VT_STR, 'bin');
      VT_OCT: V:=NewVal(VT_STR, 'oct');
      VT_INT: V:=NewVal(VT_STR, 'int');
      VT_HEX: V:=NewVal(VT_STR, 'hex');
      VT_FLO: V:=NewVal(VT_STR, 'float');
      VT_STR: V:=NewVal(VT_STR, 'string');
      VT_ARR: V:=NewVal(VT_STR, 'array');
      VT_DIC: V:=NewVal(VT_STR, 'dict');
      else V:=NewVal(VT_STR, '???')
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(V)
   end;

end.
