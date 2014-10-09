unit functions_cgi;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_Doctype(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

{$IFDEF CGI}
Function F_HTTPheader(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_HTTPcookie(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
{$ELSE}
Function F_Prepare_GET(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Prepare_POST(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Prepare_CAKE(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
{$ENDIF}

Function F_GET_Is(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GET_Val(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GET_Key(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GET_Num(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GET_Dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_POST_Is(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_POST_Val(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_POST_Key(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_POST_Num(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_POST_Dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_CAKE_Is(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CAKE_Val(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CAKE_Key(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CAKE_Num(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CAKE_Dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Procedure Prepare_GET();
Procedure Prepare_POST();
Procedure Prepare_CAKE();
Procedure FreeArrays();


implementation
   uses SysUtils, StrUtils, Math,
        Convert, Encodings, Globals,
        Values_Typecast, EmptyFunc;

Procedure Register(Const FT:PFunTrie);
   begin
      // Utils (encoding moved to functions_encodings)
      FT^.SetVal('doctype',MkFunc(@F_Doctype));
      
      // GET related functions
      FT^.SetVal('get-is',MkFunc(@F_GET_Is));
      FT^.SetVal('get-val',MkFunc(@F_GET_Val));
      FT^.SetVal('get-key',MkFunc(@F_GET_Key));
      FT^.SetVal('get-num',MkFunc(@F_GET_Num));
      FT^.SetVal('get-dict',MkFunc(@F_GET_Dict));
      
      // POST related functions
      FT^.SetVal('post-is',MkFunc(@F_POST_Is));
      FT^.SetVal('post-val',MkFunc(@F_POST_Val));
      FT^.SetVal('post-key',MkFunc(@F_POST_Key));
      FT^.SetVal('post-num',MkFunc(@F_POST_Num));
      FT^.SetVal('post-dict',MkFunc(@F_POST_Dict));
      
      // HTTP-Cookie related functions
      FT^.SetVal('cookie-is',MkFunc(@F_CAKE_Is));
      FT^.SetVal('cookie-val',MkFunc(@F_CAKE_Val));
      FT^.SetVal('cookie-key',MkFunc(@F_CAKE_Key));
      FT^.SetVal('cookie-num',MkFunc(@F_CAKE_Num));
      FT^.SetVal('cookie-dict',MkFunc(@F_CAKE_Dict));
      
      // Functions available in CGI mode only
      FT^.SetVal('http-header', MkFunc({$IFDEF CGI} @F_HTTPheader {$ELSE} @F_ {$ENDIF} ));
      FT^.SetVal('http-cookie', MkFunc({$IFDEF CGI} @F_HTTPcookie {$ELSE} @F_ {$ENDIF} ));
      
      // Functions available only outside CGI mode
      FT^.SetVal('get-prepare', MkFunc({$IFNDEF CGI} @F_Prepare_GET {$ELSE} @F_ {$ENDIF} ));
      FT^.SetVal('post-prepare', MkFunc({$IFNDEF CGI} @F_Prepare_POST {$ELSE} @F_ {$ENDIF} ));
      FT^.SetVal('cookie-prepare', MkFunc({$IFNDEF CGI} @F_Prepare_CAKE {$ELSE} @F_ {$ENDIF} ));
   end;


Var // GET / POST / COOKIE key-value pairs
   GetArr, PostArr, CakeArr : TKeyValArr; 

// Quicksort function
Procedure SortArr(Var Arr:TKeyValArr; Min, Max : LongWord);
   Var Pos, Piv:LongWord; PivVal:TKeyVal;
   begin
      Pos:=Min; Piv:=Max; PivVal:=Arr[Piv];
      While (Pos<>Piv) do
         If (Arr[Pos].Key > PivVal.Key) then begin
            Arr[Piv]:=Arr[Pos]; Arr[Pos]:=Arr[Piv-1];
            Arr[Piv-1] := PivVal; Piv -= 1
         end else Pos += 1;
      If ((Pos - Min) > 1) then SortArr(Arr, Min, Pos-1);
      If ((Max - Pos) > 1) then SortArr(Arr, Pos+1, Max)
   end;

// Truncates the GET / POST / COOKIE arrays
Procedure FreeArrays();
   begin
      SetLength(GetArr, 0); SetLength(PostArr, 0); SetLength(CakeArr, 0)
      {$IFDEF CGI} ; SetLength(Headers, 0); SetLength(Cookies, 0) {$ENDIF}
   end;


{$IFDEF CGI}
Function F_HTTPheader(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var K,V:AnsiString; C:LongWord; Match:Boolean;
   begin
      // If no args, bail out early
      If (Length(Arg^)=0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
      
      // Get header name from leftmost arg
      If (Arg^[0]^.Typ = VT_STR)
         then K:=Arg^[0]^.Str^
         else K:=ValAsStr(Arg^[0]);
      K:=LowerCase(Trim(K)); // HTTP spec says headers are case-insensitive
      
      // If two or more args are provided, we are setting a header
      If (Length(Arg^)>=2) then begin
         
         // Get header value from second arg
         If (Arg^[1]^.Typ <> VT_STR) 
            then V:=Arg^[1]^.Str^
            else V:=ValAsStr(Arg^[1]);
         
         // Look for match in already defined headers
         Match := False;
         If (Length(Headers) > 0) then
            For C:=Low(Headers) to High(Headers) do
               If (K = Headers[C].Key) then begin
                  Headers[C].Val := V; Match:=True;
                  Break
               end;
         
         // If no match found, insert new header
         If (Not Match) then begin
            SetLength(Headers, Length(Headers)+1);
            Headers[High(Headers)].Key:=K;
            Headers[High(Headers)].Val:=V
         end
      end else
      // One arg provided = unset header
      If (Length(Headers)>0) then
         For C:=Low(Headers) to High(Headers) do
            If (K = Headers[C].Key) then begin
               Headers[C] := Headers[High(Headers)];
               SetLength(Headers, Length(Headers)-1);
               Break
            end;
      // Call emptyfunc to free the arguments
      Exit(F_(DoReturn, Arg))
   end;

Function F_HTTPcookie(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var K,V:AnsiString;
   begin
      // If less than two args, bail out early
      If (Length(Arg^) < 2) then Exit(F_(DoReturn, Arg));
      
      // Get cookie name from arg0
      If (Arg^[0]^.Typ = VT_STR)
         then K:=Arg^[0]^.Str^
         else K:=ValAsStr(Arg^[0]);
      
      // Get cookie value from arg1
      If (Arg^[1]^.Typ = VT_STR) 
         then V:=Arg^[1]^.Str^
         else V:=ValAsStr(Arg^[1]);
      
      // Add cookie to cookie array
      SetLength(Cookies, Length(Cookies)+1);
      Cookies[High(Cookies)].Name := Trim(K);
      Cookies[High(Cookies)].Value := V;
      
      // Call emptyfunc to free arguments
      Exit(F_(DoReturn, Arg))
   end;
{$ENDIF}

Procedure Prepare_GET();
   {$DEFINE __ARRAY__ := GetArr }
   {$DEFINE __ENVVAR__ := 'QUERY_STRING' }
   
   {$INCLUDE functions_cgi-prepare.inc}
   
   {$UNDEF __ENVVAR__ }
   {$UNDEF __ARRAY__ }
   end;

Procedure Prepare_POST();
   {$DEFINE __POST__ }
   {$DEFINE __ARRAY__ := PostArr }
   {$DEFINE __ENVVAR__ := 'CONTENT_LENGTH' }
   
   {$INCLUDE functions_cgi-prepare.inc}
   
   {$UNDEF __ENVVAR__ }
   {$UNDEF __ARRAY__ }
   {$UNDEF __POST__ }
   end;

Procedure Prepare_CAKE();
   {$DEFINE __ARRAY__ := CakeArr }
   {$DEFINE __ENVVAR__ := 'HTTP_COOKIE' }
   
   {$INCLUDE functions_cgi-prepare.inc}
   
   {$UNDEF __ENVVAR__}
   {$UNDEF __ARRAY__}
   end;

// Binary search on selected GET / POST / COOKIE array
Function ArrSet(Var Arr:TKeyValArr; Const Key:AnsiString; Const L,R:LongInt):Boolean;
   Var Mid:LongWord;
   begin
      If (L > R) then Exit(False); // If left bound > right bound, bail out
      Mid:=(L+R) div 2; // Calculate middle index
      // Check if key matches middle index
      Case Sign(CompareStr(Key,Arr[Mid].Key)) of
         -1: Exit(ArrSet(Arr, Key,L,Mid-1));
          0: Exit(True);
         +1: Exit(ArrSet(Arr, Key,Mid+1,R));
   end end;

// Function to determine if Key is set in selected array
Function ArrSet(Var Arr:TKeyValArr; Const Key:AnsiString):Boolean;
   begin
      If (Length(Arr)>0)
         then Exit(ArrSet(Arr, Key,Low(Arr),High(Arr)))
         else Exit(False)
   end;

// Binary search to get string value of chosen key in selected array
Function ArrStr(Var Arr:TKeyValArr; Const Key:AnsiString; Const L,R:LongInt):AnsiString;
   Var Mid:LongWord;
   begin
      If (L>R) then Exit(''); // If left bound > right bound, bail out
      Mid:=(L+R) div 2; // Calculate middle index
      // Check if key matches middle index
      Case Sign(CompareStr(Key,Arr[Mid].Key)) of
         -1: Exit(ArrStr(Arr, Key,L,Mid-1));
          0: Exit(Arr[Mid].Val);
         +1: Exit(ArrStr(Arr, Key,Mid+1,R));
   end end;

// Get string value of key in chosen array
Function ArrStr(Var Arr:TKeyValArr; Const Key:AnsiString):AnsiString;
   begin
      If (Length(Arr)>0)
         then Exit(ArrStr(Arr, Key,Low(Arr),High(Arr)))
         else Exit('')
   end;

// Get Num-th element (value) from array
Function ArrStr(Var Arr:TKeyValArr; Const Num:LongWord):AnsiString;
   begin
      If (Num<Length(Arr))
         then Exit(Arr[Num].Val)
         else Exit('')
   end;

// Get Num-th key from array
Function ArrKey(Var Arr:TKeyValArr; Const Num:LongWord):AnsiString;
   begin
      If (Num<Length(Arr))
         then Exit(Arr[Num].Key)
         else Exit('')
   end;

// Get array length
Function ArrNum(Var Arr:TKeyValArr):LongWord;
   begin Exit(Length(Arr)) end;

{$IFNDEF CGI}
Function F_Prepare_GET(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      Prepare_GET(); Exit(F_(DoReturn, Arg))
   end;

Function F_Prepare_POST(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      Prepare_POST(); Exit(F_(DoReturn, Arg))
   end;

Function F_Prepare_CAKE(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      Prepare_CAKE(); Exit(F_(DoReturn, Arg))
   end;
{$ENDIF}

Function F_ArrIs(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var B:Boolean; C:LongWord; 
   begin
      // No retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return FALSE
      If (Length(Arg^)=0) then Exit(NewVal(VT_BOO,FALSE));
      
      B:=True; // Initial answer = TRUE
      For C:=High(Arg^) downto Low(Arg^) do begin
         // If argC not found in Arr, set retbool to false
         If (Not ArrSet(Arr, ValAsStr(Arg^[C]))) then B:=False;
         // Free argC if needed
         If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
         end;
      Exit(NewVal(VT_BOO,B))
   end;

Function F_ArrVal(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // No retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return emptystring
      If (Length(Arg^) = 0) then Exit(NewVal(VT_STR,''));
      
      // If arg0 is int/float, get int-th or trunc(float)-th Arr value
      // otherwise, treat arg0 as string at retrieve value under stringkey
      Case (Arg^[0]^.Typ) of
         VT_INT .. VT_BIN:
            Result := NewVal(VT_STR, ArrStr(Arr, Arg^[0]^.Int^));
         
         VT_FLO:
            Result := NewVal(VT_STR, ArrStr(Arr, Trunc(Arg^[0]^.Flo^)));
         
         VT_STR:
            Result := NewVal(VT_STR, ArrStr(Arr, Arg^[0]^.Str^));
         
         else
            Result := NewVal(VT_STR, ArrStr(Arr, ValAsStr(Arg^[0])));
      end;
      F_(False, Arg) // Be so kind to free args before leaving
   end;

Function F_ArrKey(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // No retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      // No args provided, return emptystring
      If (Length(Arg^) = 0) then Exit(NewVal(VT_STR,''));
      
      // Create return value by taking the arg0-th key of Arr
      Result := NewVal(VT_STR, ArrKey(Arr, ValAsInt(Arg^[0])));
      F_(False, Arg) // Be so kind to free args before leaving
   end;

Function F_ArrNum(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg); // Free args, if any
      If (DoReturn)
         then Exit(NewVal(VT_INT,ArrNum(Arr)))
         else Exit(NIL)
   end;

Function F_ArrDict(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C : LongInt;
   begin
      If (Length(Arg^)>0) then F_(False, Arg); // Free args, if any
      If (Not DoReturn) then Exit(NIL);        // Bail out if no retval expected
      
      Result:=EmptyVal(VT_DIC); // Create empty dictionary as result value
      If (Length(Arr) > 0) then 
         For C:=Low(Arr) to High(Arr) do
            // Insert string PValue containing arrC value into dict under arrC key
            Result^.Dic^.SetVal(Arr[C].Key, NewVal(VT_STR, Arr[C].Val))
   end;

Function F_GET_Is(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrIs(GetArr, DoReturn, Arg)) end;
   
Function F_GET_Val(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrVal(GetArr, DoReturn, Arg)) end;
   
Function F_GET_Key(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrKey(GetArr, DoReturn, Arg)) end;
   
Function F_GET_Num(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrNum(GetArr, DoReturn, Arg)) end;
   
Function F_GET_Dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrDict(GetArr, DoReturn, Arg)) end;

Function F_POST_Is(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrIs(PostArr, DoReturn, Arg)) end;
   
Function F_POST_Val(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrVal(PostArr, DoReturn, Arg)) end;
   
Function F_POST_Key(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrKey(PostArr, DoReturn, Arg)) end;
   
Function F_POST_Num(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrNum(PostArr, DoReturn, Arg)) end;
   
Function F_POST_Dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrDict(PostArr, DoReturn, Arg)) end;
   
Function F_CAKE_Is(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrIs(CakeArr, DoReturn, Arg)) end;
   
Function F_CAKE_Val(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrVal(CakeArr, DoReturn, Arg)) end;
   
Function F_CAKE_Key(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrKey(CakeArr, DoReturn, Arg)) end;
   
Function F_CAKE_Num(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrNum(CakeArr, DoReturn, Arg)) end;
   
Function F_CAKE_Dict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrDict(CakeArr, DoReturn, Arg)) end;

Function F_Doctype(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const
      HTML5 = '<!DOCTYPE html>';
      HTML4_FRAMESET = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">';
      HTML4_STRICT = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">';
      HTML4_LOOSE = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">';
      
      XHTML1_TRANSITIONAL = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
      XHTML1_FRAMESET = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">';
      XHTML1_STRICT = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
      XHTML1_1 = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">';
      
      DEFAULT = HTML5;
   begin
      // If no retval expected, bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      // If no args provided, return default doctype string
      If (Length(Arg^)=0) then Exit(NewVal(VT_STR, DEFAULT));
      
      If (Arg^[0]^.Typ = VT_STR) or (Arg^[0]^.Typ = VT_UTF) then 
         Case(ValAsStr(Arg^[0])) of
            'html5':
               Result := NewVal(VT_STR, HTML5);
            
            'html4', 'html4-strict':
               Result := NewVal(VT_STR, HTML4_STRICT);
            
            'html4-transitional', 'html4-loose':
               Result := NewVal(VT_STR, HTML4_LOOSE);
            
            'html4-frameset':
               Result := NewVal(VT_STR, HTML4_FRAMESET);
            
            'xhtml1', 'xhtml1-strict':
               Result := NewVal(VT_STR, XHTML1_STRICT);
            
            'xhtml1-transitional':
               Result := NewVal(VT_STR, XHTML1_TRANSITIONAL);
            
            'xhtml1-frameset':
               Result := NewVal(VT_STR, XHTML1_FRAMESET);
            
            'xhtml1.1':
               Result := NewVal(VT_STR, XHTML1_1);
            
            else
               Result := NewVal(VT_STR, DEFAULT)
      end else 
         Case (ValAsInt(Arg^[0])) of
            5: Result := NewVal(VT_STR, HTML5);
            4: Result := NewVal(VT_STR, HTML4_STRICT);
            1: Result := NewVal(VT_STR, XHTML1_1);
            else
               Result := NewVal(VT_STR, DEFAULT)
      end;
      F_(False, Arg) // Be so kind to free args before leaving
   end;

end.
