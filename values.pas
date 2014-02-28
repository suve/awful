unit values;

{$INCLUDE defines.inc}

interface
   uses SysUtils, NumPtrTrie, DynTrie, DynPtrTrie, UnicodeStrings;

Var RealPrec : LongWord = 3;
    RealForm : TFloatFormat = ffFixed;
    CurLev : LongWord = 0;

Type TValueType = (
     VT_NIL, VT_NEW,
     VT_PTR,
     VT_BOO,
     VT_INT, VT_HEX, VT_OCT, VT_BIN,
     VT_FLO,
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
     
     PUTF = PUTF8String;
     TUTF = TUTF8String;
     
     PBool = ^TBool;
     TBool = Boolean;
     
     PFloat = ^TFloat;
     TFloat = ValReal;
     
     PArray = ^TArray;
     TArray = specialize GenericNumPtrTrie<PValue>;
     
     PArr = PArray; TArr = TArray;
     
     PDict = ^TDict;
     TDict = specialize GenericDynPtrTrie<PValue>;
     
     PValTrie = ^TValTrie;
     TValTrie = specialize GenericDynPtrTrie<PValue>;
     
     TArrPVal = Array of PValue;
     PArrPVal = ^TArrPVal;
     
Const RETURN_VALUE_YES = True; RETURN_VALUE_NO = False;
      REF_MODIF = True; REF_CONST = False;
      CASE_UPPER = True; CASE_LOWER = False;

Type TBuiltIn = Function(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
     
     TFunc = record
        Ptr : PtrUInt;
        Usr : Boolean;
        Ref : Boolean
        end;
     
     PFunTrie = ^TFunTrie;
     TFunTrie = specialize GenericDynTrie<TFunc>;

Function NumToStr(Int:QInt;Base:LongWord;Digs:LongWord=0):TStr; 
Function IntToStr(Int:QInt;Digs:LongWord=0):TStr; 
Function HexToStr(Int:QInt;Digs:LongWord=0):TStr; 
Function OctToStr(Int:QInt;Digs:LongWord=0):TStr; 
Function BinToStr(Int:QInt;Digs:LongWord=0):TStr; 
//Function RealToStr(Val:Extended;Prec:LongWord):TStr;
Function FloatToStr(Val:TFloat):TStr;

Procedure HexCase(Upper:Boolean);
Function  HexCase():Boolean;

Function IntBase(T:TValueType):LongInt; Inline;
Function BoolToInt(B:TBool):LongWord; Inline;

Function StrToInt(Const Str:TStr):QInt;
Function StrToHex(Const Str:TStr):QInt;
Function StrToOct(Const Str:TStr):QInt;
Function StrToBin(Const Str:TStr):QInt;
Function StrToNum(Const Str:TStr;Tp:TValueType):QInt;
Function StrToReal(Str:TStr):TFloat;

Function ValAsBin(Const V:PValue):QInt;
Function ValAsOct(Const V:PValue):QInt;
Function ValAsInt(Const V:PValue):QInt;
Function ValAsHex(Const V:PValue):QInt;
Function ValAsFlo(Const V:PValue):TFloat;
Function ValAsBoo(Const V:PValue):TBool;
Function ValAsStr(Const V:PValue):TStr;

Function ValToInt(Const V:PValue):PValue;
Function ValToHex(Const V:PValue):PValue;
Function ValToOct(Const V:PValue):PValue;
Function ValToBin(Const V:PValue):PValue;
Function ValToFlo(Const V:PValue):PValue;
Function ValToBoo(Const V:PValue):PValue;
Function ValToStr(Const V:PValue):PValue;

Function  NilVal():PValue;
Procedure FreeVal(Const Val:PValue);
Procedure DestroyVal(Const Val:PValue);
Procedure AnnihilateVal(Const Val:PValue);
Function  EmptyVal(T:TValueType):PValue;
Function  CopyTyp(Const V:PValue):PValue;
Function  CopyVal(Const V:PValue):PValue;
Function  CopyVal(Const V:PValue;Lv:LongWord):PValue;
Procedure SwapPtrs(Const A,B:PValue);
Procedure SetValLev(Const V:PValue;Lv:LongWord);
Procedure SetValMaxLev(Const V:PValue;Lv:LongWord);

Function NewVal(T:TValueType;V:TFloat):PValue;
Function NewVal(T:TValueType;V:Int64):PValue;
Function NewVal(T:TValueType;V:TBool):PValue;
Function NewVal(T:TValueType;V:TStr):PValue;
Function NewVal(T:TValueType;V:PUTF):PValue;
Function NewVal(T:TValueType):PValue;

Function Exv(DoReturn:Boolean):PValue; Inline;

Procedure SpareVars_Prepare();
Procedure SpareVars_Destroy();

Function MkFunc(Fun:TBuiltIn; RefMod : Boolean = REF_CONST):TFunc;
Function MkFunc(UsrID:LongWord):TFunc;


implementation
   uses Math; 

Const SpareVarsPerType = SizeOf(NativeInt)*8;

Type TSpareArray = record
        Arr : Array[1..SpareVarsPerType] of PValue;
        Num : LongWord;
        end;

Var SpareVars : Array[TValueType] of TSpareArray;

Var Sys16Dig:Array[0..15] of Char=(
      '0','1','2','3','4','5','6','7',
      '8','9','A','B','C','D','E','F');

Procedure HexCase(Upper:Boolean);
   Var C,Off:LongWord;
   begin
   If (Upper) then Off := 65 - 10 else Off := 97 - 10;
   For C:=10 to 15 do Sys16Dig[C]:=Chr(Off+C)
   end;

Function HexCase():Boolean;
   begin Exit(Sys16Dig[10] = 'A') end;

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

(*
Function RealToStr(Val:Extended;Prec:LongWord):TStr;
   Var Res:TStr;
   begin 
   if Val<0 then Res:='-' else Res:=''; Val:=Abs(Val);
   Res+=NumToStr(Trunc(Val),10); Val:=(Frac(Val) * IntPower(10,Prec)); 
   If (Val<1) then Exit(Res+'.'+StringOfChar('0',Prec)); 
   Res+='.'; Res+=NumToStr(Trunc(Val),10,Prec);
   Exit(Res) end;
*)

Function FloatToStr(Val:TFloat):TStr;
   begin Exit(FloatToStrF(Val, RealForm, RealPrec, RealPrec)) end;

Function StrToInt(Const Str:TStr):QInt;
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

Function StrToHex(Const Str:TStr):QInt;
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

Function StrToOct(Const Str:TStr):QInt;
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

Function StrToBin(Const Str:TStr):QInt;
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

Function StrToNum(Const Str:TStr;Tp:TValueType):QInt;
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

Function IntBase(T:TValueType):LongInt; Inline;
   begin Case T of
      VT_BIN: IntBase :=  2;
      VT_OCT: IntBase :=  8;
      VT_INT: IntBase := 10;
      VT_HEX: IntBase := 16;
         else IntBase := 10
   end end;

Function BoolToInt(B:TBool):LongWord; Inline;
   begin If (B) then Exit(1) else Exit(0) end;

Function CreateVal(T:TValueType):PValue;
   Var R:PValue; I:PQInt; S:PStr; D:PFloat; B:PBoolean;
       Utf:PUTF; Arr:PArray; Dic:PDict; Fil:PFileVal;
   begin
   If (SpareVars[T].Num > 0) then begin
      R := SpareVars[T].Arr[SpareVars[T].Num];
      SpareVars[T].Num -= 1
      end else begin
      New(R); R^.Typ:=T;
      Case T of 
         VT_NIL: R^.Ptr := NIL;
         VT_INT .. VT_BIN:
                 begin New(I);            R^.Ptr:=I   end;
         VT_FLO: begin New(D);            R^.Ptr:=D   end;
         VT_BOO: begin New(B);            R^.Ptr:=B   end;
         VT_STR: begin New(S);            R^.Ptr:=S   end;
         VT_UTF: begin New(Utf,Create()); R^.Ptr:=Utf end;
         VT_ARR: begin New(Arr,Create()); R^.Ptr:=Arr end;
         VT_DIC: begin New(Dic,Create()); R^.Ptr:=Dic end;
         VT_FIL: begin New(Fil);          R^.Ptr:=Fil end;
                  else R^.Ptr:=NIL
      end end;
   Exit(R)
   end;

Function ValAsInt(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToInt(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF8String(V^.Ptr)^.ToInt(10));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      else Exit(0)
   end end;

Function ValAsHex(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToHex(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF8String(V^.Ptr)^.ToInt(16));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      else Exit(0)
   end end;

Function ValAsOct(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToOct(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF8String(V^.Ptr)^.ToInt(8));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      else Exit(0)
   end end;

Function ValAsBin(Const V:PValue):QInt;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(Trunc(PFloat(V^.Ptr)^));
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToBin(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF8String(V^.Ptr)^.ToInt(2));
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      else Exit(0)
   end end;

Function ValAsFlo(Const V:PValue):TFloat;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit(PQInt(V^.Ptr)^);
      VT_FLO: Exit(PFloat(V^.Ptr)^);
      VT_BOO: Exit(BoolToInt(PBool(V^.Ptr)^));
      VT_STR: Exit(StrToReal(PStr(V^.Ptr)^));
      VT_UTF: Exit(PUTF8String(V^.Ptr)^.ToFloat());
      VT_ARR: Exit(PArray(V^.Ptr)^.Count);
      VT_DIC: Exit(PDict(V^.Ptr)^.Count);
      else Exit(0.0)
   end end;

Function ValAsBoo(Const V:PValue):TBool;
   begin
   Case V^.Typ of
      VT_INT .. VT_BIN: Exit((PQInt(V^.Ptr)^)<>0);
      VT_FLO: Exit(Abs(PFloat(V^.Ptr)^)>=1.0);
      VT_BOO: Exit(PBoolean(V^.Ptr)^);
      VT_STR: Exit(StrToBoolDef(PStr(V^.Ptr)^,FALSE));
      VT_UTF: Exit(StrToBoolDef(PUTF(V^.Ptr)^.ToAnsiString,FALSE));
      VT_ARR: Exit(Not PArray(V^.Ptr)^.Empty());
      VT_DIC: Exit(Not PDict(V^.Ptr)^.Empty());
      else Exit(False)
   end end;

Function ValAsStr(Const V:PValue):TStr;
   begin
   Case V^.Typ of
      VT_INT: Exit(IntToStr(PQInt(V^.Ptr)^));
      VT_HEX: Exit(HexToStr(PQInt(V^.Ptr)^));
      VT_OCT: Exit(OctToStr(PQInt(V^.Ptr)^));
      VT_BIN: Exit(BinToStr(PQInt(V^.Ptr)^));
      VT_FLO: Exit(FloatToStr(PFloat(V^.Ptr)^));
      VT_BOO: If (PBoolean(V^.Ptr)^ = TRUE)
                 then Exit('TRUE') else Exit('FALSE');
      VT_STR: Exit(PStr(V^.Ptr)^);
      VT_UTF: Exit(PUTF(V^.Ptr)^.ToAnsiString);
      VT_ARR: Exit('array('+IntToStr(PArray(V^.Ptr)^.Count)+')');
      VT_DIC: Exit('dict('+IntToStr(PDict(V^.Ptr)^.Count)+')');
      else Exit('')
   end end;

Function ValToInt(Const V:PValue):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_INT); R^.Lev:=CurLev;
   PQInt(R^.Ptr)^:=ValAsInt(V); 
   Exit(R)
   end;

Function ValToHex(Const V:PValue):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_HEX); R^.Lev:=CurLev;
   PQInt(R^.Ptr)^:=ValAsHex(V);
   Exit(R)
   end;

Function ValToOct(Const V:PValue):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_OCT); R^.Lev:=CurLev;
   PQInt(R^.Ptr)^:=ValAsOct(V); 
   Exit(R)
   end;

Function ValToBin(Const V:PValue):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_BIN); R^.Lev:=CurLev;
   PQInt(R^.Ptr)^:=ValAsBin(V);
   Exit(R)
   end;

Function ValToFlo(Const V:PValue):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_FLO); R^.Lev:=CurLev;
   PFloat(R^.Ptr)^:=ValAsFlo(V);
   Exit(R)
   end;

Function ValToBoo(Const V:PValue):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_BOO); R^.Lev:=CurLev;
   PBool(R^.Ptr)^:=ValAsBoo(V);
   Exit(R)
   end;

Function ValToStr(Const V:PValue):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_STR); R^.Lev:=CurLev;
   PStr(R^.Ptr)^:=ValAsStr(V);
   Exit(R)
   end;

Function NilVal():PValue;
   Var R:PValue;
   begin
   R:=CreateVal(VT_NIL); R^.Ptr:=NIL; R^.Lev:=CurLev;
   Exit(R)
   end;

Type TValProc = Procedure(Const V:PValue);

Procedure INLINE_FreeArr(Const Val:PValue;Proc:TValProc); Inline;
   Var Arr:PArray; AEA:TArray.TEntryArr;
       C:LongWord;
   begin
   Arr:=PArray(Val^.Ptr);
   If (Not Arr^.Empty()) then begin
      AEA := Arr^.ToArray(); Arr^.Flush();
      For C:=Low(AEA) to High(AEA) do
          If (AEA[C].Val^.Lev >= CurLev) then Proc(AEA[C].Val)
      end
   end;

Procedure INLINE_FreeDict(Const Val:PValue;Proc:TValProc); Inline;
   Var Dic:PDict; DEA:TDict.TEntryArr;
       C:LongWord;
   begin
   Dic:=PDict(Val^.Ptr);
   If (Not Dic^.Empty()) then begin
      DEA := Dic^.ToArray(); Dic^.Flush();
      For C:=Low(DEA) to High(DEA) do
          If (DEA[C].Val^.Lev >= CurLev) then Proc(DEA[C].Val)
      end
   end;

Procedure FreeVal_Arr(Const Val:PValue);
   begin INLINE_FreeArr(Val,@FreeVal) end;

Procedure FreeVal_Dict(Const Val:PValue);
   begin INLINE_FreeDict(Val,@FreeVal) end;

Procedure DestroyVal_Arr(Const Val:PValue);
   begin
   INLINE_FreeArr(Val,@FreeVal); 
   Dispose(PArr(Val^.Ptr), Destroy())
   end;

Procedure DestroyVal_Dict(Const Val:PValue);
   begin
   INLINE_FreeDict(Val,@FreeVal); 
   Dispose(PDict(Val^.Ptr), Destroy())
   end;

Procedure AnnihilateVal_Arr(Const Val:PValue);
   begin
   INLINE_FreeArr(Val,@AnnihilateVal); 
   Dispose(PArr(Val^.Ptr), Destroy())
   end;

Procedure AnnihilateVal_Dict(Const Val:PValue);
   begin
   INLINE_FreeDict(Val,@AnnihilateVal); 
   Dispose(PDict(Val^.Ptr), Destroy())
   end;

Procedure DestroyVal_INLINE(Const Val:PValue); Inline;
   begin
   Case Val^.Typ of
      VT_NIL: ;
      VT_INT .. VT_BIN: 
              Dispose(PQInt(Val^.Ptr));
      VT_FLO: Dispose(PFloat(Val^.Ptr));
      VT_BOO: Dispose(PBoolean(Val^.Ptr));
      VT_STR: Dispose(PStr(Val^.Ptr));
      VT_UTF: Dispose(PUTF(Val^.Ptr), Destroy());
      VT_ARR: begin FreeVal_Arr(Val);  Dispose(PArr(Val^.Ptr), Destroy())  end;
      VT_DIC: begin FreeVal_Dict(Val); Dispose(PDict(Val^.Ptr), Destroy()) end;
      end;
   Dispose(Val)
   end;

Procedure DestroyVal(Const Val:PValue);
   begin DestroyVal_INLINE(Val) end;

Procedure FreeVal(Const Val:PValue);
   begin
   If (SpareVars[Val^.Typ].Num < SpareVarsPerType) then begin
      If (Val^.Typ = VT_ARR) then FreeVal_Arr(Val) else
      If (Val^.Typ = VT_DIC) then FreeVal_Dict(Val);
      
      SpareVars[Val^.Typ].Num += 1;
      SpareVars[Val^.Typ].Arr[SpareVars[Val^.Typ].Num] := Val
      end else DestroyVal_INLINE(Val)
   end;

Procedure AnnihilateVal(Const Val:PValue);
   begin
   Case Val^.Typ of
      VT_NIL: ;
      VT_INT: Dispose(PQInt(Val^.Ptr));
      VT_HEX: Dispose(PQInt(Val^.Ptr));
      VT_OCT: Dispose(PQInt(Val^.Ptr));
      VT_BIN: Dispose(PQInt(Val^.Ptr));
      VT_FLO: Dispose(PFloat(Val^.Ptr));
      VT_BOO: Dispose(PBoolean(Val^.Ptr));
      VT_STR: Dispose(PStr(Val^.Ptr));
      VT_UTF: Dispose(PUTF(Val^.Ptr),Destroy());
      VT_ARR: AnnihilateVal_Arr(Val); 
      VT_DIC: AnnihilateVal_Dict(Val);
      end;
   Dispose(Val)
   end;
   
Function EmptyVal(T:TValueType):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(T); R^.Lev := CurLev;
   Case T of 
      VT_INT .. VT_BIN:
              PQInt(R^.Ptr)^:=0;
      VT_FLO: PFloat(R^.Ptr)^:=0.0; 
      VT_STR: PStr(R^.Ptr)^:='';
      VT_UTF: PUTF(R^.Ptr)^.Clear();
      VT_BOO: PBool(R^.Ptr)^:=False;
      VT_FIL: begin PFileVal(R^.Ptr)^.arw:='u';
                    PFileVal(R^.Ptr)^.Pth:='';
                    PFileVal(R^.Ptr)^.Buf:=''   end;
      end;
   Exit(R)
   end;

Function  CopyTyp(Const V:PValue):PValue;
   begin Exit(EmptyVal(V^.Typ)) end;

Function  CopyVal(Const V:PValue):PValue;
   begin Exit(CopyVal(V, CurLev)) end;

Procedure CopyVal_Arr(V,R:PValue;Lv:LongWord);
   Var NArr, OArr : PArray; AEA : TArray.TEntryArr; 
       C:LongWord;
   begin
   NArr:=PArray(R^.Ptr); OArr:=PArray(V^.Ptr);
   If (Not OArr^.Empty()) then begin
       AEA := OArr^.ToArray();
       For C:=Low(AEA) to High(AEA) do
           If (AEA[C].Val^.Lev >= Lv)
              then NArr^.SetVal(AEA[C].Key, CopyVal(AEA[C].Val, Lv))
              else NArr^.SetVal(AEA[C].Key, AEA[C].Val)
   end end;

Procedure CopyVal_Dict(V,R:PValue;Lv:LongWord);
   Var NDic, ODic : PDict; DEA : TDict.TEntryArr;
       C:LongWord;
   begin
   NDic:=PDict(R^.Ptr); ODic:=PDict(V^.Ptr);
   If (Not ODic^.Empty()) then begin
       DEA := ODic^.ToArray();
       For C:=Low(DEA) to High(DEA) do
           If (DEA[C].Val^.Lev >= Lv)
              then NDic^.SetVal(DEA[C].Key, CopyVal(DEA[C].Val, Lv))
              else NDic^.SetVal(DEA[C].Key, DEA[C].Val)
   end end;

Function  CopyVal(Const V:PValue;Lv:LongWord):PValue;
   Var R:PValue;
   begin
   R:=CreateVal(V^.Typ); R^.Lev:=Lv;
   Case V^.Typ of 
      VT_INT .. VT_BIN: 
              PQInt(R^.Ptr)^:=PQInt(V^.Ptr)^;
      VT_FLO: PFloat(R^.Ptr)^:=PFloat(V^.Ptr)^;
      VT_STR: PStr(R^.Ptr)^:=PStr(V^.Ptr)^;
      VT_UTF: PUTF(R^.Ptr)^.SetTo(PUTF(V^.Ptr));
      VT_BOO: PBool(R^.Ptr)^:=PBool(V^.Ptr)^;
      VT_ARR: CopyVal_Arr(V,R,Lv);
      VT_DIC: CopyVal_Dict(V,R,Lv);
      end;
   Exit(R)
   end;

Procedure SetValLev(Const V:PValue;Lv:LongWord);
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

Procedure SetValMaxLev(Const V:PValue;Lv:LongWord);
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

Procedure SwapPtrs(Const A,B:PValue);
   Var P:Pointer; T:TValueType; //C:LongWord;
   begin
   P:=A^.Ptr; T:=A^.Typ;
   A^.Ptr:=B^.Ptr; A^.Typ:=B^.Typ;
   B^.Ptr:=P; B^.Typ:=T;
   If (A^.Typ = VT_ARR) or (A^.Typ = VT_DIC)
      then SetValMaxLev(A, A^.Lev)
   end;

Function NewVal(T:TValueType;V:TFloat):PValue;
   Var R:PValue; 
   begin
   R:=CreateVal(T); R^.Lev:=CurLev; PFloat(R^.Ptr)^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:Int64):PValue;
   Var R:PValue; 
   begin
   R:=CreateVal(T); R^.Lev:=CurLev; PQInt(R^.Ptr)^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:TBool):PValue;
   Var R:PValue; 
   begin
   R:=CreateVal(T); R^.Lev:=CurLev; PBool(R^.Ptr)^:=V; Exit(R)
   end;

Function NewVal(T:TValueType;V:TStr):PValue;
   Var R:PValue; 
   begin
   R:=CreateVal(T); R^.Lev:=CurLev;
   If (T = VT_STR) then PStr(R^.Ptr)^:=V
                   else PUTF(R^.Ptr)^.SetTo(V);
   Exit(R)
   end;

Function NewVal(T:TValueType;V:PUTF):PValue;
   Var R:PValue; 
   begin
   R:=CreateVal(T); R^.Lev:=CurLev; R^.Ptr:=V; Exit(R)
   end;

Function NewVal(T:TValueType):PValue;
   Var R:PValue;
   begin 
   R:=CreateVal(T); R^.Lev:=CurLev; Exit(R)
   end;

Function Exv(DoReturn:Boolean):PValue; Inline;
   begin If (DoReturn) then Exit(NilVal()) else Exit(NIL) end;

Procedure SpareVars_Prepare();
   Var T:TValueType;
   begin
   For T:=Low(TValueType) to High(TValueType) do
       SpareVars[T].Num := 0
   end;

Procedure SpareVars_Destroy();
   Var T:TValueType; i:LongInt;
   begin
   For T:=Low(TValueType) to High(TValueType) do
       For i:=1 to SpareVars[T].Num do
           AnnihilateVal(SpareVars[T].Arr[i])
   end;

Function MkFunc(Fun:TBuiltIn; RefMod : Boolean = REF_CONST):TFunc;
   begin
   Result.Ptr := PtrUInt(Fun);
   Result.Ref := RefMod;
   Result.Usr := False
   end;

Function MkFunc(UsrID:LongWord):TFunc;
   begin
   Result.Ptr := UsrID;
   Result.Ref := REF_MODIF;
   Result.Usr := True
   end;

end.
