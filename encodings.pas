unit encodings;

{$INCLUDE defines.inc}

interface

Function EncodeURL(Const Str:AnsiString):AnsiString;
Function DecodeURL(Const Str:AnsiString):AnsiString;
Function EncodeHTML(Const Str:AnsiString):AnsiString;
Function DecodeHTML(Const Str:AnsiString):AnsiString;

Function EncodeHex(Const Str:AnsiString):AnsiString;
Function DecodeHex(Const Str:AnsiString):AnsiString;
Function EncodeBase64(Const Str:AnsiString):AnsiString;
Function DecodeBase64(Const Str:AnsiString):AnsiString;

implementation
   uses Convert, Functions_Strings;

Function DecodeURL(Const Str:AnsiString):AnsiString;
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

Function EncodeURL(Const Str:AnsiString):AnsiString;
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

Function EncodeHTML(Const Str:AnsiString):AnsiString;
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


Function DecodeHTML(Const Str:AnsiString):AnsiString;
   
   Function DecodeEntity(Const E:AnsiString):AnsiString;
      Var Codepoint:Int64; 
      begin
      If (E[1]='#') then begin
         If (E[2]='x') then Codepoint:=Convert.StrToHex(E)
                       else Codepoint:=Convert.StrToInt(E)
         end else Case(E) of
         {$DEFINE _ := : Codepoint := }
         {$INCLUDE encodings-HTMLentities.min.inc}
         {$UNDEF _}
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

Function EncodeHex(Const Str:AnsiString):AnsiString;
   Var C,P,L:LongWord;
   begin
   L:=Length(Str); C := 1; P := 1; 
   SetLength(Result,L*2);
   While (C <= L) do begin
      Result[P  ] := Sys16Dig[Ord(Str[C]) div 16];
      Result[P+1] := Sys16Dig[Ord(Str[C]) mod 16];
      C += 1; P += 2
   end end;

Function DecodeHex(Const Str:AnsiString):AnsiString;
   Var C,P,L:LongWord;
   begin
   C := 1; P := 1;
   L:=Length(Str); L := L div 2; SetLength(Result,L); 
   While (C <= L) do begin
      Result[C] := Chr(StrToHex(Str[P..P+1]));
      C += 1; P += 2
   end end;

Function EncodeBase64(Const Str:AnsiString):AnsiString;
   Const CharTable = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+\';
   Var OL,NL,OP,NP:QWord; V:LongWord;
   begin
   OL := Length(Str); NL := OL div 3;
   If (OL mod 3 > 0) then NL += 1; NL *= 4;
   SetLength(Result,NL); OP := 3; NP := 4;
   While (OP <= OL) do begin
      V:=(((Ord(Str[OP-2])*256)+Ord(Str[OP-1]))*256)+Ord(Str[OP]);
      Result[NP  ] := CharTable[1+(V mod 64)]; V := V div 64;
      Result[NP-1] := CharTable[1+(V mod 64)]; V := V div 64;
      Result[NP-2] := CharTable[1+(V mod 64)];
      Result[NP-3] := CharTable[1+((V div 64) mod 64)];
      NP += 4; OP += 3
      end;
   NL := OL - (OP - 3);
   If (NL > 0) then begin
      V:=Ord(Str[OP-2]);
      If (NL = 1) then begin
         V := (V * 256 * 256) div (64*64);
         Result[NP  ] := '=';
         Result[NP-1] := '=';
         Result[NP-2] := CharTable[1+(V mod 64)];
         Result[NP-3] := CharTable[1+((V div 64) mod 64)]
         end else begin
         V:=(((V * 256) + Ord(Str[OP-1])) * 256 ) div 64;
         Result[NP  ] := '='; 
         Result[NP-1] := CharTable[1+(V mod 64)]; V := V div 64;
         Result[NP-2] := CharTable[1+(V mod 64)];
         Result[NP-3] := CharTable[1+((V div 64) mod 64)]
   end end end;

Function DecodeBase64(Const Str:AnsiString):AnsiString;
   
   Function Ord64(Ch:Char):Byte;
      begin
      If (Ch < #48) then begin
         If (Ch = #43) then Result:=62 else
         If (Ch = #47) then Result:=63 else
                      {else}Result:=0
         end else
      If (Ch <  #58) then Result := Ord(Ch)-48+52 else
      If (Ch <  #65) then Result := 0 else
      If (Ch <  #91) then Result := Ord(Ch)-65+00 else
      If (Ch <  #97) then Result := 0 else
      If (Ch < #123) then Result := Ord(Ch)-97+26 else
                    {else}Result := 0
      end;
      
   Var OL,NL,OP,NP:QWord; V:LongWord;
   begin
   OL := Length(Str); If (Str[OL] = '=') then OL -= 1;
   NL := (OL div 4) * 3; SetLength(Result, NL);
   OP := 4; NP := 3;
   While (OP <= OL) do begin
      V:=(((((Ord64(Str[OP-3])*64)+Ord64(Str[OP-2]))*64)+Ord64(Str[OP-1]))*64)+Ord64(Str[OP]);
      Result[NP  ] := Chr(V mod 256); V := V div 256;
      Result[NP-1] := Chr(V mod 256);
      Result[NP-2] := Chr((V div 256) mod 256);
      OP += 4; NP += 3
      end;
   OL := Length(Str);
   If (Str[OL] = '=') then begin
      V:=((((((Ord64(Str[OL-3])*64)+Ord64(Str[OL-2]))*64)+Ord64(Str[OL-1]))*64)+Ord64(Str[OL])) div 256;
      If (Str[OL-1] <> '=') then begin
         SetLength(Result,NL+2);
         Result[NL+2] := Chr(V mod 256)
         end else SetLength(Result,NL+1);
      Result[NL+1] := Chr((V div 256) mod 256)
   end end;

end.
