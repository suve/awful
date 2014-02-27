unit functions_cgi;

{$INCLUDE defines.inc}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

Function F_Doctype(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_EncodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DecodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_EncodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_DecodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

{$IFDEF CGI}
Function F_HTTPheader(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_HTTPcookie(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
{$ELSE}
Function F_GetProcess(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_PostProcess(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CakeProcess(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
{$ENDIF}

Function F_GetIs_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GetVal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GetKey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GetNum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_GetDict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_PostIs_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_PostVal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_PostKey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_PostNum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_PostDict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_CakeIs_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CakeVal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CakeKey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CakeNum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_CakeDict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function EncodeURL(Str:AnsiString):AnsiString;
Function DecodeURL(Str:AnsiString):AnsiString;
Function EncodeHTML(Str:AnsiString):AnsiString;
Function DecodeHTML(Str:AnsiString):AnsiString;

Procedure ProcessGet();
Procedure ProcessPost();
Procedure ProcessCake();
Procedure FreeArrays();

implementation
   uses Functions_Strings, SysUtils, Math, EmptyFunc, Globals;

Procedure Register(Const FT:PFunTrie);
   begin
   // String thingies
   FT^.SetVal('doctype',MkFunc(@F_Doctype));
   FT^.SetVal('encodeURL',MkFunc(@F_EncodeURL));   FT^.SetVal('url-encode',MkFunc(@F_EncodeURL));
   FT^.SetVal('decodeURL',MkFunc(@F_DecodeURL));   FT^.SetVal('url-decode',MkFunc(@F_DecodeURL));
   FT^.SetVal('encodeHTML',MkFunc(@F_EncodeHTML)); FT^.SetVal('html-encode',MkFunc(@F_EncodeHTML));
   FT^.SetVal('decodeHTML',MkFunc(@F_EncodeHTML)); FT^.SetVal('html-decode',MkFunc(@F_DecodeHTML));
   // GET related functions
   FT^.SetVal('get-is',MkFunc(@F_GetIs_));
   FT^.SetVal('get-val',MkFunc(@F_GetVal));
   FT^.SetVal('get-key',MkFunc(@F_GetKey));
   FT^.SetVal('get-num',MkFunc(@F_GetNum));
   FT^.SetVal('get-dict',MkFunc(@F_GetDict));
   // POST related functions
   FT^.SetVal('post-is',MkFunc(@F_PostIs_));
   FT^.SetVal('post-val',MkFunc(@F_PostVal));
   FT^.SetVal('post-key',MkFunc(@F_PostKey));
   FT^.SetVal('post-num',MkFunc(@F_PostNum));
   FT^.SetVal('post-dict',MkFunc(@F_PostDict));
   // HTTP-Cookie related functions
   FT^.SetVal('cookie-is',MkFunc(@F_CakeIs_));
   FT^.SetVal('cookie-val',MkFunc(@F_CakeVal));
   FT^.SetVal('cookie-key',MkFunc(@F_CakeKey));
   FT^.SetVal('cookie-num',MkFunc(@F_CakeNum));
   FT^.SetVal('cookie-dict',MkFunc(@F_CakeDict));
   // Functions available in CGI mode only
   FT^.SetVal('http-header', MkFunc({$IFDEF CGI} @F_HTTPheader {$ELSE} @F_ {$ENDIF} ));
   FT^.SetVal('http-cookie', MkFunc({$IFDEF CGI} @F_HTTPcookie {$ELSE} @F_ {$ENDIF} ));
   // Function available only outside CGI mode
   FT^.SetVal('get-prepare', MkFunc({$IFNDEF CGI} @F_GetProcess {$ELSE} @F_ {$ENDIF} ));
   FT^.SetVal('post-prepare', MkFunc({$IFNDEF CGI} @F_PostProcess {$ELSE} @F_ {$ENDIF} ));
   FT^.SetVal('cookie-prepare', MkFunc({$IFNDEF CGI} @F_CakeProcess {$ELSE} @F_ {$ENDIF} ));
   end;


Type TStrFunc = Function(Str:AnsiString):AnsiString;

Var GetArr, PostArr, CakeArr : TKeyValArr;


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


Procedure FreeArrays();
   begin
   SetLength(GetArr, 0); SetLength(PostArr, 0); SetLength(CakeArr, 0)
   {$IFDEF CGI} ; SetLength(Headers, 0); SetLength(Cookies, 0) {$ENDIF}
   end;


Function DecodeURL(Str:AnsiString):AnsiString;
   Var Res:AnsiString; P,R:LongWord;
   begin
   Res:=''; SetLength(Res,Length(Str));
   R:=1; P:=1;
   While (P<=Length(Str)) do
      If (Str[P]='%')
         then begin
         Res[R]:=Chr(StrToHex(Str[P+1..P+2]));
         P+=3; R+=1
         end else
      If (Str[P]='+')
         then begin Res[R]:=' ';    R+=1; P+=1 end else
      If (Str[P]<>#0)
         then begin Res[R]:=Str[P]; R+=1; P+=1 end
         else P+=1;
   SetLength(Res,R-1);
   Exit(Res)
   end;

Function EncodeURL(Str:AnsiString):AnsiString;
   Var Res:AnsiString; P:LongWord;
   begin
   Res:=''; 
   For P:=1 to Length(Str) do
       If (((Str[P]>=#48) and (Str[P]<= #57)) or //0-9
           ((Str[P]>=#65) and (Str[P]<= #90)) or //A-Z
           ((Str[P]>=#97) and (Str[P]<=#122)) or //a-z
           (Pos(Str[P],'-_.~')>0))
          then Res+=Str[P]
          else Res+='%'+HexToStr(Ord(Str[P]),2);
   Exit(Res)
   end;

Function EncodeHTML(Str:AnsiString):AnsiString;
   Var Res:AnsiString; P:LongWord;
   begin
   Res:=''; 
   For P:=1 to Length(Str) do
      Case Str[P] of
         '"': begin Res+='&quot;'; {R+=6; P+=1} end;
         '&': begin Res+='&amp;';  {R+=5; P+=1} end;
         '<': begin Res+='&lt;';   {R+=4; P+=1} end;
         '>': begin Res+='&gt;';   {R+=4; P+=1} end;
         else begin Res+=Str[P];   {R+=1; P+=1} end
      end;
   Exit(Res)
   end;


Function DecodeHTML(Str:AnsiString):AnsiString;
   
   Function DecodeEntity(E:AnsiString):AnsiString;
      Var Codepoint:QInt; 
      begin
      If (E[1]='#') then begin
         If (E[2]='x') then Codepoint:=Values.StrToHex(E)
                       else Codepoint:=Values.StrToInt(E)
         end else Case(E) of
         'quot':     Codepoint := $0022; // HTML 2.0
         'amp':      Codepoint := $0026; // HTML 2.0
         'apos':     Codepoint := $0027; //XHTML 1.0
         'lt':       Codepoint := $003C; // HTML 2.0
         'gt':       Codepoint := $003E; // HTML 2.0
         'nbsp':     Codepoint := $00A0; // HTML 3.2
         'iexcl':    Codepoint := $00A1; // HTML 3.2
         'cent':     Codepoint := $00A2; // HTML 3.2
         'pound':    Codepoint := $00A3; // HTML 3.2
         'curren':   Codepoint := $00A4; // HTML 3.2
         'yen':      Codepoint := $00A5; // HTML 3.2
         'brvbar':   Codepoint := $00A6; // HTML 3.2
         'sect':     Codepoint := $00A7; // HTML 3.2
         'uml':      Codepoint := $00A8; // HTML 3.2
         'copy':     Codepoint := $00A9; // HTML 3.2
         'ordf':     Codepoint := $00AA; // HTML 3.2
         'laquo':    Codepoint := $00AB; // HTML 3.2
         'not':      Codepoint := $00AC; // HTML 3.2
         'shy':      Codepoint := $00AD; // HTML 3.2
         'reg':      Codepoint := $00AE; // HTML 3.2
         'macr':     Codepoint := $00AF; // HTML 3.2
         'deg':      Codepoint := $00B0; // HTML 3.2
         'plusmn':   Codepoint := $00B1; // HTML 3.2
         'sup2':     Codepoint := $00B2; // HTML 3.2
         'sup3':     Codepoint := $00B3; // HTML 3.2
         'acute':    Codepoint := $00B4; // HTML 3.2
         'micro':    Codepoint := $00B5; // HTML 3.2
         'para':     Codepoint := $00B6; // HTML 3.2
         'middot':   Codepoint := $00B7; // HTML 3.2
         'cedil':    Codepoint := $00B8; // HTML 3.2
         'sup1':     Codepoint := $00B9; // HTML 3.2
         'ordm':     Codepoint := $00BA; // HTML 3.2
         'raquo':    Codepoint := $00BB; // HTML 3.2
         'frac14':   Codepoint := $00BC; // HTML 3.2
         'frac12':   Codepoint := $00BD; // HTML 3.2
         'frac34':   Codepoint := $00BE; // HTML 3.2
         'iquest':   Codepoint := $00BF; // HTML 3.2
         'Agrave':   Codepoint := $00C0; // HTML 2.0
         'Aacute':   Codepoint := $00C1; // HTML 2.0
         'Acirc':    Codepoint := $00C2; // HTML 2.0
         'Atilde':   Codepoint := $00C3; // HTML 2.0
         'Auml':     Codepoint := $00C4; // HTML 2.0
         'Aring':    Codepoint := $00C5; // HTML 2.0
         'AElig':    Codepoint := $00C6; // HTML 2.0
         'Ccedil':   Codepoint := $00C7; // HTML 2.0
         'Egrave':   Codepoint := $00C8; // HTML 2.0
         'Eacute':   Codepoint := $00C9; // HTML 2.0
         'Ecirc':    Codepoint := $00CA; // HTML 2.0
         'Euml':     Codepoint := $00CB; // HTML 2.0
         'Igrave':   Codepoint := $00CC; // HTML 2.0
         'Iacute':   Codepoint := $00CD; // HTML 2.0
         'Icirc':    Codepoint := $00CE; // HTML 2.0
         'Iuml':     Codepoint := $00CF; // HTML 2.0
         'ETH':      Codepoint := $00D0; // HTML 2.0
         'Ntilde':   Codepoint := $00D1; // HTML 2.0
         'Ograve':   Codepoint := $00D2; // HTML 2.0
         'Oacute':   Codepoint := $00D3; // HTML 2.0
         'Ocirc':    Codepoint := $00D4; // HTML 2.0
         'Otilde':   Codepoint := $00D5; // HTML 2.0
         'Ouml':     Codepoint := $00D6; // HTML 2.0
         'times':    Codepoint := $00D7; // HTML 3.2
         'Oslash':   Codepoint := $00D8; // HTML 2.0
         'Ugrave':   Codepoint := $00D9; // HTML 2.0
         'Uacute':   Codepoint := $00DA; // HTML 2.0
         'Ucirc':    Codepoint := $00DB; // HTML 2.0
         'Uuml':     Codepoint := $00DC; // HTML 2.0
         'Yacute':   Codepoint := $00DD; // HTML 2.0
         'THORN':    Codepoint := $00DE; // HTML 2.0
         'szlig':    Codepoint := $00DF; // HTML 2.0
         'agrave':   Codepoint := $00E0; // HTML 2.0
         'aacute':   Codepoint := $00E1; // HTML 2.0
         'acirc':    Codepoint := $00E2; // HTML 2.0
         'atilde':   Codepoint := $00E3; // HTML 2.0
         'auml':     Codepoint := $00E4; // HTML 2.0
         'aring':    Codepoint := $00E5; // HTML 2.0
         'aelig':    Codepoint := $00E6; // HTML 2.0
         'ccedil':   Codepoint := $00E7; // HTML 2.0
         'egrave':   Codepoint := $00E8; // HTML 2.0
         'eacute':   Codepoint := $00E9; // HTML 2.0
         'ecirc':    Codepoint := $00EA; // HTML 2.0
         'euml':     Codepoint := $00EB; // HTML 2.0
         'igrave':   Codepoint := $00EC; // HTML 2.0
         'iacute':   Codepoint := $00ED; // HTML 2.0
         'icirc':    Codepoint := $00EE; // HTML 2.0
         'iuml':     Codepoint := $00EF; // HTML 2.0
         'eth':      Codepoint := $00F0; // HTML 2.0
         'ntilde':   Codepoint := $00F1; // HTML 2.0
         'ograve':   Codepoint := $00F2; // HTML 2.0
         'oacute':   Codepoint := $00F3; // HTML 2.0
         'ocirc':    Codepoint := $00F4; // HTML 2.0
         'otilde':   Codepoint := $00F5; // HTML 2.0
         'ouml':     Codepoint := $00F6; // HTML 2.0
         'divide':   Codepoint := $00F7; // HTML 3.2
         'oslash':   Codepoint := $00F8; // HTML 2.0
         'ugrave':   Codepoint := $00F9; // HTML 2.0
         'uacute':   Codepoint := $00FA; // HTML 2.0
         'ucirc':    Codepoint := $00FB; // HTML 2.0
         'uuml':     Codepoint := $00FC; // HTML 2.0
         'yacute':   Codepoint := $00FD; // HTML 2.0
         'thorn':    Codepoint := $00FE; // HTML 2.0
         'yuml':     Codepoint := $00FF; // HTML 2.0
         'OElig':    Codepoint := $0152; // HTML 4.0
         'oelig':    Codepoint := $0153; // HTML 4.0
         'Scaron':   Codepoint := $0160; // HTML 4.0
         'scaron':   Codepoint := $0161; // HTML 4.0
         'Yuml':     Codepoint := $0178; // HTML 4.0
         'fnof':     Codepoint := $0192; // HTML 4.0
         'circ':     Codepoint := $02C6; // HTML 4.0
         'tilde':    Codepoint := $02DC; // HTML 4.0
         'Alpha':    Codepoint := $0391; // HTML 4.0
         'Beta':     Codepoint := $0392; // HTML 4.0
         'Gamma':    Codepoint := $0393; // HTML 4.0
         'Delta':    Codepoint := $0394; // HTML 4.0
         'Epsilon':  Codepoint := $0395; // HTML 4.0
         'Zeta':     Codepoint := $0396; // HTML 4.0
         'Eta':      Codepoint := $0397; // HTML 4.0
         'Theta':    Codepoint := $0398; // HTML 4.0
         'Iota':     Codepoint := $0399; // HTML 4.0
         'Kappa':    Codepoint := $039A; // HTML 4.0
         'Lambda':   Codepoint := $039B; // HTML 4.0
         'Mu':       Codepoint := $039C; // HTML 4.0
         'Nu':       Codepoint := $039D; // HTML 4.0
         'Xi':       Codepoint := $039E; // HTML 4.0
         'Omicron':  Codepoint := $039F; // HTML 4.0
         'Pi':       Codepoint := $03A0; // HTML 4.0
         'Rho':      Codepoint := $03A1; // HTML 4.0
         'Sigma':    Codepoint := $03A3; // HTML 4.0
         'Tau':      Codepoint := $03A4; // HTML 4.0
         'Upsilon':  Codepoint := $03A5; // HTML 4.0
         'Phi':      Codepoint := $03A6; // HTML 4.0
         'Chi':      Codepoint := $03A7; // HTML 4.0
         'Psi':      Codepoint := $03A8; // HTML 4.0
         'Omega':    Codepoint := $03A9; // HTML 4.0
         'alpha':    Codepoint := $03B1; // HTML 4.0
         'beta':     Codepoint := $03B2; // HTML 4.0
         'gamma':    Codepoint := $03B3; // HTML 4.0
         'delta':    Codepoint := $03B4; // HTML 4.0
         'epsilon':  Codepoint := $03B5; // HTML 4.0
         'zeta':     Codepoint := $03B6; // HTML 4.0
         'eta':      Codepoint := $03B7; // HTML 4.0
         'theta':    Codepoint := $03B8; // HTML 4.0
         'iota':     Codepoint := $03B9; // HTML 4.0
         'kappa':    Codepoint := $03BA; // HTML 4.0
         'lambda':   Codepoint := $03BB; // HTML 4.0
         'mu':       Codepoint := $03BC; // HTML 4.0
         'nu':       Codepoint := $03BD; // HTML 4.0
         'xi':       Codepoint := $03BE; // HTML 4.0
         'omicron':  Codepoint := $03BF; // HTML 4.0
         'pi':       Codepoint := $03C0; // HTML 4.0
         'rho':      Codepoint := $03C1; // HTML 4.0
         'sigmaf':   Codepoint := $03C2; // HTML 4.0
         'sigma':    Codepoint := $03C3; // HTML 4.0
         'tau':      Codepoint := $03C4; // HTML 4.0
         'upsilon':  Codepoint := $03C5; // HTML 4.0
         'phi':      Codepoint := $03C6; // HTML 4.0
         'chi':      Codepoint := $03C7; // HTML 4.0
         'psi':      Codepoint := $03C8; // HTML 4.0
         'omega':    Codepoint := $03C9; // HTML 4.0
         'thetasym': Codepoint := $03D1; // HTML 4.0
         'upsih':    Codepoint := $03D2; // HTML 4.0
         'piv':      Codepoint := $03D6; // HTML 4.0
         'ensp':     Codepoint := $2002; // HTML 4.0
         'emsp':     Codepoint := $2003; // HTML 4.0
         'thinsp':   Codepoint := $2009; // HTML 4.0
         'zwnj':     Codepoint := $200C; // HTML 4.0
         'zwj':      Codepoint := $200D; // HTML 4.0
         'lrm':      Codepoint := $200E; // HTML 4.0
         'rlm':      Codepoint := $200F; // HTML 4.0
         'ndash':    Codepoint := $2013; // HTML 4.0
         'mdash':    Codepoint := $2014; // HTML 4.0
         'lsquo':    Codepoint := $2018; // HTML 4.0
         'rsquo':    Codepoint := $2019; // HTML 4.0
         'sbquo':    Codepoint := $201A; // HTML 4.0
         'ldquo':    Codepoint := $201C; // HTML 4.0
         'rdquo':    Codepoint := $201D; // HTML 4.0
         'bdquo':    Codepoint := $201E; // HTML 4.0
         'dagger':   Codepoint := $2020; // HTML 4.0
         'Dagger':   Codepoint := $2021; // HTML 4.0
         'bull':     Codepoint := $2022; // HTML 4.0
         'hellip':   Codepoint := $2026; // HTML 4.0
         'permil':   Codepoint := $2030; // HTML 4.0
         'prime':    Codepoint := $2032; // HTML 4.0
         'Prime':    Codepoint := $2033; // HTML 4.0
         'lsaquo':   Codepoint := $2039; // HTML 4.0
         'rsaquo':   Codepoint := $203A; // HTML 4.0
         'oline':    Codepoint := $203E; // HTML 4.0
         'frasl':    Codepoint := $2044; // HTML 4.0
         'euro':     Codepoint := $20AC; // HTML 4.0
         'image':    Codepoint := $2111; // HTML 4.0
         'weierp':   Codepoint := $2118; // HTML 4.0
         'real':     Codepoint := $211C; // HTML 4.0
         'trade':    Codepoint := $2122; // HTML 4.0
         'alefsym':  Codepoint := $2135; // HTML 4.0
         'larr':     Codepoint := $2190; // HTML 4.0
         'uarr':     Codepoint := $2191; // HTML 4.0
         'rarr':     Codepoint := $2192; // HTML 4.0
         'darr':     Codepoint := $2193; // HTML 4.0
         'harr':     Codepoint := $2194; // HTML 4.0
         'crarr':    Codepoint := $21B5; // HTML 4.0
         'lArr':     Codepoint := $21D0; // HTML 4.0
         'uArr':     Codepoint := $21D1; // HTML 4.0
         'rArr':     Codepoint := $21D2; // HTML 4.0
         'dArr':     Codepoint := $21D3; // HTML 4.0
         'hArr':     Codepoint := $21D4; // HTML 4.0
         'forall':   Codepoint := $2200; // HTML 4.0
         'part':     Codepoint := $2202; // HTML 4.0
         'exist':    Codepoint := $2203; // HTML 4.0
         'empty':    Codepoint := $2205; // HTML 4.0
         'nabla':    Codepoint := $2207; // HTML 4.0
         'isin':     Codepoint := $2208; // HTML 4.0
         'notin':    Codepoint := $2209; // HTML 4.0
         'ni':       Codepoint := $220B; // HTML 4.0
         'prod':     Codepoint := $220F; // HTML 4.0
         'sum':      Codepoint := $2211; // HTML 4.0
         'minus':    Codepoint := $2212; // HTML 4.0
         'lowast':   Codepoint := $2217; // HTML 4.0
         'radic':    Codepoint := $221A; // HTML 4.0
         'prop':     Codepoint := $221D; // HTML 4.0
         'infin':    Codepoint := $221E; // HTML 4.0
         'ang':      Codepoint := $2220; // HTML 4.0
         'and':      Codepoint := $2227; // HTML 4.0
         'or':       Codepoint := $2228; // HTML 4.0
         'cap':      Codepoint := $2229; // HTML 4.0
         'cup':      Codepoint := $222A; // HTML 4.0
         'int':      Codepoint := $222B; // HTML 4.0
         'there4':   Codepoint := $2234; // HTML 4.0
         'sim':      Codepoint := $223C; // HTML 4.0
         'cong':     Codepoint := $2245; // HTML 4.0
         'asymp':    Codepoint := $2248; // HTML 4.0
         'ne':       Codepoint := $2260; // HTML 4.0
         'equiv':    Codepoint := $2261; // HTML 4.0
         'le':       Codepoint := $2264; // HTML 4.0
         'ge':       Codepoint := $2265; // HTML 4.0
         'sub':      Codepoint := $2282; // HTML 4.0
         'sup':      Codepoint := $2283; // HTML 4.0
         'nsub':     Codepoint := $2284; // HTML 4.0
         'sube':     Codepoint := $2286; // HTML 4.0
         'supe':     Codepoint := $2287; // HTML 4.0
         'oplus':    Codepoint := $2295; // HTML 4.0
         'otimes':   Codepoint := $2297; // HTML 4.0
         'perp':     Codepoint := $22A5; // HTML 4.0
         'sdot':     Codepoint := $22C5; // HTML 4.0
         'vellip':   Codepoint := $22EE; // HTML 5.0
         'lceil':    Codepoint := $2308; // HTML 4.0
         'rceil':    Codepoint := $2309; // HTML 4.0
         'lfloor':   Codepoint := $230A; // HTML 4.0
         'rfloor':   Codepoint := $230B; // HTML 4.0
         'lang':     Codepoint := $2329; // HTML 4.0
         'rang':     Codepoint := $232A; // HTML 4.0
         'loz':      Codepoint := $25CA; // HTML 4.0
         'spades':   Codepoint := $2660; // HTML 4.0
         'clubs':    Codepoint := $2663; // HTML 4.0
         'hearts':   Codepoint := $2665; // HTML 4.0
         'diams':    Codepoint := $2666; // HTML 4.0
         else Exit('&'+E+';')
         end;
      Exit(UTF8_Char(Codepoint))
      end;
   
   Var Res:AnsiString; S,P,R,L,Amp:LongWord; E:AnsiString;
   begin
   Res:=''; SetLength(Res,Length(Str));
   R:=1; S:=1; P:=1; L := Length(Str);
   While (True) do begin
      // Find the ampersand
      While (P < L) and (Str[P]<>'&') do P+=1;
      If (P >= L) then Break
                  else Amp := P; 
      // Find the semicolon
      While (P <= L) and (Str[P]<>';') do P+=1;
      If (P > L) then Break
                 else E := DecodeEntity(Str[(Amp+1)..(P-1)]);
      // Add text prior to entity
      While (S < Amp) do begin
         Res[R] := Str[S]; R += 1; S += 1 end;
      // Add entity text
      S := 1; While (S <= Length(E)) do begin
         Res[R] := E[S]; R += 1; S += 1 end;
      // Advance pointer
      S := P + 1
      end;
   // If there's any text left to add, do it
   While (S < L) do begin
      Res[R]:=Str[S]; R += 1; S += 1 end;
   // Cut the string and return it
   SetLength(Res,R-1);
   Exit(Res)
   end;


Function F_ParseString(Func:TStrFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) = 0) then Exit(NewVal(VT_STR, ''));
   For C:=High(Arg^) downto 1 do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_STR)
      then S:=PStr(Arg^[0]^.Ptr)^
      else S:=ValAsStr(Arg^[0]);
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_STR,Func(S)))
   end;

Function F_DecodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(@DecodeURL, DoReturn, Arg)) end;

Function F_EncodeURL(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(@EncodeURL, DoReturn, Arg)) end;
   
Function F_EncodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(@EncodeHTML, DoReturn, Arg)) end;
   
Function F_DecodeHTML(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ParseString(@DecodeHTML, DoReturn, Arg)) end;
   
   
{$IFDEF CGI}
Function F_HTTPheader(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var K,V:AnsiString; C:LongWord; Match:Boolean;
   begin
   If (Length(Arg^)=0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg^[0]^.Typ = VT_STR)
      then K:=PStr(Arg^[0]^.Ptr)^
      else K:=ValAsStr(Arg^[0]);
   K:=LowerCase(Trim(K));
   If (Length(Arg^)>=2) then begin
      If (Arg^[1]^.Typ <> VT_STR) 
         then V:=PStr(Arg^[1]^.Ptr)^
         else V:=ValAsStr(Arg^[1]);
      Match := False;
      If (Length(Headers)>0) then
         For C:=Low(Headers) to High(Headers) do
             If (K = Headers[C].Key) then begin
                Headers[C].Val := V; Match:=True;
                Break end;
      If (Not Match) then begin
         SetLength(Headers, Length(Headers)+1);
         Headers[High(Headers)].Key:=K;
         Headers[High(Headers)].Val:=V
         end
      end else
   If (Length(Arg^)=1) then
      If (Length(Headers)>0) then
         For C:=Low(Headers) to High(Headers) do
             If (K = Headers[C].Key) then begin
                Headers[C] := Headers[High(Headers)];
                SetLength(Headers, Length(Headers)-1);
                Break end;
   Exit(F_(DoReturn, Arg))
   end;

Function F_HTTPcookie(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var K,V:AnsiString;
   begin
   If (Length(Arg^) < 2) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg^[0]^.Typ = VT_STR)
      then K:=PStr(Arg^[0]^.Ptr)^
      else K:=ValAsStr(Arg^[0]);
   If (Arg^[1]^.Typ = VT_STR) 
      then V:=PStr(Arg^[1]^.Ptr)^
      else V:=ValAsStr(Arg^[1]);
   SetLength(Cookies, Length(Cookies)+1);
   Cookies[High(Cookies)].Name := Trim(K);
   Cookies[High(Cookies)].Value := V;
   Exit(F_(DoReturn, Arg))
   end;
{$ENDIF}

Function FindChar(Const Str:TStr; Chr:Char; Offset:LongWord):LongWord;
   begin
   While (Offset <= Length(Str)) do begin
      If (Str[Offset] = Chr) then Exit(Offset);
      Offset += 1
      end;
   Exit(0)
   end;

Procedure ProcessGet();
   Var Q,K,V:AnsiString; P,S,L:LongWord; I,R:LongInt;
   begin
   SetLength(GetArr,0); 
   Q:=GetEnvironmentVariable('QUERY_STRING');
   S:=1; L:=Length(Q);
   While (S <= L) do begin
      SetLength(GetArr,Length(GetArr)+1);
      P:=FindChar(Q, '&', S);
      If (P>0) then begin
         V:=Copy(Q, S, P-1); S:=P+1
         end else begin
         V:=Q; S := L+1
         end;
      P:=FindChar(V, '=', 1);
      If (P>0) then begin
         K:=DecodeURL(Copy(V,1,P-1));
         V:=DecodeURL(Copy(V,P+1,L))
         end else begin
         K:=DecodeURL(V); V:=''
         end;
      I:=High(GetArr);
      While (I>0) and (K<GetArr[I-1].Key) do I-=1;
      If (I<High(GetArr)) then 
         For R:=High(GetArr) to (I+1)
             do GetArr[R]:=GetArr[R-1];
      GetArr[I].Key:=K;
      GetArr[I].Val:=V
      end;
   If (Length(GetArr)>0) then SortArr(GetArr, Low(GetArr), High(GetArr))
   end;

Procedure ProcessPost();
   Var Q,K,V:AnsiString; P:LongWord; I,R:LongInt; S,L:QWord; Ch:Char;
   begin
   SetLength(PostArr,0);
   Q:=GetEnvironmentVariable('CONTENT_LENGTH');
   L:=Values.StrToInt(Q); S:=L; Q:=''; SetLength(Q,L);
   While (S<L) do begin Read(Ch); If Eoln then Readln(); Q[S]:=Ch; S+=1 end;
   S := 1; L += 1;
   While (S <= L) do begin
      SetLength(PostArr,Length(PostArr)+1);
      P:=FindChar(Q, '&', S);
      If (P>0) then begin
         V:=Copy(Q,S,P-1); S := P+1
         end else begin
         V:=Q; S := L+1
         end;
      P:=FindChar(V, '=', 1);
      If (P>0) then begin
         K:=DecodeURL(Copy(V,1,P-1));
         V:=DecodeURL(Copy(V,P+1,L)) //Delete(V,1,P)
         end else begin
         K:=DecodeURL(V); V:=''
         end;
      I:=High(PostArr);
      While (I>0) and (K<PostArr[I-1].Key) do I-=1;
      If (I<High(PostArr)) then 
         For R:=High(PostArr) to (I+1)
             do PostArr[R]:=PostArr[R-1];
      PostArr[I].Key:=K;
      PostArr[I].Val:=V
      end;
   If (Length(PostArr)>0) then SortArr(PostArr, Low(PostArr), High(PostArr))
   end;

Procedure ProcessCake();
   Var Q,K,V:AnsiString; P,S,L:LongWord; I,R:LongInt;
   begin
   SetLength(CakeArr,0);
   Q:=GetEnvironmentVariable('HTTP_COOKIE');
   S:=1; L:=Length(Q);
   While (S <= L) do begin
      SetLength(CakeArr,Length(CakeArr)+1);
      P:=FindChar(Q, '&', S);
      If (P>0) then begin
         V:=Copy(Q,S,P-1); S := P+1
         end else begin
         V:=Q; S:=L+1
         end;
      FindChar(V, '=', 1);
      If (P>0) then begin
         K:=DecodeURL(Copy(V,1,P-1));
         V:=DecodeURL(Copy(V,P+1,L)) //Delete(V,1,P)
         end else begin
         K:=DecodeURL(V); V:=''
         end;
      I:=High(CakeArr);
      While (I>0) and (K<CakeArr[I-1].Key) do I-=1;
      If (I<High(CakeArr)) then 
         For R:=High(CakeArr) to (I+1)
             do CakeArr[R]:=CakeArr[R-1];
      CakeArr[I].Key:=K;
      CakeArr[I].Val:=V
      end;
   If (Length(CakeArr)>0) then SortArr(CakeArr, Low(CakeArr), High(CakeArr))
   end;

Function ArrSet(Var Arr:TKeyValArr; Key:AnsiString;L,R:LongInt):Boolean;
   Var Mid:LongWord;
   begin
   If (L>R) then Exit(False);
   Mid:=(L+R) div 2;
   Case Sign(CompareStr(Key,Arr[Mid].Key)) of
      -1: Exit(ArrSet(Arr, Key,L,Mid-1));
       0: Exit(True);
      +1: Exit(ArrSet(Arr, Key,Mid+1,R));
   end end;

Function ArrSet(Var Arr:TKeyValArr; Key:AnsiString):Boolean;
   begin
   If (Length(Arr)>0)
      then Exit(ArrSet(Arr, Key,Low(Arr),High(Arr)))
      else Exit(False)
   end;

Function ArrStr(Var Arr:TKeyValArr; Key:AnsiString;L,R:LongInt):AnsiString;
   Var Mid:LongWord;
   begin
   If (L>R) then Exit('');
   Mid:=(L+R) div 2;
   Case Sign(CompareStr(Key,Arr[Mid].Key)) of
      -1: Exit(ArrStr(Arr, Key,L,Mid-1));
       0: Exit(Arr[Mid].Val);
      +1: Exit(ArrStr(Arr, Key,Mid+1,R));
   end end;

Function ArrStr(Var Arr:TKeyValArr; Key:AnsiString):AnsiString;
   begin
   If (Length(Arr)>0)
      then Exit(ArrStr(Arr, Key,Low(Arr),High(Arr)))
      else Exit('')
   end;

Function ArrStr(Var Arr:TKeyValArr; Num:LongWord):AnsiString;
   begin
   If (Num<Length(Arr))
      then Exit(Arr[Num].Val)
      else Exit('')
   end;

Function ArrKey(Var Arr:TKeyValArr; Num:LongWord):AnsiString;
   begin
   If (Num<Length(Arr))
      then Exit(Arr[Num].Key)
      else Exit('')
   end;

Function ArrNum(Var Arr:TKeyValArr):LongWord;
   begin Exit(Length(Arr)) end;

{$IFNDEF CGI}
Function F_GetProcess(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   ProcessGet();
   If (DoReturn) then Exit(NilVal()) else Exit(Nil)
   end;

Function F_PostProcess(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   ProcessPost();
   If (DoReturn) then Exit(NilVal()) else Exit(Nil)
   end;

Function F_CakeProcess(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   ProcessCake();
   If (DoReturn) then Exit(NilVal()) else Exit(Nil)
   end;
{$ENDIF}

Function F_ArrIs_(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var B:Boolean; C:LongWord; 
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_BOO,True));
   B:=True; For C:=High(Arg^) downto Low(Arg^) do begin
      If (Not ArrSet(Arr, ValAsStr(Arg^[C]))) then B:=False;
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_ArrVal(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then S:=ArrStr(Arr, PQInt(Arg^[0]^.Ptr)^) else
   If (Arg^[0]^.Typ = VT_STR)
      then S:=ArrStr(Arr, PStr(Arg^[0]^.Ptr)^)
      else S:=ArrStr(Arr, ValAsStr(Arg^[0]));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_ArrKey(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then S:=ArrKey(Arr, PQInt(Arg^[0]^.Ptr)^)
      else S:=ArrKey(Arr, ValAsInt(Arg^[0]));
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_ArrNum(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (DoReturn) then Exit(NewVal(VT_INT,ArrNum(Arr))) else Exit(NIL)
   end;

Function F_ArrDict(Var Arr:TKeyValArr; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; V:PValue; Dic:PDict;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Not DoReturn) then Exit(NIL);
   V:=EmptyVal(VT_DIC); Dic:=PDict(V^.Ptr);
   If (Length(Arr) > 0) then 
      For C:=Low(Arr) to High(Arr) do
          Dic^.SetVal(Arr[C].Key, NewVal(VT_STR, Arr[C].Val));
   Exit(V)
   end;

Function F_GetIs_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrIs_(GetArr, DoReturn, Arg)) end;
   
Function F_GetVal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrVal(GetArr, DoReturn, Arg)) end;
   
Function F_GetKey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrKey(GetArr, DoReturn, Arg)) end;
   
Function F_GetNum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrNum(GetArr, DoReturn, Arg)) end;
   
Function F_GetDict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrDict(GetArr, DoReturn, Arg)) end;

Function F_PostIs_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrIs_(PostArr, DoReturn, Arg)) end;
   
Function F_PostVal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrVal(PostArr, DoReturn, Arg)) end;
   
Function F_PostKey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrKey(PostArr, DoReturn, Arg)) end;
   
Function F_PostNum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrNum(PostArr, DoReturn, Arg)) end;
   
Function F_PostDict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrDict(PostArr, DoReturn, Arg)) end;
   
Function F_CakeIs_(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrIs_(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeVal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrVal(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeKey(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrKey(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeNum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrNum(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeDict(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_ArrDict(CakeArr, DoReturn, Arg)) end;

Function F_Doctype(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Const HTML5 = '<!DOCTYPE html>';
         HTML4_LOOSE = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">';
         XHTML1_1 = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">';
         DEFAULT = HTML5;
   Var C:LongWord; S,R:AnsiString; I:Int64;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_STR, DEFAULT));
   For C:=High(Arg^) downto 1 do
      If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ = VT_STR)
      then begin
      S:=PStr(Arg^[0]^.Ptr)^;
      If (S='html5') then
         R:=(HTML5) else
      If (S='html4-strict') then
         R:=('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">') else
      If (S='html4-transitional') or (S='html4-loose') then
         R:=(HTML4_LOOSE) else
      If (S='html4-frameset') then
         R:=('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">') else
      If (S='xhtml1-strict') then
         R:=('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">') else
      If (S='xhtml1-transitional') then
         R:=('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">') else
      If (S='xhtml1-frameset') then
         R:=('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">') else
      If (S='xhtml1.1') then
         R:=(XHTML1_1) else
         {else} R:=DEFAULT
      end else begin
      I:=ValAsInt(Arg^[0]);
      If (I = 5) then 
         R := (HTML5) else
      If (I = 4) then 
         R := (HTML4_LOOSE) else
      If (I = 1) then
         R := (XHTML1_1) else
         {else} R:=DEFAULT
      end;
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   Exit(NewVal(VT_STR,R))
   end;


end.
