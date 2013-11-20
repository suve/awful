unit functions_sysinfo;

interface
   uses Values;

Procedure Register(FT:PFunTrie);

{$IFDEF LINUX}
Function F_SysInfo_Get(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_Uptime(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_Load(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_RAMtotal(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_RAMfree(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_RAMbuffer(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_RAMused(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_SwapTotal(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_SwapFree(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_SwapUsed(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_DiskFree(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_DiskTotal(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_DiskUsed(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_Procnum(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_Thermal(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_Hostname(DoReturn:Boolean; Arg:Array of PValue):PValue;
Function F_SysInfo_DomainName(DoReturn:Boolean; Arg:Array of PValue):PValue;

Function F_SysInfo_All(DoReturn:Boolean; Arg:Array of PValue):PValue;
{$ENDIF}

implementation
   uses SysUtils,
        {$IFDEF LINUX}Unix, Linux,{$ENDIF}
        EmptyFunc;
   
Const ROOTDISK = 3;
   
Var SI:PSysInfo;

Procedure Register(FT:PFunTrie);
   begin
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
   FT^.SetVal('sysinfo',@F_SysInfo_All);
   {$ENDIF}
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

Function F_SysInfo_Get(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; GSI:Boolean;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   GSI := GetSysInfo();
   If (DoReturn) then Exit(NewVal(VT_BOO, GSI)) else Exit(NIL)
   end;

Function F_SysInfo_Uptime(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; 
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   If (DoReturn) then Exit(NewVal(VT_INT,SI^.Uptime)) else Exit(NIL)
   end;

Function F_SysInfo_Load(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; L:Int64;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
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
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_FLO,SI^.Loads[L]/65535))
   end;

Function F_SysInfo_RAMtotal(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.TotalRam))
   end;

Function F_SysInfo_RAMfree(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.FreeRam))
   end;

Function F_SysInfo_RAMused(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,(SI^.TotalRam - SI^.FreeRam - SI^.BufferRam)))
   end;

Function F_SysInfo_RAMbuffer(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.BufferRam))
   end;

Function F_SysInfo_SwapTotal(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.TotalSwap))
   end;

Function F_SysInfo_SwapFree(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.FreeSwap))
   end;

Function F_SysInfo_SwapUsed(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,(SI^.TotalSwap - SI^.FreeSwap)))
   end;

Function F_SysInfo_Procnum(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (SI = NIL) then If (Not GetSysInfo()) then Exit(NilVal());
   Exit(NewVal(VT_INT,SI^.Procs))
   end;

Function F_SysInfo_DiskTotal(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_INT,DiskSize(ROOTDISK))) else Exit(NIL)
   end;

Function F_SysInfo_DiskFree(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_INT,DiskFree(ROOTDISK))) else Exit(NIL)
   end;

Function F_SysInfo_DiskUsed(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_INT,(DiskSize(ROOTDISK) - DiskFree(ROOTDISK))))
                 else Exit(NIL)
   end;

Function F_SysInfo_Thermal(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord; V:PValue; Z,T:Int64; F:Text;
   begin
   If (Not DoReturn) then Exit(F_(False, Arg));
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

Function F_SysInfo_Hostname(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_STR,GetHostName())) else Exit(NIL)
   end;

Function F_SysInfo_DomainName(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=Low(Arg) to High(Arg) do
          If (Arg[C]^.Lev >= CurLev) then FreeVal(Arg[C]);
   If (DoReturn) then Exit(NewVal(VT_STR,GetDomainName())) else Exit(NIL)
   end;

Function F_SysInfo_All(DoReturn:Boolean; Arg:Array of PValue):PValue;
   Var SI:PSysInfo; C:LongWord; F:Text; T:Int64;
       Val:PValue; Dict:PValTrie;
       AV:PValue; Arr:PValTree;
   begin
   If (Length(Arg) > 0) then F_(False, Arg);
   If (Not DoReturn) then Exit(NIL);
   
   Val:=EmptyVal(VT_DIC); Dict:=PValTrie(Val^.Ptr);
   If (SysInfo(SI) = 0) then begin
      AV:=EmptyVal(VT_ARR); Arr:=PValTree(AV^.Ptr);
      For C:=0 to 2 do Arr^.SetValNaive(C, NewVal(VT_FLO,SI^.Loads[C]/65535));
      Arr^.Rebalance(); Dict^.SetVal('load',AV);
      
      AV:=EmptyVal(VT_ARR); Arr:=PValTree(AV^.Ptr);
      Arr^.SetValNaive(0, NewVal(VT_INT, SI^.TotalRam));
      Arr^.SetValNaive(1, NewVal(VT_INT, SI^.FreeRam));
      Arr^.SetValNaive(2, NewVal(VT_INT, SI^.TotalRam - SI^.FreeRam));
      Arr^.Rebalance(); Dict^.SetVal('ram',AV);
      
      AV:=EmptyVal(VT_ARR); Arr:=PValTree(AV^.Ptr);
      Arr^.SetValNaive(0, NewVal(VT_INT, SI^.TotalSwap));
      Arr^.SetValNaive(1, NewVal(VT_INT, SI^.FreeSwap));
      Arr^.SetValNaive(2, NewVal(VT_INT, SI^.TotalSwap - SI^.FreeSwap));
      Arr^.Rebalance(); Dict^.SetVal('swap',AV);
      
      Dict^.SetVal('uptime', NewVal(VT_INT, SI^.Uptime));
      Dict^.SetVal('procs', NewVal(VT_INT, SI^.Procs))
      end;
   AV:=EmptyVal(VT_ARR); Arr:=PValTree(AV^.Ptr);
   Arr^.SetValNaive(0, NewVal(VT_INT, DiskSize(ROOTDISK)));
   Arr^.SetValNaive(1, NewVal(VT_INT, DiskFree(ROOTDISK)));
   Arr^.SetValNaive(2, NewVal(VT_INT, DiskSize(ROOTDISK) - DiskFree(ROOTDISK)));
   Arr^.Rebalance();Dict^.SetVal('disk',AV);
   
   AV:=EmptyVal(VT_ARR); Arr:=PValTree(AV^.Ptr); C:=0;
   While (FileExists('/sys/class/thermal/thermal_zone'+IntToStr(C)+'/temp')) do begin
      Assign(F, '/sys/class/thermal/thermal_zone'+IntToStr(C)+'/temp');
      {$I-} Reset(F); {$I+}; 
      If (IOResult = 0) then begin
         Readln(F, T); Close(F)
         end else T:=0;
      Arr^.SetValNaive(C, NewVal(VT_FLO, T/1000));
      C := C + 1
      end;
   Arr^.Rebalance(); Dict^.SetVal('thermal', AV);
   
   Dict^.SetVal('hostname', NewVal(VT_STR, GetHostName()));
   Dict^.SetVal('domain', NewVal(VT_STR, GetDomainName()));
   
   Exit(Val)
   end;
{$ENDIF} //end of Linux-only functions

end.
