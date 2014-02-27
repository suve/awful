unit corefunc;

{$INCLUDE defines.inc}

interface
   uses TokExpr, Values;

Type TCallState = record
        Vars : PValTrie;
        Args : PArrPVal;
        end;

Var FCal : Array of TCallState;
    FLev : LongWord;
    DoExit : Boolean;

Procedure Register(Const FT:PFunTrie);

Function Eval(Const Ret:Boolean; Const E:PExpr):PValue;
Function RunFunc(Const P:LongWord):PValue;

Function F_If(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Else(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_While(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Done(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Until(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Break(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Continue(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Return(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Exit(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_AutoCall(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FuncArgs(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Call(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_FileIncluded(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileIncludes(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_ParamArr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_ParamCnt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_ParamStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses Globals, Parser, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('call',MkFunc(@F_Call));
   FT^.SetVal('return',MkFunc(@F_Return));
   FT^.SetVal('exit',MkFunc(@F_Exit));
   FT^.SetVal('func-args',MkFunc(@F_FuncArgs));
   FT^.SetVal('file-included',MkFunc(@F_FileIncluded));
   FT^.SetVal('file-includes',MkFunc(@F_FileIncludes));
   FT^.SetVal('param-arr',MkFunc(@F_ParamArr));
   FT^.SetVal('param-cnt',MkFunc(@F_ParamCnt));
   FT^.SetVal('param-str',MkFunc(@F_ParamStr))
   end;

Function Eval(Const Ret:Boolean; Const E:PExpr):PValue;
   
   Function GetVar(Name:PStr;Typ:TValueType):PValue;
      Var R:PValue;
      begin
      Try R:=FCal[FLev].Vars^.GetVal(Name^);
          Exit(R)
      Except Try R:=FCal[0].Vars^.GetVal(Name^);
                 Exit(R);
             Except end end;
      R:=EmptyVal(Typ); R^.Lev -= 1;
      FCal[FLev].Vars^.SetVal(Name^,R);
      Exit(R)
      end;
   
   Function GetArr(A:PValue; Index:PToken; Typ:TValueType):PValue;
      Var V,H:PValue; Arr:PArray; Dic:PDict;
          KeyStr : TStr; KeyInt : QInt;
          atk:PArrTk; C:LongWord;
      begin
      If (A^.Typ = VT_ARR) or (A^.Typ = VT_DIC) then begin
         Case (Index^.Typ) of
            TK_EXPR: V:=Eval(RETURN_VALUE_YES, PExpr(Index^.Ptr));
            TK_CONS: V:=PValue(Index^.Ptr);
            TK_LITE: V:=PValue(Index^.Ptr);
            TK_VARI, TK_REFE:
               V:=GetVar(PStr(Index^.Ptr), VT_INT);
            TK_AREF, TK_AVAL: begin
               atk := PArrTk(Index^.Ptr);
               V:=GetVar(PStr(atk^.Ptr), VT_INT);
               For C:=Low(atk^.Ind) to High(atk^.Ind) do
                   V:=GetArr(V, atk^.Ind[C], VT_INT)
               end;
            TK_AFLY: begin
               atk := PArrTk(Index^.Ptr); H:=Eval(RETURN_VALUE_YES, PExpr(atk^.Ptr)); V:=H;
               For C:=Low(atk^.Ind) to High(atk^.Ind) do V:=GetArr(V, atk^.Ind[C], Typ);
               V:=CopyVal(V); FreeVal(H)
               end;
            end;
         If (A^.Typ = VT_ARR) then begin
            If (V^.Typ >= VT_INT) and (V^.Typ <= VT_BIN) then KeyInt:=PQInt(V^.Ptr)^
               else KeyInt:=ValAsInt(V); //begin H:=ValToInt(V); KeyInt:=PQInt(H^.Ptr)^; FreeVal(H) end;
            If (Index^.Typ = TK_EXPR) then FreeVal(V);
            Arr:=PArray(A^.Ptr); 
            Try    V:=Arr^.GetVal(KeyInt)
            Except V:=EmptyVal(Typ); V^.Lev := A^.Lev;
                   Arr^.SetVal(KeyInt, V)
            end end else begin
            If (V^.Typ = VT_STR) then KeyStr:=PStr(V^.Ptr)^
               else KeyStr:=ValAsStr(V); //begin H:=ValToStr(V); KeyStr:=PStr(H^.Ptr)^; FreeVal(H) end;
            If (Index^.Typ = TK_EXPR) then FreeVal(V);
            Dic:=PDict(A^.Ptr);
            Try    V:=Dic^.GetVal(KeyStr)
            Except V:=EmptyVal(Typ); V^.Lev := A^.Lev;
                   Dic^.SetVal(KeyStr, V)
            end end
         end else
      If (A^.Typ = VT_NIL) then V:=A
                           else V:=NilVal();
      Exit(V)
      end;
   
   Var Arg:TArrPVal; T:LongWord; V:PValue; I,L:LongWord; atk:PArrTk; Tp:TValueType;
   begin
   L := Length(E^.Tok); SetLength(Arg, L);
   If (L = 0) then Exit(E^.Fun(Ret, @Arg)); L -= 1;
   //Writeln('Expr^.Ref = ',E^.Ref);
   For T:=L downto 0 do
       Case (E^.Tok[T]^.Typ) of 
          TK_CONS, TK_LITE: begin
             If (E^.Ref = REF_MODIF)
                then Arg[T]:=CopyVal(PValue(E^.Tok[T]^.Ptr))
                else Arg[T]:=PValue(E^.Tok[T]^.Ptr)
             end;
          TK_VARI, TK_REFE: begin
             If (T < L) 
                then Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr),Arg[T+1]^.Typ)
                else Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr),VT_NIL);
             If (E^.Tok[T]^.Typ = TK_VARI) and (E^.Ref = REF_MODIF)
                then Arg[T] := CopyVal(Arg[T])
             end;
          TK_AVAL, TK_AREF: begin
             If (T < L) then Tp:=Arg[T+1]^.Typ else Tp:=VT_NIL;
             atk := PArrTk(E^.Tok[T]^.Ptr); Arg[T]:=GetVar(PStr(atk^.Ptr), VT_DIC);
             For I:=Low(atk^.Ind) to High(atk^.Ind) do Arg[T]:=GetArr(Arg[T], atk^.Ind[I], Tp);
             If (E^.Tok[T]^.Typ = TK_AVAL) and (E^.Ref = REF_MODIF)
                then Arg[T]:=CopyVal(Arg[T])
             end;
          TK_AFLY: begin
             atk := PArrTk(E^.Tok[T]^.Ptr); V:=Eval(RETURN_VALUE_YES, PExpr(atk^.Ptr)); Arg[T]:=V;
             For I:=Low(atk^.Ind) to High(atk^.Ind) do Arg[T]:=GetArr(Arg[T], atk^.Ind[I], Tp);
             Arg[T]:=CopyVal(Arg[T]); FreeVal(V)
             end;
          TK_EXPR: begin
             Arg[T]:=Eval(RETURN_VALUE_YES, PExpr(E^.Tok[T]^.Ptr))
             end
          end;
   Exit(E^.Fun(Ret, @Arg))
   end;

Function RunFunc(Const P:LongWord):PValue;
   Var R:PValue;
   begin
   If (Pr[P].Num = 0) then Exit(NilVal);
   Proc:=P; ExLn:=0; CurLev += 1;
   While (Not DoExit) do begin
      R:=Eval(RETURN_VALUE_NO, Pr[P].Exp[ExLn]); ExLn+=1;
      If (ExLn >= Pr[P].Num)
         then begin CurLev -= 1; Exit(R) end
         else If (R<>NIL) then FreeVal(R)
      end;
   CurLev -= 1;
   Exit(NIL)
   end;

Function F_If(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:Boolean; 
   begin
   If (Length(Arg^)>1) then begin
      R:=True;
      For C:=High(Arg^) downto 1 do begin
          If (Arg^[C]^.Typ = VT_BOO)
             then R := (R) and (PBool(Arg^[C]^.Ptr)^)
             else R := (R) and (ValAsBoo(Arg^[C]));
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end
      end else R:=False;
   If (Not R) then ExLn:=IfArr[PQInt(Arg^[0]^.Ptr)^][1];
   //FreeVal(Arg^[0]);
   Exit(NIL)
   end;

Function F_Else(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; 
   begin
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   ExLn:=IfArr[PQInt(Arg^[0]^.Ptr)^][2];
   //FreeVal(Arg^[0]);
   Exit(NIL)
   end;

Function F_While(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:Boolean; 
   begin
   If (Length(Arg^)>1) then begin
      R:=True;
      For C:=High(Arg^) downto 1 do begin
          If (Arg^[C]^.Typ = VT_BOO)
             then R := (R) and (PBool(Arg^[C]^.Ptr)^)
             else R := (R) and (ValAsBoo(Arg^[C]));
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end
      end else R:=False;
   If (Not R) then ExLn:=WhiArr[PQInt(Arg^[0]^.Ptr)^][2];
   //FreeVal(Arg^[0]);
   Exit(NIL)
   end;

Function F_Done(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; 
   begin
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]); 
   ExLn:=WhiArr[PQInt(Arg^[0]^.Ptr)^][1];
   //FreeVal(Arg^[0]);
   Exit(NIL)
   end;

Function F_Until(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:Boolean;
   begin
   If (Length(Arg^)>1) then begin
      R:=True;
      For C:=High(Arg^) downto 1 do begin
          If (Arg^[C]^.Typ = VT_BOO)
             then R := (R) and (PBool(Arg^[C]^.Ptr)^)
             else R := (R) and (ValAsBoo(Arg^[C]));
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end
      end else R:=False;
   If (Not R) then ExLn:=RepArr[PQInt(Arg^[0]^.Ptr)^][1];
   //FreeVal(Arg^[0]);
   Exit(NIL)
   end;

Function F_Break(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   Case PQInt(Arg^[0]^.Ptr)^ of
       Ord(CT_WHILE): ExLn := WhiArr[PQInt(Arg^[1]^.Ptr)^][2];
      Ord(CT_REPEAT): ExLn := RepArr[PQInt(Arg^[1]^.Ptr)^][2];
                 else ;
      end;
   F_(False, Arg);
   Exit(NIL)
   end;

Function F_Continue(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   Case PQInt(Arg^[0]^.Ptr)^ of
       Ord(CT_WHILE): ExLn := WhiArr[PQInt(Arg^[1]^.Ptr)^][1];
      Ord(CT_REPEAT): ExLn := RepArr[PQInt(Arg^[1]^.Ptr)^][2]-1;
                 else ;
      end;
   F_(False, Arg);
   Exit(NIL)
   end;

Function F_Return(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg^)>1) then
      For C:=Low(Arg^)+1 to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Length(Arg^)>0) then begin
      If (Arg^[0]^.Lev >= CurLev)
         then R:=Arg^[0] else R:=CopyVal(Arg^[0])
      end else R:=NilVal();
   ExLn:=Pr[Proc].Num;
   Exit(R)
   end;

Function F_Exit(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   ExLn:=Pr[Proc].Num; DoExit:=True;
   Exit(NIL)
   end;

Function F_AutoCall(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var P,E:LongWord; A,H,Pass,Want:LongInt; R,TV{,ArrV}:PValue; //Arr:PArray;
   begin
   P:=Proc; E:=ExLn; Proc:=PQInt(Arg^[0]^.Ptr)^;
   
   CurLev += 1; FLev += 1;
   If (FLev > High(FCal)) then begin
      SetLength(FCal, FLev + 1);
      New(FCal[FLev].Vars,Create(#33,#255))
      end;
   FCal[FLev].Args := Arg;
   
   Want:=Length(Pr[Proc].Arg); Pass:=Length(Arg^)-1; // 1st arg is !fun number
   If (Pass>Want) then H:=Want else H:=Pass;
   
   // Insert passed params into vartrie
   If (H > 0) then For A:=0 to (H-1) do begin
      FCal[FLev].Vars^.SetVal(Pr[Proc].Arg[A],Arg^[A+1])
      end;
   
   // Insert missing params into vartie
   If (Want > Pass) then For A:=H to (Want-1) do begin
      FCal[FLev].Vars^.SetVal(Pr[Proc].Arg[A],NilVal())
      end;
   
   R:=RunFunc(Proc);
   
   // Remove params from vartie
   If (Length(Pr[Proc].Arg)>0) then
      For A:=0 to (H-1) do FCal[FLev].Vars^.RemVal(Pr[Proc].Arg[A]);
   
   // Remove user-defined vars from trie
   While (FCal[FLev].Vars^.Count > 0) do begin
      TV:=FCal[FLev].Vars^.RemVal();
      FreeVal(TV)
      end;
   
   // Decrease runlevel and free vals if needed
   FLev -= 1; CurLev -= 1;
   For A:=Low(Arg^) to High(Arg^) do
       If (Arg^[A]^.Lev >= CurLev) then FreeVal(Arg^[A]);
   
   // Set procedure and expression number back to original values and return value
   Proc:=P; ExLn:=E; 
   If (DoReturn) then begin
      If (R<>NIL) then Exit(R)
                  else Exit(NilVal()) end
      else begin
      If (R<>NIL) then FreeVal(R);
      Exit(NIL)
   end end;


Function F_FuncArgs(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var AV:PValue; Arr:PArray; C:LongWord;
   begin
   If ((Not DoReturn) or (FLev = 0)) then Exit(F_(DoReturn, Arg));
   AV:=NewVal(VT_ARR); Arr:=PArray(AV^.Ptr);
   For C:=1 to High(FCal[FLev].Args^) do
       Arr^.SetVal(C-1, FCal[FLev].Args^[C]);
   Exit(AV)
   end;

Function F_Call(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var FPtr:TFunc; S:TStr;
   
   Function BuiltInCall():PValue;
      Var C:LongWord; NArg:TArrPVal;
      begin
      SetLength(NArg, Length(Arg^)-1);
      For C:=1 to High(Arg^) do NArg[C-1] := Arg^[C];
      Exit(TBuiltIn(FPtr.Ptr)(DoReturn, @NArg))
      end;
   
   begin
   If (Length(Arg^) = 0) then Exit(NilVal());
   S:=ValAsStr(Arg^[0]);
   If (Length(S)>0) and (S[1]=':') then Delete(S,1,1);
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Try
      FPtr := Func^.GetVal(S);
      If (FPtr.Usr) then begin
         Arg^[0] := NewVal(VT_INT, FPtr.Ptr);
         Exit(F_AutoCall(DoReturn, Arg))
         end else
         Exit(BuiltInCall())
   Except
      FPtr.Ptr := PtrUInt(@F_);
      Exit(BuiltInCall())
      end
   end;

Function F_FileIncludes(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var AV:PValue; Arr:PArray; C:LongWord;
   begin
   F_(False, Arg); If (Not DoReturn) then Exit(NIL);
   AV:=NewVal(VT_ARR); Arr:=PArray(AV^.Ptr);
   For C:=Low(FileIncludes) to High(FileIncludes) do
       Arr^.SetVal(C, NewVal(VT_STR, FileIncludes[C].Name));
   Exit(AV)
   end;

Function F_FileIncluded(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var A,F:LongWord; Return,ThisFile:Boolean; FName:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(NewVal(VT_BOO, False));
   Return := True;
   For A:=High(Arg^) downto Low(Arg^) do begin
       If (Arg^[A]^.Typ = VT_STR) then FName := PStr(Arg^[A]^.Ptr)^
          else FName := ValAsStr(Arg^[A]);
       ThisFile := False;
       For F:=Low(FileIncludes) to High(FileIncludes) do
           If (FileIncludes[F].Name = FName) then begin
              ThisFile:=True; Break
              end;
       Return := Return and ThisFile;
       If (Not Return) then Break
       end;
   F_(False, Arg);
   Exit(NewVal(VT_BOO, Return))
   end;

Function F_ParamArr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; Arr:PArray;
   begin
   F_(False, Arg); If (Not DoReturn) then Exit(NIL);
   V := NewVal(VT_ARR); Arr := PArray(V^.Ptr);
   For C:=0 to (ParamCount() - ParamNum + 1) do
       Arr^.SetVal(C, NewVal(VT_STR, ParamStr(ParamNum + C)));
   Exit(V)
   end;

Function F_ParamCnt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   F_(False, Arg); If (Not DoReturn) then Exit(NIL);
   Exit(NewVal(VT_INT, ParamCount() - ParamNum + 1))
   end;

Function F_ParamStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Idx : QInt; R:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(F_(True, Arg));
   Idx := ParamNum + ValAsInt(Arg^[0]);
   If (Idx >= ParamNum) and (Idx <= ParamCount())
      then R := NewVal(VT_STR, ParamStr(Idx))
      else R := NilVal();
   F_(False, Arg);
   Exit(R)
   end;

end.
