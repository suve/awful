unit functions_sysinfo;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Procedure Register(Const FT:PFunTrie);

{$IFDEF LINUX}
Function F_SysInfo_Uptime(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_Load(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_RAMtotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_RAMfree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_RAMbuffer(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_RAMused(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_SwapTotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_SwapFree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_SwapUsed(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_Procnum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_Thermal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_DomainName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Function F_SysInfo_All(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
{$ENDIF}

Function F_SysInfo_Hostname(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_DiskFree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_DiskTotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_DiskUsed(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_System(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
Function F_SysInfo_Version(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;

implementation
   uses SysUtils,
        {$IFDEF LINUX} Unix, Linux, Process, {$ENDIF}
        {$IFDEF WINDOWS} Winsock, {$ENDIF}
        EmptyFunc, Values_Typecast, Convert;

Const DISK_DEFAULT = 0;
      {$IFDEF LINUX} ROOTDISK = 3; {$ENDIF}

{$IFDEF LINUX}
Var
       SI : TSysInfo;
   unameR : AnsiString = '';
   unameS : AnsiString = '';
{$ENDIF}

Procedure Register(Const FT:PFunTrie);
   begin
      // Deprecated
      FT^.SetVal('sysinfo-get'       , MkFunc(@F_));
      // Linux-only stuff
      FT^.SetVal('sysinfo-uptime'    , MkFunc({$IFDEF LINUX}@F_SysInfo_Uptime    {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-load'      , MkFunc({$IFDEF LINUX}@F_SysInfo_Load      {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-ram-total' , MkFunc({$IFDEF LINUX}@F_SysInfo_RAMtotal  {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-ram-free'  , MkFunc({$IFDEF LINUX}@F_SysInfo_RAMfree   {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-ram-used'  , MkFunc({$IFDEF LINUX}@F_SysInfo_RAMused   {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-ram-buffer', MkFunc({$IFDEF LINUX}@F_SysInfo_RAMbuffer {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-swap-total', MkFunc({$IFDEF LINUX}@F_SysInfo_SwapTotal {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-swap-free' , MkFunc({$IFDEF LINUX}@F_SysInfo_SwapFree  {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-swap-used' , MkFunc({$IFDEF LINUX}@F_SysInfo_SwapUsed  {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-procnum'   , MkFunc({$IFDEF LINUX}@F_SysInfo_Procnum   {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-thermal'   , MkFunc({$IFDEF LINUX}@F_SysInfo_Thermal   {$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo-domainname', MkFunc({$IFDEF LINUX}@F_SysInfo_DomainName{$ELSE}@F_{$ENDIF}));
      FT^.SetVal('sysinfo'           , MkFunc({$IFDEF LINUX}@F_SysInfo_All       {$ELSE}@F_{$ENDIF}));
      // Functions implemented on both platforms
      FT^.SetVal('sysinfo-hostname',MkFunc(@F_SysInfo_Hostname));
      FT^.SetVal('sysinfo-disk-total',MkFunc(@F_SysInfo_DiskTotal));
      FT^.SetVal('sysinfo-disk-free',MkFunc(@F_SysInfo_DiskFree));
      FT^.SetVal('sysinfo-disk-used',MkFunc(@F_SysInfo_DiskUsed));
      FT^.SetVal('sysinfo-system',MkFunc(@F_SysInfo_System));
      FT^.SetVal('sysinfo-version',MkFunc(@F_SysInfo_Version));
   end;

{$IFDEF LINUX}
Function GetSystem():AnsiString; Inline;
   begin 
      If (unameS = '') then begin
         RunCommand('/usr/bin/uname', ['-s'], unameS);
         unameS:=Trim(unameS)
      end;
      Exit(unameS)
   end;

Function GetVersion():AnsiString; Inline;
   begin
      If (unameR = '') then begin
         RunCommand('/usr/bin/uname', ['-r'], unameR);
         unameR:=Trim(unameR)
      end;
      Exit(unameR)
   end;

Function F_SysInfo_Uptime(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := SI.Uptime }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_Procnum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := SI.Procs }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_RAMtotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := SI.TotalRam }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_RAMfree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := SI.FreeRam }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_RAMbuffer(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := SI.BufferRam }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_RAMused(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := (SI.TotalRam - SI.FreeRam - SI.BufferRam) }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_SwapTotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := SI.TotalSwap }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_SwapFree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := SI.FreeSwap }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_SwapUsed(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   {$DEFINE __FIELD__ := (SI.TotalSwap - SI.FreeSwap) }
   {$INCLUDE functions_sysinfo-getfield.inc }
   {$UNDEF __FIELD__ }
   end;

Function F_SysInfo_Load(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var L:Int64;
   begin
      // If no retval expected, bail out
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // If argument present, get load type from arg0 and validate
      If (Length(Arg^) > 0) then begin
         L := ValAsInt(Arg^[0]);
         If (L < 0) then L := 0 else If (L > 2) then L := 2;
         F_(False, Arg) // Free args
      end else
         L := 0; //default to 0
      
      // Return nilval if failed to fetch sysinfo, or % load otherwise
      If (SysInfo(@SI) <> 0) then Exit(NilVal());
      
      // Loads are returned as unsigned 16-bit integers, where MAX = 100%
      Exit(NewVal(VT_FLO,SI.Loads[L]/65535))
   end;

Function F_SysInfo_Thermal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Zone:Int64; F:Text;
   begin
      // No retval expected, so bail out early
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Check if any args were provided. Extract zone number from arg0.
      If (Length(Arg^) > 0) then begin
         Zone := ValAsInt(Arg^[0]);
         If (Zone < 0) then Zone := 0;
         F_(False, Arg)
      end else
         Zone := 0; // No args? default to 0
      
      // Attemp to read thermal info, or set result to -1 on failure
      Assign(F,'/sys/class/thermal/thermal_zone'+IntToStr(Zone)+'/temp');
      {$I-} Reset(F); {$I+};
      If (IOResult() = 0) then begin
         Readln(F,Zone); Close(F)
      end else
         Zone := -1000;
      
      Exit(NewVal(VT_FLO, Zone/1000)) // temp is reported in milicelsius
   end;

Function F_SysInfo_DomainName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_STR,GetDomainName())) else Exit(NIL)
   end;

Function F_SysInfo_All(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Zone:LongWord; TZF:System.Text; Temp:Int64; AV:PValue;
   begin
      // Free args, if any, and bail out early if no retval expected
      If (Length(Arg^) > 0) then F_(False, Arg);
      If (Not DoReturn) then Exit(NIL);
   
      Result := EmptyVal(VT_DIC);
      
      (* Attemp to grab system information via FPC's SysInfo() function.  *
       * If successful, insert this info into result dictionary.          *
       * After that, insert data which can be accessed outside SysInfo(). *) 
      If (SysInfo(@SI) = 0) then begin
         
         // Create system load array and add to result dict
         AV := EmptyVal(VT_ARR);
         For Zone:=0 to 2 do AV^.Arr^.SetVal(Zone, NewVal(VT_FLO,SI.Loads[Zone]/65535));
         Result^.Dic^.SetVal('load',AV);
         
         // Create RAM usage array and add to result dict
         AV := EmptyVal(VT_ARR);
         AV^.Arr^.SetVal(0, NewVal(VT_INT, SI.TotalRam));
         AV^.Arr^.SetVal(1, NewVal(VT_INT, SI.FreeRam));
         AV^.Arr^.SetVal(2, NewVal(VT_INT, SI.TotalRam - SI.FreeRam - SI.BufferRam));
         Result^.Dic^.SetVal('ram',AV);
         
         // Create Swap usage array and add to result dict
         AV := EmptyVal(VT_ARR);
         AV^.Arr^.SetVal(0, NewVal(VT_INT, SI.TotalSwap));
         AV^.Arr^.SetVal(1, NewVal(VT_INT, SI.FreeSwap));
         AV^.Arr^.SetVal(2, NewVal(VT_INT, SI.TotalSwap - SI.FreeSwap));
         Result^.Dic^.SetVal('swap',AV);
         
         // Add uptime and procs info
         Result^.Dic^.SetVal('uptime', NewVal(VT_INT, SI.Uptime));
         Result^.Dic^.SetVal('procs', NewVal(VT_INT, SI.Procs))
      end;
      
      // Create root disk usage array and insert into result dict
      AV := EmptyVal(VT_ARR); 
      AV^.Arr^.SetVal(0, NewVal(VT_INT, DiskSize(ROOTDISK)));
      AV^.Arr^.SetVal(1, NewVal(VT_INT, DiskFree(ROOTDISK)));
      AV^.Arr^.SetVal(2, NewVal(VT_INT, DiskSize(ROOTDISK) - DiskFree(ROOTDISK)));
      Result^.Dic^.SetVal('disk',AV);
      
      (* Create array to hold info from thermal zones.                                            *
       * Start reading from zone 0 and go as far up as possible, reading thermal data on the way. *
       * After that, obviously, insert the array into function result dict.                       *)
      AV := EmptyVal(VT_ARR); Zone := 0;
      While (FileExists('/sys/class/thermal/thermal_zone'+IntToStr(Zone)+'/temp')) do begin
         
         // Assign file handle and try to open file
         Assign(TZF, '/sys/class/thermal/thermal_zone'+IntToStr(Zone)+'/temp');
         {$I-} Reset(TZF); {$I+}; 
         
         // If successful, read from file and close it. Else, set Temp to -1 to signal error
         If (IOResult() = 0) then begin
            Readln(TZF, Temp); Close(TZF)
         end else
            Temp := -1000;
         
         AV^.Arr^.SetVal(Zone, NewVal(VT_FLO, Temp/1000)); // thermal zone data is in milicelsius
         Zone += 1
      end;
      Result^.Dic^.SetVal('thermal', AV);
      
      // Insert remaining info to dict
      Result^.Dic^.SetVal('hostname', NewVal(VT_STR, GetHostName()));
      Result^.Dic^.SetVal('domain',   NewVal(VT_STR, GetDomainName()));
      Result^.Dic^.SetVal('system',   NewVal(VT_STR, GetSystem()));
      Result^.Dic^.SetVal('version',  NewVal(VT_STR, GetVersion()));
   end;
{$ENDIF} //end of Linux-only functions

Function DiskUsed(Drive:Byte):Int64; 
   begin Exit(DiskSize(Drive) - DiskFree(Drive)) end;

Type TDiskFunc = Function(Disk:Byte):Int64;

{$IFDEF LINUX} // Functions present on both Lin&Win; Linux implementations
Function F_SysInfo_Disk(DiskFunc:TDiskFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Disk:LongWord; 
   begin
      // Bail out if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      (* Check if any args provided. If yes, arg0 is expected to contain the path to check.   *
       * Under Linux, FPC's DiskSize() / DiskFree() functions, unfortunately, still expect us *
       * to provide a disk number. Fortunately there is AddDisk(), which takes in a path and  *
       * adds (or reuses) a disk entry. So we add the disk and then use the new entry number. *)
      If (Length(Arg^) >= 1) then begin
         Disk := AddDisk(ValAsStr(Arg^[0]));
         F_(False, Arg);
      end else
         Disk := DISK_DEFAULT; // no args = use default
      
      Exit(NewVal(VT_INT,DiskFunc(Disk)))
   end;

Function F_SysInfo_Hostname(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_STR,GetHostName())) else Exit(NIL)
   end;

Function F_SysInfo_System(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_STR,GetSystem())) else Exit(NIL)
   end;

Function F_SysInfo_Version(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      If (Length(Arg^)>0) then F_(False, Arg);
      If (DoReturn) then Exit(NewVal(VT_STR,GetVersion())) else Exit(NIL)
   end;
{$ENDIF}

{$IFDEF WINDOWS} // Functions present on both Lin&Win; Winderps implementations
Function F_SysInfo_Disk(Const DiskFunc:TDiskFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var DiskNum : LongInt; DiskPath : AnsiString;
   begin
      // Bail out early if no retval expected
      If (Not DoReturn) then Exit(F_(False, Arg));
      
      // Check if args provided. If yes, extract dir name from arg0
      If (Length(Arg^) >= 1) then begin
         DiskPath := ExpandFileName(ValAsStr(Arg^[0]));
         F_(False, Arg);
         
         // Convert disk letter to number (where A = 1)
         If(Length(DiskPath) > 0) then
            If(DiskPath[1] >= #65) and (DiskPath <= #90)  // A - Z
               then DiskNum := Ord(DiskPath[1]) - 64 else
            If(DiskPath[1] >= #97) and (DiskPath <= #122) // a - z
               then DiskNum := Ord(DiskPath[1]) - 96 else
            If(DiskPath[1] >= #49) and (DiskPath <= #57)  // 0 - 9, just in case...
               then DiskNum := Ord(DiskPath[1]) - 49
               else DiskNum := DISK_DEFAULT // invalid arg, use default
         else DiskNum := DISK_DEFAULT;      // empty string, use default
         
         // Validate number
         If (DiskNum < 1) or (DiskNum > 26) then DiskNum := DISK_DEFAULT; 
      end else
         DiskNum := DISK_DEFAULT; // no args, use default
      
      Exit(NewVal(VT_INT,DiskFunc(DiskNum)))
   end;

Function F_SysInfo_Hostname(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Buf : Array[0..255] of Char;
   begin
      // Free args, if any, and bail out if no retval expected
      If (Length(Arg^)>0) then F_(False, Arg);
      If (Not DoReturn) then Exit(NIL);
      
      // Attempt to get hostname. Return emptystring on fail
      If (GetHostName(PChar(@Buf), 256) = 0)
         then Exit(NewVal(VT_STR, Buf))
         else Exit(EmptyVal(VT_STR))
   end;

Function F_SysInfo_System(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // Free args, if any, and bail out if no retval expected
      If (Length(Arg^)>0) then F_(False, Arg);
      If (Not DoReturn) then Exit(NIL);
      
      // Check Win32XYZ variables and guess system version basing on this info
      If (Win32Platform = 2) then begin
         If (Win32MajorVersion = 10) then begin
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows 10'    )) else
         end else
         If (Win32MajorVersion = 6) then begin
            If (Win32MinorVersion =  3) then Exit(NewVal(VT_STR,'Windows 8.1'   )) else
            If (Win32MinorVersion =  2) then Exit(NewVal(VT_STR,'Windows 8'     )) else
            If (Win32MinorVersion =  1) then Exit(NewVal(VT_STR,'Windows 7'     )) else
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows Vista' )) else
         end else
         If (Win32MajorVersion = 5) then begin
            If (Win32MinorVersion =  1) then Exit(NewVal(VT_STR,'Windows XP'    )) else
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows 2000'  )) else
         end else
         If (Win32MajorVersion = 4) then begin
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows NT 4.0')) else
         end else
      end else
      If (Win32Platform = 1) then begin
         If (Win32MajorVersion = 4) then begin
            If (Win32MinorVersion = 90) then Exit(NewVal(VT_STR,'Windows ME'    )) else
            If (Win32MinorVersion = 10) then Exit(NewVal(VT_STR,'Windows 98'    )) else
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows 95'    )) else
         end else
      end else
      If (Win32Platform = 0) then begin
         If (Win32MajorVersion = 3) then begin
            If (Win32MinorVersion = 10) then Exit(NewVal(VT_STR,'Windows 3.1'    )) else
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows 3.0'    )) else
         end else
         If (Win32MajorVersion = 2) then begin
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows 2.0'    )) else
         end else
         If (Win32MajorVersion = 1) then begin
            If (Win32MinorVersion =  0) then Exit(NewVal(VT_STR,'Windows 1.0'    )) else
         end else
      end;
      Exit(NewVal(VT_STR,'Windows (Unknown)'))
   end;

Function F_SysInfo_Version(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
      // Free args, if any, and bail out if no retval expected
      If (Length(Arg^)>0) then F_(False, Arg);
      If (Not DoReturn) then Exit(NIL);
      
      // Get empty string for result value and then write version number to the string
      Result := EmptyVal(VT_STR);
      WriteStr(Result^.Str^, Win32Platform, '.', Win32MajorVersion, '.', Win32MinorVersion)
   end;
{$ENDIF}

// Functions present on both Lin&Win; shared code

Function F_SysInfo_DiskTotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_SysInfo_Disk(@DiskSize, DoReturn, Arg)) end;

Function F_SysInfo_DiskFree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_SysInfo_Disk(@DiskFree, DoReturn, Arg)) end;

Function F_SysInfo_DiskUsed(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin Exit(F_SysInfo_Disk(@DiskUsed, DoReturn, Arg)) end;

end.
