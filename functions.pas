unit functions; 

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

Function F_Sleep(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_Ticks(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_RunTicks(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_random(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_fork(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_SetPrecision(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_HexCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_exec(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_const(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_getenv(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

Function F_sizeof(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_typeof(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;


implementation
   uses  SysUtils, StrUtils, Math, Process, Classes,
         EmptyFunc, CoreFunc, Globals, Parser,
         Convert, StringUtils, Values_Typecast;

Procedure Register(Const FT:PFunTrie);
   begin
      // Timekeeping
      FT^.SetVal('sleep',MkFunc(@F_Sleep));
      FT^.SetVal('ticks',MkFunc(@F_Ticks));
      FT^.SetVal('runticks',MkFunc(@F_RunTicks));
      // Vartype info
      FT^.SetVal('sizeof',MkFunc(@F_sizeof));
      FT^.SetVal('typeof',MkFunc(@F_typeof));
      // Math
      FT^.SetVal('random',MkFunc(@F_random));
      FT^.SetVal('float-precision',MkFunc(@F_SetPrecision));
      FT^.SetVal('hex-case',MkFunc(@F_HexCase));
      // Stuff
      FT^.SetVal('fork',MkFunc(@F_fork));
      FT^.SetVal('exec',MkFunc(@F_exec));
      FT^.SetVal('const',MkFunc(@F_const));
      FT^.SetVal('getenv',MkFunc(@F_getenv))
   end;
   
Function F_Ticks(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; TS:Comp;
   begin
      If (Length(Arg^)>0) then
         For C:=Low(Arg^) to High(Arg^) do
            FreeIfTemp(Arg^[C]);
      
      If (Not DoReturn) then Exit(NIL);
      
      TS:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
      Exit(NewVal(VT_INT,Trunc(TS-GLOB_ms)))
   end;

Function F_RunTicks(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; TS:Comp;
   begin
      If (Length(Arg^)>0) then
         For C:=Low(Arg^) to High(Arg^) do
            FreeIfTemp(Arg^[C]);
      
      If (Not DoReturn) then Exit(NIL);
      
      TS:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
      Exit(NewVal(VT_INT,Trunc(TS-GLOB_sms)))
   end;

Function F_Sleep(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; Dur:LongWord;
       ms_st, ms_en : Comp;
   begin
      ms_st:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
      
      If (Length(Arg^)=0) then Dur:=1000
      else begin
         If (Length(Arg^)>1) then
            For C:=High(Arg^) downto 1 do
               FreeIfTemp(Arg^[C]);
         
         If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
            then Dur:=PQInt(Arg^[0]^.Ptr)^ else
         If (Arg^[0]^.Typ = VT_FLO)
            then Dur:=Trunc(1000*PFloat(Arg^[0]^.Ptr)^)
            else Dur:=ValAsInt(Arg^[0]);
         
         FreeIfTemp(Arg^[0])
      end;
      
      SysUtils.Sleep(Dur);
      If (Not DoReturn) then Exit(NIL);
      
      ms_en:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
      Exit(NewVal(VT_INT,Trunc(ms_en - ms_st)))
   end;

Function F_SetPrecision(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^) >= 1) then begin
         Values.RealForm := ffFixed;
         Values.RealPrec := ValAsInt(Arg^[0]);
         F_(False, Arg)
      end;
      
      If (DoReturn)
         then Exit(NewVal(VT_INT,Values.RealPrec))
         else Exit(NIL)
   end;

Function F_HexCase(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Vl:LongInt;
   begin
      If (Length(Arg^) >= 1) then begin
         Case LowerCase(ValAsStr(Arg^[0])) of
            'lo','low','lower','lowercase': Vl := -1;
            'up','upper','uppercase': Vl := +1;
            else Vl := 0
         end;
         Case Vl of
            +1: Convert.HexCase(CASE_UPPER);
            -1: Convert.HexCase(CASE_LOWER)
         end;
         F_(False, Arg)
      end;
      If (DoReturn) then begin
         If (Convert.HexCase())
            then Exit(NewVal(VT_STR,'upper'))
            else Exit(NewVal(VT_STR,'lower'))
      end else Exit(NIL)
   end;

Function F_fork(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; R:Boolean;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      If (Length(Arg^)=0) then Exit(NewVal(VT_BOO,False));
      
      If (Length(Arg^)>3) then For C:=High(Arg^) downto 3 do
         FreeIfTemp(Arg^[C]);
      
      If (Arg^[0]^.Typ = VT_BOO)
         then R:=Arg^[0]^.Boo^
         else R:=ValAsBoo(Arg^[0]);
      FreeIfTemp(Arg^[0]);
      
      If (R) then begin
         If (Length(Arg^)=1) then Exit(NewVal(VT_BOO,True));
         
         If (Length(Arg^)>2) then FreeIfTemp(Arg^[2]);
         
         If (Arg^[1]^.Lev >= CurLev)
            then Exit(Arg^[1])
            else Exit(CopyVal(Arg^[1]))
      
      end else begin
         If (Length(Arg^)<3) then begin
            If (Length(Arg^)=2) then
               FreeIfTemp(Arg^[1]);
            
            Exit(NewVal(VT_BOO,False))
          end;
         
         If (Arg^[2]^.Lev >= CurLev)
            then Exit(Arg^[2])
            else Exit(CopyVal(Arg^[2]))
      end
   end;

Function F_random(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; FH,FL:TFloat; IH,IL:QInt; Typ:Values.TValueType;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // More than two args, free dat shit
      If (Length(Arg^)>2) then
         For C:=High(Arg^) downto 2 do
            FreeIfTemp(Arg^[C]);
      
      // Two or more args
      If (Length(Arg^) >= 2) then begin
         
         // First arg is float
         If (Arg^[0]^.Typ = VT_FLO) then begin
            
            // Extract float from first arg and cast second arg to float
            FL := Arg^[0]^.Flo^;
            FH := ValAsFlo(Arg^[1]);
            
            // Free args
            For C:=1 downto 0 do FreeIfTemp(Arg^[C]);
            
            // Check if second arg is bigger and exit with random value in range
            If (FH >= FL)
               then Exit(NewVal(VT_FLO, FL + ((FH - FL) * System.Random())))
               else Exit(NewVal(VT_FLO, FH + ((FL - FH) * System.Random())))
            
         end else begin // First arg <> float
            
            // Cast both args to int
            IL := ValAsInt(Arg^[0]);
            IH := ValAsInt(Arg^[1]);
            
            // Ensure type is numeric
            Typ := Arg^[0]^.Typ;
            If (Not (Typ in [VT_INT, VT_HEX, VT_BIN, VT_OCT])) then Typ := VT_INT;
            
            // Free args
            For C:=1 downto 0 do FreeIfTemp(Arg^[C]);
            
            // Check if second arg is bigger and exit with random value in range
            If (IH >= IL)
               then Exit(NewVal(Typ, IL + System.Random(IH - IL + 1)))
               else Exit(NewVal(Typ, IH + System.Random(IL - IH + 1)))
         end
         
      end else // Check if one or zero args
      If (Length(Arg^) = 1) then begin
         
         // If arg is ascii/utf string, return random char from string
         If (Arg^[0]^.Typ = VT_STR) then begin
            
            // If emptystring, return emptystring; otherwise, extract random character from string
            If (Length(Arg^[0]^.Str^) > 0) 
               then Result := NewVal(VT_STR, Arg^[0]^.Str^[1 + Random(Length(Arg^[0]^.Str^))])
               else Result := EmptyVal(VT_STR) 
            
         end else If(Arg^[0]^.Typ = VT_UTF) then begin
            
            // If emptystring, return emptystring; otherwise, extract random codepoint from string
            If (Arg^[0]^.Utf^.Len > 0) 
               then Result := NewVal(VT_UTF, Arg^[0]^.Utf^[1 + Random(Arg^[0]^.Utf^.Len)])
               else Result := EmptyVal(VT_UTF) 
            
         end else begin // First arg <> string, treat it as number
            
            // Generate random number based on arg typecasted to int
            IH := Random(ValAsInt(Arg^[0]));
            
            // Ensure return type is numeric
            Typ := Arg^[0]^.Typ;
            If (Not (Typ in [VT_INT, VT_HEX, VT_BIN, VT_OCT])) then Typ := VT_INT;
            
            Result := NewVal(Typ, IH)
         end;
         
         FreeIfTemp(Arg^[0]); // Free arg
         Exit(Result) // Return value
         
      end else // 0 args
         Exit(NewVal(VT_FLO,System.Random())) // Return random float in  [0.0, 1.0) range
   end;

Function F_exec(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var expath: AnsiString; exargs : Array of AnsiString;
       outstr: AnsiString; outarr : Array of AnsiString; outsucc : Boolean;
       C : LongInt; AEA:TArr.TEntryArr; DEA:TDict.TEntryArr; StringList:TStringList;
   begin
      // If no args provided, bail out (and free args)
      If(Length(Arg^) = 0) then Exit(F_(DoReturn, Arg));
      
      // If more than 1 arg provided, extract options from arg1
      If(Length(Arg^) > 1) then begin
         Case(Arg^[1]^.Typ) of
         
            VT_ARR: begin // array - just throw contents into an FPC string array
               SetLength(exargs, Arg^[1]^.Arr^.Count);
               If (Arg^[1]^.Arr^.Count > 0) then begin
                  AEA := Arg^[1]^.Arr^.ToArray();
                  For C:=0 to (Arg^[1]^.Arr^.Count - 1) do
                     exargs[C] := ValAsStr(AEA[C].Val)
            end end;
            
            VT_DIC: begin // dict - just throw contents into an FPC string array
               SetLength(exargs, Arg^[1]^.Dic^.Count);
               If (Arg^[1]^.Dic^.Count > 0) then begin
                  DEA := Arg^[1]^.Dic^.ToArray();
                  For C:=0 to (Arg^[1]^.Dic^.Count - 1) do
                     exargs[C] := ValAsStr(DEA[C].Val)
            end end;
            
            else begin
               expath := Trim(ValAsStr(Arg^[1])); // get arg1 stringcast and trim whitespace
               If (Length(expath) > 0) then begin // Check length - if 0, no need to go through the hassle
               
                  StringList := TStringList.Create();           // Create FPC TStringList class instance
                  CommandToList(ValAsStr(Arg^[1]), StringList); // Breakup arg0 stringcast into StringList
                  
                  // Set exargs length to StringList item count and hurl StringList items into exargs
                  SetLength(exargs, StringList.Count);
                  If (StringList.Count > 0) then
                     For C:=0 to (StringList.Count - 1) do
                        exargs[C] := StringList[C];
                  
                  StringList.Destroy() // Free StringList instance
               end else
                  SetLength(exargs, 0) // string was expty, set array length to 0
            end
         end
      end else
         SetLength(exargs, 0); // Only arg0 provided, set exargs length to 0
      
      expath := ValAsStr(Arg^[0]); // Get executable path from arg0 stringcast
      F_(False, Arg);              // Free args
      
      outstr := '';
      outsucc := RunCommand(expath, exargs, outstr); 
      
      If(Not DoReturn) then Exit(NIL); // If no retval expected, return NIL straight away
      SetLength(exargs, 0);            // Set exargs length back to 0 to free some memory
      
      // Allocate result array and set succ/fail flag into index 0
      Result := EmptyVal(VT_ARR);
      Result^.Arr^.SetVal(0, NewVal(VT_INT, BoolToInt(Not OutSucc)));
      
      // Explode output string on newlines and hurl seperate lines into result array
      outarr := ExplodeString(outstr, System.LineEnding);
      For C:=0 to High(outarr) do
         Result^.Arr^.SetVal(QInt(C)+1, NewVal(VT_STR, outarr[C]))
   end;

Function F_getenv(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C,EqPos:LongInt; env:AnsiString;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      If (Length(Arg^) > 0) then begin
         // If any args present, get envvar name from arg0 and put envvar value into result
         Result := NewVal(VT_STR, GetEnvironmentVariable(ValAsStr(Arg^[0])));
         // Go through args and free if needed
         For C:=0 to High(Arg^) do FreeIfTemp(Arg^[C])
      end else begin
         // No args - return a dict containing all environment vars
         Result := EmptyVal(VT_DIC);
         For C:=1 to GetEnvironmentVariableCount() do begin
            env := GetEnvironmentString(C); // Get C-th "var=val" string
            EqPos := PosEx('=', env, 2);    // On Windows, some envvar names start with =, so start looking for = from char 2
            Result^.Dic^.SetVal(Copy(env,1,EqPos-1), NewVal(VT_STR, Copy(env,EqPos+1,Length(env)))) // Put varval into dict under varname key
         end
      end
   end;

Function F_const(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongInt; DEA:TDict.TEntryArr;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      If (Length(Arg^) > 0) then begin
         Result := Parser.Cons^.GetVal(ValAsStr(Arg^[0]));
         If (Result <> NIL)
            then Result := CopyVal(Result)
            else Result := NilVal();
         F_(False, Arg)
      end else begin
         Result := EmptyVal(VT_DIC);
         DEA := Parser.Cons^.ToArray();
         For C:=Low(DEA) to High(DEA) do
            Result^.Dic^.SetVal(DEA[C].Key, CopyVal(DEA[C].Val))
      end
   end;

Function F_sizeof(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      If (Length(Arg^)=0) then Exit(NewVal(VT_INT,0));
      
      Case (ValAsStr(Arg^[0])) of
            'flo': Result := NewVal(VT_INT, 8 * SizeOf(TFloat));
            'int': Result := NewVal(VT_INT, 8 * SizeOf(QInt));
            'hex': Result := NewVal(VT_INT, 8 * SizeOf(QInt));
            'oct': Result := NewVal(VT_INT, 8 * SizeOf(QInt));
            'bin': Result := NewVal(VT_INT, 8 * SizeOf(QInt));
            'str': Result := NewVal(VT_INT, 8 * SizeOf(TStr));
            'utf': Result := NewVal(VT_INT, 8 * SizeOf(TUTF));
            'log': Result := NewVal(VT_INT, 8 * SizeOf(TBool));
          'float': Result := NewVal(VT_INT, 8 * SizeOf(TFloat));
         'string': Result := NewVal(VT_INT, 8 * SizeOf(TStr));
           'utf8': Result := NewVal(VT_INT, 8 * SizeOf(TUTF));
          'utf-8': Result := NewVal(VT_INT, 8 * SizeOf(TUTF));
         'chrref': Result := NewVal(VT_INT, 8 * SizeOf(TCharRef));
           'bool': Result := NewVal(VT_INT, 8 * SizeOf(TBool));
            'arr': Result := NewVal(VT_INT, 8 * SizeOf(TArray));
          'array': Result := NewVal(VT_INT, 8 * SizeOf(TArray));
           'dict': Result := NewVal(VT_INT, 8 * SizeOf(TDict));
           'file': Result := NewVal(VT_INT, 8 * SizeOf(TFileHandle));
              else Result := NewVal(VT_INT, 0)
      end;
      F_(False, Arg) // Free args before leaving
   end;

Function F_typeof(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Not DoReturn) then Exit(F_(False, Arg));
      If (Length(Arg^)=0) then Exit(NewVal(VT_STR,''));
      
      Case (Arg^[0]^.Typ) of
         VT_NIL: Result := NewVal(VT_STR, 'nil'   );
         VT_NEW: Result := NewVal(VT_STR, 'new'   );
         VT_BOO: Result := NewVal(VT_STR, 'bool'  );
         VT_BIN: Result := NewVal(VT_STR, 'bin'   );
         VT_OCT: Result := NewVal(VT_STR, 'oct'   );
         VT_INT: Result := NewVal(VT_STR, 'int'   );
         VT_HEX: Result := NewVal(VT_STR, 'hex'   );
         VT_FLO: Result := NewVal(VT_STR, 'float' );
         VT_STR: Result := NewVal(VT_STR, 'string');
         VT_UTF: Result := NewVal(VT_STR, 'utf8'  );
         VT_CHR: Result := NewVal(VT_STR, 'chrref');
         VT_ARR: Result := NewVal(VT_STR, 'array' );
         VT_DIC: Result := NewVal(VT_STR, 'dict'  );
         VT_FIL: Result := NewVal(VT_STR, 'file'  );
            else Result := NewVal(VT_STR, '???'   ) // lolwut, should never happen
      end;
      F_(False, Arg) // Free args before leaving
   end;

end.
