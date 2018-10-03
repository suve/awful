unit values_bitwise;

{$INCLUDE defines.inc}

interface
   uses Values;

Function ValNot(Const V:PValue):PValue;

Function ValAnd(Const A,B:PValue):PValue;
Function ValXor(Const A,B:PValue):PValue;
Function ValOr(Const A,B:PValue):PValue;

Function ValShl(Const A,B:PValue):PValue;
Function ValShr(Const A,B:PValue):PValue;


implementation
   uses Convert, SysUtils, Values_Typecast;

Function ValNot(Const V:PValue):PValue;
   Var C:LongWord;
   begin
      Result := CopyVal(V);
      Case(Result^.Typ) of
         
         VT_INT .. VT_BIN: 
            Result^.Int^ := Not V^.Int^;
         
         VT_FLO: 
             Result^.Flo^ := Not Trunc(V^.Flo^);
      
         VT_STR: 
            For C:=1 to Length(Result^.Str^) do Result^.Str^[C] := Chr(Not Ord(Result^.Str^[C]));
      
         VT_BOO:
            Result^.Boo^ := Not V^.Boo^;
      end
   end;

Type TBitwiseFunc = Function(Const A,B:PValue):PValue;

Procedure Bitwise_Array(Const A,B:PArray;Const Bitfunc:TBitwiseFunc;Const Res:PArray);
   {$DEFINE __TYPE__ := TArr }
   
   {$INCLUDE values_bitwise-arrdict.inc }
   
   {$UNDEF __TYPE__ }
   end;

Procedure Bitwise_Dict(Const A,B:PDict;Const Bitfunc:TBitwiseFunc;Const Res:PDict);
   {$DEFINE __TYPE__ := TDict }
   
   {$INCLUDE values_bitwise-arrdict.inc }
   
   {$UNDEF __TYPE__ }
   end;

Function ValAnd(Const A,B:PValue):PValue;
   {$DEFINE __BITFUNC__ := Values_Bitwise.ValAnd }
   {$DEFINE __BITWISE__ := and }
   
   {$INCLUDE values_bitwise-bitfunc.inc }
   
   {$UNDEF __BITWISE__ }
   {$UNDEF __BITFUNC__ }
   end;

Function ValXor(Const A,B:PValue):PValue;
   {$DEFINE __BITFUNC__ := Values_Bitwise.ValXor }
   {$DEFINE __BITWISE__ := xor }
   
   {$INCLUDE values_bitwise-bitfunc.inc }
   
   {$UNDEF __BITWISE__ }
   {$UNDEF __BITFUNC__ }
   end;

Function ValOr(Const A,B:PValue):PValue;
   {$DEFINE __BITFUNC__ := Values_Bitwise.ValOr }
   {$DEFINE __BITWISE__ := or }
   
   {$INCLUDE values_bitwise-bitfunc.inc }
   
   {$UNDEF __BITWISE__ }
   {$UNDEF __BITFUNC__ }
   end;

Function ValShl(Const A,B:PValue):PValue;
   {$DEFINE __BITFUNC__ := Values_Bitwise.ValShl }
   {$DEFINE __BITWISE__ := shl }
   {$DEFINE BOOL_FROM_INT}
   
   {$INCLUDE values_bitwise-bitfunc.inc }
   
   {$UNDEF BOOL_FROM_INT}
   {$UNDEF __BITWISE__ }
   {$UNDEF __BITFUNC__ }
   end;

Function ValShr(Const A,B:PValue):PValue;
   {$DEFINE __BITFUNC__ := Values_Bitwise.ValShr }
   {$DEFINE __BITWISE__ := shr }
   {$DEFINE BOOL_FROM_INT}
   
   {$INCLUDE values_bitwise-bitfunc.inc }
   
   {$UNDEF BOOL_FROM_INT}
   {$UNDEF __BITWISE__ }
   {$UNDEF __BITFUNC__ }
   end;

end.
