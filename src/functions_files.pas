unit functions_files;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values; 

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

Function F_FileRelativePath(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileExpandName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_FileExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileUnlink(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileRename(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_DirExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DirCreate(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DirForce(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DirRemove(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_FileGetContents(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FilePutContents(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_FileForceContents(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_FileSize(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DirList(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses SysUtils, Globals, FileHandling, EmptyFunc,
        Values_Typecast;

Procedure Register(Const FT:PFunTrie);
   begin
      // File utils
      FT^.SetVal('file-extract-name',MkFunc(@F_FileExtractName));
      FT^.SetVal('file-extract-path',MkFunc(@F_FileExtractPath));
      FT^.SetVal('file-extract-ext',MkFunc(@F_FileExtractExt));
      FT^.SetVal('file-relative-path',MkFunc(@F_FileRelativePath));
      FT^.SetVal('file-expand-name',MkFunc(@F_FileExpandName));
      FT^.SetVal('file-exists',MkFunc(@F_FileExists));
      FT^.SetVal('file-unlink',MkFunc(@F_FileUnlink));
      FT^.SetVal('file-rename',MkFunc(@F_FileRename));
      FT^.SetVal('file-size',MkFunc(@F_FileSize));
      
      // Quick file read / write
      FT^.SetVal('file-get-contents',MkFunc(@F_FileGetContents));
      FT^.SetVal('file-put-contents',MkFunc(@F_FilePutContents));
      FT^.SetVal('file-force-contents',MkFunc(@F_FileForceContents));
      
      // Dir utils
      FT^.SetVal('dir-exists',MkFunc(@F_DirExists));
      FT^.SetVal('dir-create',MkFunc(@F_DirCreate));
      FT^.SetVal('dir-force' ,MkFunc(@F_DirForce ));
      FT^.SetVal('dir-remove',MkFunc(@F_DirCreate));
      FT^.SetVal('dir-list',MkFunc(@F_DirList));
      
      // Files - opening
      FT^.SetVal('f-append' ,MkFunc(@F_fappend));
      FT^.SetVal('f-reset'  ,MkFunc(@F_freset));
      FT^.SetVal('f-rewrite',MkFunc(@F_frewrite));
      FT^.SetVal('f-open'   ,MkFunc(@F_fopen));
      
      // Files - closing
      FT^.SetVal('f-eof'    ,MkFunc(@F_feof));
      FT^.SetVal('f-close'  ,MkFunc(@F_fclose));
      
      // Files - writing
      FT^.SetVal('f-write'  ,MkFunc(@F_fwrite));
      FT^.SetVal('f-writeln',MkFunc(@F_fwriteln));
      
      // Files - reading
      FT^.SetVal('f-read'   ,MkFunc(@F_fread,REF_MODIF));
      FT^.SetVal('f-readln' ,MkFunc(@F_freadln,REF_MODIF));
      FT^.SetVal('f-getln'  ,MkFunc(@F_fgetline))
   end;

Function OpenFile(Const Name:AnsiString; Const Mode:Char):LongInt;
   begin
      // Lengthen file handles array (current len will be new max idx)
      // OpenFile() returns the handle number, so we use the Result var here
      Result:=Length(FileHandles);
      SetLength(FileHandles, Result+1);
      
      // Insert file data into handle
      FileHandles[Result].Pth := ExpandFileName(Name);
      FileHandles[Result].arw := Mode;
      
      // Perform system call to open handle in desired mode
      Assign(FileHandles[Result].Fil, Name);
      Case Mode of
         'a': {$I-}  Append(FileHandles[Result].Fil); {$I+}
         'r': {$I-}   Reset(FileHandles[Result].Fil); {$I+}
         'w': {$I-} Rewrite(FileHandles[Result].Fil); {$I+}
      end;
      
      // If handle open failed, mark handle mode as unsuccessful
      If (IOResult() <> 0) then FileHandles[Result].arw := 'u'
   end;

Function F_fopen(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Mode:Char; F:LongWord;
   begin
      // If less than two args, bail out early
      If (Length(Arg^) < 2) then Exit(F_(DoReturn, Arg));
      
      // Determine mode - first case, arg1 is string
      If (Arg^[1]^.Typ = VT_STR) then begin
         If (Length(Arg^[1]^.Str^)>0) then begin
            Mode:=LowerCase(Arg^[1]^.Str^[1]);
            If (Not (Mode in ['r','w','a'])) then Mode:='r'
         end else Mode:='r'
      end else
      // Second case, arg1 is numeric
      If (Arg^[1]^.Typ >= VT_INT) and (Arg^[1]^.Typ <= VT_FLO) then begin
         Case (ValAsInt(Arg^[1])) of
              2: Mode := 'a';
              1: Mode := 'w';
            else Mode := 'r'
         end
      end else
      // Third case, arg1 is boolean
      If (Arg^[1]^.Typ = VT_BOO) then begin
         If (Arg^[1]^.Boo^) then Mode:='w' else Mode:='r';
      // Fallback to default value
      end else Mode := 'r';
      
      // Extract file path from arg0 and open file handle
      F := OpenFile(ValAsStr(Arg^[0]),Mode);
      
      // Call emptyfunc to free args
      F_(False, Arg);
      
      // Return the filehandle, or not
      If (DoReturn)
         then Exit(NewVal(VT_FIL, @FileHandles[F]))
         else Exit(NIL)
   end;

Function F_fopenMode(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Mode:Char):PValue;
   Var F:LongWord;
   begin
      // If no filepath provided (wtf?), bail out early
      If (Length(Arg^) = 0) then Exit(F_(DoReturn, Arg));
      // Create file handle with desired mode
      F := OpenFile(ValAsStr(Arg^[0]), Mode);
      // Call emptyfunc to free args
      F_(False, Arg);
      // Return the file handle (or not)
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
   begin
      Res:=True; // Set initial result to TRUE
      If (Length(Arg^)>0) then
         For C:=0 to High(Arg^) do begin
            // Check if arg is non-NIL file handle
            If (Arg^[C]^.Typ = VT_FIL) and (Arg^[C]^.Fil <> NIL) then
               // Check if file handle is in read mode
               If (Arg^[C]^.Fil^.arw = 'r') then begin
                  // Call eof on current handle
                  {$I-} Nao := eof(Arg^[C]^.Fil^.Fil); {$I+}
                  // Treat errors as eof
                  If (IOResult() <> 0) then Nao := True;
                  // Perform AND with temporary result
                  Res := Res and Nao
               end;
         // Free arg if needed
         FreeIfTemp(Arg^[C])
         end;
      If (DoReturn) then Exit(NewVal(VT_BOO,Res))
                    else Exit(NIL)
   end;

Function F_fclose(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,Num:LongWord;
   begin
      Num := 0; // Set initial closed files number to 0
      If (Length(Arg^)>0) then
         For C:=0 to High(Arg^) do begin
            // Check if argument is a non-NIL file handle
            If (Arg^[C]^.Typ = VT_FIL) and (Arg^[C]^.Fil <> NIL) then
               // Check if file handle is currently open
               If (Arg^[C]^.Fil^.arw in ['a','r','w']) then begin
                  // Attempt to close file
                  {$I-} Close(Arg^[C]^.Fil^.Fil); {$I+}
                  // Mark file handle as closed
                  PFileHandle(Arg^[C]^.Ptr)^.arw := 'c';
                  // If no errors during closing, increased closed file counter
                  If (IOResult() = 0) then Num += 1
               end;
         // Free arg if needed
         FreeIfTemp(Arg^[C])
         end;
      If (DoReturn) then Exit(NewVal(VT_INT, Num))
                    else Exit(NIL)
   end;

Function F_readfile(Const DoReturn:Boolean; Const Arg:PArrPVal; Const DoTrim:Boolean):PValue;
   Var C, P : LongWord; H:PFileHandle;
   begin
      // If no arguments, bail out early
      If (Length(Arg^)=0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
      
      // If arg0 is not a file handle (or an invalid one), bail out
      If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
      
      // Get file handle from arg0 and free arg0 if needed
      H := PFileHandle(Arg^[0]^.Ptr);
      FreeIfTemp(Arg^[0]);
      
      // Go through rest of args and fill them with values
      For C:=1 to High(Arg^) do begin 
         P := FillBuffer(H^.Fil, @H^.Buf, DoTrim);
         FillVar(Arg^[C], @H^.Buf, P);
         FreeIfTemp(Arg^[C])
      end;
      If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end;

Function F_fread(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_readfile(DoReturn, Arg, TRIM_YES)) end;

Function F_freadln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_readfile(DoReturn, Arg, TRIM_NO)) end;

Function F_fgetline(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var H:PFileHandle; 
   begin
      // If no arguments, bail out early
      If (Length(Arg^) = 0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
      
      // If arg0 is not a file handle (or an invalid one), bail out
      If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
      
      // Get file handle from arg0 and call emptyfunc to free args
      H := PFileHandle(Arg^[0]^.Ptr); F_(False, Arg);
      
      // If filehandle buffer is empty, read from file
      If (H^.Buf = '') then {$I-} Readln(H^.Fil, H^.Buf); {$I+}
      
      // If error during reading, clear buffer
      If (IOResult()<>0) then H^.Buf := '';
      
      // Insert buffer contents into return value and clear buffer
      If (DoReturn) then Result:=NewVal(VT_STR, H^.Buf) else Result:=NIL;
      H^.Buf := ''
   end;

Function F_fwrite(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   // If no arguments, bail out early
   If (Length(Arg^) = 0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   
   // If arg0 is not a file handle (or an invalid one), bail out
   If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
   
   // Write arguments to file handle
   WriteFile(Arg^[0]^.Fil^.Fil, Arg, {Ignore first arg} 1);
   
   // Free args and return value
   F_(False, Arg);
   If (DoReturn) then Exit(EmptyVal(VT_STR)) else Exit(NIL)
   end;
   
Function F_fwriteln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   // If no arguments, bail out early
   If (Length(Arg^) = 0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   
   // If arg0 is not a file handle (or an invalid one), bail out
   If (Arg^[0]^.Typ <> VT_FIL) or (Arg^[0]^.Ptr = NIL) then Exit(F_(DoReturn, Arg));
   
   // Write arguments to file handle, followed by newline
   WriteFile(Arg^[0]^.Fil^.Fil, Arg, {Ignore first arg} 1);
   {$I-} Writeln(Arg^[0]^.Fil^.Fil); {$I+}
   
   // Free args and return value
   F_(False, Arg);
   If (DoReturn) then Exit(EmptyVal(VT_STR)) else Exit(NIL)
   end;

Type TUtilStringFunc = Function(Const Str:AnsiString):AnsiString;
Type TUtilBoolFunc = Function(Const Str:AnsiString):Boolean;

Function MyExtractName(Const Str:AnsiString):AnsiString;
   Var L:LongInt;
   begin
      L := Length(Str);
      If(L = 0) then Exit('');
      If(Str[L] in ['/','\'])
         then Result := ExtractFileName(Copy(Str,1,L))
         else Result := ExtractFileName(Str)
   end;

Function MyExtractFilePath(Const Str:AnsiString):AnsiString;
   begin
      Result := ExtractFilePath(Str)
   end;

Function MyExtractFileExt(Const Str:AnsiString):AnsiString;
   begin
      Result := ExtractFileExt(Str)
   end;

Function MyExpandFileName(Const Str:AnsiString):AnsiString;
   begin
      Result := ExpandFileName(Str)
   end;

Function MyFileExists(Const Str:AnsiString):Boolean;
   begin
      Result := FileExists(Str)
   end;

Function MyDeleteFile(Const Str:AnsiString):Boolean;
   begin
      Result := DeleteFile(Str)
   end;

Function MyDirectoryExists(Const Str:AnsiString):Boolean;
   begin
      Result := DirectoryExists(Str)
   end;

Function MyCreateDir(Const Str:AnsiString):Boolean;
   begin
      Result := CreateDir(Str)
   end;

Function MyForceDirectories(Const Str:AnsiString):Boolean;
   begin
      Result := ForceDirectories(Str)
   end;

Function MyRemoveDir(Const Str:AnsiString):Boolean;
   begin
      Result := RemoveDir(Str)
   end;

Function F_FileUtils(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TUtilStringFunc):PValue; 
   begin
      // No retval expected means nothing to do
      If (Not DoReturn) then Exit(F_(False,Arg));
      // No arguments provided means return empty string
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
      
      // If arg0 is UTF, return type should be UTF, too
      If (Arg^[0]^.Typ = VT_UTF)
         then Result := NewVal(VT_UTF,Func(ValAsStr(Arg^[0])))
         else Result := NewVal(VT_STR,Func(ValAsStr(Arg^[0])));
      F_(False, Arg) // Free args before leaving
   end;

Function F_FileExtractName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @MyExtractName)) end;

Function F_FileExtractPath(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @MyExtractFilePath)) end;

Function F_FileExtractExt(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @MyExtractFileExt)) end;

Function F_FileExpandName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_FileUtils(DoReturn, Arg, @MyExpandFileName)) end;

Function F_FileRelativePath(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue; 
   Var RelativeTo:AnsiString;
   begin
      // No retval expected means nothing to do
      If (Not DoReturn) then Exit(F_(False,Arg));
      // No arguments provided means return empty string
      If (Length(Arg^) = 0) then Exit(EmptyVal(VT_STR));
      
      // If second arg is set, use it; else, default to current dir
      If (Length(Arg^) >= 2)
         then RelativeTo := ValAsStr(Arg^[1])
         else RelativeTo := GetCurrentDir();
      
      // If arg0 type is UTF, result value also should be UTF
      If (Arg^[0]^.Typ = VT_UTF)
         then Result := NewVal(VT_UTF,ExtractRelativePath(RelativeTo,ValAsStr(Arg^[0])))
         else Result := NewVal(VT_STR,ExtractRelativePath(RelativeTo,ValAsStr(Arg^[0])));
      F_(False, Arg) // Free args before leaving
   end;

Function F_FileRename(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Res:Boolean;
   begin
      Res := False; // Initial result = false
      
      // If sufficient number of args, attemp to rename
      If (Length(Arg^) >= 2) then Res:=RenameFile(ValAsStr(Arg^[0]),ValAsStr(Arg^[1]));
      
      F_(False, Arg); // Free args before returning value
      If (DoReturn)
         then Exit(NewVal(VT_BOO, Res))
         else Exit(NIL)
   end;

Function F_DirAction(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TUtilBoolFunc):PValue; Inline;
   Var C,Num:LongWord;
   begin
      Num := 0; // Initial result is 0
      
      If (Length(Arg^)>0) then
         For C:=0 to High(Arg^) do begin                      // Go through all args
            If (Func(ValAsStr(Arg^[0]))) then Num += 1;       // Perform action and increase counter on success
            FreeIfTemp(Arg^[C]) // Free arg if required
         end;
      
      If (DoReturn)
         then Exit(NewVal(VT_BOO, (Num > 0) and (Num = Length(Arg^)))) // Return success if all succeeded
         else Exit(NIL)
   end;

Function F_FileExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @MyFileExists)) end;
   
Function F_FileUnlink(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @MyDeleteFile)) end;

Function F_DirExists(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @MyDirectoryExists)) end;

Function F_DirCreate(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @MyCreateDir)) end;
   
Function F_DirForce(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @MyForceDirectories)) end;

Function F_DirRemove(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_DirAction(DoReturn, Arg, @MyRemoveDir)) end;

Function F_FileGetContents(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var F:File of Char; Ch:Char;
   begin
      // Bail out if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no arg provided, return nilval
      If (Length(Arg^) = 0) then Exit(NilVal());
      
      // Assign and open file
      Assign(F,ValAsStr(Arg^[0]));
      {$I-} Reset(F,1); {$I+}
      
      // If opened successfully, read file contents
      If (IOResult() = 0) then begin
         Result := EmptyVal(VT_STR);
         While (Not Eof(F)) do begin
            Read(F,Ch);
            Result^.Str^ += Ch
         end;
         Close(F)
      end else Result:=NilVal(); // Failed to open file, return nilval
      
      F_(False,Arg) // Free args before leaving
   end;

Const ForceDirs_YES = True; ForceDirs_NO = False; 

Function F_FileWriteContents(Const DoReturn:Boolean;Const Arg:PArrPVal;Const ForceDirs:Boolean):PValue;
   Var FilePath, DirPath, Content : AnsiString; F:File of Text; Written:Int64;
   begin
      // Not enough args, bail out early
      If (Length(Arg^) < 2) then begin
         F_(False, Arg);
         If (DoReturn) then Exit(NewVal(VT_INT, -1));
         Exit(NIL)
      end;
      
      // Get filepath from args
      FilePath := ValAsStr(Arg^[0]);
      DirPath := ExtractFileDir(FilePath);
      
      Content := ValAsStr(Arg^[1]);
      F_(False, Arg); // Free args, no longer need them around
      
      If(DirPath <> '') and (Not DirectoryExists(DirPath)) then
         // If ForceDirs is on, attempt to create directories
         If (Not ForceDirs) or (Not ForceDirectories(DirPath)) then begin
            // Fail because directory doesn't exist and failed to create it
            If (DoReturn) then Exit(NewVal(VT_INT, -1));
            Exit(NIL)
         end;
      
      // Create file, return -1 if unsuccessful
      Assign(F, FilePath);
      {$I-} Rewrite(F, 1); {$I+}
      If (IOResult() <> 0) then begin
         If (DoReturn) then Exit(NewVal(VT_INT, -1));
         Exit(NIL)
      end;
      
      // Write to file and close it; return -1 on error
      Written := -1; 
      {$I-} BlockWrite(F, Content[1], Length(Content), Written); Close(F); {$I+}
      If (IOResult() <> 0) then begin
         If (DoReturn) then Exit(NewVal(VT_INT, -1));
         Exit(NIL)
      end;
      
      // All good! Return number of bytes written (or NIL)
      If (DoReturn) then Exit(NewVal(VT_INT, Written));
      Exit(NIL)
   end;

Function F_FilePutContents(Const DoReturn:Boolean;Const Arg:PArrPVal):PValue;
   begin Exit(F_FileWriteContents(DoReturn, Arg, ForceDirs_NO)) end;

Function F_FileForceContents(Const DoReturn:Boolean;Const Arg:PArrPVal):PValue;
   begin Exit(F_FileWriteContents(DoReturn, Arg, ForceDirs_YES)) end;

Function F_FileSize(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Sr:TSearchRec;
   begin
      // If no retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, signal error
      If (Length(Arg^) = 0) then Exit(NewVal(VT_INT,-1));
      
      // Search for file in FS
      If (FindFirst(ValAsStr(Arg^[0]),(faReadOnly or faHidden),Sr) = 0)
         then Result := NewVal(VT_INT,Sr.Size) // Success, create result value
         else Result := NewVal(VT_INT,-1);     // Failed, use -1 to indicate error
      
      FindClose(Sr); // Close search handle (cause, you know, memory leaks are bad)
      F_(False,Arg)  // Free args before leaving
   end;

{$IFDEF WINDOWS}
   {$DEFINE DirDelim := '\'}
{$ELSE}
{$IFDEF LINUX}
   {$DEFINE DirDelim := '/'}
{$ENDIF}{$ENDIF}

Type
   TDirEntry = record
      Path : AnsiString;
      IsDir : Boolean
   end;
   
   PDirEntryArr = ^TDirEntryArr;
   TDirEntryArr = Array of TDirEntry;

   TListSwitch = set of (LS_RECURSE, LS_SLASH, LS_SORT, LS_GROUP);

Const LIST_RESIZE_STEP = 32;

Procedure ListDir(Const Dir,Pat:AnsiString;Const Attr:LongInt;Const Swi:TListSwitch;Const Arr:PDirEntryArr;Var Idx:LongInt);
   Var S:TSearchRec; Len:LongInt;
   begin
      Len := Length(Arr^); // Remember length
      If (FindFirst(Dir+Pat,Attr,S) = 0) then // Start search
         Repeat
            // Omit '.' and '..'
            If (S.Name = '.') or (S.Name = '..') then Continue; 
            
            // Resize array if needed
            If (Idx = Len) then begin
               Len += LIST_RESIZE_STEP;
               SetLength(Arr^, Len)
            end;
            
            // Save entry and advance array index
            Arr^[Idx].Path := Dir + S.Name;
            Arr^[Idx].IsDir := ((S.Attr and faDirectory) = faDirectory);
            Idx += 1;
            
            // If entry is a directory and recurse-switch is active, list subdir
            If (Arr^[Idx-1].isDir) and (LS_RECURSE in Swi) then begin 
               ListDir(Dir+S.Name+DirDelim, Pat, Attr, Swi, Arr, Idx);
               Len := Length(Arr^) // Save new array length (could be changed by subdir listing)
            end
         Until (FindNext(S) <> 0); // Continue until no more search entries found
      FindClose(S) // Close search
   end;

Function CompareDirEntries_NoGroup(Const A,B:TDirEntry):Boolean;
   begin
      Exit(A.Path > B.Path)
   end;

Function CompareDirEntries_DoGroup(Const A,B:TDirEntry):Boolean;
   begin
      If(Not A.IsDir) and (B.IsDir) then Exit(True);
      If(A.IsDir) and (Not B.IsDir) then Exit(False);
      Exit(A.Path > B.Path)
   end;

Type TDirEntryCompareFunc = Function(Const A,B:TDirEntry):Boolean;

Procedure Quicksort(Var Arr:TDirEntryArr;Const Min,Max:LongInt;Const Cmpr:TDirEntryCompareFunc);
   Var Piv,Pos:LongInt; PivVal : TDirEntry;
   begin
      Pos := Min; Piv := Max; PivVal := Arr[Piv];
      While (Pos < Piv) do
         If (Cmpr(Arr[Pos], PivVal)) then begin
            Arr[Piv] := Arr[Pos];
            Piv -= 1;
            Arr[Pos] := Arr[Piv];
            Arr[Piv] := PivVal
         end else Pos += 1;
      If ((Pos - Min) > 1) then Quicksort(Arr,Min,Pos-1,Cmpr);
      If ((Max - Pos) > 1) then Quicksort(Arr,Pos+1,Max,Cmpr)
   end;

Function F_DirList(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Dir,Pat,sA:AnsiString; Attr, C, Idx : LongInt; Swi:TListSwitch;
       ListArr : TDirEntryArr;
   begin
      // No retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return nilval
      If (Length(Arg^) = 0) then Exit(NilVal());
      
      // Set up default attributes
      Pat := '*'; Attr := faReadOnly; Swi := [];
      
      If (Length(Arg^) > 1) then begin
         Pat := ValAsStr(Arg^[1]); // Read pattern from arg1
       
         If (Length(Arg^) > 2) then begin
            sA := ValAsStr(Arg^[2]); // Read switches from arg2
            For C:=1 to Length(sA) do Case(sA[C]) of
               'd': Attr := Attr or faDirectory;
               'w': Attr := Attr and (Not faReadOnly);
               'h': Attr := Attr or faHidden;
               'r': Include(Swi,LS_RECURSE);
               's': Include(Swi,LS_SORT );
               '/': Include(Swi,LS_SLASH);
               'g': Include(Swi,LS_GROUP);
      end end end;
      
      // Get dir from arg0 and make sure the DirDelim is at path end
      Dir := ValAsStr(Arg^[0]);
      If (Length(Dir)>0) then
         If (Dir[Length(Dir)]<>DirDelim) then Dir += DirDelim;
      
      // List the directory and sort if required
      Idx := 0;
      ListDir(Dir,Pat,Attr,Swi,@ListArr,Idx);
      If(LS_SORT in Swi) and (Idx > 0) then
         If(LS_GROUP in Swi)
            then Quicksort(ListArr, 0, Idx-1, @CompareDirEntries_DoGroup)
            else Quicksort(ListArr, 0, Idx-1, @CompareDirEntries_NoGroup);
      
      // If Slash-switch is active, add / at end of every dir
      If(LS_SLASH in Swi) then
         For C:=0 to (Idx - 1) do
            If(ListArr[C].IsDir) then ListArr[C].Path += DirDelim;
      
      // Create result value
      Result := EmptyVal(VT_ARR);
      For C:=0 to (Idx - 1) do
         Result^.Arr^.SetVal(C,NewVal(VT_STR, ListArr[C].Path))
   end;

{$UNDEF DirDelim}

end.
