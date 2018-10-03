unit unicodestrings; 

{$MODE OBJFPC} {$COPERATORS ON} {$MACRO ON}

interface

Type
   TUTF8Char = String[4];
     
   PUTF8String = ^TUTF8String;
   TUTF8String = object
   Private
      Chr : Array of TUTF8Char;
      _Len : LongWord;
      _Bytes : LongWord;
        
      Function  GetChar(I:LongInt):TUTF8Char;
      Procedure SetChar(I:LongInt;Const V:TUTF8Char);
      Procedure SetLength(Const L:LongWord);
        
      Type TCharTransformFunc = Function(Const cIn:TUTF8Char):TUTF8Char;
      Procedure CaseTransform(Const Func:TCharTransformFunc);
     
   Public
      Procedure Append(Const Txt:AnsiString);
      Procedure Append(Const Txt:PUTF8String);
        
      Procedure Multiply(Const Times:LongInt);
        
      Procedure Insert(Const Txt:AnsiString;Const Idx:LongInt);
      Procedure Insert(Const Txt:PUTF8String;Idx:LongInt);
        
      Procedure SetTo(Const Txt:AnsiString);
      Procedure SetTo(Const Txt:PUTF8String);
        
      Function  SubStr(Start : LongInt; Len : LongWord = 0):PUTF8String;
      Function  Clone():PUTF8String;
        
      Procedure Delete(Start : LongInt; Len : LongWord);
      Procedure Clear();
        
      Procedure Replace(Const Patt,Repl:PUTF8String);
      Procedure Replace(Const Patt,Repl:AnsiString);
        
      Procedure Replace(Const Patt:PUTF8String;Const Repl:AnsiString);
      Procedure Replace(Const Patt:AnsiString;Const Repl:PUTF8String);
        
      Function  SearchLeft(Const Txt:PUTF8String;Const Offset:LongWord = 0):LongWord;
      Function  SearchRight(Const Txt:PUTF8String;Const Offset:LongWord = 0):LongWord;
        
      Function  SearchLeft(Const Txt:AnsiString;Const Offset:LongWord = 0):LongWord;
      Function  SearchRight(Const Txt:AnsiString;Const Offset:LongWord = 0):LongWord;
        
      Function  Equals(Const Txt:AnsiString):Boolean;
      Function  Equals(Const Txt:PUTF8String):Boolean;
        
      Function  Compare(Const Txt:AnsiString):LongInt;
      Function  Compare(Const Txt:PUTF8String):LongInt;
        
      Procedure UpperCase();
      Procedure LowerCase();
        
      Procedure Trim();
      Procedure TrimLeft();
      Procedure TrimRight();
        
      Procedure Reverse();
        
      Function  ToInt(Const Base:LongInt = 10):Int64;
      Function  ToFloat():Extended;
      Function  ToAnsiString():AnsiString;
        
      Procedure Print(Var F:Text);
      Procedure PrintHex(Var F:Text);
        
      Property Len : LongWord read _Len;
      Property Bytes : LongWord read _Bytes;
      Property Char[I : LongInt] : TUTF8Char read GetChar write SetChar; Default;
        
      Constructor Create();
      Constructor Create(Const Txt:AnsiString);
      Destructor  Destroy();
   end;

Operator := (A : AnsiString) R : PUTF8String;
Operator + (U: PUTF8String; A : AnsiString) R : PUTF8String;

implementation
   uses Math, SysUtils;

Function IsWhitespace(Const Chara:TUTF8Char):Boolean;
   begin
      Case Chara of
         #9,#10,#11,#12,#13,#32,#194#133,#194#160,
         #225#154#128,#226#128#128,#226#128#129,#226#128#130,
         #226#128#131,#226#128#132,#226#128#133,#226#128#134,
         #226#128#135,#226#128#136,#226#128#137,#226#128#138,
         #226#128#168,#226#128#169,#226#128#175,#226#129#159,
         #227#128#128:
            Exit(True);
         else
            Exit(False)
   end end;

{$DEFINE v := : Exit( }
{$DEFINE x := );      }
Function CharToUpper(Const Chara:TUTF8Char):TUTF8Char;
   begin
      Case Chara of
         {$INCLUDE unicodestrings-toupper.min.inc}
         else Exit(Chara)
   end end;

Function CharToLower(Const Chara:TUTF8Char):TUTF8Char;
   begin
      Case Chara of
         {$INCLUDE unicodestrings-tolower.min.inc}
         else Exit(Chara)
   end end;
{$UNDEF v x }

Procedure TUTF8String.SetLength(Const L:LongWord);
   Var C:LongWord;
   begin
      If (L <> 0) then
         Case CompareValue(_Len, L) of
            -1: begin
               System.SetLength(Self.Chr,L);
               For C:=_Len to (L-1) do Chr[C]:=''
            end;
            
             0: begin
               Exit
            end;
                
            +1: begin
               For C:=L to (_Len - 1) do _Bytes -= Length(Chr[C]);
               System.SetLength(Self.Chr, L)
            end
         end
         else begin
            System.SetLength(Self.Chr,0);
            _Bytes := 0
      end;
      _Len := L
   end;

Function TUTF8String.GetChar(I:LongInt):TUTF8Char;
   begin
      I-=1;
      If (I < 0) or (I >= _Len) then Exit('');
      Exit(Chr[I])
   end;
   
Procedure TUTF8String.SetChar(I:LongInt;Const V:TUTF8Char);
   begin
      I-=1;
      If (I < 0) then Exit();
      If (I >= _Len) then Self.SetLength(I+1);
      _Bytes := _Bytes - Length(Chr[I]) + Length(V);
      Chr[I]:=V;
   end;

Procedure TUTF8String.Append(Const Txt:AnsiString);
   Var P, C : LongWord; u : TUTF8Char;
   begin
      If (Length(Txt) = 0) then Exit;
      System.SetLength(Self.Chr, _Len + Length(Txt));
      C := _Len; u := '';
      
      For P:=1 to Length(Txt) do begin
         If (Txt[P] <= #$7F) then begin
            If (u <> '') then begin
               Self.Chr[C]:=u; C += 1;
               _Bytes += Length(u); u :=''
            end;
            Self.Chr[C]:=Txt[P]; C += 1; 
            _Bytes += 1 
         end else
         If (Txt[P] >= #$C0) then begin
            If (u <> '') then begin
               Self.Chr[C]:=u; C += 1;
               _Bytes += Length(u); u :=''
            end;
            u:=Txt[P]
         end else
            u += Txt[P]
      end;
      
      If (u <> '') then begin
         Self.Chr[C]:=u; C += 1;
         _Bytes += Length(u); u :=''
      end;
      
      _Len := C;
      System.SetLength(Self.Chr, _Len)
   end;

Procedure TUTF8String.Append(Const Txt:PUTF8String);
   Var P:LongWord;
   begin
      If (Txt = NIL) or (Txt^._Len = 0) then Exit;
      System.SetLength(Self.Chr, Self._Len + Txt^._Len);
      For P:=0 to (Txt^._Len - 1) do
         Self.Chr[Self._Len + P] := Txt^.Chr[P];
      Self._Len += Txt^._Len; Self._Bytes += Txt^._Bytes
   end;

Procedure TUTF8String.Multiply(Const Times:LongInt);
   Var C,OL:LongWord;
   begin
      If (Times < 2) or (Self._Len = 0) then Exit;
      OL := Self._Len; 
      Self._Len := Self._Len * Times;
      Self._Bytes := Self._Bytes * Times;
      System.SetLength(Self.Chr, Self._Len);
      For C := OL to (Self._Len - 1) do
         Self.Chr[C] := Self.Chr[C - OL]
   end;

Procedure TUTF8String.SetTo(Const Txt:AnsiString);
   Var P, C : LongWord; u : TUTF8Char;
   begin
      System.SetLength(Self.Chr, Length(Txt));
      _Len := 0; _Bytes := 0;
      If (Length(Txt) = 0) then Exit;
      C := 0; u := '';
      
      For P:=1 to Length(Txt) do begin
         If (Txt[P] <= #$7F) then begin
            If (u <> '') then begin
               Self.Chr[C]:=u; C += 1;
               _Bytes += Length(u); u :=''
            end;
            Self.Chr[C]:=Txt[P]; C += 1; 
            _Bytes += 1 
         end else
         If (Txt[P] >= #$C0) then begin
            If (u <> '') then begin
               Self.Chr[C]:=u; C += 1;
               _Bytes += Length(u); u :=''
            end;
            u:=Txt[P]
         end else
            u += Txt[P]
      end;
          
      If (u <> '') then begin
         Self.Chr[C]:=u; C += 1;
         _Bytes += Length(u); u :=''
      end;
      
      _Len := C;
      System.SetLength(Self.Chr, _Len)
   end;

Procedure TUTF8String.SetTo(Const Txt:PUTF8String);
   Var P:LongWord;
   begin
      If (Txt = NIL) or (Txt^._Len = 0) then begin
         System.SetLength(Self.Chr, 0);
         _Len := 0; _Bytes := 0; Exit()
      end;
      System.SetLength(Self.Chr, Txt^._Len);
      For P:=0 to (Txt^._Len - 1) do
         Self.Chr[P] := Txt^.Chr[P];
      Self._Len := Txt^._Len; Self._Bytes := Txt^._Bytes
   end;

Procedure TUTF8String.Insert(Const Txt:PUTF8String;Idx:LongInt);
   Var P:LongWord;
   begin
      If (Idx < 0)
         then Idx := _Len - Idx
         else If (Idx > 0) then Idx -= 1;
      
      If (Txt = NIL) or (Txt^._Len = 0) then Exit();
      
      System.SetLength(Self.Chr, Self._Len + Txt^._Len);
      For P:=(Self.Len + Txt^.Len - 1) downto (Idx + Txt^.Len) do
         Self.Chr[P] := Self.Chr[P - Txt^.Len];
      For P:=Idx to (Idx + Txt^.Len - 1) do
         Self.Chr[P] := Txt^.Chr[P-Idx];
      Self._Len += Txt^._Len; Self._Bytes += Txt^._Bytes
   end;

Procedure TUTF8String.Insert(Const Txt:AnsiString;Const Idx:LongInt);
   Var U:PUTF8String;
   begin
      New(U, Create(Txt));
      Self.Insert(U, Idx);
      Dispose(U, Destroy)
   end;

Function TUTF8String.Clone():PUTF8String;
   Begin Exit(SubStr(1, 0)) end;

Function TUTF8String.SubStr(Start : LongInt; Len : LongWord = 0):PUTF8String;
   Var Res:PUTF8String; Finish, P, C:LongWord;
   begin 
      If (Start < 0)
         then Start := _Len - Start
         else If (Start > 0) then Start -= 1;
         
      If (Start >= _Len) then begin New(Res,Create()); Exit(Res) end;
      
      If (Len <> 0) then begin
         Finish := Start + Len - 1;
         If (Finish >= _Len) then Finish := _Len - 1
      end else Finish := _Len - 1;
      
      Len := Finish - Start + 1;
      New(Res,Create());
      System.SetLength(Res^.Chr, Len);
      Res^._Len := Len; C := 0;
      
      For P:=Start to Finish do begin
         Res^.Chr[C] := Self.Chr[P];
         Res^._Bytes += Length(Self.Chr[P]);
         C += 1
      end;
      Exit(Res)
   end;

Procedure TUTF8String.Clear();
   begin
      Self.SetLength(0);
      Self._Len := 0; Self._Bytes := 0
   end;

Procedure TUTF8String.Delete(Start : LongInt; Len : LongWord);
   Var Finish, P, C:LongWord;
   begin
      If (Start < 0)
         then Start := _Len - Start
         else If (Start > 0) then Start -= 1;
         
      If (Start >= _Len) then Exit();
      If (Len <> 0) then begin
         Finish := Start + Len - 1;
         If (Finish >= _Len) then Finish := _Len - 1
      end else Finish := _Len - 1;
      
      For C:=Start to Finish do
          Self._Bytes -= Length(Self.Chr[C]);
          
      P:=Start;
      For C:=(Finish + 1) to (_Len - 1) do begin
         Self.Chr[P] := Self.Chr[C]; P += 1
      end;
      Self._Len := P; System.SetLength(Self.Chr, P)
   end;

Procedure TUTF8String.Replace(Const Patt,Repl:PUTF8String);
   Var BobaFett:PUTF8String; sp,ch,rp,off : LongWord;
   begin
      If (Patt^._Len > Self._Len) then Exit();
      sp := Self.SearchLeft(Patt);
      If (sp > 0) then begin
         BobaFett := Self.Clone();
         Self.Clear();
         
         ch := 1; off := 1;
         Repeat
            For rp := off to (sp-1) do begin
               Self.SetChar(ch, BobaFett^.GetChar(rp));
               ch += 1 end;
            For rp := 1 to Repl^._Len do begin
               Self.SetChar(ch, Repl^.GetChar(rp));
               ch += 1 end;
            off := sp + Repl^._Len;
            sp := BobaFett^.SearchLeft(Patt,off-1)
         Until (sp = 0);
         
         While (off <= BobaFett^._Len) do begin
            Self.SetChar(ch, BobaFett^.GetChar(off));
            ch += 1; off += 1
         end;
         
         Dispose(BobaFett, Destroy())
      end
   end;

Procedure TUTF8String.Replace(Const Patt,Repl:AnsiString);
   Var P,R:PUTF8String;
   begin
      New(P, Create(Patt)); New(R, Create(Repl));
      Self.Replace(P, R);
      Dispose(P, Destroy()); Dispose(R, Destroy())
   end;

Procedure TUTF8String.Replace(Const Patt:PUTF8String;Const Repl:AnsiString);
   Var R:PUTF8String;
   begin
      New(R, Create(Repl));
      Self.Replace(Patt, R);
      Dispose(R, Destroy())
   end;
   
Procedure TUTF8String.Replace(Const Patt:AnsiString;Const Repl:PUTF8String);
   Var P:PUTF8String;
   begin
      New(P, Create(Patt));
      Self.Replace(P, Repl);
      Dispose(P, Destroy())
   end;

Function  TUTF8String.SearchLeft(Const Txt:PUTF8String;Const Offset:LongWord = 0):LongWord;
   Var C, P, S : LongWord;
   begin
      If (Txt = NIL) or (Txt^._Len = 0) then Exit(0);
      If (Self._Len < Txt^._Len + Offset) then Exit(0);
      
      P:=0; S:=0;
      For C:=Offset to (Self._Len - 1) do begin
         If (Self.Chr[C] = Txt^.Chr[P]) then begin
            If (P = 0) then S := C;
            P += 1;
            If (P = Txt^._Len) then Exit(S+1)
         end else P:=0
      end;
         
      Exit(0)
   end;

Function  TUTF8String.SearchRight(Const Txt:PUTF8String;Const Offset:LongWord = 0):LongWord;
   Var C, P : LongWord;
   begin
      If (Txt = NIL) or (Txt^._Len = 0) then Exit(0);
      If (Self._Len < Txt^._Len + Offset) then Exit(0);
      
      P:=0; 
      For C:=(Self._Len - 1 - Offset) downto 0 do begin
         If (Self.Chr[C] = Txt^.Chr[Txt^._Len - 1 - P]) then begin
            P += 1;
            If (P = Txt^._Len) then Exit(C+1)
         end else P:=0
      end;
      
      Exit(0)
   end;

Function  TUTF8String.SearchLeft(Const Txt:AnsiString;Const Offset:LongWord = 0):LongWord;
   Var U:PUTF8String; 
   begin
      New(U, Create(Txt));
      Result := Self.SearchLeft(U,Offset);
      Dispose(U, Destroy)
   end;

Function  TUTF8String.SearchRight(Const Txt:AnsiString;Const Offset:LongWord = 0):LongWord;
   Var U:PUTF8String; 
   begin
      New(U, Create(Txt));
      Result := Self.SearchRight(U,Offset);
      Dispose(U, Destroy)
   end;

Function TUTF8String.Equals(Const Txt:AnsiString):Boolean;
   Var U:PUTF8String;
   begin
      New(U, Create(Txt));
      Result := Self.Equals(U);
      Dispose(U, Destroy)
   end;

Function TUTF8String.Equals(Const Txt:PUTF8String):Boolean;
   Var C : LongWord;
   begin
      If (Txt = NIL) then Exit(False);
      If (Txt^._Len <> Self.Len) or (Txt^._Bytes <> Self._Bytes) then Exit(False);
      For C:=0 to (Self._Len - 1) do
         If (Self.Chr[C] <> Txt^.Chr[C]) then Exit(False);
      Exit(True)
   end;

Function TUTF8String.Compare(Const Txt:AnsiString):LongInt;
   Var U:PUTF8String; 
   begin
      New(U, Create(Txt));
      Result := Self.Compare(U);
      Dispose(U, Destroy)
   end;

Function TUTF8String.Compare(Const Txt:PUTF8String):LongInt;
   Var C, L : LongWord;
   begin
      If (Txt = NIL) then Exit(1);
      If (Self._Len < Txt^._Len) then L := Self._Len - 1 else L:=Txt^.Len - 1;
      
      For C:=0 to (L) do
         Case CompareText(Self.Chr[C], Txt^.Chr[C]) of
            -1: Exit(-1);
            +1: Exit(+1);
         end;
      
      Exit(CompareValue(Self._Len, Txt^._Len))
   end;

Procedure TUTF8String.CaseTransform(Const Func:TCharTransformFunc);
   Var C:LongWord;
   begin
      If (Self._Len = 0) then Exit();
      For C:=0 to (Self._Len - 1) do begin
         Self._Bytes -= Length(Self.Chr[C]);
         Self.Chr[C] := Func(Self.Chr[C]);
         Self._Bytes += Length(Self.Chr[C])
      end
   end;

Procedure TUTF8String.UpperCase();
   begin Self.CaseTransform(@CharToUpper) end;

Procedure TUTF8String.LowerCase();
   begin Self.CaseTransform(@CharToLower) end;

Procedure TUTF8String.Trim();
   Var C,L,R:LongWord;
   begin
      If (Self._Len = 0) then Exit;
      
      R := Self._Len; While (R > 0) and (IsWhitespace(Chr[R-1])) do R -= 1;
      If (R = 0) then begin Self.SetLength(0); Exit end;
      
      L := 0; While (L < Self._Len) and (IsWhitespace(Self.Chr[L])) do L+=1;
      If (L = 0) and (R = Self._Len) then Exit;
      
      For C:=0 to (R - L - 1) do begin
         _Bytes -= Length(Chr[C]);
         Chr[C] := Chr[C+L];
         _Bytes += Length(Chr[C])
      end;
      Self.SetLength(R - L)
   end;

Procedure TUTF8String.TrimLeft();
   Var L,C:LongWord;
   begin
      If (Self._Len = 0) then Exit;
      L := 0; While (L < Self._Len) and (IsWhitespace(Self.Chr[L])) do L+=1;
      
      If (L = Self._Len) then begin 
         Self.SetLength(0); Exit
         end else
      If (L = 0) then Exit;
      
      For C:=0 to (Self._Len - L - 1) do begin
         _Bytes -= Length(Chr[C]);
         Chr[C] := Chr[C+L];
         _Bytes += Length(Chr[C])
      end;
      Self.SetLength(Self._Len - L)
   end;

Procedure TUTF8String.TrimRight();
   Var C:LongWord;
   begin
      If (Self._Len = 0) then Exit;
      C := Self._Len;
      While (C > 0) and (IsWhitespace(Self.Chr[C-1])) do C-=1;
      Self.SetLength(C)
   end;

Procedure TUTF8String.Reverse();
   Var Ch : TUTF8Char; C,L,O : LongWord;
   begin
      If (Self._Len < 2) then Exit();
      L := (Self._Len div 2) - 1;
      
      For C:=0 to L do begin
         Ch := Self.Chr[C];
         O := _Len - 1 - C;
         
         Self.Chr[C] := Self.Chr[O];
         Self.Chr[O] := Ch
      end
   end;

Function TUTF8String.ToInt(Const Base:LongInt = 10):Int64;
   Var R:Int64; C, D :LongWord;
   begin R := 0;
      For C:=0 to (Self._Len - 1) do begin
         If (Chr[C] < #48) then begin
            If (Chr[C] = #44) or (Chr[C] = #46)
               then Break    // Break loop on ',' or '.'
               else Continue // Silently ignore other characters
         end else
         If (Chr[C] <  #58) then D := Ord(Chr[C][1]) - 48 else
         If (Chr[C] <  #65) then Continue else
         If (Chr[C] <  #91) then D := Ord(Chr[C][1]) - 65 + 10 else
         If (Chr[C] <  #97) then Continue else
         If (Chr[C] < #123) then D := Ord(Chr[C][1]) - 97 + 10 else
                           {else}Continue;
         
         If (D < Base) then R := (R * Base) + D
         end;
      
      If (Chr[0] <> '-')
         then Exit(+R)
         else Exit(-R)
   end;

Function TUTF8String.ToFloat():Extended;
   Var I,F:Extended; C:LongWord; Point:Boolean;
   begin
      I := 0.0; F := 0.0; Point := False;
      For C:=0 to (Self._Len - 1) do
         If (Chr[C] < #48) then begin
            If (Chr[C] = #44) or (Chr[C] = #46) then Point := True;
            Continue
            end else
         If (Chr[C] < #57) then begin
            If (Not Point)
               then I := I * 10 + (Ord(Chr[C][1]) - 48)
               else F := F * 10 + (Ord(Chr[C][1]) - 48)
         end;
      While (F > 1) do F /= 10;
      If (Chr[0] <> '-') then Exit(+I +F)
                         else Exit(-I -F)
   end;

Function TUTF8String.ToAnsiString():AnsiString;
   Var P, C, B : LongWord;
   begin
      If (_Len = 0) then Exit('');
      System.SetLength(Result,_Bytes); P:=1;
      For C:=0 to (_Len - 1) do
         For B:=1 to Length(Self.Chr[C]) do begin
            Result[P] := Self.Chr[C][B];
            P += 1
   end end;

Procedure TUTF8String.Print(Var F:Text);
   Var C:LongWord;
   begin
      If (_Len = 0) then Exit();
      For C:=0 to (_Len - 1) do
         Write(F, Self.Chr[C])
   end;

Procedure TUTF8String.PrintHex(Var F:Text);
   Const HexDigit = '0123456789ABCDEF';
   Var C, B :LongWord;
   begin
      If (_Len = 0) then Exit();
      For C:=0 to (_Len - 1) do begin
         For B:=1 to Length(Chr[C]) do
            Write(F, HexDigit[1+(Ord(Chr[C][B]) div 16)], HexDigit[1+(Ord(Chr[C][B]) mod 16)]);
         Write(F, #$20)
      end
   end;

Constructor TUTF8String.Create();
   begin
      System.SetLength(Self.Chr,0);
      _Len := 0; _Bytes := 0
   end;
   
Constructor TUTF8String.Create(Const Txt:AnsiString);
   begin
      System.SetLength(Self.Chr, 0);
      _Len := 0; _Bytes := 0;
      SetTo(Txt)
   end;

Destructor  TUTF8String.Destroy();
   begin
      System.SetLength(Self.Chr, 0)
   end;

Operator := (A : AnsiString) R : PUTF8String;
   begin 
      New(R, Create(A));
      Exit(R)
   end;

Operator + (U: PUTF8String; A : AnsiString) R : PUTF8String;
   begin
      U^.Append(A);
      Exit(U)
   end;

end.
