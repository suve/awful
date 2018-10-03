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

(* Empty function that does nothing apart from freeing its arguments.        *
 * If return value is needed, returns NilVal().                              *
 *                                                                           *
 * Used quite often by other functions to free args without much keytapping. *)
Function F_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongInt;
   begin
      (* Low index is always 0, so no need for Low(Arg^).                       *
       * For empty arrays, High() is returned as -1.                            *
       * While this would cause an infinite loop when using unsigned variables, *
       * using a signed counter will prevent entering the loop for empty arrs.  *)
      For C:=0 to High(Arg^) do FreeIfTemp(Arg^[C]);
      
      If (DoReturn) then Exit(NilVal()) else Exit(NIL)
   end;

end.
