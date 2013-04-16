program awful;

{$MODE OBJFPC} {$COPERATORS ON} {$LONGSTRINGS ON}

uses Trie, Values, Functions, SysUtils;

Type TTokenType = (
     TK_CONS, TK_VARI, TK_EXPR, TK_BADT);
     
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

Var Func : PFunTrie;
    Vars : PValTrie;

Var dt:TDateTime; ms:Comp;
    YukFile : Text; YukPath:AnsiString; YukNum:LongWord;
    Ex : Array of PExpr;

Function F_FilePath(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   Exit(NewVal(VT_STR,YukPath))
   end;

Function F_FileName(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   Exit(NewVal(VT_STR,ExtractFileName(YukPath)))
   end;

Function F_Ticks(Arg:Array of PValue):PValue;
   Var C:LongWord; TS:Comp;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   TS:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   Exit(NewVal(VT_INT,Trunc(TS-MS)))
   end;

Function GetFunc(Name:AnsiString):PFunc;
   Var R:PFunc;
   begin
   Try R:=Func^.GetVal(Name);
       Exit(R)
   Except
       Exit(Nil)
   end end;

Function MakeExpr(Const Tk:Array of AnsiString;N,T:LongWord):PExpr;
   Var E:PExpr; FPtr:PFunc; sex:PExpr;
       Tok:PToken; V:PValue; PS:PStr;
   begin
   New(E); FPtr:=GetFunc(Copy(Tk[T],2,Length(Tk[T])));
   If (FPtr = NIL) then begin
      Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
                     'Fatal: Unknown function "',Tk[T],'".');
      Halt(1)
      end;
   E^.Fun:=FPtr; T+=1;
   While (T<=High(Tk)) do begin
      If (Length(Tk[T])=0) then begin
         Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
                 'Error: Empty token.');
         T+=1; Continue
         end;
      If (Tk[T][1]='$') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         New(Tok); New(PS); Tok^.Typ:=TK_VARI; Tok^.Ptr:=PS; 
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
      If (Tk[T][1]='!') then begin
         SetLength(E^.Tok,Length(E^.Tok)+1);
         sex:=MakeExpr(Tk,N,T);
         New(Tok); Tok^.Typ:=TK_EXPR; Tok^.Ptr:=sex;
         E^.Tok[High(E^.Tok)]:=Tok;
         Exit(E)
         end else
         Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
                 'Note: Invalid token: "',Tk[T],'".');
      T+=1 end;
   Exit(E)
   end;

Procedure ProcessLine(L:AnsiString;N,E:LongWord);
   Var Tk:Array of AnsiString; P,C:LongWord;
       Str:LongInt; Del:Char; FTok:Boolean;
   begin
   SetLength(Tk,0); P:=1; Str:=0; Del:=#255;
   While (Length(L)>0) do begin
      If (Str<=0) then begin
         If (P>Length(L)) or (L[P]=#32) then begin
            SetLength(Tk,Length(Tk)+1);
            Tk[High(Tk)]:=Copy(L,1,P-1);
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
   C:=Low(Tk); FTok:=False;
   While (C<=High(Tk)) and (Not FTok) do begin
      If (Length(Tk[C])=0) then begin
         Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
                 'Error: Empty token.');
         C+=1; Continue
         end;
      If (Tk[C][1]='!') then FTok:=True
                        else C+=1
      end;
   If (Not FTok) then begin
      Writeln(StdErr,ExtractFileName(YukPath),'(',N,'): ',
                     'Fatal: No function call.');
      Halt(1)
      end;
   Ex[E]:=MakeExpr(Tk,N,C)
   end;

Procedure ReadFile(I:PText);
   Var L:AnsiString; N:LongWord;
   begin
   SetLength(Ex,0); N:=0;
   While (Not Eof(I^)) do begin
      Readln(I^,L); N+=1;
      L:=Trim(L);
      If (Length(L)>0) and (L[1]<>'#') then begin
         SetLength(Ex,Length(Ex)+1);
         ProcessLine(L,N,High(Ex))
         end
      end
   end;

Function Eval(E:PExpr):PValue;
   Var Arg:Array of PValue; T:LongWord;
   begin
   SetLength(Arg,Length(E^.Tok));
   If (Length(E^.Tok)=0) then Exit(E^.Fun(Arg));
   For T:=High(E^.Tok) downto Low(E^.Tok) do
       If (E^.Tok[T]^.Typ = TK_CONS)
          then Arg[T]:=CopyVal(PValue(E^.Tok[T]^.Ptr)) else
       If (E^.Tok[T]^.Typ = TK_VARI) then begin
          Try    Arg[T]:=Vars^.GetVal(PStr(E^.Tok[T]^.Ptr)^)
          Except If (T<High(E^.Tok)) 
                    then Arg[T]:=CopyVal(Arg[T+1])
                    else Arg[T]:=NilVal();
                 Arg[T]^.Tmp:=False;
                 Vars^.SetVal(PStr(E^.Tok[T]^.Ptr)^,Arg[T]);
          end end else
       If (E^.Tok[T]^.Typ = TK_EXPR)
          then Arg[T]:=Eval(PExpr(E^.Tok[T]^.Ptr));
   Exit(E^.Fun(Arg))
   end;

Procedure Run();
   Var E:LongWord; R:PValue;
   begin
   If (Length(Ex)=0) then Exit() else E:=Low(Ex);
   While (E<=High(Ex)) do begin
      R:=Eval(Ex[E]);
      FreeVal(R);
      E+=1
      end;
   end;

Procedure Cleanup();
   begin
   
   end;

begin //MAIN
dt:=Now(); ms:=TimeStampToMSecs(DateTimeToTimeStamp(dt));

New(Func,Create('a','z'));
Func^.SetVal('ticks',@F_Ticks);
Func^.SetVal('filepath',@F_FilePath);
Func^.SetVal('filename',@F_FileName);
Functions.Register(Func);

New(Vars,Create('a','z'));

If (ParamCount()>0) then begin
   For YukNum:=1 to ParamCount() do begin
   Assign(YukFile,ParamStr(YukNum));
   {$I-} Reset(YukFile); {$I+}
   If (IOResult=0) then begin
      ReadFile(@YukFile); Close(YukFile);
      YukPath:=ParamStr(YukNum);
      Run(); Cleanup()
      end
   end end else begin
   ReadFile(@Input);
   YukPath:='-stdin-';
   Run()
   end;

Dispose(Vars,Destroy());
Dispose(Func,Destroy())
end.
