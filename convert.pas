unit convert;

{$INCLUDE defines.inc}

interface
   uses Values;

Function NumToStr(Int:QInt;Const Base:LongInt = 10;Const Digs:LongInt = 0):TStr; 
Function IntToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
Function HexToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
Function OctToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
Function BinToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
//Function RealToStr(Val:Extended;Prec:LongWord):TStr;
Function FloatToStr(Const Val:TFloat):TStr;

Procedure HexCase(Const Upper:Boolean);
Function  HexCase():Boolean;

Function IntBase(Const T:TValueType):LongInt; Inline;
Function BoolToInt(Const B:TBool):LongWord; Inline;

Function StrToInt(Const Str:TStr):QInt;
Function StrToHex(Const Str:TStr):QInt;
Function StrToOct(Const Str:TStr):QInt;
Function StrToBin(Const Str:TStr):QInt;
Function StrToNum(Const Str:TStr;Const Tp:TValueType):QInt;
Function StrToReal(Str:TStr):TFloat;

Var Sys16Dig : Array[0..15] of Char = (
      '0','1','2','3','4','5','6','7',
      '8','9','A','B','C','D','E','F');

implementation
   uses SysUtils, Math;

Procedure HexCase(Const Upper:Boolean);
   Var C,Off:LongWord;
   begin
   If (Upper) then Off := 65 - 10 else Off := 97 - 10;
   For C:=10 to 15 do Sys16Dig[C]:=Chr(Off+C)
   end;

Function HexCase():Boolean;
   begin Exit(Sys16Dig[10] = 'A') end;

Function NumToStr(Int:QInt;Const Base:LongInt = 10;Const Digs:LongInt = 0):TStr; 
   Var Plus:Boolean;
   Begin
   Result:='';
   If (Int<0) then begin Plus:=False; Int:=Abs(Int) end 
              else Plus:=True;
   Repeat
      Result:=Sys16Dig[Int mod Base]+Result;
      Int:=Int div Base;
      until Int=0;
   If (Length(Result)<Digs) then
      Result:=StringOfChar('0',Digs-Length(Result))+Result;
   If (Not Plus) then Result:='-' + Result
   end;

Function IntToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
   begin Exit(NumToStr(Int,10,Digs)) end;

Function HexToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
   begin Exit(NumToStr(Int,16,Digs)) end;

Function OctToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
   begin Exit(NumToStr(Int,8,Digs)) end;

Function BinToStr(Const Int:QInt;Const Digs:LongInt=0):TStr; 
   begin Exit(NumToStr(Int,2,Digs)) end;

Function NumToStr(Const Num:QInt;Const Tp:TValueType):TStr; 
   begin Case Tp of
      VT_INT: Exit(IntToStr(Num));
      VT_HEX: Exit(HexToStr(Num));
      VT_OCT: Exit(OctToStr(Num));
      VT_BIN: Exit(BinToStr(Num));
   end end;

Function FloatToStr(Const Val:TFloat):TStr;
   begin Exit(SysUtils.FloatToStrF(Val, RealForm, RealPrec, RealPrec)) end;

Function StrToInt(Const Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Result:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#57) then
          Result:=(Result*10)+Ord(Str[P])-48 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
   If Plus then Exit(Result) else Exit(-Result)
   end;

Function StrToHex(Const Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Result:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#57) then
          Result:=(Result shl 4)+Ord(Str[P])-48 else
       If (Str[P]>=#65) and (Str[P]<=#70) then
          Result:=(Result shl 4)+Ord(Str[P])-55 else
       If (Str[P]>=#97) and (Str[P]<=#102) then
          Result:=(Result shl 4)+Ord(Str[P])-87 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
   If Plus then Exit(Result) else Exit(-Result)
   end;

Function StrToOct(Const Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; 
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Result:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#55) then
          Result:=(Result shl 3)+Ord(Str[P])-48 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
   If Plus then Exit(Result) else Exit(-Result)
   end;

Function StrToBin(Const Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; 
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Result:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#49) then
          Result:=(Result shl 1)+Ord(Str[P])-48 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
   If Plus then Exit(Result) else Exit(-Result)
   end;

Function StrToNum(Const Str:TStr;Const Tp:TValueType):QInt;
   begin Case Tp of
      VT_INT: Exit(StrToInt(Str));
      VT_HEX: Exit(StrToHex(Str));
      VT_OCT: Exit(StrToOct(Str));
      VT_BIN: Exit(StrToBin(Str));
   end end;

Function StrToReal(Str:TStr):TFloat;
   Var P:LongWord; Res:TFloat;
   begin
   If (Length(Str)=0) then Exit(0);
   P:=Pos('.',Str); If (P=0) then P:=Pos(',',Str);
   If (P>0) then begin
      Res:=StrToInt(Copy(Str,1,P-1));
      Delete(Str,1,P);
      If (Res>=0)
         then Exit(Res+(StrToInt(Str)/IntPower(10,Length(Str))))
         else Exit(Res-(StrToInt(Str)/IntPower(10,Length(Str))))
      end else Exit(StrToInt(Str))
   end;

Function IntBase(Const T:TValueType):LongInt; Inline;
   begin Case T of
      VT_BIN: IntBase :=  2;
      VT_OCT: IntBase :=  8;
      VT_INT: IntBase := 10;
      VT_HEX: IntBase := 16;
         else IntBase := 10
   end end;

Function BoolToInt(Const B:TBool):LongWord; Inline;
   begin If (B) then Exit(1) else Exit(0) end;

end.
