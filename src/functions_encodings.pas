unit functions_encodings;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

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

Function F_ParseString(Const DoReturn:Boolean; Const Arg:PArrPVal; Const StrFunc:TStrFunc):PValue;
   begin
      // If no retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If no arguments, exit with empty string
      If (Length(Arg^) = 0) then Exit(NewVal(VT_STR, ''));
      
      // Prepare result value - use StrFunc on string-converted arg0
      Result := NewVal(VT_STR, StrFunc(ValAsStr(Arg^[0])));
      
      // Be so kind to free the args before you leave
      F_(False,Arg)
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
      
      (* Check if either the value was an array/dict/value, or the function was called with more than one arg, *
       * and second arg was TRUE (which allows the user to explicitely request returning bare values).         *
       *                                                                                                       *
       * If not, enclose the returned JSON representation in [braces]. The JSON standard mandates that the     *
       * top-level datatype must be either an array, or an object - so returning bare values is a no-no.       *
       * Given to choose between wrapping in array or object, I decided to go with array.                      *)
      If (Not ((Arg^[0]^.Typ in [VT_ARR, VT_DIC, VT_FIL]) or ((Length(Arg^) >= 2) and (ValAsBoo(Arg^[1])))))
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
