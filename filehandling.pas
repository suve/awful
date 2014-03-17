unit fileHandling;

interface
   uses Values;

const TRIM_YES = True; TRIM_NO = False;

Type PFileHandle = ^TFileHandle;
     TFileHandle = record
        Fil : System.Text;
        arw : Char;
        Pth : AnsiString;
        Buf : AnsiString
        end;

Function  FillBuffer(Var TheFile:Text; Const Buff:PStr; Const Trim:Boolean):LongWord;
Procedure FillVar(Const V:PValue; Const Buff : PStr; Const Pos : LongWord);
Procedure WriteFile(Var F:Text; Const Arg:PArrPVal; Idx:LongWord);

implementation
   uses SysUtils, Convert, Values_Typecast;

Function FillBuffer(Var TheFile:Text; Const Buff:PStr; Const Trim:Boolean):LongWord;
   Var P:LongWord;
   begin
   While (Length(Buff^)=0) do begin
      {$I-} Read(TheFile, Buff^); If (eoln(TheFile)) then Readln(TheFile); {$I+}
      If (IOResult<>0) then Buff^:='';
      If (Trim) then Buff^:=TrimLeft(Buff^)
      end;
   If (Not Trim) then Exit(Length(Buff^));
   P:=Pos(#32,Buff^); 
   If (P > 0) then Exit(P-1) else Exit(Length(Buff^))
   end;

Procedure FillVar(Const V:PValue; Const Buff : PStr; Const Pos : LongWord);
   begin
   Case (V^.Typ) of
      VT_BOO: PBool(V^.Ptr)^ := SysUtils.StrToBoolDef(Buff^[1..Pos], False);
      VT_BIN: PQInt(V^.Ptr)^ := Convert.StrToBin(Buff^[1..Pos]);
      VT_OCT: PQInt(V^.Ptr)^ := Convert.StrToOct(Buff^[1..Pos]);
      VT_INT: PQInt(V^.Ptr)^ := Convert.StrToInt(Buff^[1..Pos]);
      VT_HEX: PQInt(V^.Ptr)^ := Convert.StrToHex(Buff^[1..Pos]);
      VT_FLO: PFloat(V^.Ptr)^ := Convert.StrToReal(Buff^[1..Pos]);
      VT_STR: PStr(V^.Ptr)^ := Buff^[1..Pos];
      VT_UTF: PUTF(V^.Ptr)^.SetTo(Buff^[1..Pos]);
      end;
   Delete(Buff^, 1, Pos+1)
   end;

Procedure WriteFile(Var F:Text; Const Arg:PArrPVal; Idx:LongWord);
   begin
   If (Length(Arg^) > 0) then
      For Idx:=Idx to High(Arg^) do begin
         Case Arg^[Idx]^.Typ of {$I-}
            VT_NIL: Write(F, '{NIL}');
            VT_NEW: Write(F, '{NEW}');
            VT_PTR: Write(F, '{PTR}');
            VT_INT: Write(F, PQInt(Arg^[Idx]^.Ptr)^);
            VT_HEX: Write(F, Convert.HexToStr(PQInt(Arg^[Idx]^.Ptr)^));
            VT_OCT: Write(F, Convert.OctToStr(PQInt(Arg^[Idx]^.Ptr)^));
            VT_BIN: Write(F, Convert.BinToStr(PQInt(Arg^[Idx]^.Ptr)^));
            VT_FLO: Write(F, Convert.FloatToStr(PFloat(Arg^[Idx]^.Ptr)^));
            VT_BOO: Write(F, PBoolean(Arg^[Idx]^.Ptr)^);
            VT_STR: Write(F, PStr(Arg^[Idx]^.Ptr)^);
            VT_UTF: PUTF(Arg^[Idx]^.Ptr)^.Print(F);
            VT_ARR: Write(F, 'array(',PArray(Arg^[Idx]^.Ptr)^.Count,')');
            VT_DIC: Write(F, 'dict(',PDict(Arg^[Idx]^.Ptr)^.Count,')');
            VT_FIL: Write(F, 'file(',PFileHandle(Arg^[Idx]^.Ptr)^.Pth,')');
            else Write(F, '(',Arg^[Idx]^.Typ,')') {$I+}
            end;
         If (Arg^[Idx]^.Lev >= CurLev) then FreeVal(Arg^[Idx])
   end end;

end.
