unit values;

{$INCLUDE defines.inc}

interface
   uses SysUtils, NumPtrTrie, DynPtrTrie, UnicodeStrings;

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
     
     PFuncInfo = ^TFuncInfo;
     TFuncInfo = record
        Ptr : PtrUInt;
        Usr : Boolean;
        Ref : Boolean
        end;
     
     PFunTrie = ^TFunTrie;
     TFunTrie = specialize GenericDynPtrTrie<PFuncInfo>;

Procedure FreeVal(Const Val:PValue);
Procedure DestroyVal(Const Val:PValue);
Procedure AnnihilateVal(Const Val:PValue);

Function  CreateVal(Const T:TValueType):PValue;
Function  EmptyVal(Const T:TValueType):PValue;
Function  NilVal():PValue;

Function  CopyTyp(Const V:PValue):PValue;
Function  CopyVal(Const V:PValue):PValue;
Function  CopyVal(Const V:PValue;Const Lv:LongWord):PValue;

Procedure SwapPtrs(Const A,B:PValue);
Procedure SetValLev(Const V:PValue;Const Lv:LongWord);
Procedure SetValMaxLev(Const V:PValue;Const Lv:LongWord);

Function NewVal(Const T:TValueType; Const V:Pointer):PValue;
Function NewVal(Const T:TValueType; Const V:TFloat):PValue;
Function NewVal(Const T:TValueType; Const V:Int64):PValue;
Function NewVal(Const T:TValueType; Const V:TBool):PValue;
Function NewVal(Const T:TValueType; Const V:TStr):PValue;
Function NewVal(Const T:TValueType):PValue;

Function Exv(DoReturn:Boolean):PValue; Inline;

Procedure SpareVars_Prepare();
Procedure SpareVars_Destroy();

Function MkFunc(Const Fun:TBuiltIn; Const RefMod : Boolean = REF_CONST):PFuncInfo; Inline;
Function MkFunc(Const UsrID:LongWord):PFuncInfo; Inline;
Procedure DisposeFunc(Const Func:PFuncInfo);

Procedure SetFuncInfo(Var FuIn:TFuncInfo; Const FuncAddr:TBuiltin; Const RefMod : Boolean); Inline;


implementation

Const SpareVarsPerType = SizeOf(NativeInt)*8;

Type TSpareArray = record
        Arr : Array[1..SpareVarsPerType] of PValue;
        Num : LongWord;
        end;

Var SpareVars : Array[TValueType] of TSpareArray;

Function CreateVal(Const T:TValueType):PValue;
   Var I:PQInt; S:PStr; D:PFloat; B:PBoolean;
       Utf:PUTF; Arr:PArray; Dic:PDict;
   begin
   If (SpareVars[T].Num > 0) then begin
      Result := SpareVars[T].Arr[SpareVars[T].Num];
      SpareVars[T].Num -= 1
      end else begin
      New(Result); Result^.Typ:=T;
      Case T of 
         VT_NIL, VT_FIL:
            Result^.Ptr := NIL;
         
         VT_INT .. VT_BIN:
            begin New(I); Result^.Ptr:=I   end;
                 
         VT_FLO: begin New(D);            Result^.Ptr:=D   end;
         VT_BOO: begin New(B);            Result^.Ptr:=B   end;
         VT_STR: begin New(S);            Result^.Ptr:=S   end;
         VT_UTF: begin New(Utf,Create()); Result^.Ptr:=Utf end;
         VT_ARR: begin New(Arr,Create()); Result^.Ptr:=Arr end;
         VT_DIC: begin New(Dic,Create()); Result^.Ptr:=Dic end;
         else Result^.Ptr:=NIL
   end end end;

Function NilVal():PValue;
   begin
   Result:=CreateVal(VT_NIL); Result^.Ptr:=NIL; Result^.Lev:=CurLev
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
   
Function EmptyVal(Const T:TValueType):PValue;
   begin
   Result:=CreateVal(T); Result^.Lev := CurLev;
   Case T of 
      VT_INT .. VT_BIN:
         PQInt(Result^.Ptr)^:=0;
      VT_FLO:
         PFloat(Result^.Ptr)^:=0.0; 
      VT_STR:
         PStr(Result^.Ptr)^:='';
      VT_UTF:
         PUTF(Result^.Ptr)^.Clear();
      VT_BOO:
         PBool(Result^.Ptr)^:=False;
      VT_FIL:
         Result^.Ptr := NIL
   end end;

Function  CopyTyp(Const V:PValue):PValue;
   begin Exit(EmptyVal(V^.Typ)) end;

Function  CopyVal(Const V:PValue):PValue;
   begin Exit(CopyVal(V, CurLev)) end;

Procedure CopyVal_Arr(Const V,R:PValue;Const Lv:LongWord);
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

Procedure CopyVal_Dict(Const V,R:PValue;Const Lv:LongWord);
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

Function  CopyVal(Const V:PValue;Const Lv:LongWord):PValue;
   begin
   Result:=CreateVal(V^.Typ); Result^.Lev:=Lv;
   Case V^.Typ of 
      VT_INT .. VT_BIN: 
         PQInt(Result^.Ptr)^:=PQInt(V^.Ptr)^;
      VT_FLO:
         PFloat(Result^.Ptr)^:=PFloat(V^.Ptr)^;
      VT_STR:
         PStr(Result^.Ptr)^:=PStr(V^.Ptr)^;
      VT_UTF:
         PUTF(Result^.Ptr)^.SetTo(PUTF(V^.Ptr));
      VT_BOO:
         PBool(Result^.Ptr)^:=PBool(V^.Ptr)^;
      VT_ARR:
         CopyVal_Arr(V,Result,Lv);
      VT_DIC:
         CopyVal_Dict(V,Result,Lv);
      VT_FIL:
         Result^.Ptr := V^.Ptr
   end end;

Procedure SetValLev(Const V:PValue;Const Lv:LongWord);
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

Procedure SetValMaxLev(Const V:PValue;Const Lv:LongWord);
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
   Var P:Pointer; T:TValueType; 
   begin
   P:=A^.Ptr; T:=A^.Typ;
   A^.Ptr:=B^.Ptr; A^.Typ:=B^.Typ;
   B^.Ptr:=P; B^.Typ:=T;
   If (A^.Typ = VT_ARR) or (A^.Typ = VT_DIC)
      then SetValMaxLev(A, A^.Lev)
   end;

Function NewVal(Const T:TValueType; Const V:Pointer):PValue;
   begin
   Result:=CreateVal(T); Result^.Lev:=CurLev; Result^.Ptr:=V 
   end;

Function NewVal(Const T:TValueType; Const V:TFloat):PValue;
   begin
   Result:=CreateVal(T); Result^.Lev:=CurLev; PFloat(Result^.Ptr)^:=V
   end;

Function NewVal(Const T:TValueType; Const V:Int64):PValue;
   begin
   Result:=CreateVal(T); Result^.Lev:=CurLev; PQInt(Result^.Ptr)^:=V
   end;

Function NewVal(Const T:TValueType; Const V:TBool):PValue;
   begin
   Result:=CreateVal(T); Result^.Lev:=CurLev; PBool(Result^.Ptr)^:=V
   end;

Function NewVal(Const T:TValueType; Const V:TStr):PValue;
   begin
   Result:=CreateVal(T); Result^.Lev:=CurLev;
   If (T = VT_STR) then PStr(Result^.Ptr)^:=V
                   else PUTF(Result^.Ptr)^.SetTo(V);
   end;

Function NewVal(Const T:TValueType):PValue;
   begin 
   Result:=CreateVal(T); Result^.Lev:=CurLev; 
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
   For T:=Low(TValueType) to High(TValueType) do begin
      For i:=1 to SpareVars[T].Num do
         AnnihilateVal(SpareVars[T].Arr[i]);
      SpareVars[T].Num := 0
      end
   end;

Function MkFunc(Const Fun:TBuiltIn; Const RefMod : Boolean = REF_CONST):PFuncInfo; Inline;
   begin
   New(Result);
   Result^.Ptr := PtrUInt(Fun);
   Result^.Ref := RefMod;
   Result^.Usr := False
   end;

Function MkFunc(Const UsrID:LongWord):PFuncInfo; Inline;
   begin
   New(Result);
   Result^.Ptr := UsrID;
   Result^.Ref := REF_MODIF;
   Result^.Usr := True
   end;

Procedure SetFuncInfo(Var FuIn:TFuncInfo; Const FuncAddr:TBuiltin; Const RefMod : Boolean); Inline;
   begin FuIn.Ptr := PtrUInt(FuncAddr); FuIn.Ref := RefMod; FuIn.Usr := False end;

Procedure DisposeFunc(Const Func:PFuncInfo);
   begin Dispose(Func) end;

end.
