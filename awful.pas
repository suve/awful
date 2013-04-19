program awful;

{$MODE OBJFPC} {$COPERATORS ON} {$LONGSTRINGS ON}

uses Trie, Values, Functions, SysUtils, Stack;

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
     
     PText = ^System.Text;
     
     TLineInfo = LongInt; //This will probably become a record when functions get implemented
     TIf = Array[0..2] of TLineInfo;
     TLoop = Array[0..2] of TLineInfo;
     
     PLIS = ^TLIS;
     TLIS = specialize GenericStack<TLineInfo>;

Var Func : PFunTrie;
    Vars : PValTrie;

    IfArr : Array of TIf;
    RepArr, WhiArr : Array of TLoop;
    IfSta, RepSta, WhiSta : PLIS;

Var YukFile : Text; YukNum:LongWord;
    Ex : Array of PExpr;
    ExLn : LongWord;

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

Function GetFunc(Name:AnsiString):PFunc;
   Var R:PFunc;
   begin
   Try R:=Func^.GetVal(Name);
       Exit(R)
   Except
       Exit(Nil)
   end end;

Function MakeExpr(Var Tk:Array of AnsiString;Ln,En,T:LongInt):PExpr;
   Var E:PExpr; FPtr:PFunc; sex:PExpr; oT,A:LongWord;
       Tok:PToken; V:PValue; PS:PStr; Nest:LongWord;
   begin
   New(E); oT:=T;
   If (Tk[T][1]=':') then begin
      FPtr:=GetFunc(Copy(Tk[T],2,Length(Tk[T])));
      If (FPtr = NIL) then begin
         Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                        'Fatal: Unknown function: "',Tk[T],'".');
         Halt(1)
      end end else
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
         If (IfSta^.Empty) then begin
            Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                           'Fatal: !else without corresponding !if.');
            Halt(1) end;
         A:=IfSta^.Peek();
         If (IfArr[A][1]>=0) then begin
            Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                           'Fatal: !if from line ',IfArr[A][0],' has a second !else.');
            Halt(1) end;
         IfArr[A][1]:=En;
         Tk[T]:='i'+IntToStr(A); T-=1;
         FPtr:=@(F_Else)
         end else
      If (Tk[T]='!fi') then begin
         If (IfSta^.Empty()) then begin
            Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                           'Fatal: !fi without corresponding !if.');
            Halt(1) end;
         A:=IfSta^.Pop();
         If (IfArr[A][1]<0) then IfArr[A][1]:=En;
         IfArr[A][2]:=En;
         FPtr:=@(F_)
         end else
      If (Tk[T]='!while') then begin
         SetLength(WhiArr,Length(WhiArr)+1);
         WhiArr[High(WhiArr)][0]:=Ln;
         WhiArr[High(WhiArr)][1]:=En-1;
         WhiArr[High(WhiArr)][2]:=-1;
         WhiSta^.Push(High(WhiArr));
         Tk[T]:='i'+IntToStr(High(WhiArr)); T-=1;
         FPtr:=@(F_While)
         end else
      If (Tk[T]='!done') then begin
         If (WhiSta^.Empty()) then begin
            Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                           'Fatal: !done without corresponding !while.');
            Halt(1) end;
         A:=WhiSta^.Pop();
         WhiArr[A][2]:=En;
         Tk[T]:='i'+IntToStr(High(WhiArr)); T-=1;
         FPtr:=@(F_Done)
         end else
      If (Tk[T]='!repeat') then begin
         SetLength(RepArr,Length(RepArr)+1);
         RepArr[High(RepArr)][0]:=Ln;
         RepArr[High(RepArr)][1]:=En;
         RepArr[High(RepArr)][2]:=-1;
         RepSta^.Push(High(RepArr));
         Tk[T]:='i'+IntToStr(High(RepArr)); T-=1;
         FPtr:=@(F_)
         end else
      If (Tk[T]='!until') then begin
         If (RepSta^.Empty()) then begin
            Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                           'Fatal: !until without corresponding !repeat.');
            Halt(1) end;
         A:=RepSta^.Pop();
         RepArr[A][2]:=En;
         Tk[T]:='i'+IntToStr(High(WhiArr)); T-=1;
         FPtr:=@(F_Until)
         end else begin
         Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                           'Fatal: Unknown language construct: "',Tk[T],'".');
         Halt(1) end
      end else begin
      Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                    'Fatal: First token (',Tk[T],') is neither a function call nor a language construct.');
      Halt(1) end;
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
         sex:=MakeExpr(Tk,Ln,En,T+1);
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
         sex:=MakeExpr(Tk,Ln,En,T);
         New(Tok); Tok^.Typ:=TK_EXPR; Tok^.Ptr:=sex;
         E^.Tok[High(E^.Tok)]:=Tok;
         Exit(E)
         end else
      If (Tk[T][1]='!') then begin
         Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                'Fatal: Language construct used as a sub-expression. (',Tk[T],').');
         Halt(1)
         end else begin
         Writeln(StdErr,ExtractFileName(YukPath),'(',Ln,'): ',
                 'Fatal: Invalid token: "',Tk[T],'".');
         Halt(1)
         end;
      T+=1 end;
   Exit(E)
   end;

Procedure ProcessLine(L:AnsiString;N,E:LongWord);
   Var Tk:Array of AnsiString; P:LongWord;
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
   Ex[E]:=MakeExpr(Tk,N,E,0)
   end;

Procedure ReadFile(I:PText);
   Var L:AnsiString; A,N:LongWord;
   begin
   SetLength(Ex,0); N:=0;
   SetLength(IfArr,0); New(IfSta,Create());
   SetLength(WhiArr,0); New(WhiSta,Create());
   SetLength(RepArr,0); New(RepSta,Create());
   While (Not Eof(I^)) do begin
      Readln(I^,L); N+=1;
      L:=Trim(L);
      If (Length(L)>0) and (L[1]<>'#') then begin
         SetLength(Ex,Length(Ex)+1);
         ProcessLine(L,N,High(Ex))
         end
      end;
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

Function Eval(E:PExpr):PValue;
   Var Arg:Array of PValue; T:LongWord; V:PValue;
   begin
   SetLength(Arg,Length(E^.Tok));
   If (Length(E^.Tok)=0) then Exit(E^.Fun(Arg));
   For T:=High(E^.Tok) downto Low(E^.Tok) do
       If (E^.Tok[T]^.Typ = TK_CONS)
          then Arg[T]:=CopyVal(PValue(E^.Tok[T]^.Ptr)) else
       If (E^.Tok[T]^.Typ = TK_VARI) then begin
          Try    V:=Vars^.GetVal(PStr(E^.Tok[T]^.Ptr)^);
                 Arg[T]:=CopyVal(V)
          Except If (T<High(E^.Tok)) 
                    then V:=CopyTyp(Arg[T+1])
                    else V:=NilVal();
                 V^.Tmp:=False;
                 Vars^.SetVal(PStr(E^.Tok[T]^.Ptr)^,V);
                 Arg[T]:=CopyVal(V)
          end end else
       If (E^.Tok[T]^.Typ = TK_REFE) then begin
          Try    Arg[T]:=Vars^.GetVal(PStr(E^.Tok[T]^.Ptr)^)
          Except If (T<High(E^.Tok)) 
                    then Arg[T]:=CopyTyp(Arg[T+1])
                    else Arg[T]:=NilVal();
                 Arg[T]^.Tmp:=False;
                 Vars^.SetVal(PStr(E^.Tok[T]^.Ptr)^,Arg[T]);
          end end else
       If (E^.Tok[T]^.Typ = TK_EXPR)
          then Arg[T]:=Eval(PExpr(E^.Tok[T]^.Ptr));
   Exit(E^.Fun(Arg))
   end;

Procedure Run();
   Var R:PValue;
   begin
   If (Length(Ex)=0) then Exit() else ExLn:=Low(Ex);
   While (ExLn<=High(Ex)) do begin
      R:=Eval(Ex[ExLn]);
      FreeVal(R);
      ExLn+=1
      end;
   end;

Procedure Cleanup();
   begin
   
   end;

begin //MAIN
GLOB_dt:=Now(); GLOB_ms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_dt));
IfSta:=NIL; RepSta:=NIL; WhiSta:=NIL;

New(Func,Create('!','~'));
Func^.SetVal('ticks',@F_Ticks);
Func^.SetVal('filepath',@F_FilePath);
Func^.SetVal('filename',@F_FileName);
Func^.SetVal('datetime:start',@F_DateTime_Start);
Functions.Register(Func);

New(Vars,Create('A','z'));

If (ParamCount()>0) then begin
   For YukNum:=1 to ParamCount() do begin
   Assign(YukFile,ParamStr(YukNum));
   {$I-} Reset(YukFile); {$I+}
   If (IOResult=0) then begin
      YukPath:=ParamStr(YukNum);
      ReadFile(@YukFile); Close(YukFile);
      Run(); Cleanup()
      end
   end end else begin
   YukPath:='(stdin)';
   ReadFile(@Input);
   Run()
   end;

Dispose(Vars,Destroy());
Dispose(Func,Destroy())
end.
