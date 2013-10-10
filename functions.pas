unit functions;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Values;

Var GLOB_MS:Comp; GLOB_dt:TDateTime;
    GLOB_SMS:Comp; GLOB_sdt:TDateTime;
    YukPath:AnsiString;

Procedure Register(FT:PFunTrie);

Function F_(Arg:Array of PValue):PValue;

Function F_FilePath(Arg:Array of PValue):PValue;
Function F_FileName(Arg:Array of PValue):PValue;

Function F_Sleep(Arg:Array of PValue):PValue;
Function F_Ticks(Arg:Array of PValue):PValue;
Function F_FileTicks(Arg:Array of PValue):PValue;

Function F_Write(Arg:Array of PValue):PValue;
Function F_Writeln(Arg:Array of PValue):PValue;

Function F_Set(Arg:Array of PValue):PValue;
Function F_Add(Arg:Array of PValue):PValue;
Function F_Sub(Arg:Array of PValue):PValue;
Function F_Mul(Arg:Array of PValue):PValue;
Function F_Div(Arg:Array of PValue):PValue;
Function F_Mod(Arg:Array of PValue):PValue;
Function F_Pow(Arg:Array of PValue):PValue;

Function F_And(Arg:Array of PValue):PValue;
Function F_Or(Arg:Array of PValue):PValue;
Function F_Xor(Arg:Array of PValue):PValue;
Function F_Not(Arg:Array of PValue):PValue;

Function F_Eq(Arg:Array of PValue):PValue;
Function F_Seq(Arg:Array of PValue):PValue;
Function F_Neq(Arg:Array of PValue):PValue;
Function F_SNeq(Arg:Array of PValue):PValue;
Function F_Gt(Arg:Array of PValue):PValue;
Function F_Ge(Arg:Array of PValue):PValue;
Function F_Lt(Arg:Array of PValue):PValue;
Function F_Le(Arg:Array of PValue):PValue;

Function F_DecodeURL(Arg:Array of PValue):PValue;
Function F_EncodeURL(Arg:Array of PValue):PValue;
Function F_EncodeHTML(Arg:Array of PValue):PValue;

Function F_GetProcess(Arg:Array of PValue):PValue;
Function F_GetIs_(Arg:Array of PValue):PValue;
Function F_GetVal(Arg:Array of PValue):PValue;
Function F_GetKey(Arg:Array of PValue):PValue;
Function F_GetNum(Arg:Array of PValue):PValue;

Function F_SetPrecision(Arg:Array of PValue):PValue;
Function F_Perc(Arg:Array of PValue):PValue;
Function F_sqrt(Arg:Array of PValue):PValue;

{$IFDEF LINUX}
Function F_SysInfo_Get(Arg:Array of PValue):PValue;
Function F_SysInfo_Uptime(Arg:Array of PValue):PValue;
Function F_SysInfo_Load(Arg:Array of PValue):PValue;
Function F_SysInfo_RAMtotal(Arg:Array of PValue):PValue;
Function F_SysInfo_RAMfree(Arg:Array of PValue):PValue;
Function F_SysInfo_RAMbuffer(Arg:Array of PValue):PValue;
Function F_SysInfo_RAMused(Arg:Array of PValue):PValue;
Function F_SysInfo_SwapTotal(Arg:Array of PValue):PValue;
Function F_SysInfo_SwapFree(Arg:Array of PValue):PValue;
Function F_SysInfo_SwapUsed(Arg:Array of PValue):PValue;
Function F_SysInfo_DiskFree(Arg:Array of PValue):PValue;
Function F_SysInfo_DiskTotal(Arg:Array of PValue):PValue;
Function F_SysInfo_DiskUsed(Arg:Array of PValue):PValue;
Function F_SysInfo_Procnum(Arg:Array of PValue):PValue;
Function F_SysInfo_Thermal(Arg:Array of PValue):PValue;
Function F_SysInfo_Hostname(Arg:Array of PValue):PValue;
Function F_SysInfo_DomainName(Arg:Array of PValue):PValue;
{$ENDIF}

Function F_Trim(Arg:Array of PValue):PValue;
Function F_TrimLeft(Arg:Array of PValue):PValue;
Function F_TrimRight(Arg:Array of PValue):PValue;
Function F_UpperCase(Arg:Array of PValue):PValue;
Function F_LowerCase(Arg:Array of PValue):PValue;
Function F_StrLen(Arg:Array of PValue):PValue;
Function F_StrPos(Arg:Array of PValue):PValue;
Function F_SubStr(Arg:Array of PValue):PValue;
Function F_DelStr(Arg:Array of PValue):PValue;

Function F_Doctype(Arg:Array of PValue):PValue;

Function F_DateTime_Start(Arg:Array of PValue):PValue;
Function F_DateTime_FileStart(Arg:Array of PValue):PValue;
Function F_DateTime_Now(Arg:Array of PValue):PValue;
Function F_DateTime_Date(Arg:Array of PValue):PValue;
Function F_DateTime_Time(Arg:Array of PValue):PValue;
Function F_DateTime_Encode(Arg:Array of PValue):PValue;
Function F_DateTime_Decode(Arg:Array of PValue):PValue;
Function F_DateTime_Make(Arg:Array of PValue):PValue;
Function F_DateTime_Day(Arg:Array of PValue):PValue;
Function F_DateTime_Month(Arg:Array of PValue):PValue;
Function F_DateTime_Year(Arg:Array of PValue):PValue;
Function F_DateTime_DOW(Arg:Array of PValue):PValue;
Function F_DateTime_Hour(Arg:Array of PValue):PValue;
Function F_DateTime_Min(Arg:Array of PValue):PValue;
Function F_DateTime_Sec(Arg:Array of PValue):PValue;
Function F_DateTime_MS(Arg:Array of PValue):PValue;
Function F_DateTime_String(Arg:Array of PValue):PValue;

Function F_mkint(Arg:Array of PValue):PValue;
Function F_mkhex(Arg:Array of PValue):PValue;
Function F_mkoct(Arg:Array of PValue):PValue;
Function F_mkbin(Arg:Array of PValue):PValue;
Function F_mkflo(Arg:Array of PValue):PValue;
Function F_mkstr(Arg:Array of PValue):PValue;
Function F_mklog(Arg:Array of PValue):PValue;

Function F_fork(Arg:Array of PValue):PValue;

Function F_random(Arg:Array of PValue):PValue;

Function F_sizeof(Arg:Array of PValue):PValue;

Function F_array(Arg:Array of PValue):PValue;
Function F_array_count(Arg:Array of PValue):PValue;
Function F_array_empty(Arg:Array of PValue):PValue;
Function F_array_flush(Arg:Array of PValue):PValue;

Function F_dict(Arg:Array of PValue):PValue;
Function F_dict_nextkey(Arg:Array of PValue):PValue;
Function F_dict_values(Arg:Array of PValue):PValue;

implementation
   uses Math, SysUtils {$IFDEF LINUX}, Unix, Linux{$ENDIF};

Type TGetVal = record
     Key, Val : AnsiString
     end;

Var GetArr:Array of TGetVal;
    SI:PSysInfo;

Const ROOTDISK = 3;
      dtf_def = 'yyyy"-"mm"-"dd" "hh":"nn';

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('',@F_); FT^.SetVal('nil',@F_);
   FT^.SetVal('sleep',@F_Sleep);
   FT^.SetVal('ticks',@F_Ticks);
   FT^.SetVal('fileticks',@F_FileTicks);
   FT^.SetVal('filename',@F_FileName);
   FT^.SetVal('filepath',@F_FilePath);
   FT^.SetVal('write',@F_Write);
   FT^.SetVal('writeln',@F_Writeln);
   FT^.SetVal('set',@F_Set);   FT^.SetVal('=',@F_Set);
   FT^.SetVal('add',@F_Add);   FT^.SetVal('+',@F_Add);
   FT^.SetVal('sub',@F_Sub);   FT^.SetVal('-',@F_Sub);
   FT^.SetVal('mul',@F_Mul);   FT^.SetVal('*',@F_Mul);
   FT^.SetVal('div',@F_Div);   FT^.SetVal('/',@F_Div);
   FT^.SetVal('mod',@F_Mod);   FT^.SetVal('%',@F_Mod);
   FT^.SetVal('pow',@F_Pow);   FT^.SetVal('^',@F_Pow);
   FT^.SetVal('eq',@F_Eq);     FT^.SetVal('==',@F_Eq);
   FT^.SetVal('neq',@F_NEq);   FT^.SetVal('!=',@F_NEq);
   FT^.SetVal('seq',@F_SEq);   FT^.SetVal('===',@F_SEq);
   FT^.SetVal('sneq',@F_SNEq); FT^.SetVal('!==',@F_SNEq);
   FT^.SetVal('gt',@F_gt);     FT^.SetVal('>',@F_Gt);
   FT^.SetVal('ge',@F_ge);     FT^.SetVal('>=',@F_Ge);
   FT^.SetVal('lt',@F_lt);     FT^.SetVal('<',@F_Lt);
   FT^.SetVal('le',@F_le);     FT^.SetVal('<=',@F_Le);
   FT^.SetVal('not',@F_not);   FT^.SetVal('!',@F_Not);
   FT^.SetVal('and',@F_and);   FT^.SetVal('&&',@F_and);
   FT^.SetVal('xor',@F_xor);   FT^.SetVal('^^',@F_xor);
   FT^.SetVal('or' ,@F_or);    FT^.SetVal('||',@F_or);
   FT^.SetVal('floatprec',@F_SetPrecision);
   FT^.SetVal('perc',@F_Perc);
   FT^.SetVal('sqrt',@F_sqrt);
   FT^.SetVal('get-prepare',@F_GetProcess);
   FT^.SetVal('get-is',@F_GetIs_);
   FT^.SetVal('get-val',@F_GetVal);
   FT^.SetVal('get-key',@F_GetKey);
   FT^.SetVal('get-num',@F_GetNum);
   FT^.SetVal('decodeURL',@F_DecodeURL);
   FT^.SetVal('encodeURL',@F_DecodeURL);
   FT^.SetVal('encodeHTML',@F_EncodeHTML);
   {$IFDEF LINUX}
   FT^.SetVal('sysinfo-get',@F_SysInfo_Get);
   FT^.SetVal('sysinfo-uptime',@F_SysInfo_Uptime);
   FT^.SetVal('sysinfo-load',@F_SysInfo_Load);
   FT^.SetVal('sysinfo-ram-total',@F_SysInfo_RAMtotal);
   FT^.SetVal('sysinfo-ram-free',@F_SysInfo_RAMfree);
   FT^.SetVal('sysinfo-ram-used',@F_SysInfo_RAMused);
   FT^.SetVal('sysinfo-ram-buffer',@F_SysInfo_RAMbuffer);
   FT^.SetVal('sysinfo-swap-total',@F_SysInfo_SwapTotal);
   FT^.SetVal('sysinfo-swap-free',@F_SysInfo_SwapFree);
   FT^.SetVal('sysinfo-swap-used',@F_SysInfo_SwapUsed);
   FT^.SetVal('sysinfo-procnum',@F_SysInfo_Procnum);
   FT^.SetVal('sysinfo-disk-total',@F_SysInfo_DiskTotal);
   FT^.SetVal('sysinfo-disk-free',@F_SysInfo_DiskFree);
   FT^.SetVal('sysinfo-disk-used',@F_SysInfo_DiskUsed);
   FT^.SetVal('sysinfo-thermal',@F_SysInfo_Thermal);
   FT^.SetVal('sysinfo-domainname',@F_SysInfo_DomainName);
   FT^.SetVal('sysinfo-hostname',@F_SysInfo_Hostname);
   {$ENDIF}
   FT^.SetVal('trim',@F_Trim);
   FT^.SetVal('trimle',@F_TrimLeft);
   FT^.SetVal('trimri',@F_TrimRight);
   FT^.SetVal('uppercase',@F_UpperCase);
   FT^.SetVal('lowercase',@F_LowerCase);
   FT^.SetVal('strlen',@F_StrLen);
   FT^.SetVal('strpos',@F_StrPos);
   FT^.SetVal('substr',@F_SubStr);
   FT^.SetVal('delstr',@F_DelStr);
   FT^.SetVal('doctype',@F_Doctype);
   FT^.SetVal('datetime-start',@F_DateTime_Start);
   FT^.SetVal('datetime-filestart',@F_DateTime_FileStart);
   FT^.SetVal('datetime-now',@F_DateTime_Now);
   FT^.SetVal('datetime-date',@F_DateTime_Date);
   FT^.SetVal('datetime-time',@F_DateTime_Time);
   FT^.SetVal('datetime-decode',@F_DateTime_Decode);
   FT^.SetVal('datetime-encode',@F_DateTime_Encode);
   FT^.SetVal('datetime-make',@F_DateTime_Make);
   FT^.SetVal('datetime-year',@F_DateTime_Year);
   FT^.SetVal('datetime-month',@F_DateTime_Month);
   FT^.SetVal('datetime-day',@F_DateTime_Day);
   FT^.SetVal('datetime-dow',@F_DateTime_DOW);
   FT^.SetVal('datetime-hour',@F_DateTime_Hour);
   FT^.SetVal('datetime-min',@F_DateTime_Min);
   FT^.SetVal('datetime-sec',@F_DateTime_Sec);
   FT^.SetVal('datetime-ms',@F_DateTime_MS);
   FT^.SetVal('datetime-string',@F_DateTime_String);
   FT^.SetVal('mkint',@F_mkint);
   FT^.SetVal('mkhex',@F_mkhex);
   FT^.SetVal('mkoct',@F_mkoct);
   FT^.SetVal('mkbin',@F_mkbin);
   FT^.SetVal('mkflo',@F_mkflo); FT^.SetVal('mkfloat',@F_mkflo);
   FT^.SetVal('mkstr',@F_mkstr); FT^.SetVal('mkstring',@F_mkstr);
   FT^.SetVal('mklog',@F_mklog); FT^.SetVal('mkbool',@F_mklog);
   FT^.SetVal('fork',@F_fork);
   FT^.SetVal('random',@F_random);
   FT^.SetVal('sizeof',@F_sizeof);
   // array functions, bitches!
   FT^.SetVal('arr',@F_array);
   // dict funtions
   FT^.SetVal('dict',@F_dict);
   FT^.SetVal('dict-values',@F_dict_values);
   FT^.SetVal('dict-nextkey',@F_dict_nextkey);
   // arr+dic functions
   FT^.SetVal('arr-flush',@F_array_flush); FT^.SetVal('dict-flush',@F_array_flush);
   FT^.SetVal('arr-count',@F_array_count); FT^.SetVal('dict-count',@F_array_count);
   FT^.SetVal('arr-empty',@F_array_empty); FT^.SetVal('dict-empty',@F_array_empty);
   end;

Function F_(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)=0) then Exit(NilVal);
   For C:=Low(Arg) to High(Arg) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NilVal)
   end;

Function F_FilePath(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_STR,YukPath))
   end;

Function F_FileName(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_STR,ExtractFileName(YukPath)))
   end;
   
Function F_Ticks(Arg:Array of PValue):PValue;
   Var C:LongWord; TS:Comp;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   TS:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   Exit(NewVal(VT_INT,Trunc(TS-GLOB_ms)))
   end;

Function F_FileTicks(Arg:Array of PValue):PValue;
   Var C:LongWord; TS:Comp;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   TS:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   Exit(NewVal(VT_INT,Trunc(TS-GLOB_sms)))
   end;

Function F_Sleep(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; Dur:LongWord;
       ms_st, ms_en : Comp;
   begin
   ms_st:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   If (Length(Arg)=0) then Dur:=1000
      else begin
      If (Length(Arg)>1) then
         For C:=High(Arg) downto 1 do
             If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
      If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
         then Dur:=PQInt(Arg[0]^.Ptr)^ else
      If (Arg[0]^.Typ = VT_FLO)
         then Dur:=Trunc(1000*PFloat(Arg[0]^.Ptr)^)
         else begin
         V:=ValToInt(Arg[0]);
         Dur:=PQInt(V^.Ptr)^;
         FreeVal(V)
         end;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0])
      end;
   SysUtils.Sleep(Dur);
   ms_en:=TimeStampToMSecs(DateTimeToTimeStamp(Now()));
   Exit(NewVal(VT_INT,Trunc(ms_en - ms_st)))
   end;

Function F_Write(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=Low(Arg) to High(Arg) do begin
       Case Arg[C]^.Typ of
          //VT_NIL: Write('(nilvar)');
          VT_INT: Write(PQInt(Arg[C]^.Ptr)^);
          VT_HEX: Write(HexToStr(PQInt(Arg[C]^.Ptr)^));
          VT_OCT: Write(OctToStr(PQInt(Arg[C]^.Ptr)^));
          VT_BIN: Write(BinToStr(PQInt(Arg[C]^.Ptr)^));
          VT_FLO: Write(PFloat(Arg[C]^.Ptr)^:0:RealPrec);
          VT_BOO: Write(PBoolean(Arg[C]^.Ptr)^);
          VT_STR: Write(PAnsiString(Arg[C]^.Ptr)^);
          VT_ARR: Write('array(',PValTree(Arg[C]^.Ptr)^.Count,')');
          VT_DIC: Write('dict(',PValTrie(Arg[C]^.Ptr)^.Count,')');
          else Write('(',Arg[C]^.Typ,')');
          end;
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
       end;
   Exit(NewVal(VT_STR,''))
   end;

Function F_Writeln(Arg:Array of PValue):PValue;
   Var R:PValue;
   begin
   R:=F_Write(Arg);
   Writeln();
   Exit(R)
   end;

Function F_Set(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValSet(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Lev >= CurLev) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Add(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValAdd(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Lev >= CurLev) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Sub(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValSub(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Lev >= CurLev) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Mul(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValMul(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Lev >= CurLev) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Div(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValDiv(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Lev >= CurLev) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Mod(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValMod(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Lev >= CurLev) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Pow(Arg:Array of PValue):PValue;
   Var C:LongWord; R:PValue;
   begin
   If (Length(Arg)=0) then Exit(NilVal) else
   If (Length(Arg)>1) then
      For C:=(High(Arg)-1) downto Low(Arg) do begin
          R:=ValPow(Arg[C],Arg[C+1]);
          If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
          If (Arg[C]^.Lev >= CurLev) then begin
             FreeVal(Arg[C]); Arg[C]:=R
             end else begin
             SwapPtrs(Arg[C],R);
             FreeVal(R)
             end
          end;
   If (Arg[0]^.Lev >= CurLev) then R:=Arg[0]
                    else R:=CopyVal(Arg[0]);
   Exit(R)
   end;

Function F_Not(Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,True));
   If (Length(Arg)>1) then 
       For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_BOO) then B:=PBool(Arg[0]^.Ptr)^
      else begin
      V:=ValToBoo(Arg[0]); B:=PBool(V^.Ptr)^; FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,Not B))
   end;

Function F_And(Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)>1) then 
      For C:=High(Arg) downto 1 do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B and (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B and (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_Xor(Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=False;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)>1) then 
      For C:=High(Arg) downto 1 do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B xor (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B xor (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_Or(Arg:Array of PValue):PValue;
   Var C:LongWord; B:Boolean; V:PValue;
   begin B:=False;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)>1) then 
      For C:=High(Arg) downto 1 do begin
          If (Arg[C]^.Typ = VT_BOO) then B:=B or (PBool(Arg[C]^.Ptr)^)
             else begin
             V:=ValToBoo(Arg[C]); B:=B or (PBool(Arg[C]^.Ptr)^); FreeVal(V)
             end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_Eq(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
   end;

Function F_NEq(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValNEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
   end;

Function F_SEq(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValSEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
   end;

Function F_SNEq(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValSNEq(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
   end;

Function F_Gt(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValGt(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
   end;

Function F_Ge(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValGe(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
   end;

Function F_Lt(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValLt(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
   end;

Function F_Le(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin R:=True;
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_BOO,False))
      end;
   For C:=(High(Arg)-1) downto Low(Arg) do begin
       V:=ValLe(Arg[C],Arg[C+1]);
       If (Arg[C+1]^.Lev >= CurLev) then FreeVal(Arg[C+1]);
       If (Not PBool(V^.Ptr)^) then R:=False;
       FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,R))
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
   Var Res:AnsiString; P,R:LongWord;
   begin
   Res:=''; SetLength(Res,Length(Str));
   R:=1; P:=1;
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
   Var Res:AnsiString; P,R:LongWord;
   begin
   Res:=''; SetLength(Res,Length(Str));
   R:=1; P:=1;
   While (P<=Length(Str)) do
      Case Str[P] of
         '"': begin Res+='&quot;'; R+=6; P+=1 end;
         '&': begin Res+='&amp;';  R+=5; P+=1 end;
         '<': begin Res+='&lt;';   R+=4; P+=1 end;
         '>': begin Res+='&gt;';   R+=4; P+=1 end;
         else begin Res+=Str[P];   R+=1; P+=1 end
      end;
   Exit(Res)
   end;

Function F_DecodeURL(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
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
   Exit(NewVal(VT_STR,DecodeURL(S)))
   end;

Function F_EncodeURL(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
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

Function F_EncodeHTML(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
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
   end;

Function GetSet(Key:AnsiString;L,R:LongInt):Boolean;
   Var Mid:LongWord;
   begin
   If (L>R) then Exit(False);
   Mid:=(L+R) div 2;
   Case Sign(CompareStr(Key,GetArr[Mid].Key)) of
      -1: Exit(GetSet(Key,L,Mid-1));
       0: Exit(True);
      +1: Exit(GetSet(Key,Mid+1,R));
   end end;

Function GetSet(Key:AnsiString):Boolean;
   begin
   If (Length(GetArr)>0)
      then Exit(GetSet(Key,Low(GetArr),High(GetArr)))
      else Exit(False)
   end;

Function GetStr(Key:AnsiString;L,R:LongInt):AnsiString;
   Var Mid:LongWord;
   begin
   If (L>R) then Exit('');
   Mid:=(L+R) div 2;
   Case Sign(CompareStr(Key,GetArr[Mid].Key)) of
      -1: Exit(GetStr(Key,L,Mid-1));
       0: Exit(GetArr[Mid].Val);
      +1: Exit(GetStr(Key,Mid+1,R));
   end end;

Function GetStr(Key:AnsiString):AnsiString;
   begin
   If (Length(GetArr)>0)
      then Exit(GetStr(Key,Low(GetArr),High(GetArr)))
      else Exit('')
   end;

Function GetStr(Num:LongWord):AnsiString;
   begin
   If (Num<Length(GetArr))
      then Exit(GetArr[Num].Val)
      else Exit('')
   end;

Function GetKey(Num:LongWord):AnsiString;
   begin
   If (Num<Length(GetArr))
      then Exit(GetArr[Num].Key)
      else Exit('')
   end;

Function GetNum():LongWord;
   begin Exit(Length(GetArr)) end;

Function F_GetProcess(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   ProcessGet();
   Exit(NilVal())
   end;

Function F_GetIs_(Arg:Array of PValue):PValue;
   Var B:Boolean; C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,True));
   B:=True; For C:=High(Arg) downto Low(Arg) do begin
      If (Arg[C]^.Typ<>VT_STR)
         then begin
            V:=ValToStr(Arg[C]);
            If (Not GetSet(PStr(V^.Ptr)^)) then B:=False;
            FreeVal(V);
         end else
         If (Not GetSet(PStr(Arg[C]^.Ptr)^)) then B:=False;
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_GetVal(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
      then S:=GetStr(PQInt(Arg[0]^.Ptr)^) else
   If (Arg[0]^.Typ = VT_STR)
      then S:=GetStr(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=GetStr(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_GetKey(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
      then S:=GetKey(PQInt(Arg[0]^.Ptr)^)
      else begin
      V:=ValToInt(Arg[0]);
      S:=GetKey(PQInt(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_GetNum(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,GetNum()))
   end;

Function F_SetPrecision(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,Values.RealPrec));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
      then Values.RealPrec:=PQInt(Arg[0]^.Ptr)^
      else begin
      V:=ValToInt(Arg[0]);
      Values.RealPrec:=PQInt(V^.Ptr)^;
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_INT,Values.RealPrec))
   end;

Function F_Perc(Arg:Array of PValue):PValue;
   Var C:LongWord; A,V:PValue; I:PQInt; S:AnsiString; D:PFloat;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,'0%'));
   If (Length(Arg)>2) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)>=2) then begin
      If (Arg[0]^.Typ = VT_FLO) then begin
         A:=CopyVal(Arg[0]); D:=PFloat(A^.Ptr); (D^)*=100;
         V:=ValDiv(A,Arg[1]); FreeVal(A);
         S:=IntToStr(Trunc(PFloat(V^.Ptr)^))+'%';
         FreeVal(V)
         end else begin
         If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
            then A:=CopyVal(Arg[0]) else A:=ValToInt(Arg[0]);
         I:=PQInt(A^.Ptr); (I^)*=100;
         V:=ValDiv(A,Arg[1]); FreeVal(A);
         S:=IntToStr(PQInt(V^.Ptr)^)+'%';
         FreeVal(V)
         end
      end else begin
      If (Arg[0]^.Typ = VT_FLO)
         then S:=IntToStr(Trunc(100*PFloat(Arg[0]^.Ptr)^))+'%'
         else begin
         A:=ValToFlo(Arg[0]);
         S:=IntToStr(Trunc(100*PFloat(A^.Ptr)^))+'%';
         FreeVal(A)
         end
      end;
   If (Length(Arg) >= 2) and (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
   If (Length(Arg) >= 1) and (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

{$IFDEF LINUX}
Function GetSysInfo():Boolean;
   begin
   If (SI<>NIL) then Dispose(SI); New(SI);
   If (SysInfo(SI)<>0) then begin
      Dispose(SI); SI:=NIL; Exit(False)
      end;
   Exit(True)
   end;

Function F_SysInfo_Get(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_BOO,GetSysInfo()))
   end;

Function F_SysInfo_Uptime(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,SI^.Uptime))
   end;

Function F_SysInfo_Load(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; L:Int64;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_FLO,SI^.Loads[0]/65535));
   For C:=High(Arg) downto 1 do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
      then L:=PQInt(Arg[0]^.Ptr)^
      else begin
      V:=ValToInt(Arg[0]);
      L:=PQInt(V^.Ptr)^;
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   If (L < 0) or (L > 2) then L:=0;
   Exit(NewVal(VT_FLO,SI^.Loads[L]/65535))
   end;

Function F_SysInfo_RAMtotal(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,SI^.TotalRam))
   end;

Function F_SysInfo_RAMfree(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,SI^.FreeRam))
   end;

Function F_SysInfo_RAMused(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,(SI^.TotalRam - SI^.FreeRam - SI^.BufferRam)))
   end;

Function F_SysInfo_RAMbuffer(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,SI^.BufferRam))
   end;

Function F_SysInfo_SwapTotal(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,SI^.TotalSwap))
   end;

Function F_SysInfo_SwapFree(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,SI^.FreeSwap))
   end;

Function F_SysInfo_SwapUsed(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,(SI^.TotalSwap - SI^.FreeSwap)))
   end;

Function F_SysInfo_Procnum(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,SI^.Procs))
   end;

Function F_SysInfo_DiskTotal(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,DiskSize(ROOTDISK)))
   end;

Function F_SysInfo_DiskFree(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,DiskFree(ROOTDISK)))
   end;

Function F_SysInfo_DiskUsed(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,(DiskSize(ROOTDISK) - DiskFree(ROOTDISK))))
   end;

Function F_SysInfo_Thermal(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; Z,T:Int64; F:Text;
   begin
   If (Length(Arg)=0) then Z:=0 else begin
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
      If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN)
         then Z:=PQInt(Arg[0]^.Ptr)^
         else begin
         V:=ValToInt(Arg[0]);
         Z:=PQInt(V^.Ptr)^;
         FreeVal(V)
         end;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0])
      end;
   If (Z < 0) then Z:=0;
   Assign(F,'/sys/class/thermal/thermal_zone'+IntToStr(Z)+'/temp');
   {$I-} Reset(F); {$I+};
   If (IOResult = 0) then begin
      Readln(F,T); Close(F)
      end else T:=0;
   Exit(NewVal(VT_FLO,T/1000))
   end;

Function F_SysInfo_Hostname(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_STR,GetHostName()))
   end;

Function F_SysInfo_DomainName(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,GetDomainName()))
   end;
{$ENDIF} //end of Linux-only functions

Function F_Trim(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=Trim(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=Trim(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_TrimLeft(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=TrimLeft(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=TrimLeft(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_TrimRight(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=TrimRight(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=TrimRight(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_UpperCase(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=UpperCase(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=UpperCase(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_LowerCase(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; S:AnsiString;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then S:=LowerCase(PStr(Arg[0]^.Ptr)^)
      else begin
      V:=ValToStr(Arg[0]);
      S:=LowerCase(PStr(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_STR,S))
   end;

Function F_Doctype(Arg:Array of PValue):PValue;
   Const DEFAULT = '<!DOCTYPE html>';
   Var C:LongWord; V:PValue; S,R:AnsiString; I:Int64;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,DEFAULT));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_STR)
      then begin
      S:=PStr(Arg[0]^.Ptr)^;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      If (S='html5') then
         R:=('<!DOCTYPE html>') else
      If (S='html4-strict') then
         R:=('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">') else
      If (S='html4-transitional') or (S='html4-loose') then
         R:=('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">') else
      If (S='html4-frameset') then
         R:=('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">') else
      If (S='xhtml1-strict') then
         R:=('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">') else
      If (S='xhtml1-transitional') then
         R:=('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">') else
      If (S='xhtml1-frameset') then
         R:=('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">') else
      If (S='xhtml1-1') then
         R:=('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">') else
         {else} R:=DEFAULT
      end else begin
      V:=ValToInt(Arg[0]); I:=(PQInt(V^.Ptr)^); FreeVal(V);
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      If (I = 5) then 
         R:=('<!DOCTYPE html>') else
      If (I = 4) then 
         R:=('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">') else
         {else} R:=DEFAULT
      end;
   Exit(NewVal(VT_STR,R))
   end;

Function F_DateTime_Start(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_FLO,GLOB_dt))
   end;

Function F_DateTime_FileStart(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_FLO,GLOB_sdt))
   end;

Function F_DateTime_Now(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_FLO,SysUtils.Now()))
   end;

Function F_DateTime_Date(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_FLO,SysUtils.Date()))
   end;

Function F_DateTime_Time(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_FLO,SysUtils.Time()))
   end;

Function F_DateTime_Encode(Arg:Array of PValue):PValue;
   Const ARRLEN = 7; ARRHI = 6;
   Var C,H:LongWord; V:PValue;
       DT:Array[0..ARRHI] of LongInt; R:TDateTime;
   begin
   If (Length(Arg)>ARRLEN) then begin H:=ARRHI;
      For C:=High(Arg) downto ARRLEN do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end else H:=High(Arg);
   For C:=0 to ARRHI do dt[C]:=0;
   For C:=H downto 0 do begin
       If (Arg[C]^.Typ >= VT_INT) and (Arg[C]^.Typ <= VT_BIN) 
          then dt[C]:=PQInt(Arg[C]^.Ptr)^
          else begin
          V:=ValToInt(Arg[C]);
          dt[C]:=PQInt(V^.Ptr)^;
          FreeVal(V)
          end;
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
       end;
   Try R:=SysUtils.EncodeDate(dt[0],dt[1],dt[2]);
       R+=SysUtils.EncodeTime(dt[3],dt[4],dt[5],dt[6]);
   Except Exit(NilVal) end;
   Exit(NewVal(VT_FLO,R))
   end;

Function F_DateTime_Make(Arg:Array of PValue):PValue;
   Const ARRLEN = 5; ARRHI = 4;
   Var C,H:LongWord; V:PValue;
       dt:Array[0..ARRHI] of LongInt; R:TDateTime;
   begin R:=0;
   If (Length(Arg)>ARRLEN) then begin H:=ARRHI;
      For C:=High(Arg) downto ARRLEN do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end else H:=High(Arg);
   For C:=0 to ARRHI do dt[C]:=0;
   For C:=H downto 0 do begin
       If (Arg[C]^.Typ >= VT_INT) and (Arg[C]^.Typ <= VT_BIN) 
          then dt[C]:=PQInt(Arg[C]^.Ptr)^
          else begin
          V:=ValToInt(Arg[C]);
          dt[C]:=PQInt(V^.Ptr)^;
          FreeVal(V)
          end;
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
       end;
   R+=dt[4]; R/=1000; //Add milisecs
   R+=dt[3]; R/=60;   //Add secs
   R+=dt[2]; R/=60;   //Add mins
   R+=dt[1]; R/=24;   //Add hours
   R+=dt[0];          //Add days
   Exit(NewVal(VT_FLO,R))
   end;

Function F_DateTime_Decode(Arg:Array of PValue):PValue;
   Var C,H:LongWord; V,T:PValue; dt:TDateTime; dec:Array[1..8] of Word;
   begin
   If (Length(Arg)<2) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)>9) then begin H:=8;
      For C:=High(Arg) downto 9 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end else H:=High(Arg);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   DecodeDateFully(dt,dec[1],dec[2],dec[3],dec[4]);
   DecodeTime(dt,dec[5],dec[6],dec[7],dec[8]);
   For C:=H downto 1 do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) 
       else begin
       T:=NewVal(VT_INT,dec[C]);
       V:=ValSet(Arg[C],T);
       SwapPtrs(Arg[C],V);
       FreeVal(T); FreeVal(V)
       end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_BOO,True))
   end;


Function F_DateTime_Day(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeDate(dt,Y,M,D);
   Exit(NewVal(VT_INT,D))
   end;

Function F_DateTime_Month(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeDate(dt,Y,M,D);
   Exit(NewVal(VT_INT,M))
   end;

Function F_DateTime_Year(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeDate(dt,Y,M,D);
   Exit(NewVal(VT_INT,Y))
   end;

Function F_DateTime_DOW(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; D,M,Y,DOW:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeDateFully(dt,Y,M,D,DOW);
   Exit(NewVal(VT_INT,DOW))
   end;

Function F_DateTime_Hour(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,H))
   end;

Function F_DateTime_Min(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,M))
   end;

Function F_DateTime_Sec(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,S))
   end;

Function F_DateTime_ms(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; H,M,S,MS:Word;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto 1 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^)
      else begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DecodeTime(dt,H,M,S,MS);
   Exit(NewVal(VT_INT,MS))
   end;

Function dtf(S:AnsiString):AnsiString;
   Var R:AnsiString; P:LongWord; Q:Boolean;
   begin
   R:=''; Q:=False;
   If (Length(S)=0) then Exit(dtf_def);
   For P:=1 to Length(S) do
       If (S[P]='d') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='d' end else
       If (S[P]='D') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='dd' end else
       If (S[P]='a') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='ddd' end else
       If (S[P]='A') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='dddd' end else
       If (S[P]='m') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='m' end else
       If (S[P]='M') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='mm' end else
       If (S[P]='o') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='mmm' end else
       If (S[P]='O') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='mmmm' end else
       If (S[P]='y') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='yy' end else
       If (S[P]='Y') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='yyyy' end else
       If (S[P]='h') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='h' end else
       If (S[P]='H') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='hh' end else
       If (S[P]='i') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='n' end else
       If (S[P]='I') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='nn' end else
       If (S[P]='s') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='s' end else
       If (S[P]='S') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='ss' end else
       If (S[P]='p') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='a/p' end else
       If (S[P]='P') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='am/pm' end else
       If (S[P]='z') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='z' end else
       If (S[P]='Z') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='zzz' end else
       If (S[P]='t') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='t' end else
       If (S[P]='T') then begin
          If (Q) then begin Q:=False; R+='"' end;
          R+='tt' end else
          begin { else - all non-code chars}
          If (Not Q) then begin Q:=True; R+='"' end;
          R+=S[P]
          end;
   If (Q) then Exit(R+'"') else Exit(R)
   end;

Function F_DateTime_String(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; dt:TDateTime; S,F:AnsiString;
   begin
   If (Length(Arg) > 2) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg) >= 2) and (Arg[1]^.Typ = VT_STR)
      then F:=dtf(PStr(Arg[1]^.Ptr)^)
      else F:=dtf_def;
   If (Length(Arg) > 0) and (Arg[0]^.Typ = VT_FLO)
      then dt:=(PFloat(Arg[0]^.Ptr)^) else
   If (Length(Arg) > 0) then begin
      V:=ValToFlo(Arg[0]);
      dt:=(PFloat(V^.Ptr)^);
      FreeVal(V)
      end else dt:=SysUtils.Now();
   If (Length(Arg) >= 2) and (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
   If (Length(Arg) >= 1) and (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   DateTimeToString(S,F,dt);
   Exit(NewVal(VT_STR,S))
   end;

Function F_mkint(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto (Low(Arg)+1) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) else
       If (Arg[C]^.Typ <> VT_INT) then begin
          V:=ValToInt(Arg[C]); 
          SwapPtrs(Arg[C],V); FreeVal(V)
          end;
   If (Arg[0]^.Lev >= CurLev) then begin
      If (Arg[0]^.Typ <> VT_INT) then begin
         V:=ValToInt(Arg[0]); FreeVal(Arg[0])
         end else V:=Arg[0];
      Exit(V)
      end else begin
      If (Arg[0]^.Typ<>VT_INT) then begin
         V:=ValToInt(Arg[0]); 
         SwapPtrs(Arg[0],V); FreeVal(V)
         end;
      Exit(CopyVal(Arg[0]))
      end
   end;

Function F_mkhex(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto (Low(Arg)+1) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) else
       If (Arg[C]^.Typ <> VT_Hex) then begin
          V:=ValToHex(Arg[C]);
          SwapPtrs(Arg[C],V); FreeVal(V)
          end;
   If (Arg[0]^.Lev >= CurLev) then begin
      If (Arg[0]^.Typ <> VT_Hex) then begin
         V:=ValToHex(Arg[0]); FreeVal(Arg[0])
         end else V:=Arg[0];
      Exit(V)
      end else begin
      If (Arg[0]^.Typ<>VT_Hex) then begin
         V:=ValToHex(Arg[0]); 
         SwapPtrs(Arg[0],V); FreeVal(V)
         end;
      Exit(CopyVal(Arg[0]))
      end
   end;

Function F_mkoct(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_OCT,0));
   For C:=High(Arg) downto (Low(Arg)+1) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) else
       If (Arg[C]^.Typ <> VT_OCT) then begin
          V:=ValToOct(Arg[C]); 
          SwapPtrs(Arg[C],V); FreeVal(V)
          end;
   If (Arg[0]^.Lev >= CurLev) then begin
      If (Arg[0]^.Typ <> VT_OCT) then begin
         V:=ValToOct(Arg[0]); FreeVal(Arg[0])
         end else V:=Arg[0];
      Exit(V)
      end else begin
      If (Arg[0]^.Typ<>VT_OCT) then begin
         V:=ValToOct(Arg[0]);
         SwapPtrs(Arg[0],V); FreeVal(V)
         end;
      Exit(CopyVal(Arg[0]))
      end
   end;

Function F_mkbin(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_BIN,0));
   For C:=High(Arg) downto (Low(Arg)+1) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) else
       If (Arg[C]^.Typ <> VT_BIN) then begin
          V:=ValToBin(Arg[C]); 
          SwapPtrs(Arg[C],V); FreeVal(V)
          end;
   If (Arg[0]^.Lev >= CurLev) then begin
      If (Arg[0]^.Typ <> VT_BIN) then begin
         V:=ValToBin(Arg[0]); FreeVal(Arg[0])
         end else V:=Arg[0];
      Exit(V)
      end else begin
      If (Arg[0]^.Typ<>VT_BIN) then begin
         V:=ValToBin(Arg[0]); 
         SwapPtrs(Arg[0],V); FreeVal(V)
         end;
      Exit(CopyVal(Arg[0]))
      end
   end;

Function F_mkflo(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   For C:=High(Arg) downto (Low(Arg)+1) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) else
       If (Arg[C]^.Typ <> VT_INT) then begin
          V:=ValToFlo(Arg[C]); 
          SwapPtrs(Arg[C],V); FreeVal(V)
          end;
   If (Arg[0]^.Lev >= CurLev) then begin
      If (Arg[0]^.Typ <> VT_FLO) then begin
         V:=ValToFlo(Arg[0]); FreeVal(Arg[0])
         end else V:=Arg[0];
      Exit(V)
      end else begin
      If (Arg[0]^.Typ<>VT_INT) then begin
         V:=ValToFlo(Arg[0]); 
         SwapPtrs(Arg[0],V); FreeVal(V)
         end;
      Exit(CopyVal(Arg[0]))
      end
   end;

Function F_mkstr(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,0));
   For C:=High(Arg) downto (Low(Arg)+1) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) else
       If (Arg[C]^.Typ <> VT_STR) then begin
          V:=ValToStr(Arg[C]);
          SwapPtrs(Arg[C],V); FreeVal(V)
          end;
   If (Arg[0]^.Lev >= CurLev) then begin
      If (Arg[0]^.Typ <> VT_STR) then begin
         V:=ValToStr(Arg[0]); FreeVal(Arg[0])
         end else V:=Arg[0];
      Exit(V)
      end else begin
      If (Arg[0]^.Typ<>VT_STR) then begin
         V:=ValToStr(Arg[0]);
         SwapPtrs(Arg[0],V); FreeVal(V)
         end;
      Exit(CopyVal(Arg[0]))
      end
   end;

Function F_mklog(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,0));
   For C:=High(Arg) downto (Low(Arg)+1) do
       If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]) else
       If (Arg[C]^.Typ <> VT_BOO) then begin
          V:=ValToBoo(Arg[C]); 
          SwapPtrs(Arg[C],V); FreeVal(V)
          end;
   If (Arg[0]^.Lev >= CurLev) then begin
      If (Arg[0]^.Typ <> VT_BOO) then begin
         V:=ValToBoo(Arg[0]); FreeVal(Arg[0])
         end else V:=Arg[0];
      Exit(V)
      end else begin
      If (Arg[0]^.Typ<>VT_BOO) then begin
         V:=ValToBoo(Arg[0]);
         SwapPtrs(Arg[0],V); FreeVal(V)
         end;
      Exit(CopyVal(Arg[0]))
      end
   end;

Function F_fork(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; R:Boolean;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_BOO,False));
   If (Length(Arg)>3) then For C:=High(Arg) downto 3 do
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_BOO) then begin
      R:=PBool(Arg[0]^.Ptr)^;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0])
      end else begin
      V:=ValToBoo(Arg[0]); R:=PBool(V^.Ptr)^;
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      FreeVal(V)
      end;
   If (R) then begin
      If (Length(Arg)=1) then Exit(NewVal(VT_BOO,True));
      If (Length(Arg)>2) then If (Arg[2]^.Lev >= CurLev) then FreeVal(Arg[2]);
      If (Arg[1]^.Lev >= CurLev) then Exit(Arg[1]) else Exit(CopyVal(Arg[1]))
      end else begin
      If (Length(Arg)<3) then begin
         If (Length(Arg)=2) then If (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
         Exit(NewVal(VT_BOO,False))
         end;
      If (Arg[2]^.Lev >= CurLev) then Exit(Arg[2]) else Exit(CopyVal(Arg[2]))
      end
   end;

Function F_random(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; DH,DL:TFloat; IH,IL:QInt; Ch:Char;
   begin
   If (Length(Arg)>2) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)=2) then begin
      If (Arg[0]^.Typ = VT_FLO) then begin
         If (Arg[1]^.Typ <> VT_FLO) then begin
            V:=ValToFlo(Arg[1]);
            If (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1]);
            Arg[1]:=V 
            end;
         If (PFloat(Arg[0]^.Ptr)^ <= PFloat(Arg[1]^.Ptr)^)
            then begin DL:=PFloat(Arg[0]^.Ptr)^; DH:=PFloat(Arg[1]^.Ptr)^ end
            else begin DL:=PFloat(Arg[1]^.Ptr)^; DH:=PFloat(Arg[0]^.Ptr)^ end;
         DH:=DL+((DH-DL)*System.Random());
         For C:=1 downto 0 do If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
         Exit(NewVal(VT_FLO,DH))
         end else begin
         For C:=1 downto 0 do
             If (Arg[C]^.Typ<VT_INT) or (Arg[C]^.Typ>VT_BIN) then begin
                V:=ValToInt(Arg[C]); If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
                Arg[C]:=V end;
         If (PQInt(Arg[0]^.Ptr)^ <= PQInt(Arg[1]^.Ptr)^)
            then begin IL:=PQInt(Arg[0]^.Ptr)^; IH:=PQInt(Arg[1]^.Ptr)^ end
            else begin IL:=PQInt(Arg[1]^.Ptr)^; IH:=PQInt(Arg[0]^.Ptr)^ end;
         IH:=IL+System.Random(IH-IL+1);
         V:=NewVal(Arg[0]^.Typ,IH);
         For C:=1 downto 0 do If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
         Exit(V)
      end end else
   If (Length(Arg)=1) then begin
      If (Arg[0]^.Typ = VT_STR) then begin
         If (Length(PStr(Arg[0]^.Ptr)^)=0) then begin
            If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
            Exit(NewVal(VT_STR,''))
            end;
         Ch:=(PStr(Arg[0]^.Ptr)^)[1+Random(Length(PStr(Arg[0]^.Ptr)^))];
         If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
         Exit(NewVal(VT_STR,Ch))
         end else begin
         If (Arg[0]^.Typ < VT_INT) or (Arg[0]^.Typ > VT_BIN) then begin
            V:=ValToInt(Arg[0]); If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
            Arg[0]:=V end;
         IH:=Random(PQInt(Arg[0]^.Ptr)^);
         V:=NewVal(Arg[0]^.Typ,IH);
         If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
         Exit(V)
      end end else
      Exit(NewVal(VT_FLO,System.Random()))
   end;

Function F_StrLen(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; L:QInt;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ<>VT_STR) then begin
      V:=ValToStr(Arg[0]); If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Arg[0]:=V end;
   L:=Length(PStr(Arg[0]^.Ptr)^);
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_INT,L))
   end;

Function F_StrPos(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; P:QInt;
   begin
   If (Length(Arg)<2) then Exit(NewVal(VT_INT,0));
   If (Length(Arg)>2) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   For C:=1 downto 0 do 
      If (Arg[C]^.Typ<>VT_STR) then begin
         V:=ValToStr(Arg[C]); If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
         Arg[C]:=V end;
   P:=Pos(PStr(Arg[0]^.Ptr)^,PStr(Arg[1]^.Ptr)^);
   For C:=1 downto 0 do If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   Exit(NewVal(VT_INT,P))
   end;

Function F_SubStr(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; I:Array[1..2] of QInt; R:TStr;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   If (Length(Arg)>3) then
      For C:=High(Arg) downto 3 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   For C:=2 downto 1 do
       If (Length(Arg)>C) then
          If (Arg[C]^.Typ >= VT_INT) and (Arg[C]^.Typ<= VT_BIN)
             then i[C]:=PQInt(Arg[C]^.Ptr)^
             else begin
             V:=ValToInt(Arg[C]); i[C]:=PQInt(V^.Ptr)^; FreeVal(V)
             end else
             If (C=2) then i[C]:=High(Integer) else i[C]:=1;
   If (Arg[0]^.Typ = VT_STR)
      then R:=Copy(PStr(Arg[0]^.Ptr)^,i[1],i[2]) 
      else begin
      V:=ValToStr(Arg[0]); R:=Copy(PStr(V^.Ptr)^,i[1],i[2]); 
      FreeVal(V) end;
   For C:=2 downto 0 do
       If (Length(Arg)>C) and (Arg[C]^.Lev >= CurLev)
          then FreeVal(Arg[C]);
   Exit(NewVal(VT_STR,R))
   end;

Function F_DelStr(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; I:Array[1..2] of QInt; 
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_STR,''));
   If (Length(Arg)>3) then
      For C:=High(Arg) downto 3 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   For C:=2 downto 1 do
       If (Length(Arg)>C) then
          If (Arg[C]^.Typ >= VT_INT) and (Arg[C]^.Typ<= VT_BIN)
             then i[C]:=PQInt(Arg[C]^.Ptr)^
             else begin
             V:=ValToInt(Arg[C]); i[C]:=PQInt(V^.Ptr)^; FreeVal(V)
             end else
             If (C=2) then i[C]:=High(SizeInt) else i[C]:=1;
   If (Arg[0]^.Typ = VT_STR)
      then V:=CopyVal(Arg[0])
      else V:=ValToStr(Arg[0]);
   Delete(PStr(V^.Ptr)^,i[1],i[2]); 
   For C:=2 downto 0 do
       If (Length(Arg)>C) and (Arg[C]^.Lev >= CurLev)
          then FreeVal(Arg[C]);
   Exit(V)
   end;

Function F_sqrt(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; F:TFLoat;
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_FLO,0.0));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ = VT_FLO) then begin
      F:=Sqrt(PFloat(Arg[0]^.Ptr)^)
      end else
   If (Arg[0]^.Typ >= VT_INT) and (Arg[0]^.Typ <= VT_BIN) then begin
      F:=Sqrt(PQInt(Arg[0]^.Ptr)^)
      end else begin
      V:=ValToFlo(Arg[0]);
      F:=Sqrt(PFLoat(V^.Ptr)^);
      FreeVal(V)
      end;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_FLO,F))
   end;

Function F_sizeof(Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; 
   begin
   If (Length(Arg)=0) then Exit(NewVal(VT_INT,0));
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Arg[0]^.Typ <> VT_STR) then begin
      V:=ValToStr(Arg[0]);
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Arg[0]:=V
      end;
   If (PStr(Arg[0]^.Ptr)^ = 'flo') then C:=SizeOf(TFloat) else
   If (PStr(Arg[0]^.Ptr)^ = 'int') then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'hex') then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'oct') then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'bin') then C:=SizeOf(QInt) else
   If (PStr(Arg[0]^.Ptr)^ = 'str') then C:=SizeOf(TStr) else
   If (PStr(Arg[0]^.Ptr)^ = 'log') then C:=SizeOf(Bool) else
   If (PStr(Arg[0]^.Ptr)^ = 'float') then C:=SizeOf(TFloat) else
   If (PStr(Arg[0]^.Ptr)^ = 'string') then C:=SizeOf(TStr) else
   If (PStr(Arg[0]^.Ptr)^ = 'bool') then C:=SizeOf(Bool) else
      (* else *) C:=0;
   If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
   Exit(NewVal(VT_INT,C*8))
   end;

Function F_array(Arg:Array of PValue):PValue;
   Var C:LongWord; T:PValTree; A,V:PValue;
   begin
   A:=EmptyVal(VT_ARR); T:=PValTree(A^.Ptr);
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do begin
          If (Arg[C]^.Lev >= CurLev)
             then V:=Arg[C]
             else V:=CopyVal(Arg[C]);
          T^.SetValNaive(C,V)
          end;
   T^.Rebalance();
   Exit(A)
   end;

Function F_dict(Arg:Array of PValue):PValue;
   Var C:LongWord; T:PValTrie; Key:AnsiString; A,V,oV:PValue;
   begin
   A:=EmptyVal(VT_DIC); T:=PValTrie(A^.Ptr);
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If ((C mod 2)=0) then begin
             If (Arg[C]^.Typ <> VT_STR) then begin
                V:=ValToStr(Arg[C]); Key:=PStr(V^.Ptr)^; FreeVal(V)
                end else Key:=PStr(Arg[C]^.Ptr)^;
             If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
             end else begin
             If (Arg[C]^.Lev >= CurLev)
                then V:=Arg[C]
                else V:=CopyVal(Arg[C]);
             If (T^.IsVal(Key)) then begin oV:=T^.GetVal(Key); FreeVal(oV) end;
                T^.SetVal(Key, V)
             end;
   If ((Length(Arg) mod 2) = 1) then begin
      If (T^.IsVal(Key)) then begin oV:=T^.GetVal(Key); FreeVal(oV) end;
      T^.SetVal(Key, NilVal)
      end;
   Exit(A)
   end;

Function F_array_count(Arg:Array of PValue):PValue;
   Var C,R:LongWord;
   begin R:=0;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_ARR) then R += PValTree(Arg[C]^.Ptr)^.Count else
          If (Arg[C]^.Typ = VT_DIC) then R += PValTrie(Arg[C]^.Ptr)^.Count;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_INT,R))
   end;

Function F_array_empty(Arg:Array of PValue):PValue;
   Var C : LongWord; B:Boolean;
   begin B:=False;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_ARR) then B:=(B or (Not PValTree(Arg[C]^.Ptr)^.Empty)) else
          If (Arg[C]^.Typ = VT_DIC) then B:=(B or (Not PValTrie(Arg[C]^.Ptr)^.Empty));
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,B))
   end;

Function F_dict_nextkey(Arg:Array of PValue):PValue;
   Var C:LongWord; T:PValTrie; K:AnsiString; V:PValue;
   begin
   If (Length(Arg)>=3) then
      For C:=High(Arg) downto 2 do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (Length(Arg)>=2) then begin
      If (Arg[1]^.Typ = VT_STR) then K:=PStr(Arg[1]^.Ptr)^
         else begin
         V:=ValToStr(Arg[1]); K:=PStr(V^.Ptr)^;
         FreeVal(V) end;
      If (Arg[1]^.Lev >= CurLev) then FreeVal(Arg[1])
      end else K:='';
   If (Length(Arg)>=1) then begin
      If (Arg[0]^.Typ <> VT_DIC) then begin
         If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
         Exit(NilVal()) end;
      T:=PValTrie(Arg[0]^.Ptr); K:=T^.NextKey(K);
      If (Arg[0]^.Lev >= CurLev) then FreeVal(Arg[0]);
      Exit(NewVal(VT_STR,K))
      end;
   Exit(NilVal())
   end;

Function F_dict_values(Arg:Array of PValue):PValue;
   Var C,I:LongWord; A,T:PValTrie; K:AnsiString; aV,V:PValue;
   begin
   aV:=EmptyVal(VT_DIC); A:=PValTrie(aV^.Ptr); I:=0;
   If (Length(Arg)>0) then For C:=Low(Arg) to High(Arg) do begin
      If (Arg[C]^.Typ = VT_DIC) then begin
         T:=PValTrie(Arg[C]^.Ptr);
         If (T^.IsVal('')) then begin
            V:=T^.GetVal(''); V:=CopyVal(V); //V^.Tmp:=False;
            A^.SetVal(IntToStr(I),V); I+=1
            end;
         K:=T^.NextKey('');
         While (K<>'') do begin
            V:=T^.GetVal(K); V:=CopyVal(V); //V^.Tmp:=False;
            A^.SetVal(IntToStr(I),V); I+=1;
            K:=T^.NextKey(K)
            end
         end else begin
         If (Arg[C]^.Lev >= CurLev) then V:=Arg[C] else V:=CopyVal(Arg[C]);
         {V^.Tmp:=False;} A^.SetVal(IntToStr(I),V); I+=1
         end;
      If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
      end;
   Exit(aV)
   end;

Function F_array_flush(Arg:Array of PValue):PValue;
   Var C,I,R:LongWord; V:PValue;
       Arr:PValTree; AEA:TValTree.TEntryArr;
       Dic:PValTrie; DEA:TValTrie.TEntryArr;
   begin R:=0;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_ARR) then begin
             Arr:=PValTree(Arg[C]^.Ptr); 
             If (Not Arr^.Empty()) then begin
                AEA:=Arr^.ToArray(); Arr^.Flush(); R += Length(AEA);
                For I:=Low(AEA) to High(AEA) do
                    FreeVal(AEA[I].Val)
             end end;
          If (Arg[C]^.Typ = VT_DIC) then begin
             Dic:=PValTrie(Arg[C]^.Ptr); 
             If (Not Dic^.Empty()) then begin
                DEA:=Dic^.ToArray(); Dic^.Flush(); R += Length(DEA);
                For I:=Low(DEA) to High(DEA) do
                    FreeVal(DEA[I].Val)
             end end;
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_INT,R))
   end;

end.
