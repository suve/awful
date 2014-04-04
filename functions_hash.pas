unit functions_hash;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_MD2(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_MD2_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_MD4(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_MD4_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_MD5(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_MD5_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_SHA1(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SHA1_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses Convert, Values_Typecast, EmptyFunc,
        MD5, SHA1;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal( 'md2',MkFunc(@F_MD2));    FT^.SetVal( 'md2-file',MkFunc(@F_MD2_File));
   FT^.SetVal( 'md4',MkFunc(@F_MD4));    FT^.SetVal( 'md4-file',MkFunc(@F_MD4_File));
   FT^.SetVal( 'md5',MkFunc(@F_MD5));    FT^.SetVal( 'md5-file',MkFunc(@F_MD5_File));
   FT^.SetVal('sha1',MkFunc(@F_SHA1));   FT^.SetVal('sha1-file',MkFunc(@F_SHA1_File));
   end;

Type TByteArray = Array of Byte;
Type THashFunc = Function(Const Str:AnsiString):TByteArray;

Function _MD2string(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(MD2string(Str)) end;

Function _MD2file(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(MD2file(Str)) end;

Function _MD4string(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(MD4string(Str)) end;

Function _MD4file(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(MD4file(Str)) end;

Function _MD5string(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(MD5string(Str)) end;

Function _MD5file(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(MD5file(Str)) end;

Function _SHA1string(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(SHA1string(Str)) end;

Function _SHA1file(Const Str:AnsiString):TByteArray; Inline;
   begin Exit(SHA1file(Str)) end;

Function HexDigest(Const Dig:Array of Byte):AnsiString;
   Var B:LongWord;
   begin SetLength(Result,Length(Dig)*2);
   For B:=0 to Length(Dig)-1 do begin
       Result[(B*2)+1] := Convert.Sys16Dig[Dig[B] div 16];
       Result[(B*2)+2] := Convert.Sys16Dig[Dig[B] mod 16]
   end end;

Function RawDigest(Const Dig:Array of Byte):AnsiString;
   Var B:LongWord;
   begin
   SetLength(Result, Length(Dig));
   For B:=0 to Length(Dig)-1 do
       Result[B+1] := Chr(Dig[B])
   end;

Function F_Hashing(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Hash:THashFunc):PValue; 
   Var V:PValue; Raw:Boolean;
   begin
   If (Not DoReturn) then Exit(F_(False,Arg)); 
   If (Length(Arg^) > 0) then begin 
      V:=ValToStr(Arg^[0]);
      If (Length(Arg^) > 1)
         then Raw := ValAsBoo(Arg^[1])
         else Raw := False
      end else begin
      V:=EmptyVal(VT_STR);
      Raw := False
      end;
   F_(False, Arg);
   If (Not Raw) then PStr(V^.Ptr)^ := HexDigest(Hash(PStr(V^.Ptr)^))
                else PStr(V^.Ptr)^ := RawDigest(Hash(PStr(V^.Ptr)^));
   Exit(V)
   end;

Function F_MD2(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_MD2string)) end;
   
Function F_MD2_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_MD2file)) end;

Function F_MD4(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_MD4string)) end;
   
Function F_MD4_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_MD4file)) end;

Function F_MD5(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_MD5string)) end;
   
Function F_MD5_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_MD5file)) end;

Function F_SHA1(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_SHA1String)) end;
   
Function F_SHA1_File(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_Hashing(DoReturn, Arg, @_SHA1File)) end;

end.
