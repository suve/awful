unit functions_sysinfo;

{$INCLUDE defines.inc} {$INLINE ON}

interface
   uses Values;

Procedure Register(Const FT:PFunTrie);

{$IFDEF LINUX}
Function F_SysInfo_Get(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
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
   uses SysUtils, Process,
        {$IFDEF LINUX}Unix, Linux,{$ENDIF}
        {$IFDEF WINDOWS}Winsock,{$ENDIF}
        EmptyFunc;

Const DISK_DEFAULT = 0;
      {$IFDEF LINUX} ROOTDISK = 3; {$ENDIF}

{$IFDEF LINUX}
Var     SI : PSysInfo = NIL;
    unameR : AnsiString = '';
    unameS : AnsiString = '';
{$ENDIF}

{$IFDEF WINDOWS}
Var Winderps : AnsiString = '';
{$ENDIF}

Procedure Register(Const FT:PFunTrie);
   begin
   FT^.SetVal('sysinfo-get'       ,{$IFDEF LINUX}@F_SysInfo_Get       {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-uptime'    ,{$IFDEF LINUX}@F_SysInfo_Uptime    {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-load'      ,{$IFDEF LINUX}@F_SysInfo_Load      {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-ram-total' ,{$IFDEF LINUX}@F_SysInfo_RAMtotal  {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-ram-free'  ,{$IFDEF LINUX}@F_SysInfo_RAMfree   {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-ram-used'  ,{$IFDEF LINUX}@F_SysInfo_RAMused   {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-ram-buffer',{$IFDEF LINUX}@F_SysInfo_RAMbuffer {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-swap-total',{$IFDEF LINUX}@F_SysInfo_SwapTotal {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-swap-free' ,{$IFDEF LINUX}@F_SysInfo_SwapFree  {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-swap-used' ,{$IFDEF LINUX}@F_SysInfo_SwapUsed  {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-procnum'   ,{$IFDEF LINUX}@F_SysInfo_Procnum   {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-thermal'   ,{$IFDEF LINUX}@F_SysInfo_Thermal   {$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo-domainname',{$IFDEF LINUX}@F_SysInfo_DomainName{$ELSE}@F_{$ENDIF});
   FT^.SetVal('sysinfo'           ,{$IFDEF LINUX}@F_SysInfo_All       {$ELSE}@F_{$ENDIF});
   // Functions implemented on both platforms
   FT^.SetVal('sysinfo-hostname',@F_SysInfo_Hostname);
   FT^.SetVal('sysinfo-disk-total',@F_SysInfo_DiskTotal);
   FT^.SetVal('sysinfo-disk-free',@F_SysInfo_DiskFree);
   FT^.SetVal('sysinfo-disk-used',@F_SysInfo_DiskUsed);
   FT^.SetVal('sysinfo-system',@F_SysInfo_System);
   FT^.SetVal('sysinfo-version',@F_SysInfo_Version);
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

Function GetSystem():AnsiString; Inline;
   begin 
   If (unameS = '') then begin RunCommand('/usr/bin/uname',['-s'],unameS); unameS:=Trim(unameS) end;
   Exit(unameS) end;

Function GetVersion():AnsiString; Inline;
   begin
   If (unameR = '') then begin RunCommand('/usr/bin/uname',['-r'],unameR); unameR:=Trim(unameR) end;
   Exit(unameR)
   end;

Function F_SysInfo_Get(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; GSI:Boolean;
   begin
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   GSI := GetSysInfo();
   If (DoReturn) then Exit(NewVal(VT_BOO, GSI)) else Exit(NIL)
   end;

Function F_SysInfo_Uptime(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; 
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.Uptime))
   end;

Function F_SysInfo_Load(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; L:Int64;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Exit(NewVal(VT_FLO,SI^.Loads[0]/65535));
   For C:=High(Arg^) downto 1 do
       If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
      then L:=PQInt(Arg^[0]^.Ptr)^
      else L:=ValAsInt(Arg^[0]);
   If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
   If (L < 0) or (L > 2) then L:=0;
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_FLO,SI^.Loads[L]/65535))
   end;

Function F_SysInfo_RAMtotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.TotalRam))
   end;

Function F_SysInfo_RAMfree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.FreeRam))
   end;

Function F_SysInfo_RAMused(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,(SI^.TotalRam - SI^.FreeRam - SI^.BufferRam)))
   end;

Function F_SysInfo_RAMbuffer(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.BufferRam))
   end;

Function F_SysInfo_SwapTotal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.TotalSwap))
   end;

Function F_SysInfo_SwapFree(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.FreeSwap))
   end;

Function F_SysInfo_SwapUsed(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,(SI^.TotalSwap - SI^.FreeSwap)))
   end;

Function F_SysInfo_Procnum(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>0) then
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.Procs))
   end;

Function F_SysInfo_Thermal(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C:LongWord; Zone:Int64; F:Text;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)=0) then Zone:=0 else begin
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
      If (Arg^[0]^.Typ >= VT_INT) and (Arg^[0]^.Typ <= VT_BIN)
         then Zone:=PQInt(Arg^[0]^.Ptr)^
         else Zone:=ValAsInt(Arg^[0]);
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0])
      end;
   If (Zone < 0) then Zone:=0;
   Assign(F,'/sys/class/thermal/thermal_zone'+IntToStr(Zone)+'/temp');
   {$I-} Reset(F); {$I+};
   If (IOResult = 0) then begin
      Readln(F,Zone); Close(F)
      end else Zone:=0;
   Exit(NewVal(VT_FLO,Zone/1000))
   end;

Function F_SysInfo_DomainName(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   If (Length(Arg^)>0) then F_(False, Arg);
   If (DoReturn) then Exit(NewVal(VT_STR,GetDomainName())) else Exit(NIL)
   end;

Function F_SysInfo_All(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var SI:PSysInfo; C:LongWord; F:Text; T:Int64;
       Val:PValue; Dict:PDict;
       AV:PValue; Arr:PArray;
   begin
   If (Length(Arg^) > 0) then F_(False, Arg);
   If (Not DoReturn) then Exit(NIL);
   
   Val:=EmptyVal(VT_DIC); Dict:=PDict(Val^.Ptr); New(SI);
   If (SysInfo(SI) = 0) then begin
      AV:=EmptyVal(VT_ARR); Arr:=PArray(AV^.Ptr);
      For C:=0 to 2 do Arr^.SetVal(C, NewVal(VT_FLO,SI^.Loads[C]/65535));
      Dict^.SetVal('load',AV);
      
      AV:=EmptyVal(VT_ARR); Arr:=PArray(AV^.Ptr);
      Arr^.SetVal(0, NewVal(VT_INT, SI^.TotalRam));
      Arr^.SetVal(1, NewVal(VT_INT, SI^.FreeRam));
      Arr^.SetVal(2, NewVal(VT_INT, SI^.TotalRam - SI^.FreeRam));
      Dict^.SetVal('ram',AV);
      
      AV:=EmptyVal(VT_ARR); Arr:=PArray(AV^.Ptr);
      Arr^.SetVal(0, NewVal(VT_INT, SI^.TotalSwap));
      Arr^.SetVal(1, NewVal(VT_INT, SI^.FreeSwap));
      Arr^.SetVal(2, NewVal(VT_INT, SI^.TotalSwap - SI^.FreeSwap));
      Dict^.SetVal('swap',AV);
      
      Dict^.SetVal('uptime', NewVal(VT_INT, SI^.Uptime));
      Dict^.SetVal('procs', NewVal(VT_INT, SI^.Procs))
      end;
   AV:=EmptyVal(VT_ARR); Arr:=PArray(AV^.Ptr);
   Arr^.SetVal(0, NewVal(VT_INT, DiskSize(ROOTDISK)));
   Arr^.SetVal(1, NewVal(VT_INT, DiskFree(ROOTDISK)));
   Arr^.SetVal(2, NewVal(VT_INT, DiskSize(ROOTDISK) - DiskFree(ROOTDISK)));
   Dict^.SetVal('disk',AV);
   
   AV:=EmptyVal(VT_ARR); Arr:=PArray(AV^.Ptr); C:=0;
   While (FileExists('/sys/class/thermal/thermal_zone'+IntToStr(C)+'/temp')) do begin
      Assign(F, '/sys/class/thermal/thermal_zone'+IntToStr(C)+'/temp');
      {$I-} Reset(F); {$I+}; 
      If (IOResult = 0) then begin
         Readln(F, T); Close(F)
         end else T:=0;
      Arr^.SetVal(C, NewVal(VT_FLO, T/1000));
      C := C + 1
      end;
   Dict^.SetVal('thermal', AV);
   
   Dict^.SetVal('hostname', NewVal(VT_STR, GetHostName()));
   Dict^.SetVal('domain',   NewVal(VT_STR, GetDomainName()));
   Dict^.SetVal('system',   NewVal(VT_STR, GetSystem()));
   Dict^.SetVal('version',  NewVal(VT_STR, GetVersion()));
   
   Dispose(SI); Exit(Val)
   end;
{$ENDIF} //end of Linux-only functions

Function DiskUsed(Drive:Byte):Int64; 
   begin Exit(DiskSize(Drive) - DiskFree(Drive)) end;

Type TDiskFunc = Function(Disk:Byte):Int64;

{$IFDEF LINUX} // Functions present on both Lin&Win; Linux implementations
Function F_SysInfo_Disk(DiskFunc:TDiskFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C, Disk:LongWord; DiskName : TStr;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^)>1) then
      For C:=High(Arg^) downto 1 do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C]);
   If (Length(Arg^) >= 1) then begin
      If (Arg^[0]^.Typ = VT_STR)
         then DiskName := PStr(Arg^[0]^.Ptr)^
         else DiskName := ValAsStr(Arg^[0]);
      If (Arg^[0]^.Lev >= CurLev) then FreeVal(Arg^[0]);
      Disk := AddDisk(DiskName)
      end else Disk := DISK_DEFAULT;
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
Function F_SysInfo_Disk(DiskFunc:TDiskFunc; Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var C, DiskNum : LongInt; DiskPath : AnsiString;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg^) >= 1) then begin
      DiskPath := ExpandFileName(ValAsStr(Arg^[0]));
      DiskNum := Ord(DiskPath[1]) - 64;
      If (DiskNum < 1) or (DiskNum > 26) then DiskNum := DISK_DEFAULT;
      For C:=Low(Arg^) to High(Arg^) do
          If (Arg^[C]^.Lev >= CurLev) then FreeVal(Arg^[C])
      end else DiskNum := DISK_DEFAULT;
   Exit(NewVal(VT_INT,DiskFunc(DiskNum)))
   end;

Function F_SysInfo_Hostname(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   Var Buf : Array[0..255] of Char;
   begin
   If (Length(Arg^)>0) then F_(False, Arg);
   If (Not DoReturn) then Exit(NIL);
   If (GetHostName(@Buf, 256) = 0)
      then Exit(NewVal(VT_STR, Buf))
      else Exit(EmptyVal(VT_STR))
   end;

Function F_SysInfo_System(Const DoReturn:Boolean; Const Arg:PArrPVal):PValue;
   begin
   If (Length(Arg^)>0) then F_(False, Arg);
   If (Not DoReturn) then Exit(NIL);
   If (Win32Platform = 2) then begin
      If (Win32MajorVersion = 6) then begin
         If (Win32MinorVersion = 3) then Exit(NewVal(VT_STR,'Windows 8.1'   )) else
         If (Win32MinorVersion = 2) then Exit(NewVal(VT_STR,'Windows 8'     )) else
         If (Win32MinorVersion = 1) then Exit(NewVal(VT_STR,'Windows 7'     )) else
         If (Win32MinorVersion = 0) then Exit(NewVal(VT_STR,'Windows Vista' )) else
         end else
      If (Win32MajorVersion = 5) then begin
         If (Win32MinorVersion = 1) then Exit(NewVal(VT_STR,'Windows XP'    )) else
         If (Win32MinorVersion = 0) then Exit(NewVal(VT_STR,'Windows 2000'  )) else
         end else
      If (Win32MajorVersion = 4) then begin
         If (Win32MinorVersion = 0) then Exit(NewVal(VT_STR,'Windows NT 4.0')) else
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
   If (Length(Arg^)>0) then F_(False, Arg);
   If (Not DoReturn) then Exit(NIL);
   Exit(NewVal(VT_STR, Values.IntToStr(Win32Platform)+'.'+
                       Values.IntToStr(Win32MajorVersion)+'.'+
                       Values.IntToStr(Win32MinorVersion)))
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
