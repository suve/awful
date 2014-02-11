unit functions_stdio; 

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_Write(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Writeln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_Read(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Readln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GetChar(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_stdin_BufferFlush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_stdin_BufferClear(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_stdin_BufferPush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses SysUtils, Globals, Functions_CGI, EmptyFunc;

{$MACRO ON} {$DEFINE TRIM_YES := TRUE} {$DEFINE TRIM_NO := FALSE}

Procedure Register(Const FT:PFunTrie);
   begin
   // stdout
   FT^.SetVal('write', @F_Write);
   FT^.SetVal('writeln', @F_Writeln);
   // stdin
   FT^.SetVal('read', @F_Read);
   FT^.SetVal('readln', @F_Readln);
   FT^.SetVal('getchar', @F_GetChar);
   FT^.SetVal('stdin-flush', @F_stdin_BufferFlush);
   FT^.SetVal('stdin-clear', @F_stdin_BufferClear);
   FT^.SetVal('stdin-push', @F_stdin_BufferPush)
   end;


{$IFDEF CGI} Var WasOutput : Boolean = False; {$ENDIF}

Function CapitalizeHeader(Hdr:TStr):TStr;
   Var C:LongWord;
   begin
   If (Length(Hdr) = 0) then Exit('');
   Hdr[1]:=UpCase(Hdr[1]); C:=2;
   While (C < Length(Hdr)) do 
      If (Hdr[C]<>'-') then C += 1
         else begin
         Hdr[C+1]:=UpCase(Hdr[C+1]); C += 2
         end;
   Exit(Hdr)
   end;

Function F_Write(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   {$IFDEF CGI}
   If (Not WasOutput) then begin
      If (Length(Headers)>0) or (Length(Cookies)>0) then begin
         If (Length(Headers)>0) then
            For C:=Low(Headers) to High(Headers) do
                Writeln(StdOut, CapitalizeHeader(Headers[C].Key),': ',Headers[C].Val);
         If (Length(Cookies)>0) then
            For C:=Low(Cookies) to High(Cookies) do
                Writeln(StdOut, 'Set-Cookie: ',EncodeURL(Cookies[C].Name),'=',EncodeURL(Cookies[C].Value));
         Writeln(StdOut)
         end;
      WasOutput := True
      end;
   {$ENDIF}
   If (Length(Arg^) > 0) then
      For C:=Low(Arg^) to High(Arg^) do begin
          Case Arg^[C]^.Typ of
             VT_NIL: Write(StdOut, '{NIL}');
             VT_NEW: Write(StdOut, '{NEW}');
             VT_PTR: Write(StdOut, '{PTR}');
             VT_INT: Write(StdOut, PQInt(Arg^[C]^.Ptr)^);
             VT_HEX: Write(StdOut, Values.HexToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_OCT: Write(StdOut, Values.OctToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_BIN: Write(StdOut, Values.BinToStr(PQInt(Arg^[C]^.Ptr)^));
             VT_FLO: Write(StdOut, Values.FloatToStr(PFloat(Arg^[C]^.Ptr)^));
             VT_BOO: Write(StdOut, PBoolean(Arg^[C]^.Ptr)^);
             VT_STR: Write(StdOut, PAnsiString(Arg^[C]^.Ptr)^);
             VT_UTF: Write(StdOut, '{UTF8}');
             VT_ARR: Write(StdOut, 'array(',PArray(Arg^[C]^.Ptr)^.Count,')');
             VT_DIC: Write(StdOut, 'dict(',PDict(Arg^[C]^.Ptr)^.Count,')');
             VT_FIL: Write(StdOut, 'file(',PFileVal(Arg^[C]^.Ptr)^.Pth,')');
             else Write(StdOut, '(',Arg^[C]^.Typ,')')
             end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then Exit(NewVal(VT_STR,'')) else Exit(NIL)
   end;

Function F_Writeln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var R:PValue;
   begin
   R:=F_Write(DoReturn, Arg);
   Writeln(StdOut);
   Exit(R)
   end;

// stdIN buffer.
Var stdinBuffer : AnsiString = '';

Function FillBuffer(Var TheFile:Text; Buff:PStr; Trim:Boolean):LongWord;
   Var P:LongWord;
   begin
   While (Length(Buff^)=0) do begin
      Read(TheFile, Buff^); If (eoln(TheFile)) then Readln(TheFile);
      If (Trim) then Buff^:=TrimLeft(Buff^)
      end;
   If (Not Trim) then Exit(Length(Buff^));
   P:=Pos(#32,Buff^); 
   If (P > 0) then Exit(P-1) else Exit(Length(Buff^))
   end;

Procedure FillVar(V:PValue; Buff : PStr; Pos : LongWord);
   begin
   Case (V^.Typ) of
      VT_BOO: PBool(V^.Ptr)^ := SysUtils.StrToBoolDef(Buff^[1..Pos], False);
      VT_BIN: PQInt(V^.Ptr)^ := Values.StrToBin(Buff^[1..Pos]);
      VT_OCT: PQInt(V^.Ptr)^ := Values.StrToOct(Buff^[1..Pos]);
      VT_INT: PQInt(V^.Ptr)^ := Values.StrToInt(Buff^[1..Pos]);
      VT_HEX: PQInt(V^.Ptr)^ := Values.StrToHex(Buff^[1..Pos]);
      VT_FLO: PFloat(V^.Ptr)^ := Values.StrToReal(Buff^[1..Pos]);
      VT_STR: PStr(V^.Ptr)^ := Buff^[1..Pos]
      end;
   Delete(Buff^, 1, Pos+1)
   end;

Function F_stdio(DoTrim:Boolean; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C, P : LongWord; 
   begin
   If (Length(Arg^)=0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   For C:=Low(Arg^) to High(Arg^) do begin 
      P := FillBuffer(Input, @stdinBuffer, DoTrim);
      FillVar(Arg^[C], @stdinBuffer, P);
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end;

Function F_read(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_stdio(TRIM_YES, DoReturn, Arg)) end;

Function F_readln(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_stdio(TRIM_NO, DoReturn, Arg)) end;

Function F_getchar(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Chr:Char;
   begin
   If (Length(Arg^)>0) then F_(False, Arg);
   FillBuffer(Input, @stdinBuffer, TRIM_NO);
   Chr:=stdinBuffer[1]; Delete(stdinBuffer, 1, 1);
   If (DoReturn) then Exit(NewVal(VT_STR, Chr)) else Exit(NIL)
   end;

Function F_stdin_BufferFlush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var V:PValue;
   begin
   If (Length(Arg^)>0) then F_(False, Arg);
   If (DoReturn) then V:=NewVal(VT_STR, stdinBuffer) else V:=NIL;
   stdinBuffer := ''; Exit(V)
   end;

Function F_stdin_BufferClear(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var V:PValue;
   begin
   If (Length(Arg^)>0) then F_(False, Arg);
   If (DoReturn) then V:=NewVal(VT_INT, Length(stdinBuffer)) else V:=NIL;
   stdinBuffer := ''; Exit(V)
   end;

Function F_stdin_BufferPush(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do begin
          If (Length(stdinBuffer) > 0) and (stdinBuffer[Length(stdinBuffer)]<>#32) then stdinBuffer += #32;
          Case Arg^[C]^.Typ of
             VT_BOO: stdinBuffer += SysUtils.BoolToStr(PBool(Arg^[C]^.Ptr)^);
             VT_BIN: stdinBuffer += Values.BinToStr(PQInt(Arg^[C]^.Ptr)^);
             VT_OCT: stdinBuffer += Values.OctToStr(PQInt(Arg^[C]^.Ptr)^);
             VT_INT: stdinBuffer += Values.IntToStr(PQInt(Arg^[C]^.Ptr)^);
             VT_HEX: stdinBuffer += Values.HexToStr(PQInt(Arg^[C]^.Ptr)^);
             VT_FLO: stdinBuffer += Values.FloatToStr(PFloat(Arg^[C]^.Ptr)^){RealToStr(PFloat(Arg^[C]^.Ptr)^, 5)};
             VT_STR: stdinBuffer += PStr(Arg^[C]^.Ptr)^;
             end;
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
          end;
   If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end;

(*
Function F_fopen(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Mode:Char; PS:PStr; S:TStr; I:QInt; V:PValue; F:PFileVal;
   begin
   If (Length(Arg^)<2) then Exit(F_(DoReturn, Arg^));
   If (Length(Arg^)>2) then F_(False, Arg^[2..High(Arg^)]);
   // Determine mode
   If (Arg^[1]^.Typ = VT_STR) then begin
      PS := PStr(Arg^[1]^.Ptr);
      If (Length(PS^)>0) then Mode:=PS^[1] else Mode:='r'
      end else
   If (Arg^[1]^.Typ >= VT_INT) and (Arg^[1]^.Typ <= VT_FLO) then begin
      If (Arg^[1]^.Typ <> VT_FLO) then I:=PQInt(Arg^[1]^.Ptr)^
                                 else I:=Trunc(PDouble(Arg^[1]^.Ptr)^);
      Case (I) of
         2: Mode := 'w';
         1: Mode := 'a';
         else Mode := 'r'
      end end else begin
      V:=ValToBoo(Arg^[1]);
      If (PBool(V^.Ptr)^) then Mode:='w' else Mode:='r';
      FreeVal(V)
      end;
   // Determine file path
   If (Arg^[0]^.Typ = VT_STR) then S:=PStr(Arg^[0]^.Ptr)^
      else begin
      V:=ValToStr(Arg^[0]); S:=PStr(V^.Ptr)^; FreeVal(V)
      end;
   // Free args
   If (Arg^[1]^.Lev >= CurLev) then FreeVal(Arg^[1]);
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   // Create value and open file
   V:=EmptyVal(VT_FIL); F:=PFileVal(V^.Ptr);
   F^.Pth := ExpandFileName(S); F^.arw := Mode;
   {$I-} Assign(F^.Fil, S);
   Case Mode of
      'a': Append(F^.Fil);
      'r': Reset(F^.Fil);
      'w': Rewrite(F^.Fil)
      end; {$I+}
   If (IOResult <> 0) then F^.arw := 'u';
   If (DoReturn) then Exit(V) else FreeVal(V);
   Exit(NIL)
   end;
*)

end.
