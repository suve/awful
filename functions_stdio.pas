unit functions_stdio; 

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

{$IFDEF CGI}
Procedure CGI_Write(Const Text:AnsiString);
Procedure CGI_Writeln(Const Text:AnsiString);
{$ENDIF}

Function F_Write(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Writeln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Read(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Readln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GetChar(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_stdin_BufferFlush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_stdin_BufferClear(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_stdin_BufferPush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses SysUtils, Convert, 
        {$IFDEF CGI} Encodings, Globals, {$ENDIF}
        EmptyFunc, FileHandling;

Procedure Register(Const FT:PFunTrie);
   begin
      // stdout
      FT^.SetVal('write', MkFunc(@F_Write));
      FT^.SetVal('writeln', MkFunc(@F_Writeln));
      // stdin
      FT^.SetVal('read', MkFunc(@F_Read,REF_MODIF));
      FT^.SetVal('readln', MkFunc(@F_Readln,REF_MODIF));
      FT^.SetVal('getchar', MkFunc(@F_GetChar));
      FT^.SetVal('stdin-flush', MkFunc(@F_stdin_BufferFlush));
      FT^.SetVal('stdin-clear', MkFunc(@F_stdin_BufferClear));
      FT^.SetVal('stdin-push', MkFunc(@F_stdin_BufferPush))
   end;

{$IFDEF CGI}
Var WasOutput : Boolean = False;

Function CapitalizeHeader(Const Hdr:TStr):TStr;
   Var C,L:LongWord;
   begin
      L := Length(Hdr);
      If (L = 0) then Exit('');
      
      SetLength(Result, L);            // Set result length appropriately
      Result[1]:=UpCase(Hdr[1]); C:=2; // Capitalise first letter
      While (C <= L) do begin
         Result[C] := Hdr[C];          // Copy character
         If (Hdr[C] = '-') and (C < L) then begin 
            Result[C+1]:=UpCase(Hdr[C+1]); C += 2  // Copy next char capitalised and skip it
         end else
            C += 1 
   end end;

Procedure PrintHeaders();
   Var C:LongWord;
   begin
      If (Length(Headers)>0) or (Length(Cookies)>0) then begin
         If (Length(Headers)>0) then
            For C:=Low(Headers) to High(Headers) do
                Writeln(StdOut, CapitalizeHeader(Headers[C].Key),': ',Headers[C].Val);
         If (Length(Cookies)>0) then
            For C:=Low(Cookies) to High(Cookies) do
                Writeln(StdOut, 'Set-Cookie: ',EncodeURL(Cookies[C].Name),'=',EncodeURL(Cookies[C].Value));
         Writeln(StdOut) // Empty line separates headers from content
      end;
      WasOutput := True
   end; 

Procedure CGI_Write(Const Text:AnsiString);
   begin
      If (Not WasOutput) then PrintHeaders();
      Write(StdOut, Text) 
   end;

Procedure CGI_Writeln(Const Text:AnsiString);
   begin
      If (Not WasOutput) then PrintHeaders();
      Writeln(StdOut, Text) 
   end;
{$ENDIF}

Function F_Write(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      {$IFDEF CGI} If (Not WasOutput) then PrintHeaders(); {$ENDIF}
      WriteFile(StdOut, Arg, 0);
      If (DoReturn) then Exit(EmptyVal(VT_STR)) else Exit(NIL)
   end;

Function F_Writeln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      Result:=F_Write(DoReturn, Arg);
      Writeln(StdOut)
   end;

// stdIN buffer.
Var stdinBuffer : AnsiString = '';

Function F_stdio(Const DoReturn:Boolean; Const Arg:PArrPVal; Const DoTrim:Boolean):PValue; Inline;
   Var C : LongInt; P : LongWord; 
   begin
      For C:=Low(Arg^) to High(Arg^) do begin 
         P := FillBuffer(Input, @stdinBuffer, DoTrim);
         FillVar(Arg^[C], @stdinBuffer, P);
         If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
      If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end;

Function F_read(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_stdio(DoReturn, Arg, TRIM_YES)) end;

Function F_readln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_stdio(DoReturn, Arg, TRIM_NO)) end;

Function F_getchar(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Chr:Char;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      FillBuffer(Input, @stdinBuffer, TRIM_NO);
      Chr:=stdinBuffer[1]; Delete(stdinBuffer, 1, 1);
      If (DoReturn) then Exit(NewVal(VT_STR, Chr)) else Exit(NIL)
   end;

Function F_stdin_BufferFlush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Result:=NewVal(VT_STR, stdinBuffer) else Result:=NIL;
      stdinBuffer := ''
   end;

Function F_stdin_BufferClear(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Result:=NewVal(VT_INT, Length(stdinBuffer)) else Result:=NIL;
      stdinBuffer := ''
   end;

Function F_stdin_BufferPush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
      If (Length(Arg^)>0) then
         For C:=Low(Arg^) to High(Arg^) do begin
            If (Length(stdinBuffer) > 0) and (stdinBuffer[Length(stdinBuffer)]<>#32) then stdinBuffer += #32;
            Case Arg^[C]^.Typ of
               VT_BOO: stdinBuffer += SysUtils.BoolToStr(PBool(Arg^[C]^.Ptr)^);
               VT_BIN: stdinBuffer += Convert.BinToStr(PQInt(Arg^[C]^.Ptr)^);
               VT_OCT: stdinBuffer += Convert.OctToStr(PQInt(Arg^[C]^.Ptr)^);
               VT_INT: stdinBuffer += Convert.IntToStr(PQInt(Arg^[C]^.Ptr)^);
               VT_HEX: stdinBuffer += Convert.HexToStr(PQInt(Arg^[C]^.Ptr)^);
               VT_FLO: stdinBuffer += Convert.FloatToStr(PFloat(Arg^[C]^.Ptr)^);
               VT_STR: stdinBuffer += PStr(Arg^[C]^.Ptr)^;
               VT_UTF: stdinBuffer += PUTF(Arg^[C]^.Ptr)^.ToAnsiString();
            end;
            If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
      If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end;

end.
