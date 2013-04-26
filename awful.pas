program awful;

{$MODE OBJFPC} {$COPERATORS ON} {$LONGSTRINGS ON}

uses SysUtils, Math, Trie, Values, Functions, Stack;

const AWFUL_REVISION = '8';

Type TTokenType = (
     TK_CONS, TK_VARI, TK_REFE, TK_EXPR, TK_BADT);
     
     PExpr = ^TExpr;
     PToken = ^TToken;
     
     TToken = record
     Typ : TTokenType;
     Ptr : Pointer
     end;
     
     TExpr = record
     //Lin : LongWord;
     Fun : PFunc;
     Tok : Array of PToken
     end;
     
     TProc = record
     Nu : LongWord;
     Ex : Array of PExpr;
     Ar : Array of AnsiString;
     end;
     
     PText = ^System.Text;
     
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

Var YukFile : Text; YukNum:LongWord;
    Pr : Array of TProc;
    Proc, ExLn : LongWord;
    ParMod:TParamMode;

Function GetVar(Name:AnsiString;Typ:TValueType):PValue;
   Var C:LongInt; R:PValue;
   begin
   //Writeln(StdErr,'GetVar: ',Name,'; ',Typ);
   C:=High(Vars);
   While (C>=0) do
      Try    R:=Vars[C]^.GetVal(Name);
             Exit(R)
      Except C-=1 end;
   //Writeln(StdErr,'Vars[',High(Vars),']^.SetVal(',Name,',',Typ,')');
   R:=EmptyVal(Typ); R^.Tmp:=False;
   Vars[High(Vars)]^.SetVal(Name,R);
   Exit(R)
   end;

Function Eval(E:PExpr):PValue;
   Var Arg:Array of PValue; T:LongWord; V:PValue;
   begin
   SetLength(Arg,Length(E^.Tok));
   If (Length(E^.Tok)=0) then Exit(E^.Fun(Arg));
   For T:=High(E^.Tok) downto Low(E^.Tok) do
       If (E^.Tok[T]^.Typ = TK_CONS)
          then Arg[T]:=CopyVal(PValue(E^.Tok[T]^.Ptr)) else
       If (E^.Tok[T]^.Typ = TK_VARI) then begin
          If (T<High(E^.Tok)) 
             then V:=GetVar(PStr(E^.Tok[T]^.Ptr)^,Arg[T+1]^.Typ)
             else V:=GetVar(PStr(E^.Tok[T]^.Ptr)^,VT_NIL);
          Arg[T]:=CopyVal(V)
          end else
       If (E^.Tok[T]^.Typ = TK_REFE) then begin
          If (T<High(E^.Tok)) 
             then Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr)^,Arg[T+1]^.Typ)
             else Arg[T]:=GetVar(PStr(E^.Tok[T]^.Ptr)^,VT_NIL);
          end else
       If (E^.Tok[T]^.Typ = TK_EXPR)
          then Arg[T]:=Eval(PExpr(E^.Tok[T]^.Ptr));
   Exit(E^.Fun(Arg))
   end;

Function RunFunc(P:LongWord):PValue;
   Var R:PValue;
   begin
   If (Pr[P].Nu = 0) then Exit(NilVal);
   Proc:=P; ExLn:=0;
   While (True) do begin
      R:=Eval(Pr[P].Ex[ExLn]); ExLn+=1;
      If (ExLn < Pr[P].Nu)
         then FreeVal(R)
         else Exit(R)
      end
   end;

Function F_If(Arg:Array of PValue):PValue;
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
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end
      end else R:=False;
   IfNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   If (Not R) then ExLn:=IfArr[IfNum][1];
   Exit(NilVal)
   end;

Function F_Else(Arg:Array of PValue):PValue;
   Var C:LongWord; IfNum:QInt;
   begin
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   IfNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   ExLn:=IfArr[IfNum][2];
   Exit(NilVal)
   end;

Function F_While(Arg:Array of PValue):PValue;
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
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end
      end else R:=False;
   WhiNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   If (Not R) then ExLn:=WhiArr[WhiNum][2];
   Exit(NilVal)
   end;

Function F_Done(Arg:Array of PValue):PValue;
   Var C:LongWord; WhiNum:QInt;
   begin
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   WhiNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   ExLn:=WhiArr[WhiNum][1];
   Exit(NilVal)
   end;

Function F_Until(Arg:Array of PValue):PValue;
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
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end
      end else R:=False;
   RepNum:=PQInt(Arg[0]^.Ptr)^; FreeVal(Arg[0]);
   If (Not R) then ExLn:=RepArr[RepNum][1];
   Exit(NilVal)
   end;

Function F_Return(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)>1) then
      For C:=Low(Arg)+1 to High(Arg) do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   If (Not Arg[0]^.Tmp)
      then R:=CopyVal(Arg[0]) else R:=Arg[0];
   ExLn:=Pr[Proc].Nu;
   Exit(R)
   end;

Function F_AutoCall(Arg:Array of PValue):PValue;
   Var P,E,V:LongWord; A,H,PA,CA:LongInt; R,TV:PValue;
   begin
   P:=Proc; E:=ExLn; Proc:=PQInt(Arg[0]^.Ptr)^;
   SetLength(Vars,Length(Vars)+1); V:=High(Vars);
   New(Vars[V],Create('A','z'));
   If (Length(Pr[Proc].Ar)>0) then begin
      PA:=Length(Pr[Proc].Ar); CA:=Length(Arg)-1;
      H:=Min(PA,CA);
      If (H>0) then For A:=0 to (H-1) do begin
         Vars[V]^.SetVal(Pr[Proc].Ar[A],Arg[A+1]);
         Arg[A+1]^.Tmp:=False end;
      If (PA>CA) then For A:=H to (PA-1) do begin
         TV:=NilVal(); TV^.Tmp:=False;
         Vars[V]^.SetVal(Pr[Proc].Ar[A],TV) end else
      If (CA<PA) then For A:=H to (CA-1) do begin
         Vars[V]^.SetVal('ARG'+IntToStr(A),Arg[A+1]);
         Arg[A+1]^.Tmp:=False end
      end;
   R:=RunFunc(Proc);
   //Writeln(StdErr,'F_AutoCall(',Proc,'): Trie size: ',Vars[V]^.Count);
   If (Length(Pr[Proc].Ar)>0) then begin
      For A:=0 to High(Pr[Proc].Ar) do Vars[V]^.RemVal(Pr[Proc].Ar[A]);
      A+=1 end else A:=1;
   While (A<=High(Arg)) do begin
      Vars[V]^.RemVal('ARG'+IntToStr(A-1)); A+=1 end;
   While (Vars[V]^.Count > 0) do begin
      //Writeln(StdErr,'F_AutoCall(',Proc,'): Vars[',V,']; Count: ',Vars[V]^.Count,'; RemVal()');
      TV:=Vars[V]^.RemVal();
      //F_Writeln([NewVal(VT_STR,'TV = '),TV]);
      FreeVal(TV)
      end;
   //Writeln(StdErr,'F_AutoCall(',Proc,'): Trie size: ',Vars[V]^.Count);
   Dispose(Vars[V],Destroy()); SetLength(Vars,Length(Vars)-1);
   For A:=Low(Arg) to High(Arg) do
       If (Arg[A]^.Tmp) then FreeVal(Arg[A]);
   Proc:=P; ExLn:=E;
   Exit(R)
   end;

Function GetFunc(Name:AnsiString):PFunc;
   Var R:PFunc;
   begin
   Try R:=Func^.GetVal(Name);
       Exit(R)
   Except
       Exit(Nil)
   end end;

Procedure Fatal(Ln:LongWord;Msg:AnsiString);
   begin
   Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): Fatal: ',Msg);
   Halt(1)
   end;

Function MakeExpr(Var Tk:Array of AnsiString;Ln,T:LongInt):PExpr;
   
   Function ConstPrefix(C:Char):Boolean;
      begin Exit(Pos(C,'sflihob=')<>0) end;
   
   Var E:PExpr; FPtr:PFunc; sex:PExpr; oT,A:LongWord;
       Tok:PToken; V:PValue; PS:PStr; Nest:LongWord; CName:TStr;
   begin
   New(E); oT:=T;
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
         If (IfSta^.Empty()) then Fatal(Ln,'Fatal: !fi without corresponding !if.');
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
         Tk[T]:='i'+IntToStr(High(WhiArr)); T-=1;
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
         Tk[T]:='i'+IntToStr(High(RepArr)); T-=1;
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
         V^.Tmp:=False; Cons^.SetVal(CName,V);
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
         T+=1; Continue
         end;
      If (Tk[T][1]='&') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         New(Tok); New(PS); Tok^.Typ:=TK_VARI; Tok^.Ptr:=PS; 
         PS^:=Copy(Tk[T],2,Length(Tk[T]));
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='$') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         New(Tok); New(PS); Tok^.Typ:=TK_REFE; Tok^.Ptr:=PS; 
         PS^:=Copy(Tk[T],2,Length(Tk[T]));
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='=') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         CName:=Copy(Tk[T],2,Length(Tk[T]));
         Try    V:=Cons^.GetVal(CName);
         Except Fatal(Ln,'Unknown constant "'+CName+'".') end;
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V;
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='s') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         V:=NewVal(VT_STR,Copy(Tk[T],3,Length(Tk[T])-3));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Tmp:=False;
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='i') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         V:=NewVal(VT_INT,StrToInt(Copy(Tk[T],2,Length(Tk[T]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Tmp:=False;
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='h') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         V:=NewVal(VT_HEX,StrToHex(Copy(Tk[T],2,Length(Tk[T]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Tmp:=False;
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='o') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         V:=NewVal(VT_OCT,StrToOct(Copy(Tk[T],2,Length(Tk[T]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Tmp:=False;
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='b') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         V:=NewVal(VT_BIN,StrToBin(Copy(Tk[T],2,Length(Tk[T]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Tmp:=False;
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='l') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         V:=NewVal(VT_BOO,StrToBoolDef(Copy(Tk[T],2,Length(Tk[T])),False));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Tmp:=False;
         E^.Tok[High(E^.Tok)]:=Tok
         end else
      If (Tk[T][1]='f') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         V:=NewVal(VT_FLO,StrToReal(Copy(Tk[T],2,Length(Tk[T]))));
         New(Tok); Tok^.Typ:=TK_CONS; Tok^.Ptr:=V; V^.Tmp:=False;
         E^.Tok[High(E^.Tok)]:=Tok
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
               end else T+=1
         end else
      If (Tk[T][1]=')') then begin
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
         Fatal(Ln,'Invalid token: "'+Tk[T]+'".')
         end;
      T+=1 end;
   Exit(E)
   end;

Function ProcessLine(L:AnsiString;N:LongWord):PExpr;
   Var Tk:Array of AnsiString; P,E:LongWord;
       Str:LongInt; Del:Char;
   begin
   SetLength(Tk,0); P:=1; Str:=0; Del:=#255;
   While (Length(L)>0) do begin
      If (Str<=0) then begin
         If (P>Length(L)) or (L[P]=#32) then begin
            SetLength(Tk,Length(Tk)+1);
            Tk[High(Tk)]:=Copy(L,1,P-1);
            If (Tk[High(Tk)]='|') then begin
               Tk[High(Tk)]:=')';
               SetLength(Tk,Length(Tk)+1);
               Tk[High(Tk)]:='('
               end;
            While (P<Length(L)) and (L[P+1]=#32) do P+=1;
            Delete(L,1,P); P:=0; Str:=0
            end else
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
      P+=1;
      end;
   If (Length(Tk)=0) then begin //Should never happen.
      Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
              'Fatal: Line with no tokens.');
      Halt(1) end;
   Exit(MakeExpr(Tk,N,0))
   end;

Procedure ReadFile(I:PText);
   Var L:AnsiString; A,N,E,P:LongWord; R:PExpr;
   begin
   SetLength(Pr,1); N:=0; Proc:=0; ExLn:=0;
   SetLength(Pr[0].Ar,0); SetLength(Pr[0].Ex,0); Pr[0].Nu:=0;
   SetLength(IfArr,0);  New(IfSta,Create());
   SetLength(WhiArr,0); New(WhiSta,Create());
   SetLength(RepArr,0); New(RepSta,Create());
   While (Not Eof(I^)) do begin
      Readln(I^,L); N+=1;
      L:=Trim(L);
      If (Length(L)>0) and (L[1]<>'#') then begin
         P:=Proc; E:=Pr[P].Nu; ExLn:=E;
         R:=ProcessLine(L,N);
         If (R<>NIL) then begin
            SetLength(Pr[P].Ex,Length(Pr[P].Ex)+1);
            Pr[P].Ex[E]:=R;
            Pr[P].Nu+=1
            end
         end
      end;
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
      Writeln(StdErr,ExtractFileName(YukPath),'(',A,'): ',
              'Fatal: !if stretches past end of code.');
      Halt(1) end;
   If (Not WhiSta^.Empty()) then begin
      A:=WhiSta^.Peek(); A:=WhiArr[A][0];
      Writeln(StdErr,ExtractFileName(YukPath),'(',A,'): ',
              'Fatal: !while stretches past end of code.');
      Halt(1) end;
   If (Not RepSta^.Empty()) then begin
      A:=RepSta^.Peek(); A:=RepArr[A][0];
      Writeln(StdErr,ExtractFileName(YukPath),'(',A,'): ',
              'Fatal: !repeat stretches past end of code.');
      Halt(1) end;
   Dispose(WhiSta,Destroy()); Dispose(RepSta,Destroy());
   Dispose(IfSta,Destroy())
   end;

Procedure Run();
   Var R:PValue;
   begin
   R:=RunFunc(0);
   FreeVal(R)
   end;

Procedure Cleanup();
   begin
   
   end;

begin //MAIN
GLOB_dt:=Now(); GLOB_ms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_dt));
IfSta:=NIL; RepSta:=NIL; WhiSta:=NIL;

New(Func,Create('!','~'));
Func^.SetVal('return',@F_Return);
Functions.Register(Func);

SetLength(Vars,1); New(Vars[0],Create('A','z'));
New(Cons,Create('A','z'));
New(UsrFun,Create('A','z'));

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

Dispose(Vars[0],Destroy());
Dispose(Cons,Destroy());
Dispose(Func,Destroy())
end.
