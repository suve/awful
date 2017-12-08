unit stringutils;

{$INCLUDE defines.inc}

interface

Type
   AnsiStringArray = Array of AnsiString;

Function ExplodeString(Const Str, Delim:AnsiString):AnsiStringArray;
Function ImplodeString(Const Arr:Array of AnsiString;Const Delim:AnsiString):AnsiString;


implementation
   uses StrUtils;


Function ExplodeString(Const Str, Delim:AnsiString):AnsiStringArray;
   Var Idx, P, Offset, StrLen,DelLen : NativeInt;
   begin
      StrLen := Length(Str);
      DelLen := Length(Delim);
      
      Idx := 0; Offset := 1;
      SetLength(Result, 0);
      
      P := PosEx(Delim,Str,Offset);
      While (P <> 0) do begin
         SetLength(Result, Idx+1);
         Result[Idx] := Copy(Str,Offset,P - Offset);
         
         Offset := P + DelLen;
         P := PosEx(Delim,Str,Offset);
         Idx += 1;
      end;
      
      If(Offset <= StrLen) then begin
         SetLength(Result, Idx+1);
         Result[Idx] := Copy(Str,Offset,StrLen)
      end else
      If(RightStr(Str, DelLen) = Delim) then begin
         SetLength(Result, Idx+1);
         Result[Idx] := ''
      end
   end;


Function ImplodeString(Const Arr:Array of AnsiString;Const Delim:AnsiString):AnsiString;
   Var Idx : NativeInt;
   begin
      If (Length(Arr) = 0) then Exit('');
      
      Result := '';
      For Idx := Low(Arr) to (High(Arr)-1) do
         Result += Arr[Idx] + Delim;
      Result += Arr[High(Arr)]
   end;

end.
