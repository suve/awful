unit fileHandling;

{$INCLUDE defines.inc}

interface
   uses Values;

const
   TRIM_YES = True; TRIM_NO = False;

Function  FillBuffer(Var TheFile:Text; Const Buff:PStr; Const Trim:Boolean):LongWord;
Procedure FillVar(Const V:PValue; Const Buff : PStr; Const Pos : LongWord);
Procedure WriteFile(Var F:Text; Const Arg:PArrPVal; Idx:LongWord);


implementation
   uses SysUtils, Convert;

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
      If (P > 0)
         then Exit(P-1)
         else Exit(Length(Buff^))
   end;

Procedure FillVar(Const V:PValue; Const Buff : PStr; Const Pos : LongWord);
   begin
      Case (V^.Typ) of
         VT_BOO:
            V^.Boo^ := SysUtils.StrToBoolDef(Buff^[1..Pos], False);
         
         VT_BIN:
            V^.Int^ := Convert.StrToBin(Buff^[1..Pos]);
         
         VT_OCT:
            V^.Int^ := Convert.StrToOct(Buff^[1..Pos]);
         
         VT_INT:
            V^.Int^ := Convert.StrToInt(Buff^[1..Pos]);
         
         VT_HEX:
            V^.Int^ := Convert.StrToHex(Buff^[1..Pos]);
         
         VT_FLO:
            V^.Flo^ := Convert.StrToReal(Buff^[1..Pos]);
         
         VT_STR:
            V^.Str^ := Buff^[1..Pos];
         
         VT_UTF:
            V^.Utf^.SetTo(Buff^[1..Pos]);
      end;
      Delete(Buff^, 1, Pos+1)
   end;

Procedure WriteFile(Var F:Text; Const Arg:PArrPVal; Idx:LongWord);
   begin
      If (Length(Arg^) > 0) then
         For Idx:=Idx to High(Arg^) do begin
            Case Arg^[Idx]^.Typ of {$I-}
               
               VT_NIL:
                  Write(F, '{NIL}');
               
               VT_NEW:
                  Write(F, '{NEW}');
               
               VT_PTR:
                  Write(F, '{PTR}');
               
               VT_INT:
                  Write(F, Arg^[Idx]^.Int^);
               
               VT_HEX:
                  Write(F, Convert.HexToStr(Arg^[Idx]^.Int^));
               
               VT_OCT:
                  Write(F, Convert.OctToStr(Arg^[Idx]^.Int^));
               
               VT_BIN:
                  Write(F, Convert.BinToStr(Arg^[Idx]^.Int^));
               
               VT_FLO:
                  Write(F, Convert.FloatToStr(Arg^[Idx]^.Flo^));
               
               VT_BOO:
                  Write(F, PBoolean(Arg^[Idx]^.Ptr)^);
               
               VT_STR:
                  Write(F, PStr(Arg^[Idx]^.Ptr)^);
               
               VT_UTF:
                  PUTF(Arg^[Idx]^.Ptr)^.Print(F);
               
               VT_ARR:
                  Write(F, 'array(',Arg^[Idx]^.Arr^.Count,')');
               
               VT_DIC:
                  Write(F, 'dict(',Arg^[Idx]^.Dic^.Count,')');
               
               VT_FIL:
                  Write(F, 'file(',Arg^[Idx]^.Fil^.Pth,')');
               
               else
                  Write(F, '{',Arg^[Idx]^.Typ,'}') {$I+}
            end;
            If (Arg^[Idx]^.Lev >= CurLev) then FreeVal(Arg^[Idx])
   end end;

end.
