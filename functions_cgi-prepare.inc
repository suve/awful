Var Q,K,V:AnsiString; P,S,L,AL:LongWord;
begin
   SetLength(__ARRAY__,0); 
   Q:=GetEnvironmentVariable(__ENVVAR__);
   {$IFDEF __POST__}
      L:=Convert.StrToInt(Q); SetLength(Q,L);
      For S:=1 to L do Read(Q[S]);
   {$ELSE}
      L:=Length(Q);
   {$ENDIF}
   S:=1; 
   While (S <= L) do begin
   
      P:=PosEx('&', Q, S);
      If (P>0) then begin
         V:=Copy(Q, S, P-S); S:=P+1
      end else begin
         V:=Copy(Q, S, L); S := L+1
      end;
      
      P:=PosEx('=', V, 1);
      If (P>0) then begin
         K:=DecodeURL(Copy(V,1,P-1));
         V:=DecodeURL(Copy(V,P+1,L))
      end else begin
         K:=DecodeURL(V); V:=''
      end;
      
      AL := Length(__ARRAY__);
      SetLength(__ARRAY__, AL + 1);
      
      __ARRAY__[AL].Key := K;
      __ARRAY__[AL].Val := V
   end;
   
   If (Length(__ARRAY__) > 0) then SortArr(__ARRAY__, Low(__ARRAY__), High(__ARRAY__))
