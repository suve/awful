unit values;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses SysUtils, Trie, NumTrie;

Var RealPrec : LongWord = 3;
    RealForm : TFloatFormat = ffFixed;
    CurLev : LongWord = 0;

Type TValueType = (
     VT_NIL, VT_NEW,
     VT_PTR,
     VT_BOO,
     VT_INT, VT_HEX, VT_OCT, VT_BIN, VT_FLO,
     VT_STR, VT_UTF,
     VT_ARR, VT_DIC,
     VT_FIL);

Const VT_LOG = VT_BOO; VT_DICT = VT_DIC;

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
     
     PArray = ^TArray;
     TArray = specialize GenericNumTrie<PValue>;
     
     PArr = PArray; TArr = TArray;
     
     PDict = ^TDict;
     TDict = specialize GenericTrie<PValue>;
     
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
Function FloatToStr(Val:TFloat):TStr;

Function BoolToInt(B:Bool):LongWord; Inline;

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

Function  NilVal():PValue;
Procedure FreeVal(Val:PValue);
Function  EmptyVal(T:TValueType):PValue;
Function  CopyTyp(V:PValue):PValue;
Function  CopyVal(V:PValue):PValue;
Function  CopyVal(V:PValue;Lv:LongWord):PValue;
Procedure SwapPtrs(A,B:PValue);
Procedure SetValLev(V:PValue;Lv:LongWord);
Procedure SetValMaxLev(V:PValue;Lv:LongWord);

Function NewVal(T:TValueType;V:TFloat):PValue;
Function NewVal(T:TValueType;V:Int64):PValue;
Function NewVal(T:TValueType;V:Bool):PValue;
Function NewVal(T:TValueType;V:TStr):PValue;
Function NewVal(T:TValueType):PValue;

Function Exv(DoReturn:Boolean):PValue; Inline;

implementation
   uses Math; 

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

Function FloatToStr(Val:TFloat):TStr;
   begin Exit(FloatToStrF(Val, RealForm, RealPrec, RealPrec)) end;

Function StrToInt(Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; Res:QInt;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Res:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#57) then
          Res:=(Res*10)+Ord(Str[P])-48 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
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
          Res:=(Res shl 4)+Ord(Str[P])-87 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
   If Plus then Exit(Res) else Exit(-Res)
   end;

Function StrToOct(Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; Res:QInt;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Res:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#55) then
          Res:=(Res shl 3)+Ord(Str[P])-48 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
   If Plus then Exit(Res) else Exit(-Res)
   end;

Function StrToBin(Str:TStr):QInt;
   Var Plus:Boolean; P:LongWord; Res:QInt;
   begin
   If (Length(Str)=0) then Exit(0);
   Plus:=(Str[1]<>'-'); Res:=0;
   For P:=1 to Length(Str) do
       If (Str[P]>=#48) and (Str[P]<=#49) then
          Res:=(Res shl 1)+Ord(Str[P])-48 else
       If (Str[P]='.') or (Str[P]=',') then
          Break;
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
      VT_ARR: P^:=PArray(V^.Ptr)^.Count;
      VT_DIC: P^:=PDict(V^.Ptr)^.Count;
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
      VT_ARR: P^:=PArray(V^.Ptr)^.Count;
      VT_DIC: P^:=PDict(V^.Ptr)^.Count;
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
      VT_ARR: P^:=PArray(V^.Ptr)^.Count;
      VT_DIC: P^:=PDict(V^.Ptr)^.Count;
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
      VT_ARR: P^:=PArray(V^.Ptr)^.Count;
      VT_DIC: P^:=PDict(V^.Ptr)^.Count;
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
      VT_ARR: P^:=PArray(V^.Ptr)^.Count;
      VT_DIC: P^:=PDict(V^.Ptr)^.Count;
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
      VT_ARR: P^:=Not PArray(V^.Ptr)^.Empty();
      VT_DIC: P^:=Not PDict(V^.Ptr)^.Empty();
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
      VT_FLO: P^:=FloatToStr(PFloat(V^.Ptr)^);
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE)
                 then P^:='TRUE' else P^:='FALSE';
      VT_STR: P^:=PStr(V^.Ptr)^;
      VT_ARR: P^:='array('+IntToStr(PDict(V^.Ptr)^.Count)+')';
      VT_DIC: P^:='dict('+IntToStr(PDict(V^.Ptr)^.Count)+')';
      else P^:='';
      end;
   Exit(R)
   end;

Function NilVal():PValue;
   Var R:PValue;
   begin
   New(R); R^.Typ:=VT_NIL; R^.Ptr:=NIL; R^.Lev:=CurLev;
   Exit(R)
   end;

Procedure FreeVal(Val:PValue);
   Var Arr:PArray; AEA:TArray.TEntryArr;
       Dic:PDict; DEA:TDict.TEntryArr;
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
              Arr:=PArray(Val^.Ptr);
              If (Not Arr^.Empty()) then begin
                 AEA := Arr^.ToArray();
                 For C:=Low(AEA) to High(AEA) do
                     If (AEA[C].Val^.Lev >= CurLev) then FreeVal(AEA[C].Val)
                 end;
              Dispose(Arr, Destroy())
              end;
      VT_DIC: begin
              Dic:=PDict(Val^.Ptr);
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
   Var R:PValue; I:PQInt; S:PStr; D:PFloat; B:PBoolean; Arr:PArray; Dic:PDict; Fil:PFileVal;
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
      VT_ARR: begin New(Arr,Create());    R^.Ptr:=Arr end;
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
   begin Exit(CopyVal(V, CurLev)) end;

Function  CopyVal(V:PValue;Lv:LongWord):PValue;
   Var R:PValue; I:PQInt; S:PStr; D:PFloat; B:PBoolean;
       NArr, OArr : PArray; NDic, ODic : PDict;
       AEA : TArray.TEntryArr; DEA : TDict.TEntryArr;
       C:LongWord;
   begin
   New(R); R^.Lev:=Lv; R^.Typ:=V^.Typ;
   Case V^.Typ of 
      VT_INT: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_HEX: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_OCT: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_BIN: begin New(I); (I^):=PQInt(V^.Ptr)^; R^.Ptr:=I end;
      VT_FLO: begin New(D); (D^):=PFloat(V^.Ptr)^; R^.Ptr:=D end;
      VT_STR: begin New(S); (S^):=PStr(V^.Ptr)^; R^.Ptr:=S end;
      VT_BOO: begin New(B); (B^):=PBool(V^.Ptr)^; R^.Ptr:=B end;
      VT_ARR: begin
              New(NArr,Create()); R^.Ptr:=NArr; OArr:=PArray(V^.Ptr);
              If (Not OArr^.Empty()) then begin
                  AEA := OArr^.ToArray();
                  For C:=Low(AEA) to High(AEA) do
                      If (AEA[C].Val^.Lev >= Lv)
                         then NArr^.SetVal(AEA[C].Key, CopyVal(AEA[C].Val, Lv))
                         else NArr^.SetVal(AEA[C].Key, AEA[C].Val)
              end end;
      VT_DIC: begin
              New(NDic,Create('!','~')); R^.Ptr:=NDic; ODic:=PDict(V^.Ptr);
              If (Not ODic^.Empty()) then begin
                  DEA := ODic^.ToArray();
                  For C:=Low(DEA) to High(DEA) do
                      If (DEA[C].Val^.Lev >= Lv)
                         then NDic^.SetVal(DEA[C].Key, CopyVal(DEA[C].Val, Lv))
                         else NDic^.SetVal(DEA[C].Key, DEA[C].Val)
              end end;
      else R^.Ptr:=NIL
      end;
   Exit(R)
   end;

Procedure SetValLev(V:PValue;Lv:LongWord);
   Var C:LongWord;
       Arr:PArray; AEA:TArray.TEntryArr;
       Dic:PDict; DEA:TDict.TEntryArr;
   begin
   V^.Lev := Lv;
   If (V^.Typ = VT_ARR) then begin
      Arr:=PArray(V^.Ptr); If (Arr^.Empty()) then Exit();
      AEA:=Arr^.ToArray();
      For C:=Low(AEA) to High(AEA) do
          SetValLev(AEA[C].Val, Lv)
      end else
   If (V^.Typ = VT_DIC) then begin
      Dic:=PDict(V^.Ptr); If (Dic^.Empty()) then Exit();
      DEA:=Dic^.ToArray();
      For C:=Low(DEA) to High(DEA) do
          SetValLev(DEA[C].Val, Lv)
      end
   end;

Procedure SetValMaxLev(V:PValue;Lv:LongWord);
   Var C:LongWord;
       Arr:PArray; AEA:TArray.TEntryArr;
       Dic:PDict; DEA:TDict.TEntryArr;
   begin
   If (V^.Lev > Lv) then V^.Lev := Lv;
   If (V^.Typ = VT_ARR) then begin
      Arr:=PArray(V^.Ptr); If (Arr^.Empty()) then Exit();
      AEA:=Arr^.ToArray();
      For C:=Low(AEA) to High(AEA) do
          If (AEA[C].Val^.Lev >= Lv) then SetValMaxLev(AEA[C].Val, Lv)
      end else
   If (V^.Typ = VT_DIC) then begin
      Dic:=PDict(V^.Ptr); If (Dic^.Empty()) then Exit();
      DEA:=Dic^.ToArray();
      For C:=Low(DEA) to High(DEA) do
          If (DEA[C].Val^.Lev > Lv) then SetValMaxLev(DEA[C].Val, Lv)
      end
   end;

Procedure SwapPtrs(A,B:PValue);
   Var P:Pointer; T:TValueType; //C:LongWord;
   begin
   P:=A^.Ptr; T:=A^.Typ;
   A^.Ptr:=B^.Ptr; A^.Typ:=B^.Typ;
   B^.Ptr:=P; B^.Typ:=T;
   If (A^.Typ = VT_ARR) or (A^.Typ = VT_DIC)
      then SetValMaxLev(A, A^.Lev)
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
   Var R:PValue; Arr : PArray; Dic : PDict;
   begin
   New(R); R^.Typ := T; R^.Lev := CurLev;
   Case T of
      VT_ARR: begin New(Arr,Create()); R^.Ptr := Arr end;
      VT_DIC: begin New(Dic,Create('!','~')); R^.Ptr := Dic end;
         else begin R^.Typ := VT_NIL; R^.Ptr := NIL end
      end;
   Exit(R)
   end;


Function Exv(DoReturn:Boolean):PValue; Inline;
   begin If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;

end.
