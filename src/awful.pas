{$INCLUDE defines.inc} {$LONGSTRINGS ON} {$PASCALMAINNAME AWFUL_MAIN}

program awful;

uses
   SysUtils,
   
   FuncInfo, TokExpr, Values,
   
   Globals, Parser,
   
   EmptyFunc, CoreFunc, Functions,
   
   Functions_Arith,     Functions_ArrDict,
   Functions_Bitwise,   Functions_Boole,
   Functions_CGI,       Functions_Compare, Functions_Convert,
   Functions_DateTime,  
   Functions_Encodings, 
   Functions_Files,     
   Functions_Hash,      
   Functions_Math,      
   Functions_stdIO,     Functions_Strings, Functions_SysInfo,
   Functions_TypeCast;
// ----- uses

Type
   TParamMode = (
      PAR_SCRIPT,
      PAR_OUT_R, PAR_ERR_R,
      PAR_OUT_A, PAR_ERR_A,
      PAR_INPUT
   );

Var
   OrigDir : AnsiString;
   Switch_NoRun : Boolean;
    
   CustomScript, CustomStdIn : ^System.Text;
   CustomStdErr, CustomStdOut : System.Text;

Procedure AnalyseParams();
   Var ParMod:TParamMode; ParamLim : LongWord; ParamNow : AnsiString; NoMoreParams : Boolean;
   begin
      OrigDir := GetCurrentDir();
         YukPath := '(stdin)';
         YukName := '(stdin)';
      ScriptName := '(stdin)';
      CustomScript := NIL;
      CustomStdIn := NIL;
      Switch_NoRun := False;
      
      ParamNum := 1;
      ParamLim := ParamCount();
      If (ParamLim = 0) then Exit();
      
      ParMod:=PAR_SCRIPT; NoMoreParams := False;
      While (ParamNum <= ParamLim) do begin
         ParamNow := ParamStr(ParamNum);
         If (Not NoMoreParams) then begin
            If (ParamNow = '-o') then begin
               ParMod:=PAR_OUT_R; ParamNum += 1; Continue
            end else
            If (ParamNow = '-O') then begin
               ParMod:=PAR_OUT_A; ParamNum += 1; Continue
            end else
            If (ParamNow = '-e') then begin
               ParMod:=PAR_ERR_R; ParamNum += 1; Continue
            end else
            If (ParamNow = '-E') then begin
               ParMod:=PAR_ERR_A; ParamNum += 1; Continue
            end else
            If (ParamNow = '-i') then begin
               ParMod:=PAR_INPUT; ParamNum += 1; Continue
            end else
            If (ParamNow = '--') then begin
               NoMoreParams := True; ParamNum += 1; Continue
            end else
            If (ParamNow = '--norun') then begin
               Switch_NoRun := True; ParamNum += 1; Continue
            end else
            If (ParamNow = '--version') then begin
               Writeln(FULLNAME,' v.',VERSION,' (rev. ',VREVISION,')');
               Writeln(
                  'Built by ', {$IFDEF WINDOWS} {$I %USERNAME%} {$ELSE} {$I %USER%} {$ENDIF},
                  ' at ', {$IFDEF WINDOWS} {$I %COMPUTERNAME%} {$ELSE} {$I %HOSTNAME%} {$ENDIF},
                  ' on ',BuildNum(),
                  {$IFDEF FPC}' using FPC ',{$I %FPCVERSION%},{$ENDIF}
                  '.');
               Writeln('--- svgames.pl ---');
               Halt(0)
            end
         end;
         If (ParMod = PAR_SCRIPT) then begin
            ParamNum += 1; New(CustomScript);
            Assign(CustomScript^, ParamNow);
            
            ScriptName:=ParamNow;
            YukPath:=ExpandFileName(ParamNow);
            YukName:=ExtractFileName(YukPath);
            
            {$I-} Reset(CustomScript^); {$I+}
            If (IOResult() <> 0) then Fatal(0,'Could not read script file.', 2);
            
            {$I-} ChDir(ExtractFilePath(YukPath)); {$I+}
            ParamLim := 0 //; ParamNum := High(ParamNum)
         end else
         If (ParMod = PAR_OUT_R) or (ParMod = PAR_OUT_A) then begin
            ParamNum += 1;
            Assign(CustomStdOut, ParamNow);
            If (ParMod = PAR_OUT_R)
               then {$I-} Rewrite(CustomStdOut) {$I+}
               else {$I-}  Append(CustomStdOut) {$I+} ;
            If (IOResult() = 0)
               then begin Output := CustomStdOut; StdOut := CustomStdOut end
               else Writeln(StdErr,'Could not redirect stdout to "'+ParamNow+'".');
            ParMod:=PAR_SCRIPT
         end else
         If (ParMod = PAR_ERR_R) or (ParMod = PAR_ERR_A) then begin
            ParamNum += 1;
            Assign(CustomStdErr, ParamNow);
            If (ParMod = PAR_ERR_R)
               then {$I-} Rewrite(CustomStdErr) {$I+}
               else {$I-}  Append(CustomStdErr) {$I+} ;
            If (IOResult() = 0)
               then StdErr := CustomStdErr
               else Writeln(StdErr,'Could not redirect stderr to "'+ParamNow+'".');
            ParMod:=PAR_SCRIPT
         end else
         If (ParMod = PAR_INPUT) then begin
            ParamNum += 1;
            New(CustomStdIn); Assign(CustomStdIn^, ParamNow);
            {$I-} Reset(CustomStdIn^); {$I+}
            If (IOResult() <> 0) then begin 
               Writeln(StdErr,'Could not read input from "'+ParamNow+'".');
               Dispose(CustomStdIn); CustomStdIn := NIL
            end;
            ParMod:=PAR_SCRIPT
         end
   end end;

Procedure RunScript();
   Var R:PValue;
   begin
      DoExit:=False;
      
      GLOB_sdt:=Now();
      GLOB_sms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_sdt));
      
      {$IFDEF CGI}
      Functions_CGI.Prepare_GET();
      Functions_CGI.Prepare_POST();
      Functions_CGI.Prepare_CAKE();
      
      SetLength(Headers, 1);
      Headers[0].Key:='content-type'; Headers[0].Val:='text/html';
      {$ENDIF}
      
      CurLev := 0;
      R:=RunFunc(0); If (R<>NIL) then AnnihilateVal(R)
      {$IFDEF CGI} ; CGI_EnsureHeaders() {$ENDIF}
   end;

Procedure Cleanup();
   Var C:LongWord;
   begin
      (* Free all the user-functions, their expressions and tokens. *)
      If (Length(Pr)>0) then
         For C:=Low(Pr) to High(Pr) do
            FreeProc(Pr[C]);
      // SetLength(Pr, 0);
      
      (* Free any remaining variable tries. *)
      If (Length(FCal)>0) then
         For C:=High(FCal) downto Low(FCal) do begin
            If (Not FCal[C].Vars^.Empty) then FCal[C].Vars^.Purge(@AnnihilateVal);
            // SetLength(FCal[C]^.Args,0);
            Dispose(FCal[C].Vars,Destroy());
         end;
      // SetLength(FCal, 0);
      
      (* Free the spare variables. *)
      SpareVars_Destroy();
      
      (* If in CGI mode, free the GET/POST/COOKIE arrays. *)
      // {$IFDEF CGI} Functions_CGI.FreeArrays(); {$ENDIF}
      
      (* Free the name/path consts of included files. *)
      If (Length(FileIncludes)>0) then
         For C:=Low(FileIncludes) to High(FileIncludes) do begin
            AnnihilateVal(FileIncludes[C].Cons[0]);
            AnnihilateVal(FileIncludes[C].Cons[1])
         end;
      // SetLength(FileIncludes, 0);
      
      (* Close all user-made file handles. *)
      If (Length(FileHandles)>0) then
         For C:=Low(FileHandles) to High(FileHandles) do
            {$I-} Close(FileHandles[C].Fil); {$I+}
      // SetLength(FileHandles, 0);
      
      (* Free the constants trie. *)
      Cons^.Purge(@AnnihilateVal);
      Dispose(Cons,Destroy());
      
      (* At the very end, destroy the trie of functions. *)
      Func^.Purge(@DisposeFunc);
      Dispose(Func,Destroy())
   end;

begin // awful_main()
   GLOB_dt:=Now(); GLOB_ms:=TimeStampToMSecs(DateTimeToTimeStamp(GLOB_dt));
   Randomize();

   New(Func,Create());
   // Register all built-in functions to the FuncTree
   CoreFunc            . Register(Func);
   EmptyFunc           . Register(Func);
   Functions           . Register(Func);
   Functions_Arith     . Register(Func);
   Functions_ArrDict   . Register(Func);
   Functions_Boole     . Register(Func);
   Functions_Bitwise   . Register(Func);
   Functions_CGI       . Register(Func);
   Functions_Compare   . Register(Func);
   Functions_Convert   . Register(Func);
   Functions_DateTime  . Register(Func);
   Functions_Encodings . Register(Func);
   Functions_Files     . Register(Func);
   Functions_Hash      . Register(Func);
   Functions_Math      . Register(Func);
   Functions_stdIO     . Register(Func);
   Functions_Strings   . Register(Func);
   Functions_SysInfo   . Register(Func);
   Functions_TypeCast  . Register(Func);
   //YukSDL.Register(Func);

   AnalyseParams();

   If (CustomScript <> NIL) then begin
      ReadFile(CustomScript^);
      Close(CustomScript^);
      Dispose(CustomScript)
   end else
      ReadFile(Input);

   If (Not Switch_NoRun) then begin
      If (CustomStdIn <> NIL) then Input := CustomStdIn^;
      RunScript()
   end else
      Writeln('No syntax errors detected in "',ScriptName,'" (parsed in ',Cons^.GetVal('AWFUL-PARSETIME')^.Int^,'ms).');

   {$I-} ChDir(OrigDir); {$I+}
   Cleanup();

   If (CustomStdIn <> NIL) then Dispose(CustomStdIn)
end.
