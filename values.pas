unit values;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Trie;

Var RealPrec : LongWord = 3;

Type TValueType = (
     VT_NIL, VT_REC, VT_PTR,
     VT_INT, VT_HEX, VT_OCT, VT_BIN, VT_FLO,
     VT_BOO, VT_STR, VT_TXT); 

     PValue = ^TValue;
     TValue = record
     Typ : TValueType;
     Tmp : Boolean;
     Ptr : Pointer
     end;
     
     PQInt = ^QInt;
     QInt = Int64;
     
     PStr = ^TStr;
     TStr = AnsiString;
     
     PBool = ^Bool;
     Bool = Boolean;
     
     PValTrie = ^TValTrie;
     TValTrie = specialize GenericTrie<PValue>;
     
     PFunc = Function(Arg:Array of PValue):PValue;
     
     PFunTrie = ^TFunTrie;
     TFunTrie = specialize GenericTrie<PFunc>;

Function NumToStr(Int:QInt;Base:LongWord;Digs:LongWord=0):TStr; 
Function IntToStr(Int:QInt;Digs:LongWord=0):TStr; 
Function HexToStr(Int:QInt;Digs:LongWord=0):TStr; 
Function OctToStr(Int:QInt;Digs:LongWord=0):TStr; 
Function BinToStr(Int:QInt;Digs:LongWord=0):TStr; 
Function RealToStr(Val:Extended;Prec:LongWord):TStr;

Function StrToInt(Str:TStr):QInt;
Function StrToHex(Str:TStr):QInt;
Function StrToOct(Str:TStr):QInt;
Function StrToBin(Str:TStr):QInt;
Function StrToNum(Str:TStr;Tp:TValueType):QInt;
Function StrToReal(Str:TStr):Double;

Function ValToInt(V:PValue):PValue;
Function ValToHex(V:PValue):PValue;
Function ValToOct(V:PValue):PValue;
Function ValToBin(V:PValue):PValue;
Function ValToFlo(V:PValue):PValue;
Function ValToBoo(V:PValue):PValue;
Function ValToStr(V:PValue):PValue;

Function ValSet(A,B:PValue):PValue;
Function ValAdd(A,B:PValue):PValue;
Function ValSub(A,B:PValue):PValue;
Function ValMul(A,B:PValue):PValue;
Function ValDiv(A,B:PValue):PValue;
Function ValMod(A,B:PValue):PValue;
Function ValPow(A,B:PValue):PValue;

Function ValSeq(A,B:PValue):PValue;
Function ValSNeq(A,B:PValue):PValue;
Function ValEq(A,B:PValue):PValue;
Function ValNeq(A,B:PValue):PValue;
Function ValGt(A,B:PValue):PValue;
Function ValGe(A,B:PValue):PValue;
Function ValLt(A,B:PValue):PValue;
Function ValLe(A,B:PValue):PValue;

Function  NilVal():PValue;
Procedure FreeVal(Var Val:PValue);
Function  EmptyVal(T:TValueType):PValue;
Function  CopyTyp(V:PValue):PValue;
Function  CopyVal(V:PValue):PValue;
Procedure SwapPtrs(A,B:PValue);

Function NewVal(T:TValueType;V:Double):PValue;
Function NewVal(T:TValueType;V:Int64):PValue;
Function NewVal(T:TValueType;V:Bool):PValue;
Function NewVal(T:TValueType;V:TStr):PValue;
Function NewVal(T:TValueType):PValue;

implementation
   uses Math, SysUtils;

const Sys16Dig:Array[0..15] of Char=(
      '0','1','2','3','4','5','6','7',
      '8','9','A','B','C','D','E','F');
   
Function NumToStr(Int:QInt;Base:LongWord;Digs:LongWord=0):TStr; 
   Var Tmp:TStr; Plus:Boolean;
   Begin Tmp:='';
   If (Int<0) then begin Plus:=False; Int:=Abs(Int) end 
              else Plus:=True;
   Repeat
      Tmp:=Sys16Dig[Int mod Base]+Tmp;
      Int:=Int div Base;
      until Int=0;
   If (Length(Tmp)<Digs) then
      Tmp:=StringOfChar('0',Digs-Length(Tmp))+Tmp;
   If Plus then Exit(Tmp)
           else Exit('-'+Tmp)
   end;

Function IntToStr(Int:QInt;Digs:LongWord=0):TStr; 
   begin Exit(NumToStr(Int,10,Digs)) end;

Function HexToStr(Int:QInt;Digs:LongWord=0):TStr; 
   begin Exit(NumToStr(Int,16,Digs)) end;

Function OctToStr(Int:QInt;Digs:LongWord=0):TStr; 
   begin Exit(NumToStr(Int,8,Digs)) end;

Function BinToStr(Int:QInt;Digs:LongWord=0):TStr; 
   begin Exit(NumToStr(Int,2,Digs)) end;

Function NumToStr(Num:QInt;Tp:TValueType):TStr; 
   begin Case Tp of
      VT_INT: Exit(IntToStr(Num));
      VT_HEX: Exit(HexToStr(Num));
      VT_OCT: Exit(OctToStr(Num));
      VT_BIN: Exit(BinToStr(Num));
   end end;

Function RealToStr(Val:Extended;Prec:LongWord):TStr;
   Var Res:TStr;
   begin 
   if Val<0 then Res:='-' else Res:=''; Val:=Abs(Val);
   Res+=NumToStr(Trunc(Val),10); Val:=(Frac(Val) * IntPower(10,Prec)); 
   If (Val<1) then Exit(Res+'.'+StringOfChar('0',Prec)); 
   Res+='.'; Res+=NumToStr(Trunc(Val),10,Prec);
   Exit(Res) end;

Function StrToInt(Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; Res:QInt;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Res:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#57) then
          Res:=(Res*10)+Ord(Str[P])-48;
   If Plus then Exit(Res) else Exit(-Res)
   end;

Function StrToHex(Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; Res:QInt;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Res:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#57) then
          Res:=(Res shl 4)+Ord(Str[P])-48 else
       If (Str[P]>=#65) and (Str[P]<=#70) then
          Res:=(Res shl 4)+Ord(Str[P])-55;
   If Plus then Exit(Res) else Exit(-Res)
   end;

Function StrToOct(Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; Res:QInt;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Res:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#55) then
          Res:=(Res shl 3)+Ord(Str[P])-48;
   If Plus then Exit(Res) else Exit(-Res)
   end;

Function StrToBin(Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; Res:QInt;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Res:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#49) then
          Res:=(Res shl 1)+Ord(Str[P])-48;
   If Plus then Exit(Res) else Exit(-Res)
   end;

Function StrToNum(Str:TStr;Tp:TValueType):QInt;
   begin Case Tp of
      VT_INT: Exit(StrToInt(Str));
      VT_HEX: Exit(StrToHex(Str));
      VT_OCT: Exit(StrToOct(Str));
      VT_BIN: Exit(StrToBin(Str));
   end end;

Function StrToReal(Str:TStr):Double;
   Var P:LongWord; Res:Double;
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

Function BoolToInt(B:Bool):LongWord; Inline;
   begin If (B) then Exit(1) else Exit(0) end;

Function ValToInt(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_INT; R^.Tmp:=True; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_NIL: P^:=0;
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PDouble(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToInt(PStr(V^.Ptr)^);
      end;
   Exit(R)
   end;

Function ValToHex(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_HEX; R^.Tmp:=True; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_NIL: P^:=0;
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PDouble(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToHex(PStr(V^.Ptr)^);
      end;
   Exit(R)
   end;

Function ValToOct(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_OCT; R^.Tmp:=True; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_NIL: P^:=0;
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PDouble(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToOct(PStr(V^.Ptr)^);
      end;
   Exit(R)
   end;

Function ValToBin(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_BIN; R^.Tmp:=True; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_NIL: P^:=0;
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PDouble(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToBin(PStr(V^.Ptr)^);
      end;
   Exit(R)
   end;

Function ValToFlo(V:PValue):PValue;
   Var R:PValue; P:PDouble;
   begin
   New(R); R^.Typ:=VT_FLO; R^.Tmp:=True; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_NIL: P^:=0;
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=PDouble(V^.Ptr)^;
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToReal(PStr(V^.Ptr)^);
      end;
   Exit(R)
   end;

Function ValToBoo(V:PValue):PValue;
   Var R:PValue; P:PBoolean;
   begin
   New(R); R^.Typ:=VT_BOO; R^.Tmp:=True; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_NIL: P^:=FALSE;
      VT_INT: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_HEX: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_OCT: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_BIN: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_FLO: P^:=(PDouble(V^.Ptr)^)<>0;
      VT_BOO: P^:=PBoolean(V^.Ptr)^;
      VT_STR: P^:=StrToBoolDef(PStr(V^.Ptr)^,FALSE);
      end;
   Exit(R)
   end;

Function ValToStr(V:PValue):PValue;
   Var R:PValue; P:PStr;
   begin
   New(R); R^.Typ:=VT_STR; R^.Tmp:=True; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_NIL: P^:='';
      VT_INT: P^:=IntToStr(PQInt(V^.Ptr)^);
      VT_HEX: P^:=HexToStr(PQInt(V^.Ptr)^);
      VT_OCT: P^:=OctToStr(PQInt(V^.Ptr)^);
      VT_BIN: P^:=BinToStr(PQInt(V^.Ptr)^);
      VT_FLO: P^:=RealToStr(PDouble(V^.Ptr)^,RealPrec);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE)
                 then P^:='TRUE' else P^:='FALSE';
      VT_STR: P^:=PStr(V^.Ptr)^;
      end;
   Exit(R)
   end;

Function ValSet(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PDouble;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Tmp:=True;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=0;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)+(PDouble(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^):=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (I^):=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=0;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^):=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^):=PDouble(B^.Ptr)^ else
      If (B^.Typ = VT_STR)
         then (D^):=StrToReal(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (D^):=1
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):='';
      If (B^.Typ = VT_INT)
         then (S^):=IntToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_HEX)
         then (S^):=HexToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_OCT)
         then (S^):=OctToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_BIN)
         then (S^):=BinToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (S^):=RealToStr(PDouble(B^.Ptr)^,RealPrec) else
      If (B^.Typ = VT_STR)
         then (S^):=(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (S^):='TRUE' else (S^):='FALSE'
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=False;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=(PQInt(B^.Ptr)^<>0) else
      If (B^.Typ = VT_FLO)
         then (L^):=(PDouble(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(PBoolean(B^.Ptr)^)
      end;
   Exit(R)
   end;

Function ValAdd(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PDouble;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Tmp:=True;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^)+=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)+(PDouble(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^)+=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (I^)+=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PDouble(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)+=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)+=PDouble(B^.Ptr)^ else
      If (B^.Typ = VT_STR)
         then (D^)+=StrToReal(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (D^)+=1
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      If (B^.Typ = VT_INT)
         then (S^)+=IntToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_HEX)
         then (S^)+=HexToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_OCT)
         then (S^)+=OctToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_BIN)
         then (S^)+=BinToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (S^)+=RealToStr(PDouble(B^.Ptr)^,RealPrec) else
      If (B^.Typ = VT_STR)
         then (S^)+=(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (S^)+='TRUE' else (S^)+='FALSE'
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=(L^) or (PQInt(B^.Ptr)^<>0) else
      If (B^.Typ = VT_FLO)
         then (L^):=(L^) or (PDouble(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) or StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) or (PBoolean(B^.Ptr)^)
      end;
   Exit(R)
   end;

Function ValSub(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PDouble;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Tmp:=True;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^)-=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)-(PDouble(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^)-=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (I^)-=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PDouble(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)-=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)-=PDouble(B^.Ptr)^ else
      If (B^.Typ = VT_STR)
         then (D^)-=StrToReal(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (D^)-=1
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      {If (B^.Typ = VT_INT)
         then (S^)+=IntToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_HEX)
         then (S^)+=HexToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_OCT)
         then (S^)+=OctToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_BIN)
         then (S^)+=BinToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (S^):=RealToStr(PDouble(B^.Ptr)^,RealPrec) else
      If (B^.Typ = VT_STR)
         then (S^)+=(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (S^)+='TRUE' else (S^)+='FALSE'}
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=(L^) xor (PQInt(B^.Ptr)^<>0) else
      If (B^.Typ = VT_FLO)
         then (L^):=(L^) xor (PDouble(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) xor StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) xor (PBoolean(B^.Ptr)^)
      end;
   Exit(R)
   end;

Function ValMul(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S,O:PStr; L:PBoolean; D:PDouble; C,T:LongWord;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Tmp:=True;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^)*=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)*(PDouble(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^)*=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (I^):=0
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PDouble(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)*=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)*=PDouble(B^.Ptr)^ else
      If (B^.Typ = VT_STR)
         then (D^)*=StrToReal(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (D^):=0
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^; O:=PStr(A^.Ptr);
      If (B^.Typ = VT_INT)
         then T:=Abs(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_HEX)
         then T:=Abs(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_OCT)
         then T:=Abs(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_BIN)
         then T:=Abs(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then T:=Abs(Trunc(PDouble(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then T:=StrToInt(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then T:=BoolToInt(PBool(B^.Ptr)^);
      T*=Length(O^); SetLength(S^,T);
      For C:=1 to T do 
          (S^)[C]:=(O^)[((C-1) mod Length(O^))+1]
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=(L^) and (PQInt(B^.Ptr)^<>0) else
      If (B^.Typ = VT_FLO)
         then (L^):=(L^) and (PDouble(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) and StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) and (PBoolean(B^.Ptr)^)
      end;
   Exit(R)
   end;

Function ValDiv(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PDouble;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Tmp:=True;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=(I^) div (PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)/(PDouble(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^):=(I^) div StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (I^):=0
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PDouble(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)/=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)/=PDouble(B^.Ptr)^ else
      If (B^.Typ = VT_STR)
         then (D^)/=StrToReal(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (D^):=0
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      {If (B^.Typ = VT_INT)
         then (S^)+=IntToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_HEX)
         then (S^)+=HexToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_OCT)
         then (S^)+=OctToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_BIN)
         then (S^)+=BinToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (S^):=RealToStr(PDouble(B^.Ptr)^,RealPrec) else
      If (B^.Typ = VT_STR)
         then (S^)+=(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (S^)+='TRUE' else (S^)+='FALSE'}
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=Not ((L^) xor (PQInt(B^.Ptr)^<>0)) else
      If (B^.Typ = VT_FLO)
         then (L^):=Not ((L^) xor (PDouble(B^.Ptr)^<>0)) else
      If (B^.Typ = VT_STR)
         then (L^):=Not ((L^) xor StrToBoolDef(PStr(B^.Ptr)^,FALSE)) else
      If (B^.Typ = VT_BOO)
         then (L^):=Not ((L^) xor (PBoolean(B^.Ptr)^))
      end;
   Exit(R)
   end;

Function ValMod(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PDouble; T:Double;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Tmp:=True;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=(I^) mod (PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then begin 
         T:=(I^); While (T>=PDouble(B^.Ptr)^) do T-=PDouble(B^.Ptr)^;
         (I^):=Trunc(T)
         end else
      If (B^.Typ = VT_STR)
         then (I^):=(I^) mod StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then (I^):=0
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PDouble(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then While (D^>=PQInt(B^.Ptr)^) do (D^)-=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then While (D^>=PDouble(B^.Ptr)^) do (D^)-=PDouble(B^.Ptr)^ else
      If (B^.Typ = VT_STR)
         then begin
         T:=StrToReal(PStr(B^.Ptr)^); While (D^>=T) do (D^)-=T
         end else
      If (B^.Typ = VT_BOO)
         then (D^):=0
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      {If (B^.Typ = VT_INT)
         then (S^)+=IntToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_HEX)
         then (S^)+=HexToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_OCT)
         then (S^)+=OctToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_BIN)
         then (S^)+=BinToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (S^):=RealToStr(PDouble(B^.Ptr)^,RealPrec) else
      If (B^.Typ = VT_STR)
         then (S^)+=(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (S^)+='TRUE' else (S^)+='FALSE'}
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      {If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=(L^) and (PQInt(B^.Ptr)^<>0) else
      If (B^.Typ = VT_FLO)
         then (L^):=(L^) and (PDouble(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) and StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) and (PBoolean(B^.Ptr)^)}
      end;
   Exit(R)
   end;

Function ValPow(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PDouble;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Tmp:=True;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=Trunc(IntPower(I^,PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc(Power(I^,PDouble(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^):=Trunc(IntPower(I^,StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (I^):=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PDouble(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)*=Power(D^,PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)*=Power(D^,PDouble(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (D^)*=Power(D^,StrToReal(PStr(B^.Ptr)^)) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (D^):=0
      end else
   If (A^.Typ = VT_STR) then begin
      New(S); R^.Ptr:=S; (S^):=PStr(A^.Ptr)^;
      {If (B^.Typ = VT_INT)
         then (S^)+=IntToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_HEX)
         then (S^)+=HexToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_OCT)
         then (S^)+=OctToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_BIN)
         then (S^)+=BinToStr(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (S^):=RealToStr(PDouble(B^.Ptr)^,RealPrec) else
      If (B^.Typ = VT_STR)
         then (S^)+=(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (S^)+='TRUE' else (S^)+='FALSE'}
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=PBoolean(A^.Ptr)^;
      {If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=(L^) and (PQInt(B^.Ptr)^<>0) else
      If (B^.Typ = VT_FLO)
         then (L^):=(L^) and (PDouble(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) and StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) and (PBoolean(B^.Ptr)^)}
      end;
   Exit(R)
   end;

Function ValSeq(A,B:PValue):PValue;
   begin
   If (A^.Typ <> B^.Typ) then Exit(NewVal(VT_BOO,False));
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then
      Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = (PQInt(B^.Ptr)^))) else
   If (A^.Typ = VT_FLO) then
      Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) = (PDouble(B^.Ptr)^))) else
   If (A^.Typ = VT_STR) then
      Exit(NewVal(VT_BOO, (PStr(A^.Ptr)^) = (PStr(B^.Ptr)^))) else
   If (A^.Typ = VT_BOO) then
      Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = (PBool(B^.Ptr)^))) else
      {else} Exit(NewVal(VT_BOO,False))
   end;

Function ValSNeq(A,B:PValue):PValue;
   Var R:PValue; P:PBool;
   begin 
   R:=ValSeq(A,B); P:=PBool(R^.Ptr); (P^):=Not (P^);
   Exit(R)
   end;

Function ValEq(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, Trunc(PDouble(A^.Ptr)^) = (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) = (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) = StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, Trunc(PDouble(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) = (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) = (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PStr(A^.Ptr)^) = (PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, StrToBoolDef(PStr(A^.Ptr)^,FALSE) = (PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = (PQInt(B^.Ptr)^ <> 0))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = (PDouble(B^.Ptr)^ <> 0.0))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = StrToBoolDef(PStr(B^.Ptr)^,FALSE))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = (PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
      Exit(NewVal(VT_BOO,False))
   end;

Function ValNeq(A,B:PValue):PValue;
   Var R:PValue; P:PBool;
   begin 
   R:=ValEq(A,B); P:=PBool(R^.Ptr); (P^):=Not (P^);
   Exit(R)
   end;

Function ValGt(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) > (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) > Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) > StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) > BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) > Double(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) > (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) > StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) > Double(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) > (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) > (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PStr(A^.Ptr)^) > (PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) > BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) > (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) > Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) > BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) > BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
      Exit(NewVal(VT_BOO,False))
   end;

Function ValGe(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) >= Double(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) >= (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) >= StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) >= Double(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) >= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) >= (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PStr(A^.Ptr)^) >= (PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) >= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) >= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) >= Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) >= BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) >= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
      Exit(NewVal(VT_BOO,False))
   end;

Function ValLt(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) < Double(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) < (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) < StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) < Double(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) < (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) < (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PStr(A^.Ptr)^) < (PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) < BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) < (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) < Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) < BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) < BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
      Exit(NewVal(VT_BOO,False))
   end;

Function ValLe(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) <= Double(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) <= (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) <= StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PDouble(A^.Ptr)^) <= Double(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) <= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) <= (PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PStr(A^.Ptr)^) <= (PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(StrToBoolDef(PStr(A^.Ptr)^,FALSE)) <= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_BOO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) <= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) <= Trunc(PDouble(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) <= BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) <= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
      Exit(NewVal(VT_BOO,False))
   end;

Function NilVal():PValue;
   Var R:PValue;
   begin
   New(R); R^.Typ:=VT_NIL; R^.Ptr:=NIL; R^.Tmp:=True;
   Exit(R)
   end;

Procedure FreeVal(Var Val:PValue);
   Var V:PValue; T:PValTrie;
   begin
   Case Val^.Typ of
      VT_NIL: ;
      VT_INT: Dispose(PQInt(Val^.Ptr));
      VT_HEX: Dispose(PQInt(Val^.Ptr));
      VT_OCT: Dispose(PQInt(Val^.Ptr));
      VT_BIN: Dispose(PQInt(Val^.Ptr));
      VT_FLO: Dispose(PDouble(Val^.Ptr));
      VT_BOO: Dispose(PBoolean(Val^.Ptr));
      VT_STR: Dispose(PAnsiString(Val^.Ptr));
      VT_REC: begin
              T:=PValTrie(Val^.Ptr);
              While (Not T^.Empty()) do begin
                 V:=T^.GetVal();
                 FreeVal(V);
                 T^.RemVal()
                 end;
              Dispose(T,Destroy())
              end;
      end;
   Dispose(Val)
   end;

Function  EmptyVal(T:TValueType):PValue;
   Var R:PValue; I:PQInt; S:PStr; D:PDouble; B:PBoolean;
   begin
   New(R); R^.Tmp:=True; R^.Typ:=T;
   Case T of 
      VT_NIL: R^.Ptr := NIL;
      VT_INT: begin New(I); (I^):=0;     R^.Ptr:=I end;
      VT_HEX: begin New(I); (I^):=0;     R^.Ptr:=I end;
      VT_OCT: begin New(I); (I^):=0;     R^.Ptr:=I end;
      VT_BIN: begin New(I); (I^):=0;     R^.Ptr:=I end;
      VT_FLO: begin New(D); (D^):=0.0;   R^.Ptr:=D end;
      VT_STR: begin New(S); (S^):='';    R^.Ptr:=S end;
      VT_BOO: begin New(B); (B^):=False; R^.Ptr:=B end;
      else R^.Ptr:=NIL
      end;
   Exit(R)
   end;

Function  CopyTyp(V:PValue):PValue;
   begin Exit(EmptyVal(V^.Typ)) end;

Function  CopyVal(V:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; D:PDouble; B:PBoolean;
   begin
   New(R); R^.Tmp:=True; R^.Typ:=V^.Typ;
   Case V^.Typ of 
      VT_NIL: ;
      VT_INT: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_HEX: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_OCT: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_BIN: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_FLO: begin New(D); (D^):=PDouble(V^.Ptr)^; R^.Ptr:=D end;
      VT_STR: begin New(S); (S^):=PStr(V^.Ptr)^; R^.Ptr:=S end;
      VT_BOO: begin New(B); (B^):=PBool(V^.Ptr)^; R^.Ptr:=B end;
      end;
   Exit(R)
   end;

Procedure SwapPtrs(A,B:PValue);
   Var P:Pointer;
   begin P:=A^.Ptr; A^.Ptr:=B^.Ptr; B^.Ptr:=P end;

Function NewVal(T:TValueType;V:Double):PValue;
   Var R:PValue; P:PDouble;
   begin
   New(R); R^.Typ:=VT_FLO; New(P); R^.Ptr:=P; R^.Tmp:=True;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:Int64):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_INT; New(P); R^.Ptr:=P; R^.Tmp:=True;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:Bool):PValue;
   Var R:PValue; P:PBool;
   begin
   New(R); R^.Typ:=VT_BOO; New(P); R^.Ptr:=P; R^.Tmp:=True;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:TStr):PValue;
   Var R:PValue; P:PStr;
   begin
   New(R); R^.Typ:=VT_STR; New(P); R^.Ptr:=P; R^.Tmp:=True;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType):PValue;
   Var R:PValue; P:PValTrie;
   begin
   If (T<>VT_REC) then Exit(NilVal);
   New(R); R^.Typ:=VT_REC; New(P,Create('A','z'));
   R^.Ptr:=P; R^.Tmp:=True;
   Exit(R)
   end;

end.
