unit values;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Scapegoat, Trie;

Var RealPrec : LongWord = 3;
    CurLev : LongWord = 0;

Type TValueType = (
     VT_NIL, VT_NEW,
     VT_PTR,
     VT_BOO,
     VT_INT, VT_HEX, VT_OCT, VT_BIN, VT_FLO,
     VT_STR, VT_UTF,
     VT_ARR, VT_DIC,
     VT_FIL);

Const VT_LOG = VT_BOO;

Type PValue = ^TValue;
     TValue = record
     Typ : TValueType;
     Lev : LongWord;
     Ptr : Pointer
     end;
     
     PFileVal = ^TFileVal;
     TFileVal = record
     Fil : System.Text;
     arw : Char;
     Pth : AnsiString;
     Buf : AnsiString
     end;
     
     PQInt = ^QInt;
     QInt = Int64;
     
     PStr = ^TStr;
     TStr = AnsiString;
     
     PBool = ^Bool;
     Bool = Boolean;
     
     PFloat = ^TFloat;
     TFloat = Extended;
     
     PValTree = ^TValTree;
     TValTree = specialize GenericScapegoat<PValue>;
     
     PValTrie = ^TValTrie;
     TValTrie = specialize GenericTrie<PValue>;
     
     PFunc = Function(DoReturn:Boolean; Arg:Array of PValue):PValue;
     
Const RETURN_VALUE_YES = True; RETURN_VALUE_NO = False;
     
Type PFunTrie = ^TFunTrie;
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
Function StrToReal(Str:TStr):TFloat;

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

Function NewVal(T:TValueType;V:TFloat):PValue;
Function NewVal(T:TValueType;V:Int64):PValue;
Function NewVal(T:TValueType;V:Bool):PValue;
Function NewVal(T:TValueType;V:TStr):PValue;
Function NewVal(T:TValueType):PValue;

Function Exv(DoReturn:Boolean):PValue; Inline;

implementation
   uses Math, SysUtils;

const Sys16Dig:Array[0..15] of Char=(
      '0','1','2','3','4','5','6','7',
      '8','9','A','B','C','D','E','F');
      Alfa = 0.575;
   
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
          Res:=(Res shl 4)+Ord(Str[P])-55 else
       If (Str[P]>=#97) and (Str[P]<=#102) then
          Res:=(Res shl 4)+Ord(Str[P])-87;
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

Function BoolToInt(B:Bool):LongWord; Inline;
   begin If (B) then Exit(1) else Exit(0) end;

Function ValToInt(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_INT; R^.Lev:=CurLev; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PFloat(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToInt(PStr(V^.Ptr)^);
      VT_ARR: P^:=PValTree(V^.Ptr)^.Count;
      VT_DIC: P^:=PValTrie(V^.Ptr)^.Count;
      else P^:=0;
      end;
   Exit(R)
   end;

Function ValToHex(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_HEX; R^.Lev:=CurLev; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PFloat(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToHex(PStr(V^.Ptr)^);
      VT_ARR: P^:=PValTree(V^.Ptr)^.Count;
      VT_DIC: P^:=PValTrie(V^.Ptr)^.Count;
      else P^:=0;
      end;
   Exit(R)
   end;

Function ValToOct(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_OCT; R^.Lev:=CurLev; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PFloat(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToOct(PStr(V^.Ptr)^);
      VT_ARR: P^:=PValTree(V^.Ptr)^.Count;
      VT_DIC: P^:=PValTrie(V^.Ptr)^.Count;
      else P^:=0;
      end;
   Exit(R)
   end;

Function ValToBin(V:PValue):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=VT_BIN; R^.Lev:=CurLev; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=Trunc(PFloat(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToBin(PStr(V^.Ptr)^);
      VT_ARR: P^:=PValTree(V^.Ptr)^.Count;
      VT_DIC: P^:=PValTrie(V^.Ptr)^.Count;
      else P^:=0;
      end;
   Exit(R)
   end;

Function ValToFlo(V:PValue):PValue;
   Var R:PValue; P:PFloat;
   begin
   New(R); R^.Typ:=VT_FLO; R^.Lev:=CurLev; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_INT: P^:=PQInt(V^.Ptr)^;
      VT_HEX: P^:=PQInt(V^.Ptr)^;
      VT_OCT: P^:=PQInt(V^.Ptr)^;
      VT_BIN: P^:=PQInt(V^.Ptr)^;
      VT_FLO: P^:=PFloat(V^.Ptr)^;
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE) then P^:=1 else P^:=0;
      VT_STR: P^:=StrToReal(PStr(V^.Ptr)^);
      VT_ARR: P^:=PValTree(V^.Ptr)^.Count;
      VT_DIC: P^:=PValTrie(V^.Ptr)^.Count;
      else P^:=0;
      end;
   Exit(R)
   end;

Function ValToBoo(V:PValue):PValue;
   Var R:PValue; P:PBoolean;
   begin
   New(R); R^.Typ:=VT_BOO; R^.Lev:=CurLev; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_INT: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_HEX: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_OCT: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_BIN: P^:=(PQInt(V^.Ptr)^)<>0;
      VT_FLO: P^:=(PFloat(V^.Ptr)^)<>0;
      VT_BOO: P^:=PBoolean(V^.Ptr)^;
      VT_STR: P^:=StrToBoolDef(PStr(V^.Ptr)^,FALSE);
      VT_ARR: P^:=Not PValTree(V^.Ptr)^.Empty();
      VT_DIC: P^:=Not PValTrie(V^.Ptr)^.Empty();
      else P^:=False;
      end;
   Exit(R)
   end;

Function ValToStr(V:PValue):PValue;
   Var R:PValue; P:PStr;
   begin
   New(R); R^.Typ:=VT_STR; R^.Lev:=CurLev; New(P); R^.Ptr:=P;
   Case V^.Typ of
      VT_INT: P^:=IntToStr(PQInt(V^.Ptr)^);
      VT_HEX: P^:=HexToStr(PQInt(V^.Ptr)^);
      VT_OCT: P^:=OctToStr(PQInt(V^.Ptr)^);
      VT_BIN: P^:=BinToStr(PQInt(V^.Ptr)^);
      VT_FLO: P^:=RealToStr(PFloat(V^.Ptr)^,RealPrec);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE)
                 then P^:='TRUE' else P^:='FALSE';
      VT_STR: P^:=PStr(V^.Ptr)^;
      VT_ARR: P^:='array('+IntToStr(PValTrie(V^.Ptr)^.Count)+')';
      VT_DIC: P^:='dict('+IntToStr(PValTrie(V^.Ptr)^.Count)+')';
      else P^:='';
      end;
   Exit(R)
   end;

Function ValSet(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
       AArr,BArr,NArr:PValTree; AEA:TValTree.TEntryArr;
       ADic,BDic,NDic:PValTrie; DEA:TValTrie.TEntryArr;
       V,oV:PValue; C:LongWord; KeyStr:TStr; KeyInt:QInt;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=0;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)+(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^):=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_ARR)
         then (I^):=PValTree(B^.Ptr)^.Count else
      If (B^.Typ = VT_DIC)
         then (I^):=PValTrie(B^.Ptr)^.Count else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (I^):=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=0;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^):=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^):=PFloat(B^.Ptr)^ else
      If (B^.Typ = VT_STR)
         then (D^):=StrToReal(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_ARR)
         then (D^):=PValTree(B^.Ptr)^.Count else
      If (B^.Typ = VT_DIC)
         then (D^):=PValTrie(B^.Ptr)^.Count else
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
         then (S^):=RealToStr(PFloat(B^.Ptr)^,RealPrec) else
      If (B^.Typ = VT_STR)
         then (S^):=(PStr(B^.Ptr)^) else
      If (B^.Typ = VT_ARR)
         then (S^):=IntToStr(PValTree(B^.Ptr)^.Count) else
      If (B^.Typ = VT_DIC)
         then (S^):=IntToStr(PValTrie(B^.Ptr)^.Count) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (S^):='TRUE' else (S^):='FALSE'
      end else
   If (A^.Typ = VT_BOO) then begin
      New(L); R^.Ptr:=L; (L^):=False;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (L^):=(PQInt(B^.Ptr)^<>0) else
      If (B^.Typ = VT_FLO)
         then (L^):=(PFloat(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_ARR)
         then (L^):=(Not PValTree(B^.Ptr)^.Empty) else
      If (B^.Typ = VT_DIC)
         then (L^):=(Not PValTrie(B^.Ptr)^.Empty) else
      If (B^.Typ = VT_BOO)
         then (L^):=(PBoolean(B^.Ptr)^)
      end else
   If (A^.Typ = VT_ARR) then begin
      New(NArr,Create(Alfa)); R^.Ptr:=NArr;
      AArr:=PValTree(A^.Ptr);
      If (Not AArr^.Empty()) then begin
         AEA:=AArr^.ToArray();
         For C:=Low(AEA) to High(AEA) do
             NArr^.SetValNaive(AEA[C].Key, CopyVal(AEA[C].Val));
         end;
      If (B^.Typ = VT_ARR) then begin
         BArr:=PValTree(B^.Ptr);
         If (Not BArr^.Empty()) then begin
            AEA:=BArr^.ToArray();
            For C:=Low(AEA) to High(AEA) do
                If (Not NArr^.IsVal(AEA[C].Key))
                   then NArr^.SetValNaive(AEA[C].Key, CopyVal(AEA[C].Val))
                   else begin
                   oV:=NArr^.GetVal(AEA[C].Key); V:=ValSet(oV, AEA[C].Val);
                   FreeVal(oV); NArr^.SetValNaive(AEA[C].Key, V)
                   end
            end
         end else
      If (B^.Typ = VT_DIC) then begin
         BDic:=PValTrie(B^.Ptr);
         If (Not BDic^.Empty()) then begin
            DEA:=BDic^.ToArray();
            For C:=Low(DEA) to High(DEA) do begin
                KeyInt:=StrToInt(DEA[C].Key);
                If (Not NArr^.IsVal(KeyInt))
                   then NArr^.SetValNaive(KeyInt, CopyVal(DEA[C].Val))
                   else begin
                   oV:=NArr^.GetVal(KeyInt); V:=ValSet(oV, DEA[C].Val);
                   FreeVal(oV); NArr^.SetValNaive(KeyInt, V)
                   end
                end
            end
         end;
      NArr^.Rebalance()
      end;
   If (A^.Typ = VT_DIC) then begin
      New(NDic,Create('!','~')); R^.Ptr:=NDic;
      ADic:=PValTrie(A^.Ptr);
      If (Not ADic^.Empty()) then begin
         DEA:=ADic^.ToArray();
         For C:=Low(DEA) to High(DEA) do
             NDic^.SetVal(DEA[C].Key, CopyVal(DEA[C].Val));
         end;
      If (B^.Typ = VT_DIC) then begin
         BDic:=PValTrie(B^.Ptr);
         If (Not BDic^.Empty()) then begin
            DEA:=BDic^.ToArray();
            For C:=Low(DEA) to High(DEA) do
                If (Not NDic^.IsVal(DEA[C].Key))
                   then NDic^.SetVal(DEA[C].Key, CopyVal(DEA[C].Val))
                   else begin
                   oV:=NDic^.GetVal(DEA[C].Key); V:=ValSet(oV, DEA[C].Val);
                   FreeVal(oV); NDic^.SetVal(DEA[C].Key, V)
                   end
            end
         end else
      If (B^.Typ = VT_ARR) then begin
         BArr:=PValTree(B^.Ptr);
         If (Not BArr^.Empty()) then begin
            AEA:=BArr^.ToArray();
            For C:=Low(AEA) to High(AEA) do begin
                KeyStr:=IntToStr(AEA[C].Key);
                If (Not NDic^.IsVal(KeyStr))
                   then NDic^.SetVal(KeyStr, CopyVal(AEA[C].Val))
                   else begin
                   oV:=NDic^.GetVal(KeyStr); V:=ValSet(oV, AEA[C].Val);
                   FreeVal(oV); NDic^.SetVal(KeyStr, V)
                   end
                end
            end
         end
      end;
   Exit(R)
   end;

Function ValAdd(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^)+=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)+(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^)+=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (I^)+=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)+=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)+=PFloat(B^.Ptr)^ else
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
         then (S^)+=RealToStr(PFloat(B^.Ptr)^,RealPrec) else
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
         then (L^):=(L^) or (PFloat(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) or StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) or (PBoolean(B^.Ptr)^)
      end;
   Exit(R)
   end;

Function ValSub(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^)-=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)-(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^)-=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (PBoolean(B^.Ptr)^) then (I^)-=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)-=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)-=PFloat(B^.Ptr)^ else
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
         then (S^):=RealToStr(PFloat(B^.Ptr)^,RealPrec) else
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
         then (L^):=(L^) xor (PFloat(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) xor StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) xor (PBoolean(B^.Ptr)^)
      end;
   Exit(R)
   end;

Function ValMul(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S,O:PStr; L:PBoolean; D:PFloat; C,T:LongWord;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^)*=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)*(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^)*=StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (I^):=0
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)*=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)*=PFloat(B^.Ptr)^ else
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
         then T:=Abs(Trunc(PFloat(B^.Ptr)^)) else
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
         then (L^):=(L^) and (PFloat(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) and StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) and (PBoolean(B^.Ptr)^)
      end;
   Exit(R)
   end;

Function ValDiv(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=(I^) div (PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc((I^)/(PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^):=(I^) div StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (I^):=0
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^)/=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^)/=PFloat(B^.Ptr)^ else
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
         then (S^):=RealToStr(PFloat(B^.Ptr)^,RealPrec) else
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
         then (L^):=Not ((L^) xor (PFloat(B^.Ptr)^<>0)) else
      If (B^.Typ = VT_STR)
         then (L^):=Not ((L^) xor StrToBoolDef(PStr(B^.Ptr)^,FALSE)) else
      If (B^.Typ = VT_BOO)
         then (L^):=Not ((L^) xor (PBoolean(B^.Ptr)^))
      end;
   Exit(R)
   end;

Function ValMod(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat; T:TFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=(I^) mod (PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then begin 
         T:=(I^); While (T>=PFloat(B^.Ptr)^) do T-=PFloat(B^.Ptr)^;
         (I^):=Trunc(T)
         end else
      If (B^.Typ = VT_STR)
         then (I^):=(I^) mod StrToNum(PStr(B^.Ptr)^,A^.Typ) else
      If (B^.Typ = VT_BOO)
         then (I^):=0
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then While (D^>=PQInt(B^.Ptr)^) do (D^)-=(PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then While (D^>=PFloat(B^.Ptr)^) do (D^)-=PFloat(B^.Ptr)^ else
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
         then (S^):=RealToStr(PFloat(B^.Ptr)^,RealPrec) else
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
         then (L^):=(L^) and (PFloat(B^.Ptr)^<>0) else
      If (B^.Typ = VT_STR)
         then (L^):=(L^) and StrToBoolDef(PStr(B^.Ptr)^,FALSE) else
      If (B^.Typ = VT_BOO)
         then (L^):=(L^) and (PBoolean(B^.Ptr)^)}
      end;
   Exit(R)
   end;

Function ValPow(A,B:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; L:PBoolean; D:PFloat;
   begin
   New(R); R^.Typ:=A^.Typ; R^.Lev:=CurLev;
   If (A^.Typ = VT_NIL) then begin 
      R^.Ptr:=NIL; Exit(R)
      end else
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      New(I); R^.Ptr:=I; (I^):=PQInt(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (I^):=Trunc(IntPower(I^,PQInt(B^.Ptr)^)) else
      If (B^.Typ = VT_FLO)
         then (I^):=Trunc(Power(I^,PFloat(B^.Ptr)^)) else
      If (B^.Typ = VT_STR)
         then (I^):=Trunc(IntPower(I^,StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO)
         then If (Not PBoolean(B^.Ptr)^) then (I^):=1
      end else
   If (A^.Typ = VT_FLO) then begin
      New(D); R^.Ptr:=D; (D^):=PFloat(A^.Ptr)^;
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) 
         then (D^):=Power(D^,PQInt(B^.Ptr)^) else
      If (B^.Typ = VT_FLO)
         then (D^):=Power(D^,PFloat(B^.Ptr)^) else
      If (B^.Typ = VT_STR)
         then (D^):=Power(D^,StrToReal(PStr(B^.Ptr)^)) else
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
         then (S^):=RealToStr(PFloat(B^.Ptr)^,RealPrec) else
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
         then (L^):=(L^) and (PFloat(B^.Ptr)^<>0) else
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
      Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) = (PFloat(B^.Ptr)^))) else
   If (A^.Typ = VT_STR) then
      Exit(NewVal(VT_BOO, (PStr(A^.Ptr)^) = (PStr(B^.Ptr)^))) else
   If (A^.Typ = VT_BOO) then
      Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = (PBool(B^.Ptr)^))) else
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(NewVal(VT_BOO,True)) else
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
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, Trunc(PFloat(A^.Ptr)^) = (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) = (PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) = StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, Trunc(PFloat(A^.Ptr)^) = BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) = (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) = (PFloat(B^.Ptr)^))) else
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
         Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = (PFloat(B^.Ptr)^ <> 0.0))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = StrToBoolDef(PStr(B^.Ptr)^,FALSE))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PBool(A^.Ptr)^) = (PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(NewVal(VT_BOO,True))
      else
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
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) > Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) > StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) > BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) > TFloat(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) > (PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) > StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) > TFloat(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) > (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) > (PFloat(B^.Ptr)^))) else
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
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) > Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) > BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) > BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(NewVal(VT_BOO,False))
      else
      Exit(NewVal(VT_BOO,False))
   end;

Function ValGe(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) >= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) >= TFloat(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) >= (PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) >= StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) >= TFloat(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) >= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) >= (PFloat(B^.Ptr)^))) else
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
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) >= Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) >= BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) >= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(NewVal(VT_BOO,True))
      else
      Exit(NewVal(VT_BOO,False))
   end;

Function ValLt(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) < BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) < TFloat(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) < (PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) < StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) < TFloat(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) < (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) < (PFloat(B^.Ptr)^))) else
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
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) < Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) < BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) < BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(NewVal(VT_BOO,False))
      else
      Exit(NewVal(VT_BOO,False))
   end;

Function ValLe(A,B:PValue):PValue;
   begin
   If (A^.Typ >= VT_INT) and (A^.Typ <= VT_BIN) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= StrToNum(PStr(B^.Ptr)^,A^.Typ))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PQInt(A^.Ptr)^) <= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_FLO) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) <= TFloat(PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) <= (PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) <= StrToReal(PStr(B^.Ptr)^))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, (PFloat(A^.Ptr)^) <= TFloat(BoolToInt(PBool(B^.Ptr)^)))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else
   If (A^.Typ = VT_STR) then begin
      If (B^.Typ >= VT_INT) and (B^.Typ <= VT_BIN) then
         Exit(NewVal(VT_BOO, StrToNum(PStr(A^.Ptr)^,B^.Typ) <= (PQInt(B^.Ptr)^))) else
      If (B^.Typ = VT_FLO) then
         Exit(NewVal(VT_BOO, StrToReal(PStr(A^.Ptr)^) <= (PFloat(B^.Ptr)^))) else
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
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) <= Trunc(PFloat(B^.Ptr)^))) else
      If (B^.Typ = VT_STR) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) <= BoolToInt(StrToBoolDef(PStr(B^.Ptr)^,FALSE)))) else
      If (B^.Typ = VT_BOO) then
         Exit(NewVal(VT_BOO, BoolToInt(PBool(A^.Ptr)^) <= BoolToInt(PBool(B^.Ptr)^))) else
         {else} Exit(NewVal(VT_BOO, False))
      end else // all other, non-comparable types
   If (A^.Typ = VT_NIL) and (B^.Typ = VT_NIL) then Exit(NewVal(VT_BOO,False))
      else
      Exit(NewVal(VT_BOO,False))
   end;

Function NilVal():PValue;
   Var R:PValue;
   begin
   New(R); R^.Typ:=VT_NIL; R^.Ptr:=NIL; R^.Lev:=CurLev;
   Exit(R)
   end;

Procedure FreeVal(Var Val:PValue);
   Var Arr:PValTree; AEA:TValTree.TEntryArr;
       Dic:PValTrie; DEA:TValTrie.TEntryArr;
       C:LongWord;
   begin
   Case Val^.Typ of
      VT_NIL: ;
      VT_INT: Dispose(PQInt(Val^.Ptr));
      VT_HEX: Dispose(PQInt(Val^.Ptr));
      VT_OCT: Dispose(PQInt(Val^.Ptr));
      VT_BIN: Dispose(PQInt(Val^.Ptr));
      VT_FLO: Dispose(PFloat(Val^.Ptr));
      VT_BOO: Dispose(PBoolean(Val^.Ptr));
      VT_STR: Dispose(PAnsiString(Val^.Ptr));
      VT_ARR: begin
              Arr:=PValTree(Val^.Ptr);
              If (Not Arr^.Empty()) then begin
                 AEA := Arr^.ToArray();
                 For C:=Low(AEA) to High(AEA) do
                     If (AEA[C].Val^.Lev >= CurLev) then FreeVal(AEA[C].Val)
                 end;
              Dispose(Arr, Destroy())
              end;
      VT_DIC: begin
              Dic:=PValTrie(Val^.Ptr);
              If (Not Dic^.Empty()) then begin
                 DEA := Dic^.ToArray();
                 For C:=Low(DEA) to High(DEA) do
                     If (DEA[C].Val^.Lev >= CurLev) then FreeVal(DEA[C].Val)
                 end;
              Dispose(Dic, Destroy())
              end;
      end;
   Dispose(Val)
   end;

Function  EmptyVal(T:TValueType):PValue;
   Var R:PValue; I:PQInt; S:PStr; D:PFloat; B:PBoolean; Arr:PValTree; Dic:PValTrie; Fil:PFileVal;
   begin
   New(R); R^.Lev:=CurLev; R^.Typ:=T;
   Case T of 
      VT_NIL: R^.Ptr := NIL;
      VT_INT: begin New(I); (I^):=0;          R^.Ptr:=I end;
      VT_HEX: begin New(I); (I^):=0;          R^.Ptr:=I end;
      VT_OCT: begin New(I); (I^):=0;          R^.Ptr:=I end;
      VT_BIN: begin New(I); (I^):=0;          R^.Ptr:=I end;
      VT_FLO: begin New(D); (D^):=0.0;        R^.Ptr:=D end;
      VT_STR: begin New(S); (S^):='';         R^.Ptr:=S end;
      VT_BOO: begin New(B); (B^):=False;      R^.Ptr:=B end;
      VT_ARR: begin New(Arr,Create(Alfa));    R^.Ptr:=Arr end;
      VT_DIC: begin New(Dic,Create('!','~')); R^.Ptr:=Dic end;
      VT_FIL: begin New(Fil); Fil^.arw:='u';
                  Fil^.Pth:=''; Fil^.Buf:=''; R^.Ptr:=Fil end;
      else R^.Ptr:=NIL
      end;
   Exit(R)
   end;

Function  CopyTyp(V:PValue):PValue;
   begin Exit(EmptyVal(V^.Typ)) end;

Function  CopyVal(V:PValue):PValue;
   Var R:PValue; I:PQInt; S:PStr; D:PFloat; B:PBoolean;
       NArr, OArr : PValTree; NDic, ODic : PValTrie;
       AEA : TValTree.TEntryArr; DEA : TValTrie.TEntryArr;
       C:LongWord;
   begin
   New(R); R^.Lev:=CurLev; R^.Typ:=V^.Typ;
   Case V^.Typ of 
      VT_INT: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_HEX: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_OCT: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_BIN: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_FLO: begin New(D); (D^):=PFloat(V^.Ptr)^; R^.Ptr:=D end;
      VT_STR: begin New(S); (S^):=PStr(V^.Ptr)^; R^.Ptr:=S end;
      VT_BOO: begin New(B); (B^):=PBool(V^.Ptr)^; R^.Ptr:=B end;
      VT_ARR: begin
              New(NArr,Create(Alfa)); R^.Ptr:=NArr; OArr:=PValTree(V^.Ptr);
              If (Not OArr^.Empty()) then begin
                  AEA := OArr^.ToArray();
                  For C:=Low(AEA) to High(AEA) do
                      If (AEA[C].Val^.Lev >= V^.Lev)
                         then NArr^.SetVal(AEA[C].Key, CopyVal(AEA[C].Val))
                         else NArr^.SetVal(AEA[C].Key, AEA[C].Val)
              end end;
      VT_DIC: begin
              New(NDic,Create('!','~')); R^.Ptr:=NDic; ODic:=PValTrie(V^.Ptr);
              If (Not ODic^.Empty()) then begin
                  DEA := ODic^.ToArray();
                  For C:=Low(DEA) to High(DEA) do
                      If (DEA[C].Val^.Lev >= V^.Lev)
                         then NDic^.SetVal(DEA[C].Key, CopyVal(DEA[C].Val))
                         else NDic^.SetVal(DEA[C].Key, DEA[C].Val)
              end end;
      else R^.Ptr:=NIL
      end;
   Exit(R)
   end;

Procedure SwapPtrs(A,B:PValue);
   Var P:Pointer; T:TValueType; C:LongWord;
       Arr:PValTree; AEA:TValTree.TEntryArr;
       Dic:PValTrie; DEA:TValTrie.TEntryArr;
   begin
   P:=A^.Ptr; T:=A^.Typ;
   A^.Ptr:=B^.Ptr; A^.Typ:=B^.Typ;
   B^.Ptr:=P; B^.Typ:=T;
   If (A^.Typ = VT_ARR) then begin
      Arr := A^.Ptr;
      If (Not Arr^.Empty()) then begin
         AEA:=Arr^.ToArray();
         For C:=Low(AEA) to High(AEA) do
             If (AEA[C].Val^.Lev > A^.Lev) then AEA[C].Val^.Lev := A^.Lev
      end end else
   If (A^.Typ = VT_DIC) then begin
      Dic := A^.Ptr;
      If (Not Dic^.Empty()) then begin
         DEA:=Dic^.ToArray();
         For C:=Low(DEA) to High(DEA) do
             If (DEA[C].Val^.Lev > A^.Lev) then DEA[C].Val^.Lev := A^.Lev
      end end else
   end;

Function NewVal(T:TValueType;V:TFloat):PValue;
   Var R:PValue; P:PFloat;
   begin
   New(R); R^.Typ:=VT_FLO; New(P); R^.Ptr:=P; R^.Lev:=CurLev;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:Int64):PValue;
   Var R:PValue; P:PQInt;
   begin
   New(R); R^.Typ:=T; New(P); R^.Ptr:=P; R^.Lev:=CurLev;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:Bool):PValue;
   Var R:PValue; P:PBool;
   begin
   New(R); R^.Typ:=VT_BOO; New(P); R^.Ptr:=P; R^.Lev:=CurLev;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:TStr):PValue;
   Var R:PValue; P:PStr;
   begin
   New(R); R^.Typ:=VT_STR; New(P); R^.Ptr:=P; R^.Lev:=CurLev;
   P^:=V; Exit(R)
   end;

Function NewVal(T:TValueType):PValue;
   Var R:PValue; Arr : PValTree; Dic : PValTrie;
   begin
   New(R); R^.Typ := T; R^.Lev := CurLev;
   Case T of
      VT_ARR: begin New(Arr,Create(Alfa)); R^.Ptr := Arr end;
      VT_DIC: begin New(Dic,Create('!','~')); R^.Ptr := Dic end;
         else begin R^.Typ := VT_NIL; R^.Ptr := NIL end
      end;
   Exit(R)
   end;


Function Exv(DoReturn:Boolean):PValue; Inline;
   begin If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;

end.
