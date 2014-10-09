unit encodings;

{$INCLUDE defines.inc}

interface
   uses Values;

Function EncodeURL(Const Str:AnsiString):AnsiString;
Function DecodeURL(Const Str:AnsiString):AnsiString;
Function EncodeHTML(Const Str:AnsiString):AnsiString;
Function DecodeHTML(Const Str:AnsiString):AnsiString;

Function EncodeHex(Const Str:AnsiString):AnsiString;
Function DecodeHex(Const Str:AnsiString):AnsiString;
Function EncodeBase64(Const Str:AnsiString):AnsiString;
Function DecodeBase64(Const Str:AnsiString):AnsiString;

Function EncodeJSON(Const V:PValue):AnsiString;
Function DecodeJSON(Const JSONstring:AnsiString):PValue;


implementation
   uses
      SysUtils, JSONparser, fpJSON,
      Convert, 
      Functions_Strings;

Function DecodeURL(Const Str:AnsiString):AnsiString;
   Var P,R:LongWord;
   begin
      Result:=''; SetLength(Result,Length(Str));
      
      R:=1; P:=1;
      While (P<=Length(Str)) do
         If (Str[P]='%') then begin
            Result[R]:=Chr(StrToHex(Str[P+1..P+2]));
            P+=3; R+=1
         end else
         If (Str[P]='+') then begin
            Result[R]:=' ';    R+=1; P+=1
         end else
         If (Str[P]<>#0)
            then begin Result[R]:=Str[P]; R+=1; P+=1 end
            else P+=1;
      
      SetLength(Result,R-1);
      Exit(Result)
   end;

Function EncodeURL(Const Str:AnsiString):AnsiString;
   Var P:LongWord;
   begin
      Result:=''; 
      For P:=1 to Length(Str) do
         If (((Str[P]>=#48) and (Str[P]<= #57)) or // 0-9
             ((Str[P]>=#65) and (Str[P]<= #90)) or // A-Z
             ((Str[P]>=#97) and (Str[P]<=#122)) or // a-z
             (Pos(Str[P],'-_.~')>0))               // non-reserved symbols
         then Result += Str[P]
         else Result += '%'+HexToStr(Ord(Str[P]),2)
   end;

Function EncodeHTML(Const Str:AnsiString):AnsiString;
   Var P:LongWord;
   begin
      Result:=''; 
      For P:=1 to Length(Str) do
         Case Str[P] of
            '"': begin Result += '&quot;'; {R+=6; P+=1} end;
            '&': begin Result += '&amp;';  {R+=5; P+=1} end;
            '<': begin Result += '&lt;';   {R+=4; P+=1} end;
            '>': begin Result += '&gt;';   {R+=4; P+=1} end;
            else begin Result += Str[P];   {R+=1; P+=1} end
         end
   end;


Function DecodeHTML(Const Str:AnsiString):AnsiString;
   
   Function DecodeEntity(Const E:AnsiString):AnsiString;
      Var Codepoint:Int64; 
      begin
         If (E[1]='#') then begin
            If (E[2]='x')
               then Codepoint:=Convert.StrToHex(E)
               else Codepoint:=Convert.StrToInt(E)

         end else Case(E) of
            {$DEFINE _ := : Codepoint := }
            {$INCLUDE encodings-HTMLentities.min.inc}
            {$UNDEF _}
            else Exit('&'+E+';')
         end;

         Exit(UTF8_Char(Codepoint))
      end;
   
   Var S,P,R,L,Amp:LongWord; E:AnsiString;
   begin
      Result:=''; SetLength(Result,Length(Str));
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
            Result[R] := Str[S]; R += 1; S += 1 end;
      
         // Add entity text
         S := 1; While (S <= Length(E)) do begin
            Result[R] := E[S]; R += 1; S += 1 end;
      
         // Advance pointer
         S := P + 1
      end;
      
      // If there's any text left to add, do it
      While (S < L) do begin
         Result[R]:=Str[S]; R += 1; S += 1 end;
      
      // Cut the string and return it
      SetLength(Result,R-1)
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
         end
   end end;

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
         end else
            SetLength(Result,NL+1);
         
         Result[NL+1] := Chr((V div 256) mod 256)
   end end;

Function EncodeJSON(Const V:PValue):AnsiString;
   Var AEA:TArr.TEntryArr; DEA:TDict.TEntryArr;
       C,H:LongWord;
   begin Case (V^.Typ) of
      VT_NIL:
         Result := 'null';
      
      VT_INT, VT_BIN, VT_OCT, VT_HEX:
         Result := IntToStr(V^.Int^);
      
      VT_FLO:
         Result := SysUtils.FloatToStr(V^.Flo^);
      
      VT_STR:
         Result := '"'+StringToJSONString(V^.Str^)+'"';
      
      VT_UTF:
         Result := '"'+StringToJSONString(V^.Utf^.ToAnsiString())+'"';
      
      VT_BOO:
         If (V^.Boo^)
            then Result := 'true'
            else Result := 'false';
      
      VT_FIL:
         Result := '{'+
            '"path":"'+StringToJSONString(V^.Fil^.Pth)+'",'+
            '"mode":"'+StringToJSONString(V^.Fil^.arw)+
            '}';
      
      VT_ARR: begin
         Result := '[';
         If (Not V^.Arr^.Empty) then begin
            AEA:=V^.Arr^.ToArray();
            C:=Low(AEA); H:=High(AEA);
            While (True) do begin
               Result += EncodeJSON(AEA[C].Val);
               If (C < H) then begin Result += ','; C += 1 end
                          else Break
         end end;
         Result += ']'
      end;
      
      VT_DIC: begin
         Result := '{';
         If (Not V^.Dic^.Empty) then begin
            DEA:=V^.Dic^.ToArray();
            C:=Low(DEA); H:=High(DEA);
            While (True) do begin
               Result += '"'+StringToJSONString(DEA[C].Key)+'":'+EncodeJSON(DEA[C].Val);
               If (C < H) then begin Result += ','; C += 1 end
                          else Break
         end end;
         Result += '}'
      end;
      
      else
         Result := 'null'
   end end;

Function JSONDataToAwfulValue(Const JSON:TJSONData):PValue;
   Var C:LongWord;
   begin
      Case JSON.JSONType() of
         jtBoolean:
            Result := NewVal(VT_BOO, JSON.AsBoolean);
         
         jtString:
            Result := NewVal(VT_STR, JSON.AsString);
         
         jtNumber:
            Case TJSONNumber(JSON).NumberType() of
               ntFloat:
                  Result := NewVal(VT_FLO, JSON.AsFloat);
               ntInteger:
                  Result := NewVal(VT_INT, JSON.AsInteger);
               ntInt64:
                  Result := NewVal(VT_INT, JSON.AsInt64);
         end;
         
         jtArray: begin
            Result := EmptyVal(VT_ARR);
            If (JSON.Count > 0) then
               For C:=0 to (JSON.Count - 1) do
                  Result^.Arr^.SetVal(C,JSONDataToAwfulValue(JSON.Items[C]))
         end;
         
         jtObject:
            begin
            Result := EmptyVal(VT_DIC);
            If (JSON.Count > 0) then
               For C:=0 to (JSON.Count - 1) do
                  Result^.Dic^.SetVal(TJSONObject(JSON).Names[C],JSONDataToAwfulValue(JSON.Items[C]))
         end;

         else
            Result := NilVal()
      end
   end;

Function DecodeJSON(Const JSONstring:AnsiString):PValue;
   Var JSON:TJSONData; Parser:TJSONParser;
   begin
      JSON := NIL; Parser := NIL;
      Try
         Parser := TJSONParser.Create(JSONstring);
         JSON := Parser.Parse();
         Result := JSONDataToAwfulValue(JSON)
      Except
         Result := NilVal()
      end;
      If (JSON <> NIL) then JSON.Destroy();
      If (Parser <> NIL) then Parser.Destroy()
   end;

end.
