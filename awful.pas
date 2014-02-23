program awful;

{$INCLUDE defines.inc} {$LONGSTRINGS ON} {$PASCALMAINNAME AWFUL_MAIN}

uses SysUtils,
     
     Values, TokExpr,
     
     Globals, Parser,
     
     EmptyFunc, CoreFunc, Functions,
     
     Functions_Arith,    Functions_ArrDict,
     Functions_Bitwise,  Functions_Boole,
     Functions_CGI,      Functions_Compare,
     Functions_DateTime,
     Functions_Math,
     Functions_stdIO,    Functions_Strings, Functions_SysInfo,
     Functions_TypeCast;
// ----- uses

Type TParamMode = (PAR_INPUT, PAR_OUTPUT, PAR_ERR);

Var ParMod:TParamMode;
    Switch_NoRun : Boolean = FALSE;
    
    CustomStdIn : ^System.Text;
    CustomStdErr, CustomStdOut : System.Text;
    OrigDir : AnsiString;

Procedure AnalyseParams();
   Var ParamLim : LongWord; ParamNow : AnsiString;
   begin
   GetDir(0, OrigDir);
   YukPath := '(stdin)';
   YukName := YukPath;
   ParamNum := 1;
   CustomStdIn := NIL;
   
   ParamLim := ParamCount();
   If (ParamLim = 0) then Exit();
   
   ParMod:=PAR_INPUT; 
   While (ParamNum <= ParamLim) do begin
      ParamNow := ParamStr(ParamNum);
      If (ParamNow = '-o') then begin
         ParMod:=PAR_OUTPUT; ParamNum += 1; Continue
         end else
      If (ParamNow = '-e') then begin
         ParMod:=PAR_ERR; ParamNum += 1; Continue
         end else
      If (ParamNow = '--norun') then begin
         Switch_NoRun := True; ParamNum += 1; Continue
         end else
      If (ParamNow = '--version') then begin
         Writeln('awful v.',VERSION,' (rev. ',VREVISION,')');
         Halt(0)
         end else
      If (ParMod = PAR_INPUT) then begin
         ParamNum += 1; New(CustomStdIn);
         Assign(CustomStdIn^, ParamNow);
         
         YukPath:=ExpandFileName(ParamNow);
         YukName:=ExtractFileName(YukPath);
         
         {$I-} Reset(CustomStdIn^); {$I+}
         If (IOResult() <> 0) then Fatal(0,'Could not read script file.', 2);
         
         {$I-} ChDir(ExtractFilePath(YukPath)); {$I+}
         ParamLim := 0 //; ParamNum := High(ParamNum)
         end else
      If (ParMod = PAR_OUTPUT) then begin
         ParamNum += 1;
         Assign(CustomStdOut, ParamNow);
         {$I-} Rewrite(CustomStdOut); {$I+}
         If (IOResult() = 0) then begin Output := CustomStdOut; StdOut := CustomStdOut end;
            ParMod:=PAR_INPUT
         end else
      If (ParMod = PAR_ERR) then begin
         ParamNum += 1;
         Assign(CustomStdErr, ParamNow);
         {$I-} Rewrite(CustomStdErr); {$I+}
         If (IOResult() = 0) then StdErr := CustomStdErr;
            ParMod:=PAR_INPUT
         end
      end
   end;

Procedure Run();
   Var R:PValue;
   begin
   DoExit:=False;
   
   GLOB_sdt:=Now();
   GLOB_sms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_sdt));
   
   {$IFDEF CGI}
   Functions_CGI.ProcessGet();
   Functions_CGI.ProcessPost();
   Functions_CGI.ProcessCake();
   
   SetLength(Headers, 1);
   Headers[0].Key:='content-type'; Headers[0].Val:='text/html';
   {$ENDIF}
   
   R:=RunFunc(0); If (R<>NIL) then FreeVal(R)
   end;

Procedure Cleanup();
   Var C,I:LongWord; VEA:TDict.TEntryArr;
   begin
   // Free all the user-functions, their expressions and tokens
   UsrFun^.Flush(); Dispose(UsrFun, Destroy());
   If (Length(Pr)>0) then
      For C:=Low(Pr) to High(Pr) do
          FreeProc(Pr[C]);
   // Free any remaining variable tries
   If (Length(FCal)>0) then
      For C:=High(FCal) downto Low(FCal) do begin
          If (Not FCal[C].Vars^.Empty) then begin
             VEA := FCal[C].Vars^.ToArray(); FCal[C].Vars^.Flush();
             For I:=Low(VEA) to High(VEA) do AnnihilateVal(VEA[I].Val)
             end;
          Dispose(FCal[C].Vars,Destroy());
          end;
   // Set dynarr length to 0
   {$IFDEF CGI} Functions_CGI.FreeArrays(); {$ENDIF}
   SetLength(Pr, 0); SetLength(FCal, 0);
   // Free the name/path consts of included files
   If (Length(FileIncludes)>0) then
      For C:=Low(FileIncludes) to High(FileIncludes) do begin
          AnnihilateVal(FileIncludes[C].Cons[0]);
          AnnihilateVal(FileIncludes[C].Cons[1])
          end;
   SetLength(FileIncludes, 0);
   // Free the constants trie
   If (Not Cons^.Empty) then begin
      VEA := Cons^.ToArray(); Cons^.Flush();
      For I:=Low(VEA) to High(VEA) do AnnihilateVal(VEA[I].Val)
      end;
   Dispose(Cons,Destroy());
   // At the very end, free the spare variables
   SpareVars_Destroy()
   end;

begin //MAIN
GLOB_dt:=Now(); GLOB_ms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_dt));
Randomize();

New(Func,Create('!','z'));
CoreFunc           . Register(Func);
EmptyFunc          . Register(Func);
Functions          . Register(Func);
Functions_Arith    . Register(Func);
Functions_ArrDict  . Register(Func);
Functions_Boole    . Register(Func);
Functions_Bitwise  . Register(Func);
Functions_CGI      . Register(Func);
Functions_Compare  . Register(Func);
Functions_DateTime . Register(Func);
Functions_Math     . Register(Func);
Functions_stdIO    . Register(Func);
Functions_Strings  . Register(Func);
Functions_SysInfo  . Register(Func);
Functions_TypeCast . Register(Func);
//YukSDL.Register(Func);

AnalyseParams();

If (CustomStdIn <> NIL) then begin
   ReadFile(CustomStdIn^);
   Close(CustomStdIn^);
   Dispose(CustomStdIn)
   end else ReadFile(Input);

If (Not Switch_NoRun)
    then Run()
    else Writeln('No syntax errors detected in "',YukName,'" (parsed in ',PQInt(Cons^.GetVal('AWFUL-PARSETIME')^.Ptr)^,'ms).');

{$I-} ChDir(OrigDir); {$I+}
Cleanup();

// At the very end, destroy the trie of built-in functions.
Dispose(Func,Destroy())
end.
