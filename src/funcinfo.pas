unit funcinfo;

{$INCLUDE defines.inc}

interface
   uses SysUtils, DynPtrTrie, Values;
     
Const
   RETURN_VALUE_YES = True; RETURN_VALUE_NO = False;
   REF_MODIF = True; REF_CONST = False;

Type
   TBuiltIn = Function(Const DoReturn:Boolean;Const Arg:PArrPVal):PValue;
     
   PFuncInfo = ^TFuncInfo;
   TFuncInfo = record
      Ref : Boolean;
      Case Usr : Boolean of
         True  : (uid: PtrUInt);
         False : (Ptr: TBuiltIn);
   end;
     
   PFunTrie = ^TFunTrie;
   TFunTrie = specialize GenericDynPtrTrie<PFuncInfo>;

Function MkFunc(Const Fun:TBuiltIn; Const RefMod : Boolean = REF_CONST):PFuncInfo; Inline;
Function MkFunc(Const UsrID:LongWord):PFuncInfo; Inline;
Procedure DisposeFunc(Const Func:PFuncInfo);

Procedure SetFuncInfo(Var FuIn:TFuncInfo; Const FuncAddr:TBuiltin; Const RefMod : Boolean); Inline;


implementation


Function MkFunc(Const Fun:TBuiltIn; Const RefMod : Boolean = REF_CONST):PFuncInfo; Inline;
   begin
      New(Result);
      Result^.Ref := RefMod;
      Result^.Usr := False;
      Result^.Ptr := Fun
   end;

Function MkFunc(Const UsrID:LongWord):PFuncInfo; Inline;
   begin
      New(Result);
      Result^.Ref := REF_MODIF;
      Result^.Usr := True;
      Result^.uid := UsrID
   end;

Procedure SetFuncInfo(Var FuIn:TFuncInfo; Const FuncAddr:TBuiltin; Const RefMod : Boolean); Inline;
   begin 
      FuIn.Ptr := FuncAddr;
      FuIn.Ref := RefMod;
      FuIn.Usr := False
  end;

Procedure DisposeFunc(Const Func:PFuncInfo);
   begin Dispose(Func) end;

end.

