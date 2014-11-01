unit emptyfunc;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Var
   FuncInfo_NIL : TFuncInfo;


implementation

Procedure Register(Const FT:PFunTrie);
   begin
      FT^.SetVal('nil', MkFunc(@F_));
      SetFuncInfo(FuncInfo_NIL, @F_, REF_CONST)
   end;

(* Empty function that does nothing apart from freeing its argument.         *
 * If return value is needed, returns NilVal.                                *
 *                                                                           *
 * Used quite often by other functions to free args without much keytapping. *)
Function F_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
      If (Length(Arg^) > 0) then
         For C:=Low(Arg^) to High(Arg^) do
            FreeIfTemp(Arg^[C]);

      If (DoReturn) then Exit(NilVal) else Exit(NIL)
   end;

end.
