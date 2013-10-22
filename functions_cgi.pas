unit functions_cgi;

{$INCLUDE defines.inc}

interface
   uses Values;


Type TKeyVal = record
     Key, Val : AnsiString
     end;
     
     TKeyValArr = Array of TKeyVal;
     
     TCookie = record
     Name, Value : AnsiString
     end;

{$IFDEF CGI}
Var Headers:TKeyValArr;
    Cookies:Array of TCookie;
{$ENDIF}

Procedure Register(FT:PFunTrie);


Function F_DecodeURL(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_EncodeURL(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_EncodeHTML(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_Doctype(DoReturn:Boolean; Arg:Array of PValue):PValue;

{$IFDEF CGI}
Function F_HTTPheader(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_HTTPcookie(DoReturn:Boolean; Arg:Array of PValue):PValue;
{$ELSE}
Function F_GetProcess(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_PostProcess(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_CakeProcess(DoReturn:Boolean; Arg:Array of PValue):PValue;
{$ENDIF}

Function F_GetIs_(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_GetVal(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_GetKey(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_GetNum(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_GetDict(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_PostIs_(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_PostVal(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_PostKey(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_PostNum(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_PostDict(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_CakeIs_(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_CakeVal(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_CakeKey(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_CakeNum(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_CakeDict(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function EncodeURL(Str:AnsiString):AnsiString;
Function EncodeHTML(Str:AnsiString):AnsiString;

Procedure ProcessGet();
Procedure ProcessPost();
Procedure ProcessCake();
Procedure FreeArrays();

implementation
   uses SysUtils, Math, EmptyFunc;


Procedure Register(FT:PFunTrie);
   begin
   // String thingies
   FT^.SetVal('decodeURL',@F_DecodeURL);
   FT^.SetVal('encodeURL',@F_DecodeURL);
   FT^.SetVal('encodeHTML',@F_EncodeHTML);
   FT^.SetVal('doctype',@F_Doctype);
   // GET related functions
   FT^.SetVal('get-is',@F_GetIs_);
   FT^.SetVal('get-val',@F_GetVal);
   FT^.SetVal('get-key',@F_GetKey);
   FT^.SetVal('get-num',@F_GetNum);
   FT^.SetVal('get-dict',@F_GetDict);
   // POST related functions
   FT^.SetVal('post-is',@F_PostIs_);
   FT^.SetVal('post-val',@F_PostVal);
   FT^.SetVal('post-key',@F_PostKey);
   FT^.SetVal('post-num',@F_PostNum);
   FT^.SetVal('post-dict',@F_PostDict);
   // HTTP-Cookie related functions
   FT^.SetVal('cookie-is',@F_CakeIs_);
   FT^.SetVal('cookie-val',@F_CakeVal);
   FT^.SetVal('cookie-key',@F_CakeKey);
   FT^.SetVal('cookie-num',@F_CakeNum);
   FT^.SetVal('cookie-dict',@F_CakeDict);
   // Functions available in CGI mode only
   FT^.SetVal('http-header', {$IFDEF CGI} @F_HTTPheader {$ELSE} @F_ {$ENDIF} );
   FT^.SetVal('http-cookie', {$IFDEF CGI} @F_HTTPcookie {$ELSE} @F_ {$ENDIF} );
   // Function available only outside CGI mode
   FT^.SetVal('get-prepare', {$IFNDEF CGI} @F_GetProcess {$ELSE} @F_ {$ENDIF} );
   FT^.SetVal('post-prepare', {$IFNDEF CGI} @F_PostProcess {$ELSE} @F_ {$ENDIF} );
   FT^.SetVal('cookie-prepare', {$IFNDEF CGI} @F_CakeProcess {$ELSE} @F_ {$ENDIF} );
   end;


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
   Var Res:AnsiString; P{,R}:LongWord;
   begin
   Res:=''; //SetLength(Res,Length(Str));
   {R:=1;} P:=1;
   While (P<=Length(Str)) do
      If (((Str[P]>=#48) and (Str[P]<= #57)) or //0-9
          ((Str[P]>=#65) and (Str[P]<= #90)) or //A-Z
          ((Str[P]>=#97) and (Str[P]<=#122)) or //a-z
          (Pos(Str[P],'-_.~')>0))
         then Res+=Str[P]
         else Res+='%'+HexToStr(Ord(Str[P]),2);
   Exit(Res)
   end;

Function EncodeHTML(Str:AnsiString):AnsiString;
   Var Res:AnsiString; P{,R}:LongWord;
   begin
   Res:=''; //SetLength(Res,Length(Str));
   {R:=1;} P:=1;
   While (P<=Length(Str)) do
      Case Str[P] of
         '"': begin Res+='&quot;'; {R+=6;} P+=1 end;
         '&': begin Res+='&amp;';  {R+=5;} P+=1 end;
         '<': begin Res+='&lt;';   {R+=4;} P+=1 end;
         '>': begin Res+='&gt;';   {R+=4;} P+=1 end;
         else begin Res+=Str[P];   {R+=1;} P+=1 end
      end;
   //SetLength(Res, R);
   Exit(Res)
   end;

Function F_DecodeURL(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg) = 0) then Exit(NewVal(VT_STR, ''));
   For C:=High(Arg) downto 1 do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=PStr(Arg[0]^.Ptr)^
      else begin
      V:=ValToStr(Arg[0]);
      S:=PStr(V^.Ptr)^;
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,DecodeURL(S)))
   end;

Function F_EncodeURL(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=PStr(Arg[0]^.Ptr)^
      else begin
      V:=ValToStr(Arg[0]);
      S:=PStr(V^.Ptr)^;
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,EncodeURL(S)))
   end;

Function F_EncodeHTML(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=PStr(Arg[0]^.Ptr)^
      else begin
      V:=ValToStr(Arg[0]);
      S:=PStr(V^.Ptr)^;
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,EncodeHTML(S)))
   end;

{$IFDEF CGI}
Function F_HTTPheader(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var T:PValue; K,V:AnsiString; C:LongWord; Match:Boolean;
   begin
   If (Length(Arg)=0) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg[0]^.Typ <> VT_STR) then begin
      T:=ValToStr(Arg[0]); K:=PStr(T^.Ptr)^; FreeVal(T)
      end else K:=PStr(Arg[0]^.Ptr)^;
   K:=LowerCase(Trim(K));
   If (Length(Arg)>=2) then begin
      If (Arg[1]^.Typ <> VT_STR) then begin
         T:=ValToStr(Arg[1]); V:=PStr(T^.Ptr)^; FreeVal(T)
         end else V:=PStr(Arg[1]^.Ptr)^;
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
   If (Length(Arg)=1) then
      If (Length(Headers)>0) then
         For C:=Low(Headers) to High(Headers) do
             If (K = Headers[C].Key) then begin
                Headers[C] := Headers[High(Headers)];
                SetLength(Headers, Length(Headers)-1);
                Break end;
   Exit(F_(DoReturn, Arg))
   end;

Function F_HTTPcookie(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var T:PValue; K,V:AnsiString;
   begin
   If (Length(Arg) < 2) then If (DoReturn) then Exit(NilVal()) else Exit(NIL);
   If (Arg[0]^.Typ <> VT_STR) then begin
      T:=ValToStr(Arg[0]); K:=PStr(T^.Ptr)^; FreeVal(T)
      end else K:=PStr(Arg[0]^.Ptr)^;
   If (Arg[1]^.Typ <> VT_STR) then begin
      T:=ValToStr(Arg[1]); V:=PStr(T^.Ptr)^; FreeVal(T)
      end else V:=PStr(Arg[1]^.Ptr)^;
   SetLength(Cookies, Length(Cookies)+1);
   Cookies[High(Cookies)].Name := Trim(K);
   Cookies[High(Cookies)].Value := V;
   Exit(F_(DoReturn, Arg))
   end;
{$ENDIF}

Procedure ProcessGet();
   Var Q,K,V:AnsiString; P:LongWord; I,R:LongInt;
   begin
   SetLength(GetArr,0);
   Q:=GetEnvironmentVariable('QUERY_STRING');
   While (Length(Q)>0) do begin
      SetLength(GetArr,Length(GetArr)+1);
      P:=Pos('&',Q);
      If (P>0) then begin
         V:=Copy(Q,1,P-1);
         Delete(Q,1,P)
         end else begin
         V:=Q; Q:=''
         end;
      P:=Pos('=',V);
      If (P>0) then begin
         K:=Copy(V,1,P-1);
         Delete(V,1,P)
         end else begin
         K:=V; V:=''
         end;
      K:=DecodeURL(K); V:=DecodeURL(V);
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
   Var Q,K,V:AnsiString; P:LongWord; I,R:LongInt; L:QWord; Ch:Char;
   begin
   SetLength(PostArr,0);
   Q:=GetEnvironmentVariable('CONTENT_LENGTH');
   L:=Values.StrToInt(Q); Q:=''; SetLength(Q,L);
   While (L>0) do begin Read(Ch); If Eoln then Readln(); Q:=Q+Ch; L-=1 end;
   While (Length(Q)>0) do begin
      SetLength(PostArr,Length(PostArr)+1);
      P:=Pos('&',Q);
      If (P>0) then begin
         V:=Copy(Q,1,P-1);
         Delete(Q,1,P)
         end else begin
         V:=Q; Q:=''
         end;
      P:=Pos('=',V);
      If (P>0) then begin
         K:=Copy(V,1,P-1);
         Delete(V,1,P)
         end else begin
         K:=V; V:=''
         end;
      K:=DecodeURL(K); V:=DecodeURL(V);
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
   Var Q,K,V:AnsiString; P:LongWord; I,R:LongInt;
   begin
   SetLength(CakeArr,0);
   Q:=GetEnvironmentVariable('HTTP_COOKIE');
   While (Length(Q)>0) do begin
      SetLength(CakeArr,Length(CakeArr)+1);
      P:=Pos(';',Q);
      If (P>0) then begin
         V:=Copy(Q,1,P-1);
         Delete(Q,1,P)
         end else begin
         V:=Q; Q:=''
         end;
      P:=Pos('=',V);
      If (P>0) then begin
         K:=Copy(V,1,P-1);
         Delete(V,1,P)
         end else begin
         K:=V; V:=''
         end;
      K:=DecodeURL(K); V:=DecodeURL(V);
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
Function F_GetProcess(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   ProcessGet();
   If (DoReturn) then Exit(NilVal()) else Exit(Nil)
   end;

Function F_PostProcess(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   ProcessPost();
   If (DoReturn) then Exit(NilVal()) else Exit(Nil)
   end;

Function F_CakeProcess(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   ProcessCake();
   If (DoReturn) then Exit(NilVal()) else Exit(Nil)
   end;
{$ENDIF}

Function F_ArrIs_(Var Arr:TKeyValArr; DoReturn:Boolean; Var Arg:Array of PValue):PValue;
   Var B:Boolean; C:LongWord; V:PValue;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,True));
   B:=True; For C:=High(Arg) downto Low(Arg) do begin
      If (Arg[C]^.Typ<>VT_STR)
         then begin
            V:=ValToStr(Arg[C]);
            If (Not ArrSet(Arr, PStr(V^.Ptr)^)) then B:=False;
            FreeVal(V);
         end else
         If (Not ArrSet(Arr, PStr(Arg[C]^.Ptr)^)) then B:=False;
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_ArrVal(Var Arr:TKeyValArr; DoReturn:Boolean; Var Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
      then S:=ArrStr(Arr, PQInt(Arg[0]^.Ptr)^) else
   If (Arg[0]^.Typ = VT_STR)
      then S:=ArrStr(Arr, PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=ArrStr(Arr, PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_ArrKey(Var Arr:TKeyValArr; DoReturn:Boolean; Var Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
      then S:=ArrKey(Arr, PQInt(Arg[0]^.Ptr)^)
      else begin
      V:=ValToInt(Arg[0]);
      S:=ArrKey(Arr, PQInt(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_ArrNum(Var Arr:TKeyValArr; DoReturn:Boolean; Var Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_INT,ArrNum(Arr))) else Exit(NIL)
   end;

Function F_ArrDict(Var Arr:TKeyValArr; DoReturn:Boolean; Var Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; Dic:PValTrie;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Not DoReturn) then Exit(NIL);
   V:=EmptyVal(VT_DIC); Dic:=PValTrie(V^.Ptr);
   If (Length(Arr) > 0) then 
      For C:=Low(Arr) to High(Arr) do
          Dic^.SetVal(Arr[C].Key, NewVal(VT_STR, Arr[C].Val));
   Exit(V)
   end;

Function F_GetIs_(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrIs_(GetArr, DoReturn, Arg)) end;
   
Function F_GetVal(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrVal(GetArr, DoReturn, Arg)) end;
   
Function F_GetKey(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrKey(GetArr, DoReturn, Arg)) end;
   
Function F_GetNum(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrNum(GetArr, DoReturn, Arg)) end;
   
Function F_GetDict(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrDict(GetArr, DoReturn, Arg)) end;

Function F_PostIs_(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrIs_(PostArr, DoReturn, Arg)) end;
   
Function F_PostVal(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrVal(PostArr, DoReturn, Arg)) end;
   
Function F_PostKey(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrKey(PostArr, DoReturn, Arg)) end;
   
Function F_PostNum(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrNum(PostArr, DoReturn, Arg)) end;
   
Function F_PostDict(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrDict(PostArr, DoReturn, Arg)) end;
   
Function F_CakeIs_(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrIs_(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeVal(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrVal(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeKey(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrKey(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeNum(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrNum(CakeArr, DoReturn, Arg)) end;
   
Function F_CakeDict(DoReturn:Boolean; Arg:Array of PValue):PValue;
   begin Exit(F_ArrDict(CakeArr, DoReturn, Arg)) end;

Function F_Doctype(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Const HTML5 = '<!DOCTYPE html>';
         HTML4_LOOSE = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">';
         XHTML1_1 = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">';
         DEFAULT = HTML5;
   Var C:LongWord; V:PValue; S,R:AnsiString; I:Int64;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)=0) then Exit(NewVal(VT_STR, DEFAULT));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then begin
      S:=PStr(Arg[0]^.Ptr)^;
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
      V:=ValToInt(Arg[0]); I:=(PQInt(V^.Ptr)^); FreeVal(V);
      If (I = 5) then 
         R := (HTML5) else
      If (I = 4) then 
         R := (HTML4_LOOSE) else
      If (I = 1) then
         R := (XHTML1_1) else
         {else} R:=DEFAULT
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,R))
   end;


end.
