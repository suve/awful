unit corefunc;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, TokExpr, Values;

Type
   TCallState = record
      Vars : PValTrie;
      Args : Array of PValue;
      NumA : LongInt
   end;

Var
   FCal : Array of TCallState;
   FLev : LongInt;
   DoExit : Boolean;

   FuncInfo_AutoCall,
   FuncInfo_If, FuncInfo_Else,
   FuncInfo_Break, FuncInfo_Continue,
   FuncInfo_While, FuncInfo_Done, FuncInfo_Until : TFuncInfo;
    
Procedure Register(Const FT:PFunTrie);

Function  Eval(Const Ret:Boolean; Const E:PExpr):PValue;
Function  RunFunc(Const P:LongWord):PValue;

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
   uses SysUtils, Globals, Parser, EmptyFunc, Values_Typecast;

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
      FT^.SetVal('param-num',MkFunc(@F_ParamCnt));
      FT^.SetVal('param-str',MkFunc(@F_ParamStr));
      
      SetFuncInfo(FuncInfo_AutoCall, @F_AutoCall, REF_MODIF);
      SetFuncInfo(FuncInfo_If      , @F_If      , REF_CONST);
      SetFuncInfo(FuncInfo_Else    , @F_Else    , REF_CONST);
      SetFuncInfo(FuncInfo_While   , @F_While   , REF_CONST);
      SetFuncInfo(FuncInfo_Done    , @F_Done    , REF_CONST);
      SetFuncInfo(FuncInfo_Until   , @F_Until   , REF_CONST);
      SetFuncInfo(FuncInfo_Break   , @F_Break   , REF_CONST);
      SetFuncInfo(FuncInfo_Continue, @F_Continue, REF_CONST)
   end;

Function Eval(Const Ret:Boolean; Const E:PExpr):PValue;
   
   Function GetVar(Const Name:PStr;Const Typ:TValueType):PValue;
      begin
         Result:=FCal[FLev].Vars^.GetVal(Name^);
         If (Result <> NIL) then Exit();
         
         Result:=FCal[0].Vars^.GetVal(Name^);
         If (Result <> NIL) then Exit();
         
         Result:=EmptyVal(Typ); Result^.Lev -= 1;
         FCal[FLev].Vars^.SetVal(Name^,Result)
      end;
   
   Function GetArr(Const ArrV:PValue; Const Index:PToken; Const Typ:TValueType):PValue;
      Var Fly:PValue; atk:PArrTk; C:LongWord;
          KeyStr : TStr; KeyInt : QInt;
      begin
         If (ArrV^.Typ = VT_ARR) or (ArrV^.Typ = VT_DIC) then begin
            Case (Index^.Typ) of
               TK_EXPR:
                  Result:=Eval(RETURN_VALUE_YES, PExpr(Index^.Ptr));
               
               TK_CONS:
                  Result:=PValue(Index^.Ptr);
               
               TK_LITE:
                  Result:=PValue(Index^.Ptr);
               
               TK_VARI, TK_REFE:
                  Result:=GetVar(PStr(Index^.Ptr), VT_INT);
               
               TK_AREF, TK_AVAL: begin
                  atk := PArrTk(Index^.Ptr);
                  Result:=GetVar(PStr(atk^.Ptr), VT_INT);
                  For C:=Low(atk^.Ind) to High(atk^.Ind) do
                     Result:=GetArr(Result, atk^.Ind[C], VT_INT)
               end;
               
               TK_AFLY: begin
                  atk := PArrTk(Index^.Ptr);
                  Fly:=Eval(RETURN_VALUE_YES, PExpr(atk^.Ptr));
                  
                  Result:=Fly;
                  For C:=Low(atk^.Ind) to High(atk^.Ind) do
                     Result:=GetArr(Result, atk^.Ind[C], Typ);
                  
                  Result:=CopyVal(Result);
                  FreeVal(Fly)
               end;
            end;
            
            If (ArrV^.Typ = VT_ARR) then begin
               If (Result^.Typ >= VT_INT) and (Result^.Typ <= VT_BIN)
                  then KeyInt:=Result^.Int^
                  else KeyInt:=ValAsInt(Result); 
                  
               If (Index^.Typ = TK_EXPR) then FreeVal(Result);
               
               Result:=ArrV^.Arr^.GetVal(KeyInt);
               If (Result = NIL) then begin
                  Result:=EmptyVal(Typ); Result^.Lev := ArrV^.Lev;
                  ArrV^.Arr^.SetVal(KeyInt, Result)
               end
               
            end else begin
            
               If (Result^.Typ = VT_STR)
                  then KeyStr:=Result^.Str^
                  else KeyStr:=ValAsStr(Result); 
                  
               If (Index^.Typ = TK_EXPR) then FreeVal(Result);
               
               Result:=ArrV^.Dic^.GetVal(KeyStr);
               If (Result = NIL) then begin
                  Result:=EmptyVal(Typ); Result^.Lev := ArrV^.Lev;
                  ArrV^.Dic^.SetVal(KeyStr, Result)
               end
            end
         end else
         If (ArrV^.Typ = VT_NIL)
            then Result:=ArrV
            else Result:=NilVal()
      end;
   
   Var T:LongWord; V:PValue; I:LongWord; atk:PArrTk; Tp:TValueType;
   begin
      If (E^.Num < 0) then Exit(E^.Fun(Ret, @E^.Arg));
      
      If (E^.Ref = REF_CONST) then begin
         {$INCLUDE corefunc-eval.inc}
      end else begin
         {$DEFINE REF_MODIF}
         {$INCLUDE corefunc-eval.inc}
         {$UNDEF REF_MODIF}
      end;
      
      Exit(E^.Fun(Ret, @E^.Arg))
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
               then R := (R) and (Arg^[C]^.Boo^)
               else R := (R) and (ValAsBoo(Arg^[C]));
            
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end
      end else
         R:=False;
      
      If (Not R) then ExLn:=IfArr[Arg^[0]^.Int^][1];
      Exit(NIL)
   end;

Function F_Else(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; 
   begin
      If (Length(Arg^)>1) then
         For C:=High(Arg^) downto 1 do
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);

      ExLn:=IfArr[Arg^[0]^.Int^][2];
      Exit(NIL)
   end;

Function F_While(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:Boolean; 
   begin
      If (Length(Arg^)>1) then begin
         
         R:=True;
         For C:=High(Arg^) downto 1 do begin
            If (Arg^[C]^.Typ = VT_BOO)
               then R := (R) and (Arg^[C]^.Boo^)
               else R := (R) and (ValAsBoo(Arg^[C]));
         
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end
      end else
         R:=False;

      If (Not R) then ExLn:=WhiArr[Arg^[0]^.Int^][2];
      Exit(NIL)
   end;

Function F_Done(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; 
   begin
      If (Length(Arg^)>1) then
         For C:=High(Arg^) downto 1 do
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]); 

      ExLn:=WhiArr[Arg^[0]^.Int^][1];
      Exit(NIL)
   end;

Function F_Until(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:Boolean;
   begin
      If (Length(Arg^)>1) then begin
         
         R:=True;
         For C:=High(Arg^) downto 1 do begin
            If (Arg^[C]^.Typ = VT_BOO)
               then R := (R) and (Arg^[C]^.Boo^)
               else R := (R) and (ValAsBoo(Arg^[C]));
         
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end
      end else
         R:=False;
      
      If (Not R) then ExLn:=RepArr[Arg^[0]^.Int^][1];
      Exit(NIL)
   end;

Function F_Break(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      Case TConstructType(Arg^[0]^.Int^) of
         CT_WHILE:
            ExLn := WhiArr[Arg^[1]^.Int^][2];
         
         CT_REPEAT:
            ExLn := RepArr[Arg^[1]^.Int^][2];
         
         else ;
      end;
   Exit(NIL)
   end;

Function F_Continue(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      Case TConstructType(Arg^[0]^.Int^) of
         CT_WHILE:
            ExLn := WhiArr[Arg^[1]^.Int^][1];
         
         CT_REPEAT:
            ExLn := RepArr[Arg^[1]^.Int^][2]-1;
         
         else ;
      end;
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
            then R:=Arg^[0]
            else R:=CopyVal(Arg^[0])
      end else
         R:=NilVal();
      
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
   Var P,E:LongWord; A,H,Pass,Want:LongInt; R:PValue; 
   begin
      // Save procedure and expression number to restore on exit
      P:=Proc; E:=ExLn;
      
      // Extract new procedure number from argument and free argument
      Proc:=Arg^[0]^.Int^; 
      FreeVal(Arg^[0]);
      
      // Increase varlevel and function call level.
      // If there are no callstate entries available, lengthen the array.
      CurLev += 1; FLev += 1;
      If (FLev > High(FCal)) then begin
         SetLength(FCal, FLev + 1);
         New(FCal[FLev].Vars,Create())
      end;
      
      // Determine number of wanted and passed arguments
      Want:=Length(Pr[Proc].Arg); Pass:=Length(Arg^)-1; // -1 because 1st arg is !fun number
      If (Pass > Want)
         then H:=Want
         else H:=Pass;
      
      // Copy arguments because Eval() could overwrite what's under Arg
      // if the procedure contains a recursive call
      If (Length(FCal[FLev].Args) < Pass) then SetLength(FCal[FLev].Args, Pass); // Make sure there is enough space
      For A:=1 to (Pass) do FCal[FLev].Args[A-1] := Arg^[A];                     // Copy args
      FCal[FLev].NumA := Pass;                                                   // Remember number of args
      
      // Insert passed params into vartrie
      If (H > 0) then For A:=0 to (H-1) do begin
         FCal[FLev].Vars^.SetVal(Pr[Proc].Arg[A],Arg^[A+1])
      end;
      
      // Insert missing params into vartie
      If (Want > Pass) then For A:=H to (Want-1) do begin
         FCal[FLev].Vars^.SetVal(Pr[Proc].Arg[A],NilVal())
      end; 
      
      // Run the proper function
      R:=RunFunc(Proc);
      
      // Remove params from vartie
      If (Length(Pr[Proc].Arg)>0) then
         For A:=0 to (H-1) do FCal[FLev].Vars^.RemVal(Pr[Proc].Arg[A]);
      
      // Remove user-defined vars from trie
      FCal[FLev].Vars^.Purge(@FreeVal);
      
      // Decrease runlevel and free args if needed
      CurLev -= 1;
      For A:=0 to (FCal[FLev].NumA-1) do
         If (FCal[FLev].Args[A]^.Lev >= CurLev) then
            FreeVal(FCal[FLev].Args[A]);
      
      FLev -= 1; // Deacrease function call level
      
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
   Var C:LongInt;
   begin
      If ((Not DoReturn) or (FLev = 0)) then Exit(F_(DoReturn, Arg));
      
      Result:=NewVal(VT_ARR);
      For C:=0 to (FCal[FLev].NumA - 1) do
         Result^.Arr^.SetVal(C, FCal[FLev].Args[C])
   end;

Function F_Call(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var FPtr:PFuncInfo; S:TStr;
   
   Function BuiltInCall():PValue;
      Var C:LongWord; NArg:TArrPVal;
         begin
         SetLength(NArg, Length(Arg^)-1);
         For C:=1 to High(Arg^) do NArg[C-1] := Arg^[C];
         Exit(TBuiltIn(FPtr^.Ptr)(DoReturn, @NArg))
      end;
   
   begin
      If (Length(Arg^) = 0) then Exit(NilVal());
      
      S:=ValAsStr(Arg^[0]);
      If (Length(S)>0) and (S[1]=':') then Delete(S,1,1);
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      
      FPtr := Func^.GetVal(S);
      If (FPtr = NIL) then begin
         FPtr := @FuncInfo_NIL;
         Exit(BuiltInCall())
      end;
      
      If (FPtr^.Usr) then begin
         Arg^[0] := NewVal(VT_INT, FPtr^.Ptr);
         Exit(F_AutoCall(DoReturn, Arg))
      end else
         Exit(BuiltInCall())
   end;

Function F_FileIncludes(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
      F_(False, Arg); If (Not DoReturn) then Exit(NIL);
      
      Result:=NewVal(VT_ARR);
      For C:=Low(FileIncludes) to High(FileIncludes) do
         Result^.Arr^.SetVal(C, NewVal(VT_STR, FileIncludes[C].Name))
   end;

Function F_FileIncluded(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var A,F:LongWord; ThisFile:Boolean; FName:AnsiString;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      If (Length(Arg^) = 0) then Exit(NewVal(VT_BOO, False));
      
      Result := NewVal(VT_BOO, True);
      For A:=High(Arg^) downto Low(Arg^) do begin
         If (Arg^[A]^.Typ = VT_STR)
            then FName := Arg^[A]^.Str^
            else FName := ValAsStr(Arg^[A]);
         
         ThisFile := False;
         For F:=Low(FileIncludes) to High(FileIncludes) do
            If (FileIncludes[F].Name = FName) then begin
               ThisFile:=True; Break
            end;
         
         Result^.Boo^ := Result^.Boo^ and ThisFile;
         If (Not Result^.Boo^) then Break
      end;
      
      F_(False, Arg)
   end;

Function F_ParamArr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
      F_(False, Arg); If (Not DoReturn) then Exit(NIL);
      
      Result := NewVal(VT_ARR);
      For C:=0 to (ParamCount() - ParamNum + 1) do
         Result^.Arr^.SetVal(C, NewVal(VT_STR, ParamStr(ParamNum + C)))
   end;

Function F_ParamCnt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      F_(False, Arg); If (Not DoReturn) then Exit(NIL);
      Exit(NewVal(VT_INT, ParamCount() - ParamNum + 1))
   end;

Function F_ParamStr(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Idx : QInt;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      If (Length(Arg^) = 0) then Exit(F_(True, Arg));
      
      Idx := ParamNum + ValAsInt(Arg^[0]);
      If (Idx >= ParamNum) and (Idx <= ParamCount())
         then Result := NewVal(VT_STR, ParamStr(Idx))
         else Result := NilVal();
      
      F_(False, Arg)
   end;

end.
