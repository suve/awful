unit corefunc;

{$INCLUDE defines.inc}

interface
   uses TokExpr, Values;

Type TCallState = record
        Vars : PDict;
        Args : PArrPVal;
        end;

Var FCal : Array of TCallState;
    FLev : LongWord;
    DoExit : Boolean;

Procedure Register(FT:PFunTrie);

Function Eval(Ret:Boolean; E:PExpr):PValue;
Function RunFunc(P:LongWord):PValue;

Function F_If(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Else(DoReturn:Boolean; Arg:PArrPVal):PValue;

Function F_While(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Done(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Until(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Return(DoReturn:Boolean; Arg:PArrPVal):PValue;

Function F_Exit(DoReturn:Boolean; Arg:PArrPVal):PValue;

Function F_AutoCall(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_FuncArgs(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_Call(DoReturn:Boolean; Arg:PArrPVal):PValue;

Function F_FileIncluded(DoReturn:Boolean; Arg:PArrPVal):PValue;
Function F_FileIncludes(DoReturn:Boolean; Arg:PArrPVal):PValue;

implementation
   uses Globals, Parser, EmptyFunc;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('call',@F_Call);
   FT^.SetVal('return',@F_Return);
   FT^.SetVal('exit',@F_Exit);
   FT^.SetVal('func-args',@F_FuncArgs);
   FT^.SetVal('file-included',@F_FileIncluded);
   FT^.SetVal('file-includes',@F_FileIncludes);
   end;

Function Eval(Ret:Boolean; E:PExpr):PValue;
   
   Function GetVar(Name:AnsiString;Typ:TValueType):PValue;
      Var R:PValue;
      begin
      Try R:=FCal[FLev].Vars^.GetVal(Name);
          Exit(R)
      Except Try R:=FCal[0].Vars^.GetVal(Name);
                 Exit(R);
             Except end end;
      R:=EmptyVal(Typ); R^.Lev -= 1;
      FCal[FLev].Vars^.SetVal(Name,R);
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
               V:=GetVar(PStr(Index^.Ptr)^, VT_INT);
            TK_AREF, TK_AVAL: begin
               atk := PArrTk(Index^.Ptr);
               V:=GetVar(PStr(atk^.Ptr)^, VT_INT);
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
               else begin H:=ValToInt(V); KeyInt:=PQInt(H^.Ptr)^; FreeVal(H) end;
            If (Index^.Typ = TK_EXPR) then FreeVal(V);
            Arr:=PArray(A^.Ptr); 
            Try    V:=Arr^.GetVal(KeyInt)
            Except V:=EmptyVal(Typ); V^.Lev := A^.Lev;
                   Arr^.SetVal(KeyInt, V)
            end end else begin
            If (V^.Typ = VT_STR) then KeyStr:=PStr(V^.Ptr)^
               else begin H:=ValToStr(V); KeyStr:=PStr(H^.Ptr)^; FreeVal(H) end;
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
   
   Var Arg:TArrPVal; T:LongWord; V:PValue; I:LongWord; atk:PArrTk; Tp:TValueType;
   begin
   SetLength(Arg,Length(E^.Tok));
   If (Length(E^.Tok)=0) then Exit(E^.Fun(Ret, @Arg));
   For T:=High(E^.Tok) downto Low(E^.Tok) do
       Case (E^.Tok[T]^.Typ) of 
          TK_CONS: begin
             Arg[T]:=CopyVal(PValue(E^.Tok[T]^.Ptr))
             end;
          TK_LITE: begin
             Arg[T]:=CopyVal(PValue(E^.Tok[T]^.Ptr))
             end;
          TK_VARI: begin
             If (T<High(E^.Tok)) 
                then V:=GetVar(PStr(E^.Tok[T]^.Ptr)^,Arg[T+1]^.Typ)
                else V:=GetVar(PStr(E^.Tok[T]^.Ptr)^,VT_NIL);
             Arg[T]:=CopyVal(V)
             end;
          TK_REFE: begin
             If (T<High(E^.Tok)) 
                then Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr)^,Arg[T+1]^.Typ)
                else Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr)^,VT_NIL);
             end;
          TK_AVAL, TK_AREF: begin
             If (T<High(E^.Tok)) then Tp:=Arg[T+1]^.Typ else Tp:=VT_NIL;
             atk := PArrTk(E^.Tok[T]^.Ptr); V:=GetVar(PStr(atk^.Ptr)^, VT_DIC);
             For I:=Low(atk^.Ind) to High(atk^.Ind) do V:=GetArr(V, atk^.Ind[I], Tp);
             If (E^.Tok[T]^.Typ = TK_AVAL) then Arg[T]:=CopyVal(V) else Arg[T]:=V
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

Function RunFunc(P:LongWord):PValue;
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

Function F_If(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; IfNum:QInt; R:Boolean; V:PValue;
   begin
   If (Length(Arg^)>1) then begin
      R:=True;
      For C:=High(Arg^) downto 1 do begin
          If (Arg^[C]^.Typ = VT_BOO) then begin
             If (Not PBool(Arg^[C]^.Ptr)^) then R:=False
             end else begin
             V:=ValToBoo(Arg^[C]);
             If (Not PBool(V^.Ptr)^) then R:=False;
             FreeVal(V)
             end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end
      end else R:=False;
   IfNum:=PQInt(Arg^[0]^.Ptr)^; FreeVal(Arg^[0]);
   If (Not R) then ExLn:=IfArr[IfNum][1];
   Exit(NIL)
   end;

Function F_Else(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; IfNum:QInt;
   begin
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   IfNum:=PQInt(Arg^[0]^.Ptr)^; FreeVal(Arg^[0]);
   ExLn:=IfArr[IfNum][2];
   Exit(NIL)
   end;

Function F_While(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; WhiNum:QInt; R:Boolean; V:PValue;
   begin
   If (Length(Arg^)>1) then begin
      R:=True;
      For C:=High(Arg^) downto 1 do begin
          If (Arg^[C]^.Typ = VT_BOO) then begin
             If (Not PBool(Arg^[C]^.Ptr)^) then R:=False
             end else begin
             V:=ValToBoo(Arg^[C]);
             If (Not PBool(V^.Ptr)^) then R:=False;
             FreeVal(V)
             end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end
      end else R:=False;
   WhiNum:=PQInt(Arg^[0]^.Ptr)^; FreeVal(Arg^[0]);
   If (Not R) then ExLn:=WhiArr[WhiNum][2];
   Exit(NIL)
   end;

Function F_Done(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; WhiNum:QInt;
   begin
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   WhiNum:=PQInt(Arg^[0]^.Ptr)^; FreeVal(Arg^[0]);
   ExLn:=WhiArr[WhiNum][1];
   Exit(NIL)
   end;

Function F_Until(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; RepNum:QInt; R:Boolean; V:PValue;
   begin
   If (Length(Arg^)>1) then begin
      R:=True;
      For C:=High(Arg^) downto 1 do begin
          If (Arg^[C]^.Typ = VT_BOO) then begin
             If (Not PBool(Arg^[C]^.Ptr)^) then R:=False
             end else begin
             V:=ValToBoo(Arg^[C]);
             If (Not PBool(V^.Ptr)^) then R:=False;
             FreeVal(V)
             end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end
      end else R:=False;
   RepNum:=PQInt(Arg^[0]^.Ptr)^; FreeVal(Arg^[0]);
   If (Not R) then ExLn:=RepArr[RepNum][1];
   Exit(NIL)
   end;

Function F_Return(DoReturn:Boolean; Arg:PArrPVal):PValue;
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

Function F_Exit(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   ExLn:=Pr[Proc].Num; DoExit:=True;
   Exit(NIL)
   end;

Function F_AutoCall(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var P,E:LongWord; A,H,PA,CA:LongInt; R,TV{,ArrV}:PValue; //Arr:PArray;
   begin
   P:=Proc; E:=ExLn; Proc:=PQInt(Arg^[0]^.Ptr)^;
   
   CurLev += 1; FLev += 1;
   If (FLev > High(FCal)) then begin
      SetLength(FCal, FLev + 1);
      New(FCal[FLev].Vars,Create('!','~'))
      end;
   FCal[FLev].Args := Arg;

   PA:=Length(Pr[Proc].Arg); CA:=Length(Arg^)-1;
   If (CA>PA) then H:=PA else H:=CA;
   
   If (H>0) then For A:=0 to (H-1) do begin
      FCal[FLev].Vars^.SetVal(Pr[Proc].Arg[A],Arg^[A+1])
      end;
   
   If (PA>CA) then For A:=H to (PA-1) do begin
      FCal[FLev].Vars^.SetVal(Pr[Proc].Arg[A],NilVal())
      end;
   {
   ArrV:=EmptyVal(VT_ARR); Arr:=PArray(ArrV^.Ptr);
   For A:=0 to (CA-1) do Arr^.SetVal(A, Arg[A+1]);
   Vars[FLev]^.SetVal('ARG',ArrV);
   }
   FCal[FLev].Vars^.SetVal('ARGNUM',NewVal(VT_INT,CA));
   //Vars[FLev]^.SetVal('ARGWNT',NewVal(VT_INT,PA));
   R:=RunFunc(Proc);
   
   If (Length(Pr[Proc].Arg)>0) then
      For A:=0 to (H-1) do FCal[FLev].Vars^.RemVal(Pr[Proc].Arg[A]);
   
   While (FCal[FLev].Vars^.Count > 0) do begin
      TV:=FCal[FLev].Vars^.RemVal();
      FreeVal(TV)
      end;
   //Dispose(Vars[V],Destroy()); SetLength(Vars,Length(Vars)-1); 
   
   FLev -= 1; CurLev -= 1;
   For A:=Low(Arg^) to High(Arg^) do
       If (Arg^[A]^.Lev >= CurLev) then FreeVal(Arg^[A]);
   
   Proc:=P; ExLn:=E; 
   If (DoReturn) then begin If (R<>NIL) then Exit(R) else Exit(NilVal()) end
                 else begin If (R<>NIL) then FreeVal(R) else Exit(NIL) end
   end;


Function F_FuncArgs(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var AV:PValue; Arr:PArray; C:LongWord;
   begin
   If ((Not DoReturn) or (FLev = 0)) then Exit(F_(DoReturn, Arg));
   AV:=NewVal(VT_ARR); Arr:=PArray(AV^.Ptr);
   For C:=1 to High(FCal[FLev].Args^) do
       Arr^.SetVal(C-1, FCal[FLev].Args^[C]);
   Exit(AV)
   end;

Function F_Call(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; UFN:LongWord; FPtr:PFunc; S:TStr; NArg:TArrPVal;
   begin
   If (Length(Arg^)=0) then Exit(NilVal());
   If (Arg^[0]^.Typ <> VT_STR) then begin
      V:=ValToStr(Arg^[0]); If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Arg^[0]:=V end;
   S:=PStr(Arg^[0]^.Ptr)^;
   If (Length(S)>0) and (S[1]=':') then Delete(S,1,1);
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Try
      UFN:=UsrFun^.GetVal(S);
      Arg^[0]:=NewVal(VT_INT,UFN);
      Exit(F_AutoCall(DoReturn, Arg))
   Except
      SetLength(NArg, Length(Arg^)-1);
      For C:=1 to High(Arg^) do NArg[C-1] := Arg^[C];
      Try
         FPtr:=Func^.GetVal(S);
         Exit(FPtr(DoReturn, @NArg));
      Except
         Exit(F_(DoReturn, @NArg))
   end end end;

Function F_FileIncludes(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var AV:PValue; Arr:PArray; C:LongWord;
   begin
   F_(False, Arg); If (Not DoReturn) then Exit(NIL);
   AV:=NewVal(VT_ARR); Arr:=PArray(AV^.Ptr);
   For C:=Low(FileIncludes) to High(FileIncludes) do
       Arr^.SetVal(C, NewVal(VT_STR, FileIncludes[C]));
   Exit(AV)
   end;

Function F_FileIncluded(DoReturn:Boolean; Arg:PArrPVal):PValue;
   Var V:PValue; A,F:LongWord; Return,ThisFile:Boolean; FName:AnsiString;
   begin
   If (Length(Arg^) = 0) then Exit(F_(DoReturn, Arg));
   If (Not DoReturn) then Exit(F_(False, Arg));
   Return := True;
   For A:=High(Arg^) downto Low(Arg^) do begin
       If (Arg^[A]^.Typ = VT_STR) then FName := PStr(Arg^[A]^.Ptr)^
          else begin
          V:=ValToStr(Arg^[A]); FName:=PStr(V^.Ptr)^; FreeVal(V)
          end;
       ThisFile := False;
       For F:=Low(FileIncludes) to High(FileIncludes) do
           If (FileIncludes[F] = FName) then begin
              ThisFile:=True; Break
              end;
       Return := Return and ThisFile;
       If (Not Return) then Break
       end;
   F_(False, Arg);
   Exit(NewVal(VT_BOO, Return))
   end;

end.
