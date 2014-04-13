unit functions_encodings;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_EncodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DecodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_EncodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DecodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_EncodeHex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DecodeHex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_EncodeBase64(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DecodeBase64(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_EncodeJSON(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DecodeJSON(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses Encodings, Values_Typecast, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal(   'url-encode',MkFunc(@F_EncodeURL));     FT^.SetVal('encodeURL',   MkFunc(@F_EncodeURL));
   FT^.SetVal(   'url-decode',MkFunc(@F_DecodeURL));     FT^.SetVal('decodeURL',   MkFunc(@F_DecodeURL));   
   FT^.SetVal(  'html-encode',MkFunc(@F_EncodeHTML));    FT^.SetVal('encodeHTML',  MkFunc(@F_EncodeHTML));
   FT^.SetVal(  'html-decode',MkFunc(@F_DecodeHTML));    FT^.SetVal('decodeHTML',  MkFunc(@F_DecodeHTML)); 
   FT^.SetVal(   'hex-encode',MkFunc(@F_EncodeHex));     FT^.SetVal('encodeHex',   MkFunc(@F_EncodeHex));
   FT^.SetVal(   'hex-decode',MkFunc(@F_DecodeHex));     FT^.SetVal('decodeHex',   MkFunc(@F_DecodeHex)); 
   FT^.SetVal('base64-encode',MkFunc(@F_EncodeBase64));  FT^.SetVal('encodeBase64',MkFunc(@F_EncodeBase64));
   FT^.SetVal('base64-decode',MkFunc(@F_DecodeBase64));  FT^.SetVal('decodeBase64',MkFunc(@F_DecodeBase64)); 
   FT^.SetVal(  'json-encode',MkFunc(@F_EncodeJSON));    FT^.SetVal('encodeJSON',  MkFunc(@F_EncodeJSON));
   FT^.SetVal(  'json-decode',MkFunc(@F_DecodeJSON));    FT^.SetVal('decodeJSON',  MkFunc(@F_DecodeJSON)); 
   end;

Type TStrFunc = Function(Const Str:AnsiString):AnsiString;

Function F_ParseString(Const DoReturn:Boolean; Const Arg:PArrPVal; Const Func:TStrFunc):PValue;
   Var S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(NewVal(VT_STR, ''));
   S:=ValAsStr(Arg^[0]); F_(False,Arg);
   Exit(NewVal(VT_STR,Func(S)))
   end;

Function F_DecodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.DecodeURL)) end;

Function F_EncodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.EncodeURL)) end;
   
Function F_EncodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.EncodeHTML)) end;
   
Function F_DecodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.DecodeHTML)) end;

Function F_EncodeHex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.EncodeHex)) end;

Function F_DecodeHex(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.DecodeHex)) end;

Function F_EncodeBase64(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.EncodeBase64)) end;

Function F_DecodeBase64(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(DoReturn, Arg, @Encodings.DecodeBase64)) end;

Function F_EncodeJSON(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var JSON:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False,Arg));
   If (Length(Arg^) = 0) then Exit(NilVal());
   
   JSON := EncodeJSON(Arg^[0]);
   If (Arg^[0]^.Typ <> VT_ARR) and (Arg^[0]^.Typ <> VT_DIC) and (Arg^[0]^.Typ <> VT_FIL)
      then JSON := '['+JSON+']';
   
   F_(False,Arg); Exit(NewVal(VT_STR,JSON))
   end;

Function F_DecodeJSON(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   If (Not DoReturn) then Exit(F_(False,Arg));
   If (Length(Arg^) = 0) then Exit(NilVal());
   
   Result := DecodeJSON(ValAsStr(Arg^[0]));
   F_(False,Arg)
   end;

end.
