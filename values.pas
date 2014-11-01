unit values;

{$INCLUDE defines.inc}

interface
   uses SysUtils, NumPtrTrie, DynPtrTrie, UnicodeStrings;

Var
   RealPrec : LongWord = 3;
   RealForm : TFloatFormat = ffFixed;
   CurLev : LongWord = 0;

Type
   TValueType = (
      VT_NIL, VT_NEW,
      VT_PTR,
      VT_BOO,
      VT_INT, VT_HEX, VT_OCT, VT_BIN,
      VT_FLO,
      VT_STR, VT_UTF,
      VT_ARR, VT_DIC,
      VT_FIL
   );

Const
   VT_LOG = VT_BOO; VT_DICT = VT_DIC;

Type
   PFileHandle = ^TFileHandle;
   TFileHandle = record
      Fil : System.Text;
      arw : Char;
      Pth : AnsiString;
      Buf : AnsiString
   end;

Type
   PValue = ^TValue;
   PQInt = ^QInt;
   PStr = ^TStr;
   PUTF = PUTF8String;
   PBool = ^TBool;
   PFloat = ^TFloat;
   PArray = ^TArray;
   PDict = ^TDict;
     
   TValue = record
      Lev : LongWord;
      Case Typ : TValueType of
         VT_NIL .. VT_PTR: (Ptr : Pointer);
         VT_BOO: (Boo : PBool);
         VT_INT .. VT_BIN: (Int : PQInt);
         VT_FLO: (Flo : PFloat);
         VT_STR: (Str : PStr);
         VT_UTF: (Utf : PUTF);
         VT_ARR: (Arr : PArray);
         VT_DIC: (Dic : PDict);
         VT_FIL: (Fil : PFileHandle)
   end;
     
     
   QInt = Int64;
   TStr = AnsiString;
   TUTF = TUTF8String;
   TBool = Boolean;
   TFloat = ValReal;
   TArray = specialize GenericNumPtrTrie<PValue>;
   TDict = specialize GenericDynPtrTrie<PValue>;
   
   PArr = PArray; TArr = TArray;
    
   PValTrie = ^TValTrie;
   TValTrie = specialize GenericDynPtrTrie<PValue>;
   
   TArrPVal = Array of PValue;
   PArrPVal = ^TArrPVal;
   

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

Function  IsTempVal(Const V:PValue):Boolean; Inline;
Procedure FreeIfTemp(Const V:PValue); Inline;
Procedure DestroyIfTemp(Const V:PValue); Inline;
Procedure AnnihilateIfTemp(Const V:PValue); Inline;

Function  Exv(Const DoReturn:Boolean):PValue; Inline;

Procedure SpareVars_Prepare();
Procedure SpareVars_Destroy();


implementation

Const
   SpareVarsPerType = SizeOf(NativeInt)*8;

Type
   TSpareArray = record
      Arr : Array[1..SpareVarsPerType] of PValue;
      Num : LongWord;
   end;

Var SpareVars : Array[TValueType] of TSpareArray;

Function CreateVal(Const T:TValueType):PValue;
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
               New(Result^.Int);
                    
            VT_FLO: New(Result^.Flo);
            VT_BOO: New(Result^.Boo);
            VT_STR: New(Result^.Str);
            VT_UTF: New(Result^.Utf, Create());
            VT_ARR: New(Result^.Arr, Create());
            VT_DIC: New(Result^.Dic, Create());
            else Result^.Ptr:=NIL
   end end end;

Function NilVal():PValue;
   begin
      Result:=CreateVal(VT_NIL); Result^.Ptr:=NIL; Result^.Lev:=CurLev
   end;

Procedure DestroyVal_INLINE(Const Val:PValue); Inline;
   begin
      Case Val^.Typ of
         VT_NIL: ;
         VT_INT .. VT_BIN: 
                 Dispose(Val^.Int);
         VT_FLO: Dispose(Val^.Flo);
         VT_BOO: Dispose(Val^.Boo);
         VT_STR: Dispose(Val^.Str);
         VT_UTF: Dispose(Val^.Utf, Destroy());
         VT_ARR: begin Val^.Arr^.Purge(@FreeIfTemp); Dispose(Val^.Arr, Destroy()) end;
         VT_DIC: begin Val^.Dic^.Purge(@FreeIfTemp); Dispose(Val^.Dic, Destroy()) end;
      end;
      Dispose(Val)
   end;

Procedure DestroyVal(Const Val:PValue);
   begin DestroyVal_INLINE(Val) end;

Procedure FreeVal(Const Val:PValue);
   begin
      If (SpareVars[Val^.Typ].Num < SpareVarsPerType) then begin
         
         Case (Val^.Typ) of
            VT_ARR: Val^.Arr^.Purge(@FreeIfTemp);
            VT_DIC: Val^.Dic^.Purge(@FreeIfTemp)
         end;
         
         SpareVars[Val^.Typ].Num += 1;
         SpareVars[Val^.Typ].Arr[SpareVars[Val^.Typ].Num] := Val
         
      end else DestroyVal_INLINE(Val)
   end;

Procedure AnnihilateVal(Const Val:PValue);
   begin
      Case Val^.Typ of
         VT_NIL: ;
         VT_INT.. VT_BIN:
                 Dispose(Val^.Int);
         VT_FLO: Dispose(Val^.Flo);
         VT_BOO: Dispose(Val^.Boo);
         VT_STR: Dispose(Val^.Str);
         VT_UTF: Dispose(Val^.Utf, Destroy());
         VT_ARR: begin Val^.Arr^.Purge(@AnnihilateIfTemp); Dispose(Val^.Arr, Destroy()) end;
         VT_DIC: begin Val^.Dic^.Purge(@AnnihilateIfTemp); Dispose(Val^.Dic, Destroy()) end;
      end;
      Dispose(Val)
   end;
   
Function EmptyVal(Const T:TValueType):PValue;
   begin
      Result:=CreateVal(T); Result^.Lev := CurLev;
      Case T of 
         VT_INT .. VT_BIN:
            Result^.Int^:=0;
         VT_FLO:
            Result^.Flo^:=0.0; 
         VT_STR:
            Result^.Str^:='';
         VT_UTF:
            Result^.Utf^.Clear();
         VT_BOO:
            Result^.Boo^:=False;
         VT_FIL:
            Result^.Fil := NIL
   end end;

Function  CopyTyp(Const V:PValue):PValue;
   begin Exit(EmptyVal(V^.Typ)) end;

Function  CopyVal(Const V:PValue):PValue;
   begin Exit(CopyVal(V, CurLev)) end;

Procedure CopyVal_Arr(Const OldV,NewV:PValue;Const Lv:LongWord);
   Var AEA : TArray.TEntryArr; C:LongWord;
   begin
      If (Not OldV^.Arr^.Empty()) then begin
         AEA := OldV^.Arr^.ToArray();
         For C:=Low(AEA) to High(AEA) do
            If (AEA[C].Val^.Lev >= Lv)
               then NewV^.Arr^.SetVal(AEA[C].Key, CopyVal(AEA[C].Val, Lv))
               else NewV^.Arr^.SetVal(AEA[C].Key, AEA[C].Val)
   end end;

Procedure CopyVal_Dict(Const OldV,NewV:PValue;Const Lv:LongWord);
   Var DEA : TDict.TEntryArr; C:LongWord;
   begin
      If (Not OldV^.Dic^.Empty()) then begin
         DEA := OldV^.Dic^.ToArray();
         For C:=Low(DEA) to High(DEA) do
            If (DEA[C].Val^.Lev >= Lv)
               then NewV^.Dic^.SetVal(DEA[C].Key, CopyVal(DEA[C].Val, Lv))
               else NewV^.Dic^.SetVal(DEA[C].Key, DEA[C].Val)
   end end;

Function  CopyVal(Const V:PValue;Const Lv:LongWord):PValue;
   begin
      Result:=CreateVal(V^.Typ); Result^.Lev:=Lv;
      Case V^.Typ of 
         VT_INT .. VT_BIN: 
            Result^.Int^ := V^.Int^;
         VT_FLO:
            Result^.Flo^ := V^.Flo^;
         VT_STR:
            Result^.Str^ := V^.Str^;
         VT_UTF:
            Result^.Utf^.SetTo(V^.Utf);
         VT_BOO:
            Result^.Boo^ := V^.Boo^;
         VT_ARR:
            CopyVal_Arr(V,Result,Lv);
         VT_DIC:
            CopyVal_Dict(V,Result,Lv);
         VT_FIL:
            Result^.Fil := V^.Fil
   end end;

Procedure SetValLev(Const V:PValue;Const Lv:LongWord);
   Var C:LongWord; AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
   begin
      V^.Lev := Lv;
      If (V^.Typ = VT_ARR) then begin
         If (V^.Arr^.Empty()) then Exit();
         AEA:=V^.Arr^.ToArray();
         For C:=Low(AEA) to High(AEA) do
            SetValLev(AEA[C].Val, Lv)
      end else
      If (V^.Typ = VT_DIC) then begin
         If (V^.Dic^.Empty()) then Exit();
         DEA:=V^.Dic^.ToArray();
         For C:=Low(DEA) to High(DEA) do
            SetValLev(DEA[C].Val, Lv)
      end
   end;

Procedure SetValMaxLev(Const V:PValue;Const Lv:LongWord);
   Var C:LongWord; AEA:TArray.TEntryArr; DEA:TDict.TEntryArr;
   begin
      If (V^.Lev > Lv) then V^.Lev := Lv;
      If (V^.Typ = VT_ARR) then begin
         If (V^.Arr^.Empty()) then Exit();
         AEA:=V^.Arr^.ToArray();
         For C:=Low(AEA) to High(AEA) do
            If (AEA[C].Val^.Lev >= Lv) then SetValMaxLev(AEA[C].Val, Lv)
      end else
      If (V^.Typ = VT_DIC) then begin
         If (V^.Dic^.Empty()) then Exit();
         DEA:=V^.Dic^.ToArray();
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
      Result:=CreateVal(T); Result^.Lev:=CurLev; Result^.Flo^:=V
   end;

Function NewVal(Const T:TValueType; Const V:Int64):PValue;
   begin
      Result:=CreateVal(T); Result^.Lev:=CurLev; Result^.Int^:=V
   end;

Function NewVal(Const T:TValueType; Const V:TBool):PValue;
   begin
      Result:=CreateVal(T); Result^.Lev:=CurLev; Result^.Boo^:=V
   end;

Function NewVal(Const T:TValueType; Const V:TStr):PValue;
   begin
      Result:=CreateVal(T); Result^.Lev:=CurLev;
      If (T = VT_STR)
         then Result^.Str^:=V
         else Result^.Utf^.SetTo(V);
   end;

Function NewVal(Const T:TValueType):PValue;
   begin 
      Result:=CreateVal(T); Result^.Lev:=CurLev
   end;

Function IsTempVal(Const V:PValue):Boolean; Inline;
   begin Exit(V^.Lev >= CurLev) end;

Procedure FreeIfTemp(Const V:PValue); Inline;
   begin If(V^.Lev >= CurLev) then FreeVal(V) end;

Procedure DestroyIfTemp(Const V:PValue); Inline;
   begin If(V^.Lev >= CurLev) then DestroyVal(V) end;

Procedure AnnihilateIfTemp(Const V:PValue); Inline;
   begin If(V^.Lev >= CurLev) then AnnihilateVal(V) end;

Function Exv(Const DoReturn:Boolean):PValue; Inline;
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
   end end;

end.
