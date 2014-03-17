unit functions_files;

{$INCLUDE defines.inc}

interface
   uses Values; 

// TODO: parameter if dir <> file

Procedure Register(Const FT:PFunTrie);

Function F_fappend(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_freset(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_frewrite(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_fopen(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_feof(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_fclose(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

//Function F_fget(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_fgetline(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_fread(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_freadln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_fwrite(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_fwriteln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_FileExtractName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileExtractPath(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileExtractExt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileExpandName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_FileExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileUnlink(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileRename(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DirExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DirCreate(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DirForce(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DirRemove(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses SysUtils, Globals, FileHandling, EmptyFunc,
        Values_Typecast;

Procedure Register(Const FT:PFunTrie);
   begin
   // File utils
   FT^.SetVal('file-extract-name',MkFunc(@F_FileExtractName));
   FT^.SetVal('file-extract-path',MkFunc(@F_FileExtractPath));
   FT^.SetVal('file-extract-ext',MkFunc(@F_FileExtractExt));
   FT^.SetVal('file-expand-name',MkFunc(@F_FileExpandName));
   FT^.SetVal('file-exists',MkFunc(@F_FileExists));
   FT^.SetVal('file-unlink',MkFunc(@F_FileUnlink));
   FT^.SetVal('file-rename',MkFunc(@F_FileRename));
   // Dir utils
   FT^.SetVal('dir-exists',MkFunc(@F_DirExists));
   FT^.SetVal('dir-create',MkFunc(@F_DirCreate));
   FT^.SetVal('dir-force' ,MkFunc(@F_DirForce ));
   FT^.SetVal('dir-remove',MkFunc(@F_DirCreate));
   // File handling
   FT^.SetVal('f-append' ,MkFunc(@F_fappend));
   FT^.SetVal('f-reset'  ,MkFunc(@F_freset));
   FT^.SetVal('f-rewrite',MkFunc(@F_frewrite));
   FT^.SetVal('f-open'   ,MkFunc(@F_fopen));
   FT^.SetVal('f-close'  ,MkFunc(@F_fclose));
   FT^.SetVal('f-read'   ,MkFunc(@F_fread,REF_MODIF));
   FT^.SetVal('f-readln' ,MkFunc(@F_freadln,REF_MODIF));
   FT^.SetVal('f-getln'  ,MkFunc(@F_fgetline));
   FT^.SetVal('f-eof'    ,MkFunc(@F_feof))
   end;

Function OpenFile(Const Name:AnsiString; Const Mode:Char):LongInt;
   Var F:LongWord;
   begin
   F:=Length(FileHandles); SetLength(FileHandles, F+1);
   FileHandles[F].Pth := ExpandFileName(Name);
   FileHandles[F].arw := Mode;
   Assign(FileHandles[F].Fil, Name);
   Case Mode of
      'a': {$I-}  Append(FileHandles[F].Fil); {$I+}
      'r': {$I-}   Reset(FileHandles[F].Fil); {$I+}
      'w': {$I-} Rewrite(FileHandles[F].Fil); {$I+}
      end; 
   If (IOResult <> 0) then FileHandles[F].arw := 'u';
   Exit(F)
   end;

Function F_fopen(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Mode:Char; PS:PStr; F:LongWord;
   begin
   If (Length(Arg^)<2) then Exit(F_(DoReturn, Arg));
   // Determine mode
   If (Arg^[1]^.Typ = VT_STR) then begin
      PS := PStr(Arg^[1]^.Ptr);
      If (Length(PS^)>0) then begin
         Mode:=LowerCase(PS^[1]);
         If (Not (Mode in ['r','w','a'])) then Mode:='r'
         end else Mode:='r'
      end else
   If (Arg^[1]^.Typ >= VT_INT) and (Arg^[1]^.Typ <= VT_FLO) then begin
      Case (ValAsInt(Arg^[1])) of
           2: Mode := 'a';
           1: Mode := 'w';
         else Mode := 'r'
      end end else
   If (Arg^[1]^.Typ = VT_BOO) then begin
      If (PBool(Arg^[1]^.Ptr)^) then Mode:='w' else Mode:='r';
      end else
      Mode := 'r';
   // Determine file path
   F := OpenFile(ValAsStr(Arg^[0]),Mode);
   F_(False, Arg);
   If (DoReturn)
      then Exit(NewVal(VT_FIL, @FileHandles[F]))
      else Exit(NIL)
   end;

Function F_fopenMode(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Mode:Char):PValue;
   Var F:LongWord;
   begin
   If (Length(Arg^) = 0) then Exit(F_(DoReturn, Arg));
   F := OpenFile(ValAsStr(Arg^[0]), Mode);
   F_(False, Arg);
   If (DoReturn) then Exit(NewVal(VT_FIL, @FileHandles[F]))
                 else Exit(NIL)
   end;

Function F_fappend(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_fopenMode(DoReturn, Arg, 'a')) end;

Function F_freset(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_fopenMode(DoReturn, Arg, 'r')) end;

Function F_frewrite(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_fopenMode(DoReturn, Arg, 'w')) end;

Function F_feof(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; Res,Nao:Boolean;
   begin Res:=True;
   If (Length(Arg^)>0) then
      For C:=0 to High(Arg^) do begin
         If (Arg^[C]^.Typ = VT_FIL) and (Arg^[C]^.Ptr <> NIL) then
            If (PFileHandle(Arg^[C]^.Ptr)^.arw = 'r') then begin
               {$I-} Nao := eof(PFileHandle(Arg^[C]^.Ptr)^.Fil); {$I+}
               If (IOResult() <> 0) then Nao := True;
               Res := Res and Nao
               end;
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   If (DoReturn) then Exit(NewVal(VT_BOO,Res))
                 else Exit(NIL)
   end;

Function F_fclose(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,Num:LongWord;
   begin Num := 0;
   If (Length(Arg^)>0) then
      For C:=0 to High(Arg^) do begin
         If (Arg^[C]^.Typ = VT_FIL) and (Arg^[C]^.Ptr <> NIL) then
            If (PFileHandle(Arg^[C]^.Ptr)^.arw in ['a','r','w']) then begin
               {$I-} Close(PFileHandle(Arg^[C]^.Ptr)^.Fil); {$I+}
               PFileHandle(Arg^[C]^.Ptr)^.arw := 'c';
               If (IOResult() = 0) then Num += 1
               end;
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   If (DoReturn) then Exit(NewVal(VT_INT, Num))
                 else Exit(NIL)
   end;

Function F_readfile(Const DoReturn:Boolean; Const Arg:PArrPVal; Const DoTrim:Boolean):PValue;
   Var C, P : LongWord; H:PFileHandle;
   begin
   If (Length(Arg^)=0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
   H := PFileHandle(Arg^[0]^.Ptr); If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   For C:=1 to High(Arg^) do begin 
      P := FillBuffer(H^.Fil, @H^.Buf, DoTrim);
      FillVar(Arg^[C], @H^.Buf, P);
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end;

Function F_fread(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_readfile(DoReturn, Arg, TRIM_NO)) end;

Function F_freadln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_readfile(DoReturn, Arg, TRIM_YES)) end;

Function F_fgetline(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var H:PFileHandle; 
   begin
   If (Length(Arg^) = 0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
   H := PFileHandle(Arg^[0]^.Ptr); F_(False, Arg);
   If (H^.Buf = '') then {$I-} Readln(H^.Fil, H^.Buf); {$I+}
   If (IOResult<>0) then H^.Buf := '';
   If (DoReturn) then Result:=NewVal(VT_STR, H^.Buf) else Result:=NIL;
   H^.Buf := ''
   end;

Function F_fwrite(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   If (Length(Arg^) = 0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
   WriteFile(PFileHandle(Arg^[0]^.Ptr)^.Fil, Arg, 1); F_(False, Arg);
   If (DoReturn) then Exit(EmptyVal(VT_STR)) else Exit(NIL)
   end;
   
Function F_fwriteln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   If (Length(Arg^) = 0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
   WriteFile(PFileHandle(Arg^[0]^.Ptr)^.Fil, Arg, 1);
   Writeln(PFileHandle(Arg^[0]^.Ptr)^.Fil);
   F_(False, Arg);
   If (DoReturn) then Exit(EmptyVal(VT_STR)) else Exit(NIL)
   end;

Type TUtilStringFunc = Function(Const Str:AnsiString):AnsiString;
Type TUtilBoolFunc = Function(Const Str:AnsiString):Boolean;

Function F_FileUtils(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TUtilStringFunc):PValue; 
   begin
   If (Not DoReturn) then Exit(F_(False,Arg));
   If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
   If (Arg^[0]^.Typ = VT_UTF)
      then Result := NewVal(VT_UTF,Func(ValAsStr(Arg^[0])))
      else Result := NewVal(VT_STR,Func(ValAsStr(Arg^[0])));
   F_(False, Arg)
   end;

Function F_FileExtractName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @ExtractFileName)) end;

Function F_FileExtractPath(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @ExtractFilePath)) end;

Function F_FileExtractExt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @ExtractFileExt)) end;

Function F_FileExpandName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @ExpandFileName)) end;

Function F_FileRename(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Res:Boolean;
   begin Res := False;
   If (Length(Arg^) >= 2) then Res:=RenameFile(ValAsStr(Arg^[0]),ValAsStr(Arg^[1]));
   F_(False, Arg);
   If (DoReturn) then Exit(NewVal(VT_BOO, Res))
                 else Exit(NIL)
   end;

Function F_DirAction(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TUtilBoolFunc):PValue; Inline;
   Var C,Num:LongWord;
   begin Num := 0;
   If (Length(Arg^)>0) then
      For C:=0 to High(Arg^) do begin
         If (Func(ValAsStr(Arg^[0]))) then Num += 1;
         If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
   If (DoReturn) then Exit(NewVal(VT_BOO, (Num > 0) and (Num = Length(Arg^))))
                 else Exit(NIL)
   end;

Function F_FileExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @FileExists)) end;
   
Function F_FileUnlink(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @DeleteFile)) end;

Function F_DirExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @DirectoryExists)) end;

Function F_DirCreate(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @CreateDir)) end;
   
Function F_DirForce(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @ForceDirectories)) end;

Function F_DirRemove(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @RemoveDir)) end;

end.
