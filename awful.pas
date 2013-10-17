program awful;

{$MODE OBJFPC} {$COPERATORS ON} {$LONGSTRINGS ON}

//{$DEFINE CGI}

uses SysUtils, Math,
     Trie, Stack,
     Values, TokExpr, EmptyFunc,
     Functions,
     Functions_ArrDict,
     Functions_CGI,
     Functions_DateTime,
     Functions_Strings, Functions_SysInfo,
     Functions_TypeCast;

const VMAJOR = '0';
      VMINOR = '2';
      VBUGFX = '0';
      VREVISION = 20;
      VERSION = VMAJOR + '.' + VMINOR + '.' + VBUGFX;

Type PText = ^System.Text;
     
     TLineInfo = LongInt; //This will probably become a record when functions get implemented
     TIf = Array[0..2] of TLineInfo;
     TLoop = Array[0..2] of TLineInfo;
     
     PLIS = ^TLIS;
     TLIS = specialize GenericStack<TLineInfo>;
     
     PNumTrie = ^TNumTrie; 
     TNumTrie = specialize GenericTrie<LongWord>;
     
     TParamMode = (PAR_INPUT, PAR_OUTPUT, PAR_ERR);

Var Func : PFunTrie;
    Cons : PValTrie;

    Vars : Array of PValTrie;

    IfArr : Array of TIf;
    RepArr, WhiArr : Array of TLoop;
    IfSta, RepSta, WhiSta : PLIS;
    UsrFun : PNumTrie;
    DoExit : Boolean;

Var YukFile : Text; YukNum:LongWord;
    Pr : Array of TProc;
    Proc, ExLn : LongWord;
    mulico:LongWord; {$IFDEF CGI} codemode:LongWord; {$ENDIF}
    ParMod:TParamMode;

Function Eval(Ret:Boolean; E:PExpr):PValue;
   
   Function GetVar(Name:AnsiString;Typ:TValueType):PValue;
      Var R:PValue;
      begin
      //Writeln(StdErr,'GetVar: ',Name,'; ',Typ);
      Try R:=Vars[High(Vars)]^.GetVal(Name);
          Exit(R)
      Except Try R:=Vars[0]^.GetVal(Name);
                 Exit(R);
             Except end end;
      //Writeln(StdErr,'Vars[',High(Vars),']^.SetVal(',Name,',',Typ,')');
      R:=EmptyVal(Typ); R^.Lev -= 1;
      Vars[High(Vars)]^.SetVal(Name,R);
      Exit(R)
      end;
   
   Function GetArr(A:PValue; Index:PToken; Typ:TValueType):PValue;
      Var V,H:PValue; Arr:PValTree; Dic:PValTrie;
          KeyStr : TStr; KeyInt : QInt;
          atk:PArrTk; C:LongWord;
      begin
      If (A^.Typ = VT_ARR) then begin
         Case (Index^.Typ) of
            TK_EXPR: V:=Eval(RETURN_VALUE_YES, PExpr(Index^.Ptr));
            TK_CONS: V:=PValue(Index^.Ptr);
            TK_VARI, TK_REFE:
               V:=GetVar(PStr(Index^.Ptr)^, VT_INT);
            TK_AREF, TK_AVAL: begin
               //Writeln(StdErr, 'GetArr(Arr, ', Index^.Typ, ')');
               atk := PArrTk(Index^.Ptr);
               V:=GetVar(atk^.Nam, VT_INT);
               For C:=Low(atk^.Ind) to High(atk^.Ind) do
                   V:=GetArr(V, atk^.Ind[C], VT_INT)
               end
            end;
         If (V^.Typ >= VT_INT) and (V^.Typ <= VT_BIN) then KeyInt:=PQInt(V^.Ptr)^
            else begin H:=ValToInt(V); KeyInt:=PQInt(H^.Ptr)^; FreeVal(H) end;
         If (Index^.Typ = TK_EXPR) then FreeVal(V);
         //Writeln(StdErr, 'GetArr(Arr[',KeyInt,'])');
         Arr:=PValTree(A^.Ptr); 
         Try    V:=Arr^.GetVal(KeyInt)
         Except V:=EmptyVal(Typ); V^.Lev := A^.Lev;
                Arr^.SetVal(KeyInt, V)
         end end else
      If (A^.Typ = VT_DIC) then begin
         Case (Index^.Typ) of
            TK_EXPR: V:=Eval(RETURN_VALUE_YES, PExpr(Index^.Ptr));
            TK_CONS: V:=PValue(Index^.Ptr);
            TK_VARI, TK_REFE:
               V:=GetVar(PStr(Index^.Ptr)^, VT_STR);
            TK_AREF, TK_AVAL: begin
               atk := PArrTk(Index^.Ptr);
               V:=GetVar(atk^.Nam, VT_STR);
               For C:=Low(atk^.Ind) to High(atk^.Ind) do
                   V:=GetArr(V, atk^.Ind[C], VT_STR)
               end
            end;
         If (V^.Typ = VT_STR) then KeyStr:=PStr(V^.Ptr)^
            else begin H:=ValToStr(V); KeyStr:=PStr(H^.Ptr)^; FreeVal(H) end;
         If (Index^.Typ = TK_EXPR) then FreeVal(V);
         //Writeln(StdErr, 'GetArr(Dic[',KeyStr,'])');
         Dic:=PValTrie(A^.Ptr);
         Try    V:=Dic^.GetVal(KeyStr)
         Except V:=EmptyVal(Typ); V^.Lev := A^.Lev;
                Dic^.SetVal(KeyStr, V)
         end end else
         V:=NilVal();
      Exit(V)
      end;
   
   Var Arg:Array of PValue; T:LongWord; V:PValue; I:LongWord; atk:PArrTk; Tp:TValueType;
   begin
   If (Length(E^.Tok)=0) then Exit(E^.Fun(Ret, []));
   SetLength(Arg,Length(E^.Tok));
   For T:=High(E^.Tok) downto Low(E^.Tok) do
       Case (E^.Tok[T]^.Typ) of 
          TK_CONS: begin
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
          TK_AVAL: begin
             If (T<High(E^.Tok)) then Tp:=Arg[T+1]^.Typ else Tp:=VT_NIL;
             atk := PArrTk(E^.Tok[T]^.Ptr); V:=GetVar(atk^.Nam, VT_DIC);
             For I:=Low(atk^.Ind) to High(atk^.Ind) do 
                 V:=GetArr(V, atk^.Ind[I], Tp);
             Arg[T]:=CopyVal(V)
             end;
          TK_AREF: begin
             If (T<High(E^.Tok)) then Tp:=Arg[T+1]^.Typ else Tp:=VT_NIL;
             atk := PArrTk(E^.Tok[T]^.Ptr); V:=GetVar(atk^.Nam, VT_DIC);
             For I:=Low(atk^.Ind) to High(atk^.Ind) do 
                 V:=GetArr(V, atk^.Ind[I], Tp);
             Arg[T]:=V
             end;
          TK_EXPR: begin
             Arg[T]:=Eval(RETURN_VALUE_YES, PExpr(E^.Tok[T]^.Ptr))
             end
          end;
   Exit(E^.Fun(Ret, Arg))
   end;

Function RunFunc(P:LongWord):PValue;
   Var R:PValue;
   begin
   If (Pr[P].Nu = 0) then Exit(NilVal);
   Proc:=P; ExLn:=0; CurLev += 1;
   While (Not DoExit) do begin
      R:=Eval(RETURN_VALUE_NO, Pr[P].Ex[ExLn]); ExLn+=1;
      If (ExLn >= Pr[P].Nu)
         then begin CurLev -= 1; Exit(R) end
         else If (R<>NIL) then FreeVal(R)
      end;
   CurLev -= 1;
   Exit(NIL)
   end;

Function F_If(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; IfNum:QInt; R:Boolean; V:PValue;
   begin
   If (Length(Arg)>1) then begin
      R:=True;
      For C:=High(Arg) downto 1 do begin
          If (Arg[C]^.Typ = VT_BOO) then begin
             If (Not PBool(Arg[C]^.Ptr)^) then R:=False
             end else begin
             V:=ValToBoo(Arg[C]);
             If (Not PBool(V^.Ptr)^) then R:=False;
             FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end
      end else R:=False;
   IfNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   If (Not R) then ExLn:=IfArr[IfNum][1];
   Exit(NIL)
   end;

Function F_Else(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; IfNum:QInt;
   begin
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   IfNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   ExLn:=IfArr[IfNum][2];
   Exit(NIL)
   end;

Function F_While(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; WhiNum:QInt; R:Boolean; V:PValue;
   begin
   If (Length(Arg)>1) then begin
      R:=True;
      For C:=High(Arg) downto 1 do begin
          If (Arg[C]^.Typ = VT_BOO) then begin
             If (Not PBool(Arg[C]^.Ptr)^) then R:=False
             end else begin
             V:=ValToBoo(Arg[C]);
             If (Not PBool(V^.Ptr)^) then R:=False;
             FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end
      end else R:=False;
   WhiNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   If (Not R) then ExLn:=WhiArr[WhiNum][2];
   Exit(NIL)
   end;

Function F_Done(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; WhiNum:QInt;
   begin
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   WhiNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   ExLn:=WhiArr[WhiNum][1];
   Exit(NIL)
   end;

Function F_Until(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; RepNum:QInt; R:Boolean; V:PValue;
   begin
   If (Length(Arg)>1) then begin
      R:=True;
      For C:=High(Arg) downto 1 do begin
          If (Arg[C]^.Typ = VT_BOO) then begin
             If (Not PBool(Arg[C]^.Ptr)^) then R:=False
             end else begin
             V:=ValToBoo(Arg[C]);
             If (Not PBool(V^.Ptr)^) then R:=False;
             FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end
      end else R:=False;
   RepNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   If (Not R) then ExLn:=RepArr[RepNum][1];
   Exit(NIL)
   end;

Function F_Return(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)>1) then
      For C:=Low(Arg)+1 to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)>0) then 
      If (Not Arg[0]^.Lev >= CurLev)
         then R:=CopyVal(Arg[0]) else R:=Arg[0]
      else R:=NilVal();
   ExLn:=Pr[Proc].Nu;
   Exit(R)
   end;

Function F_Exit(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   ExLn:=Pr[Proc].Nu; DoExit:=True;
   Exit(NIL)
   end;

Function F_AutoCall(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var P,E,V:LongWord; A,H,PA,CA:LongInt; R,TV,ArrV:PValue; Arr:PValTree;
   begin
   P:=Proc; E:=ExLn; Proc:=PQInt(Arg[0]^.Ptr)^; CurLev += 1;
   SetLength(Vars,Length(Vars)+1); V:=High(Vars);
   
   New(Vars[V],Create('A','z'));
   PA:=Length(Pr[Proc].Ar); CA:=Length(Arg)-1;
   H:=Min(PA,CA);
   
   If (H>0) then For A:=0 to (H-1) do begin
      Vars[V]^.SetVal(Pr[Proc].Ar[A],Arg[A+1]);
      {Arg[A+1]^.Tmp:=False} end;
   
   If (PA>CA) then For A:=H to (PA-1) do begin
      TV:=NilVal(); {TV^.Tmp:=False;}
      Vars[V]^.SetVal(Pr[Proc].Ar[A],TV) end;
   
   //If (CA>PA) then begin
   ArrV:=EmptyVal(VT_ARR); Arr:=PValTree(ArrV^.Ptr);
   For A:=0 to (CA-1) do Arr^.SetValNaive(A, Arg[A+1]);
   Arr^.Rebalance(); Vars[V]^.SetVal('ARG',ArrV);
   //end;
   
   Vars[V]^.SetVal('ARGNUM',NewVal(VT_INT,CA));
   //Vars[V]^.SetVal('ARGWNT',NewVal(VT_INT,PA));
   R:=RunFunc(Proc);
   //Writeln(StdErr,'F_AutoCall(',Proc,'): Trie size: ',Vars[V]^.Count);
   If (Length(Pr[Proc].Ar)>0) then begin
      For A:=0 to High(Pr[Proc].Ar) do Vars[V]^.RemVal(Pr[Proc].Ar[A]);
      A+=1 end else A:=1;
   //While (A<=High(Arg)) do begin
   // Vars[V]^.RemVal('ARG'+IntToStr(A-1)); A+=1 end;
   While (Vars[V]^.Count > 0) do begin
      //Writeln(StdErr,'F_AutoCall(',Proc,'): Vars[',V,']; Count: ',Vars[V]^.Count,'; RemVal()');
      TV:=Vars[V]^.RemVal();
      //F_Writeln([NewVal(VT_STR,'TV = '),TV]);
      FreeVal(TV)
      end;
   //Writeln(StdErr,'F_AutoCall(',Proc,'): Trie size: ',Vars[V]^.Count);
   Dispose(Vars[V],Destroy()); SetLength(Vars,Length(Vars)-1);
   For A:=Low(Arg) to High(Arg) do
       If (Arg[A]^.Lev >= CurLev) then FreeVal(Arg[A]);
   Proc:=P; ExLn:=E; CurLev -= 1;
   If (DoReturn) then Exit(R)
                 else begin If (R<>NIL) then FreeVal(R); Exit(NIL) end
   end;

Function F_Call(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; UFN:LongWord; FPtr:PFunc; S:TStr;
   begin
   If (Length(Arg)=0) then Exit(NilVal());
   If (Arg[0]^.Typ <> VT_STR) then begin
      V:=ValToStr(Arg[0]); If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Arg[0]:=V end;
   S:=PStr(Arg[0]^.Ptr)^;
   If (Length(S)>0) and (S[1]=':') then Delete(S,1,1);
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Try
      UFN:=UsrFun^.GetVal(S);
      Arg[0]:=NewVal(VT_INT,UFN);
      Exit(F_AutoCall(DoReturn, Arg))
   Except
      Try
         FPtr:=Func^.GetVal(S);
         Exit(FPtr(DoReturn, Arg[1..High(Arg)]));
      Except
         If (Length(Arg)>1) then
            For C:=High(Arg) downto 1 do
                If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
         If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end end end;

Function GetFunc(Name:AnsiString):PFunc;
   Var R:PFunc;
   begin
   Try R:=Func^.GetVal(Name);
       Exit(R)
   Except
       Exit(Nil)
   end end;

Procedure Fatal(Ln:LongWord;Msg:AnsiString);
   {$IFDEF CGI} Var DTstr:AnsiString; {$ENDIF}
   begin
   Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): Fatal: ',Msg);
   {$IFDEF CGI}
   Writeln('Content-type: text/html');
   Writeln();
   Writeln('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">');
   Writeln('<html lang="en">');
   Writeln('<head>');
   Writeln('  <meta http-equiv="content-type" content="text/html;charset=UTF-8">');
   Writeln('  <title>Error</title>');
   Writeln('</head>');
   Writeln('<body>');
   Writeln('<h3>awful-cgi: fatal error</h3><hr>');
   Writeln('<p><strong>File:</strong> ',YukPath,'</p>');
   Writeln('<p><strong>Line:</strong> ',Ln,'</p>');
   Writeln('<p><i>',Msg,'</i></p>');
   DateTimeToString(DTstr, dtf_def, Now());
   Writeln('<p><small>Generated by awful rev.',VREVISION,' on ',DTstr,'.</small></p>');
   Writeln('</body>');
   Writeln('</html>');
   Halt(0)
   {$ELSE}
   Halt(1)
   {$ENDIF}
   end;

Function MakeExpr(Var Tk:Array of AnsiString;Ln,T:LongInt):PExpr;
   
   Function ConstPrefix(C:Char):Boolean;
      begin Exit(Pos(C,'sflihob=')<>0) end;
   
   Function MakeToken(Var Index:LongInt):PToken;
      Var Tok,otk:PToken; atk:PArrTk; TkIn, Nest:LongInt;
          sex:PExpr; V:PValue; PS:PStr; CName:TStr; 
      begin
      // Check string prefix and generate token
      If (Tk[Index][1]='&') then begin
         New(Tok); New(PS); Tok^.Typ:=TK_VARI; Tok^.Ptr:=PS; 
         PS^:=Copy(Tk[Index],2,Length(Tk[Index]))
         end else
      If (Tk[Index][1]='$') then begin
         New(Tok); New(PS); Tok^.Typ:=TK_REFE; Tok^.Ptr:=PS; 
         PS^:=Copy(Tk[Index],2,Length(Tk[Index]))
         end else
      If (Tk[Index][1]='=') then begin
         CName:=Copy(Tk[Index],2,Length(Tk[Index]));
         Try    V:=Cons^.GetVal(CName);
         Except Fatal(Ln,'Unknown constant "'+CName+'".') end;
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V
         end else
      If (Tk[Index][1]='s') then begin
         V:=NewVal(VT_STR,Copy(Tk[Index],3,Length(Tk[Index])-3));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Lev := 0
         end else
      If (Tk[Index][1]='i') then begin
         V:=NewVal(VT_INT,StrToInt(Copy(Tk[Index],2,Length(Tk[Index]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Lev := 0
         end else
      If (Tk[Index][1]='h') then begin
         V:=NewVal(VT_HEX,StrToHex(Copy(Tk[Index],2,Length(Tk[Index]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Lev := 0
         end else
      If (Tk[Index][1]='o') then begin
         V:=NewVal(VT_OCT,StrToOct(Copy(Tk[Index],2,Length(Tk[Index]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Lev := 0
         end else
      If (Tk[Index][1]='b') then begin
         V:=NewVal(VT_BIN,StrToBin(Copy(Tk[Index],2,Length(Tk[Index]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Lev := 0
         end else
      If (Tk[Index][1]='l') then begin
         V:=NewVal(VT_BOO,StrToBoolDef(Copy(Tk[Index],2,Length(Tk[Index])),False));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Lev := 0
         end else
      If (Tk[Index][1]='f') then begin
         V:=NewVal(VT_FLO,StrToReal(Copy(Tk[Index],2,Length(Tk[Index]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Lev := 0
         end else
         Tok:=NIL;
      // Check if next token is an array index
      If (Index < High(Tk)) and (Tk[Index+1][1] = '[') then begin
         If (Tok = NIL) then
            Fatal(Ln,'Array expression ("[") found, but previous token is not a variable name.');
         otk:=Tok; Index += 1; TkIn := Index + 1; // E^.Tok[High(E^.Tok)];
         If (otk^.Typ = TK_VARI) or (otk^.Typ = TK_REFE) then begin
            Tok:=MakeToken(TkIn);
            If (Tok=NIL) then begin
               sex:=MakeExpr(Tk, Ln, Index + 1);
               New(Tok); Tok^.Typ:=TK_EXPR; Tok^.Ptr:=sex
               end;
            CName:=PStr(otk^.Ptr)^; Dispose(PStr(otk^.Ptr));
            If (otk^.Typ = TK_REFE) then otk^.Typ := TK_AREF
                                    else otk^.Typ := TK_AVAL;
            New(atk); atk^.Nam:=CName;
            SetLength(atk^.Ind, 1); atk^.Ind[0] := Tok;
            otk^.Ptr := atk
            end else 
            Fatal(Ln,'Array expression ("[") found, but previous token is not a variable name.');
         Nest:=0;
         While (Index <= High(Tk)) do 
            //If (Length(Tk[Index])=0) then Index +=1 else
            If (Tk[Index][1]='[') then begin Nest+=1; Index+=1 end else
            If (Tk[Index][1]=']') then begin
               Nest-=1; If (Nest=0) then Break else Index+=1
               end else Index+=1;
         If (Nest>0) then Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                                  'Error: Un-closed array expression. ("[" without a matching "]".)');
         Tok := otk // Return value
         end;
      Exit(Tok)
      end;
   
   Var E:PExpr; FPtr:PFunc; sex:PExpr; A:LongWord;
       Tok,otk:PToken; V:PValue; {PS:PStr;} atk : PArrTk;
       Nest:LongWord; CName:TStr; Tmp:LongInt;
   begin New(E); 
   If (Tk[T][1]=':') then begin
      FPtr:=GetFunc(Copy(Tk[T],2,Length(Tk[T])));
      If (FPtr = NIL) then begin
         Try    A:=UsrFun^.GetVal(Copy(Tk[T],2,Length(Tk[T])));
         Except Fatal(Ln,'Unknown function: "'+Tk[T]+'".') end;
         Tk[T]:='i'+IntToStr(A);
         FPtr:=@F_AutoCall; T-=1
         end
      end else
   If (Tk[T][1]='!') then begin
      If (Tk[T]='!if') then begin
         SetLength(IfArr,Length(IfArr)+1);
         IfArr[High(IfArr)][0]:=Ln;
         IfArr[High(IfArr)][1]:=-1;
         IfArr[High(IfArr)][2]:=-1;
         IfSta^.Push(High(IfArr));
         Tk[T]:='i'+IntToStr(High(IfArr)); T-=1;
         FPtr:=@(F_If)
         end else
      If (Tk[T]='!else') then begin
         If (IfSta^.Empty) then Fatal(Ln,'!else without corresponding !if.');
         A:=IfSta^.Peek();
         If (IfArr[A][1]>=0) then Fatal(Ln,'!if from line '+IntToStr(IfArr[A][0])+' has a second !else.');
         IfArr[A][1]:=ExLn;
         Tk[T]:='i'+IntToStr(A); T-=1;
         FPtr:=@(F_Else)
         end else
      If (Tk[T]='!fi') then begin
         If (IfSta^.Empty()) then Fatal(Ln,'!fi without corresponding !if.');
         A:=IfSta^.Pop();
         If (IfArr[A][1]<0) then IfArr[A][1]:=ExLn;
         IfArr[A][2]:=ExLn;
         FPtr:=@(F_)
         end else
      If (Tk[T]='!while') then begin
         SetLength(WhiArr,Length(WhiArr)+1);
         WhiArr[High(WhiArr)][0]:=Ln;
         WhiArr[High(WhiArr)][1]:=ExLn-1;
         WhiArr[High(WhiArr)][2]:=-1;
         WhiSta^.Push(High(WhiArr));
         Tk[T]:='i'+IntToStr(High(WhiArr)); T-=1;
         FPtr:=@(F_While)
         end else
      If (Tk[T]='!done') then begin
         If (WhiSta^.Empty()) then Fatal(Ln,'!done without corresponding !while.');
         A:=WhiSta^.Pop();
         WhiArr[A][2]:=ExLn;
         Tk[T]:='i'+IntToStr(A); T-=1;
         FPtr:=@(F_Done)
         end else
      If (Tk[T]='!repeat') then begin
         SetLength(RepArr,Length(RepArr)+1);
         RepArr[High(RepArr)][0]:=Ln;
         RepArr[High(RepArr)][1]:=ExLn;
         RepArr[High(RepArr)][2]:=-1;
         RepSta^.Push(High(RepArr));
         Tk[T]:='i'+IntToStr(High(RepArr)); T-=1;
         FPtr:=@(F_)
         end else
      If (Tk[T]='!until') then begin
         If (RepSta^.Empty()) then Fatal(Ln,'!until without corresponding !repeat.');
         A:=RepSta^.Pop();
         RepArr[A][2]:=ExLn;
         Tk[T]:='i'+IntToStr(A); T-=1;
         FPtr:=@(F_Until)
         end else
      If (Tk[T]='!const') then begin
         If ((Length(Tk)-T)<>3) then Fatal(Ln,'Wrong number of arguments passed to !const.');
         If (Length(Tk[T+1])=0) or (Tk[T+1][1]<>'=')
            then Fatal(Ln,'!const names must start with a "=" character.');
         CName:=Copy(Tk[T+1],2,Length(Tk[T+1]));
         If (Cons^.IsVal(CName)) 
            then Fatal(Ln,'Redefinition of const "'+CName+'".');
         If (Length(Tk[T+2])=0) or (Not ConstPrefix(Tk[T+2][1]))
            then Fatal(Ln,'Second argument for !const must be either a value or a const.');
         If (Tk[T+2][1]='s') then
            V:=NewVal(VT_STR,Copy(Tk[T+2],3,Length(Tk[T+2])-3)) else
         If (Tk[T+2][1]='f') then
            V:=NewVal(VT_FLO,StrToReal(Copy(Tk[T+2],2,Length(Tk[T+2])))) else
         If (Tk[T+2][1]='l') then
            V:=NewVal(VT_BOO,StrToBoolDef(Copy(Tk[T+2],2,Length(Tk[T+2])),False)) else
         If (Tk[T+2][1]='i') then
            V:=NewVal(VT_INT,StrToInt(Copy(Tk[T+2],2,Length(Tk[T+2])))) else
         If (Tk[T+2][1]='h') then
            V:=NewVal(VT_HEX,StrToInt(Copy(Tk[T+2],2,Length(Tk[T+2])))) else
         If (Tk[T+2][1]='o') then
            V:=NewVal(VT_OCT,StrToInt(Copy(Tk[T+2],2,Length(Tk[T+2])))) else
         If (Tk[T+2][1]='b') then
            V:=NewVal(VT_BIN,StrToInt(Copy(Tk[T+2],2,Length(Tk[T+2])))) else
         If (Tk[T+2][1]='=') then
            Try    V:=Cons^.GetVal(Copy(Tk[T+2],2,Length(Tk[T+2])))
            Except Fatal(Ln,'Unknown const "'+Copy(Tk[T+2],2,Length(Tk[T+2]))+'".') end;
         V^.Lev := 0; Cons^.SetVal(CName,V);
         Dispose(E); Exit(NIL)
         end else
      If (Tk[T]='!fun') then begin
         If (Not IfSta^.Empty()) then begin
            A:=IfSta^.Peek(); A:=IfArr[A][0];
            Fatal(A,'Function declaration inside an !if block.')
            end else
         If (Not WhiSta^.Empty()) then begin
            A:=WhiSta^.Peek(); A:=WhiArr[A][0];
            Fatal(A,'Function declaration inside a !while block.')
            end else
         If (Not RepSta^.Empty()) then begin
            A:=RepSta^.Peek(); A:=RepArr[A][0];
            Fatal(A,'Function declaration inside a !repeat block.')
            end else
         If (Proc<>0) then Fatal(Ln,'Nested function declaration.');
         If ((Length(Tk)-T)<2) then Fatal(Ln,'No function name specified.');
         If (Length(Tk[T+1])=0) or (Tk[T+1][1]<>':')
            then Fatal(Ln,'Function names must start with the colon (":") character.');
         CName:=Copy(Tk[T+1],2,Length(Tk[T+1]));
         If (UsrFun^.IsVal(CName))
            then Fatal(Ln,'Duplicate user function identifier ("'+Cname+'").');
         SetLength(Pr,Length(Pr)+1);
         Proc:=High(Pr); ExLn:=0;
         Pr[Proc].Nu:=0; SetLength(Pr[Proc].Ex,0); SetLength(Pr[Proc].Ar,0);
         UsrFun^.SetVal(CName,Proc); T+=2;
         While (T<=High(Tk)) do begin
            If (Length(Tk[T])=0) then begin
               Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                              'Error: Empty token (',T,').');
               T+=1; Continue end;
            If (Tk[T][1]<>'$') then
               Fatal(Ln,'Function argument names must start with the dollar ("$") character.');
            SetLength(Pr[Proc].Ar,Length(Pr[Proc].Ar)+1);
            Pr[Proc].Ar[High(Pr[Proc].Ar)]:=Copy(Tk[T],2,Length(Tk[T]));
            T+=1 end;
         Dispose(E); Exit(NIL)
         end else
      If (Tk[T]='!nuf') then begin
         If (Proc = 0) then Fatal(Ln,'!nuf without corresponding !fun.');
         If (Not IfSta^.Empty()) then begin
            A:=IfSta^.Peek(); A:=IfArr[A][0];
            Fatal(A,'!if stretches past end of function.')
            end else
         If (Not WhiSta^.Empty()) then begin
            A:=WhiSta^.Peek(); A:=WhiArr[A][0];
            Fatal(A,'!while stretches past end of function.')
            end else
         If (Not RepSta^.Empty()) then begin
            A:=RepSta^.Peek(); A:=RepArr[A][0];
            Fatal(A,'!repeat stretches past end of function.')
            end;
         Proc:=0; ExLn:=Pr[0].Nu-1;
         Dispose(E); Exit(NIL)
         end else
      {If (Tk[T]='!return') then begin
         If (Proc = 0) then Fatal(Ln,'!return used in main function.');
         FPtr:=@F_Return
         end else}
         Fatal(Ln,'Unknown language construct: "'+Tk[T]+'".')
      end else
      Fatal(Ln,'First token ('+Tk[T]+') is neither a function call nor a language construct.');
   E^.Fun:=FPtr; T+=1;
   While (T<=High(Tk)) do begin
      If (Length(Tk[T])=0) then begin
         Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                 'Error: Empty token (',T,').');
         end else
      If (Tk[T][1]='(') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         sex:=MakeExpr(Tk,Ln,T+1);
         New(Tok); Tok^.Typ:=TK_EXPR; Tok^.Ptr:=sex;
         E^.Tok[High(E^.Tok)]:=Tok;
         Nest:=0;
         While (T<=High(Tk)) do 
            If (Length(Tk[T])=0) then T+=1 else
            If (Tk[T][1]='(') then begin Nest+=1; T+=1 end else
            If (Tk[T][1]=')') then begin
               Nest-=1; If (Nest=0) then Break else T+=1
               end else T+=1;
         If (Nest>0) then Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                                  'Error: Un-closed sub-expression. ("(" without a matching ")".)')
         end else
      If (Tk[T][1]=')') then begin
         Exit(E)
         end else 
      If (Tk[T][1]='[') then begin
         If (Length(E^.Tok)=0) then
            Fatal(Ln,'Array expression ("[") found, but previous token is not a variable name.');
         otk:=E^.Tok[High(E^.Tok)]; Tmp:=T+1;
         If (otk^.Typ = TK_AREF) or (otk^.Typ = TK_AVAL) then begin
            Tok:=MakeToken(Tmp);
            If (Tok=NIL) then begin
               sex:=MakeExpr(Tk,Ln,T+1);
               New(Tok); Tok^.Typ:=TK_EXPR; Tok^.Ptr:=sex
               end;
            atk := PArrTk(otk^.Ptr);
            SetLength(atk^.Ind, Length(atk^.Ind) + 1);
            atk^.Ind[High(atk^.Ind)] := Tok
            end else
            Fatal(Ln,'Array expression ("[") found, but previous token is not a variable name.');
         Nest:=0;
         While (T<=High(Tk)) do 
            If (Length(Tk[T])=0) then T+=1 else
            If (Tk[T][1]='[') then begin Nest+=1; T+=1 end else
            If (Tk[T][1]=']') then begin
               Nest-=1; If (Nest=0) then Break else T+=1
               end else T+=1;
         If (Nest>0) then Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                                  'Error: Un-closed array expression. ("[" without a matching "]".)')
         end else 
      If (Tk[T][1]=']') then begin
         Exit(E)
         end else
      If (Tk[T][1]=':') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         sex:=MakeExpr(Tk,Ln,T);
         New(Tok); Tok^.Typ:=TK_EXPR; Tok^.Ptr:=sex;
         E^.Tok[High(E^.Tok)]:=Tok;
         Exit(E)
         end else
      If (Tk[T][1]='!') then begin
         Fatal(Ln,'Language construct used as a sub-expression. ("'+Tk[T]+'").')
         end else begin
         Tok:=MakeToken(T);
         If (Tok<>NIL) then begin
            SetLength(E^.Tok,Length(E^.Tok)+1);
            E^.Tok[High(E^.Tok)]:=Tok
            end else
            Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                          'Error: Invalid token ("',Tk[T],'").')
         end;
      T+=1 end;
   Exit(E)
   end;

Function ProcessLine(L:AnsiString;N:LongWord):Array_PExpr;
   Var Tk:Array of AnsiString; P:LongWord;
       Str:LongInt; Del:Char; R:Array_PExpr; Rs,Rn:LongWord;
   
   Function BreakToken(Ch:Char):Boolean;
      begin Exit(Pos(Ch,' (|)[#]~')<>0) end;
   
   begin
   {$IFDEF CGI}
   If (codemode = 0) and (Length(L) = 0) then begin
      SetLength(Tk,1); Tk[0]:=':writeln';
      SetLength(R,1);   R[0]:=MakeExpr(Tk, N, 0);
      Exit(R)
      end;
   {$ENDIF}
   SetLength(Tk,0); P:=1; Str:=0; Del:=#255;
   While (Length(L)>0) do begin
      If (mulico > 0) then begin
         If (P>Length(L)) then L:='' else
         If (L[P]='#') then
            If (Length(L)>P) and (L[P+1]='>') then mulico+=1 else
            If (P>1) and (L[P-1]='<') then begin
               If (mulico > 1) then mulico-=1 else begin
                  Delete(L,1,P); P:=0; mulico:=0
               end end
         end else
      {$IFDEF CGI}
      If (codemode = 0) then begin
         If (P>Length(L)) then begin
            If (Length(Tk) > 0) then begin
               SetLength(Tk, Length(Tk)+3); Tk[High(Tk)-2] := '~'
               end else SetLength(Tk, Length(Tk)+2);
            Tk[High(Tk)-1] := ':writeln';
            Tk[High(Tk)] := 's"' + L +'"';
            L:=''; P:=0
            end else
         If (L[P] = '?') then begin
            If ((P>1) and (L[P-1] = '<')) and ((P <= Length(L)-3) and (L[P+1..P+3] = 'yuk')) then begin
               If (P > 2) then begin
                  If (Length(Tk) > 0) then begin
                     SetLength(Tk, Length(Tk)+4); Tk[High(Tk)-2] := '~'
                     end else SetLength(Tk, Length(Tk)+3);
                  Tk[High(Tk)-2] := ':write';
                  Tk[High(Tk)-1] := 's"' + L[1..P-2] +'"';
                  Tk[High(Tk)] := '~'
                  end;
               codemode := 1; Delete(L, 1, P+4); P:=0
               end
            end else
         If (N = 1) and (P = 1) and (L[1]='#') then begin
            If (Length(L)>1) and (L[2]='!') then L:=''
            end
         end else
      {$ENDIF}
      If (Str<=0) then begin
         If (P>Length(L)) or (BreakToken(L[P])) then begin
            //Writeln(StdErr,'Breaking line: "',L,'" at "',L[P],'".');
            If (L[P]=' ') then begin
               If (P>1) then begin
                  SetLength(Tk,Length(Tk)+1);
                  Tk[High(Tk)]:=Copy(L,1,P-1)
                  end;
               While (P<Length(L)) and (L[P+1]=#32) do P+=1;
               Delete(L,1,P) 
               end else 
            If (L[P]='#') then begin //Comment character! 
               If (P>1) then begin
                  SetLength(Tk,Length(Tk)+1);
                  Tk[High(Tk)]:=Copy(L,1,P-1)
                  end;
               If (Length(L)>P) and (L[P+1]='>') //begin of multi-line comment
                  then begin Delete(L,1,P+1); mulico += 1 end 
                  else L:='' {normal comment} end
            {$IFDEF CGI}
               else
            If (P = 3) and (L[1..2] = '?>') then begin
               If (codemode = 0) then Fatal(N,'Unpaired codemode closing tag. ("?>")');
               SetLength(Tk, Length(Tk)+1); Tk[High(Tk)]:='~';
               codemode -= 1; Delete(L, 1, 2)
               end
            {$ENDIF}
               else begin // paren
               SetLength(Tk,Length(Tk)+1);
               If (P>1) then begin
                  Tk[High(Tk)]:=Copy(L,1,P-1);
                  Delete(L,1,P-1)
                  end else begin
                  Tk[High(Tk)]:=L[1];
                  While (P<Length(L)) and (L[P+1]=#32) do P+=1;
                  Delete(L,1,P)
                  end;
               If (Tk[High(Tk)]='|') then begin
                  Tk[High(Tk)]:=')';
                  SetLength(Tk,Length(Tk)+1);
                  Tk[High(Tk)]:='('
                  end
               end;
            P:=0; Str:=0
            end else
         {$IFDEF CGI}
         If (L[P]='?') and (P<Length(L)) and (L[P+1]='>') then begin
            If (codemode = 0) then Fatal(N,'Unpaired codemode closing tag. ("?>")');
            SetLength(Tk, Length(Tk)+1); Tk[High(Tk)]:='~'; 
            codemode -= 1; Delete(L, 1, P+1); P:=0;
            end else
         {$ENDIF}
         If (Str=0) and (L[P]='s')
            then Str:=+1 else Str:=-1
         end else
      If (Str=1) then begin
         If (P>Length(L)) then begin
            Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
                    'Note: String prefix found at end of line.');
            SetLength(Tk,Length(Tk)+1);
            Tk[High(Tk)]:='s""';
            L:=''; P:=0; Str:=0
            end else begin
            Del:=L[P]; Str:=2
         end end else
      If (Str=2) and ((P>Length(L)) or (L[P]=Del)) then begin
         SetLength(Tk,Length(Tk)+1);
         Tk[High(Tk)]:=Copy(L,1,P);
         If (P<=Length(L))
            then While (P<Length(L)) and (L[P+1]=#32) do P+=1
            else begin
            Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
                    'Note: String token exceeds line.');
            Tk[High(Tk)]+=Del
            end;
         Delete(L,1,P); P:=0; Str:=0
         end;
      P+=1
      end;
   If (Length(Tk)=0) then Exit(NIL);
   If (Length(Tk)=1) and (Tk[0][1]='~') then Exit(NIL);
   Rs:=0; Rn:=1;
   For P:=1 to High(Tk) do 
       If (Tk[P][1]='!') or (Tk[P][1]='~') then Rn += 1;
   SetLength(R, Rn); Rn := 0;
   For P:=1 to High(Tk) do 
       If (Tk[P][1]='!') then begin
          R[Rn] := MakeExpr(Tk[Rs..P-1], N, 0);
          Rs := P; Rn += 1
          end else
       If (Tk[P][1]='~') then begin
          If (Tk[Rs][1]<>'~') then begin
             R[Rn]:=MakeExpr(Tk[Rs..P-1], N, 0); Rn += 1;
             end;
          Rs := P + 1
          end;
   If (Rs <= High(Tk)) then begin R[Rn] := MakeExpr(Tk[Rs..High(Tk)], N, 0); Rn += 1 end;
   SetLength(R, Rn); Exit(R)
   end;

Procedure ReadFile(I:PText);
   
   Function BuildNum():AnsiString;
      Var D,T:AnsiString;
      begin
      D:={$I %DATE%}; Delete(D, 8, 1);
      T:={$I %TIME%}; Delete(T, 3, 1); Delete(T, 5, 3);
      Exit(D+'/'+T)
      end;
   
   Var L:AnsiString; A,N,E,P,Rn:LongWord; R:Array_PExpr; V:PValue;
       PTV:PValue; //tik:Comp;
   begin
   //tik:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   
   New(UsrFun,Create('!','~'));
   SetLength(Pr,1); N:=0; Proc:=0; ExLn:=0; mulico:=0; {$IFDEF CGI} codemode:=0; {$ENDIF}
   SetLength(Pr[0].Ar,0); SetLength(Pr[0].Ex,0); Pr[0].Nu:=0;
   
   SetLength(IfArr,0);  New(IfSta,Create());
   SetLength(WhiArr,0); New(WhiSta,Create());
   SetLength(RepArr,0); New(RepSta,Create());
   
   New(Cons,Create('!','~'));
   V:=NilVal(); V^.Lev := 0; Cons^.SetVal('NIL', V);
   
   V:=NewVal(VT_STR,ExpandFileName(YukPath));  V^.Lev := 0; Cons^.SetVal('FILEPATH',V);
   V:=NewVal(VT_STR,ExtractFileName(YukPath)); V^.Lev := 0; Cons^.SetVal('FILENAME',V);
   PTV:=EmptyVal(VT_INT);                    PTV^.Lev := 0; Cons^.SetVal('FILE-PARSETIME', PTV);
   
   V:=NewVal(VT_STR,ParamStr(0)); V^.Lev := 0; Cons^.SetVal('AWFUL-PATH',V);
   V:=NewVal(VT_STR,BuildNum());  V^.Lev := 0; Cons^.SetVal('AWFUL-BUILD',V);
   V:=NewVal(VT_STR,VERSION);     V^.Lev := 0; Cons^.SetVal('AWFUL-VERSION',V);
   V:=NewVal(VT_INT,VREVISION);   V^.Lev := 0; Cons^.SetVal('AWFUL-REVISION',V);
   
   SetLength(Vars,1); New(Vars[0],Create('!','~')); 
   
   While (Not Eof(I^)) do begin
      Readln(I^,L); N+=1;
      L:=Trim(L);
      {$IFNDEF CGI} If (Length(L)>0) then begin {$ENDIF}
         P:=Proc; E:=Pr[P].Nu; ExLn:=E; Rn := 0;
         R:=ProcessLine(L, N);
         If (R<>NIL) then begin
            For A:=Low(R) to High(R) do 
                If (R[A] <> NIL) then Rn += 1;
            If (Rn > 0) then begin
               SetLength(Pr[P].Ex, Length(Pr[P].Ex)+Rn);
               For A:=Low(R) to High(R) do
                   If (R[A] <> NIL) then begin
                      //SetLength(Pr[P].Ex,Length(Pr[P].Ex)+1);
                      Pr[P].Ex[E] := R[A];
                      Pr[P].Nu += 1; E += 1
                      end
               end
            end
         end;
      {$IFNDEF CGI} end; {$ENDIF}
   {For P:=Low(Pr) to High(Pr) do begin
       Write(StdErr,'Func #',P,' has ',Pr[P].Nu,'/',Length(Pr[P].Ex),' expressions and ',
             Length(Pr[P].Ar),' arguments');
       If (Length(Pr[P].Ar)>0) then begin Write(StdErr,':');
          For A:=Low(Pr[P].Ar) to High(Pr[P].Ar)
          do Write(StdErr,' ',Pr[P].Ar[A]) end;
       Writeln(StdErr,'.')
       end;}
   If (Not IfSta^.Empty()) then begin
      A:=IfSta^.Peek(); A:=IfArr[A][0];
      Fatal(A, '!if stretches past end of code.') end;
   If (Not WhiSta^.Empty()) then begin
      A:=WhiSta^.Peek(); A:=WhiArr[A][0];
      Fatal(A, 'Fatal: !while stretches past end of code.') end;
   If (Not RepSta^.Empty()) then begin
      A:=RepSta^.Peek(); A:=RepArr[A][0];
      Fatal(A, '!repeat stretches past end of code.') end;
   Dispose(WhiSta,Destroy()); Dispose(RepSta,Destroy());
   Dispose(IfSta,Destroy());
   
   PQInt(PTV^.Ptr)^ := Ceil(TimeStampToMSecs(DateTimeToTimeStamp(Now()))-GLOB_ms);
   end;

Procedure Run();
   Var R:PValue;
   begin
   DoExit:=False;
   GLOB_sdt:=Now();
   GLOB_sms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_sdt));
   
   R:=RunFunc(0); If (R<>NIL) then FreeVal(R)
   end;

Procedure Cleanup();
   Var C,I:LongWord; VEA:TValTrie.TEntryArr;
   begin
   // Free all the user-functions, their expressions and tokens
   UsrFun^.Flush(); Dispose(UsrFun, Destroy());
   If (Length(Pr)>0) then
      For C:=Low(Pr) to High(Pr) do
          FreeProc(Pr[C]);
   // Free any remaining variable tries
   If (Length(Vars)>0) then
      For C:=High(Vars) to Low(Vars) do begin
          If (Not Vars[C]^.Empty) then begin
             VEA := Vars[C]^.ToArray(); Vars[C]^.Flush();
             For I:=Low(VEA) to High(VEA) do FreeVal(VEA[I].Val)
             end;
          Dispose(Vars[C],Destroy());
          end;
   // Free the constants trie
   If (Not Cons^.Empty) then begin
      VEA := Cons^.ToArray(); Cons^.Flush();
      For I:=Low(VEA) to High(VEA) do FreeVal(VEA[I].Val)
      end;
   Dispose(Cons,Destroy());
   end;

begin //MAIN
GLOB_dt:=Now(); GLOB_ms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_dt));
IfSta:=NIL; RepSta:=NIL; WhiSta:=NIL; Randomize();

New(Func,Create('!','~'));
Func^.SetVal('call',@F_Call);
Func^.SetVal('return',@F_Return);
Func^.SetVal('exit',@F_Exit);
EmptyFunc.Register(Func);
Functions.Register(Func);
Functions_ArrDict.Register(Func);
Functions_CGI.Register(Func);
Functions_DateTime.Register(Func);
Functions_Strings.Register(Func);
Functions_SysInfo.Register(Func);
Functions_TypeCast.Register(Func);
//YukSDL.Register(Func);

If (ParamCount()>0) then begin
   ParMod:=PAR_INPUT;
   For YukNum:=1 to ParamCount() do begin
   If (ParamStr(YukNum)='-o') then begin
      ParMod:=PAR_OUTPUT; Continue end else
   If (ParamStr(YukNum)='-e') then begin
      ParMod:=PAR_ERR; Continue end;
   Assign(YukFile,ParamStr(YukNum));
   If (ParMod = PAR_INPUT) then begin
      {$I-} Reset(YukFile); {$I+}
      If (IOResult=0) then begin
         YukPath:=ParamStr(YukNum);
         ReadFile(@YukFile); Close(YukFile);
         Run(); Cleanup()
         end
      end else begin
      {$I-} Rewrite(YukFile); {$I+}
      If (IOResult = 0) then begin
         If (ParMod = PAR_OUTPUT)
            then begin StdOut:=YukFile; Output:=YukFile end
            else StdErr:=YukFile;
         ParMod:=PAR_INPUT
         end
      end
   end end else begin
   YukPath:='(stdin)';
   ReadFile(@Input);
   Run()
   end;

// At the very end, destroy the trie of built-in functions.
Dispose(Func,Destroy())
end.
