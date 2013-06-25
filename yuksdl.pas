unit yuksdl;

{$MODE OBJFPC} {$COPERATORS ON}

interface
   uses Values;

Procedure Register(FT:PFunTrie);

Function F_SDL_Init(Arg:Array of PValue):PValue;
Function F_SDL_Init_Subsystem(Arg:Array of PValue):PValue;
Function F_SDL_WasInit(Arg:Array of PValue):PValue;
Function F_SDL_Quit(Arg:Array of PValue):PValue;
Function F_SDL_Quit_Subsystem(Arg:Array of PValue):PValue;

Function F_SDL_SetVideoMode(Arg:Array of PValue):PValue;

Function F_SDL_EventCheck(Arg:Array of PValue):PValue;
Function F_SDL_EventGet(Arg:Array of PValue):PValue;

Function F_SDL_WindowName(Arg:Array of PValue):PValue;

implementation
   uses SysUtils, Functions, SDL;

Var WindowNameSet:Boolean = FALSE;

Procedure Register(FT:PFunTrie);
   begin
   FT^.SetVal('SDL-init',@F_SDL_Init); FT^.SetVal('SDL-init-subsystem',@F_SDL_Init_Subsystem);
   FT^.SetVal('SDL-quit',@F_SDL_Quit); FT^.SetVal('SDL-quit-subsystem',@F_SDL_Quit_Subsystem); 
   FT^.SetVal('SDL-was-init',@F_SDL_Quit);
   FT^.SetVal('SDL-set-video-mode',@F_SDL_SetVideoMode);
   FT^.SetVal('SDL-event-check',@F_SDL_EventCheck);
   FT^.SetVal('SDL-event-get',@F_SDL_EventGet);
   FT^.SetVal('SDL-windowname',@F_SDL_WindowName);
   end;

Function F_SDL_Init(Arg:Array of PValue):PValue;
   Var C:LongWord; Flags:LongWord; S:TStr;
   begin Flags:=0;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_STR) then begin
             S:=UpperCase(PStr(Arg[C]^.Ptr)^);
             If (S='SDL_INIT_VIDEO') then Flags:=(Flags or SDL_INIT_VIDEO) else
             If (S='SDL_INIT_AUDIO') then Flags:=(Flags or SDL_INIT_AUDIO) else
             If (S='SDL_INIT_TIMER') then Flags:=(Flags or SDL_INIT_TIMER) else
             If (S='SDL_INIT_CDROM') then Flags:=(Flags or SDL_INIT_CDROM) else
             If (S='SDL_INIT_JOYSTICK') then Flags:=(Flags or SDL_INIT_JOYSTICK) else
             If (S='SDL_INIT_EVERYTHING') then Flags:=(Flags or SDL_INIT_EVERYTHING) else
             end;
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,SDL_Init(Flags) = 0))
   end;

Function F_SDL_Init_Subsystem(Arg:Array of PValue):PValue;
   Var C:LongWord; Flags:LongWord; S:TStr;
   begin Flags:=0;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_STR) then begin
             S:=UpperCase(PStr(Arg[C]^.Ptr)^);
             If (S='SDL_INIT_VIDEO') then Flags:=(Flags or SDL_INIT_VIDEO) else
             If (S='SDL_INIT_AUDIO') then Flags:=(Flags or SDL_INIT_AUDIO) else
             If (S='SDL_INIT_TIMER') then Flags:=(Flags or SDL_INIT_TIMER) else
             If (S='SDL_INIT_CDROM') then Flags:=(Flags or SDL_INIT_CDROM) else
             If (S='SDL_INIT_JOYSTICK') then Flags:=(Flags or SDL_INIT_JOYSTICK) else
             If (S='SDL_INIT_EVERYTHING') then Flags:=(Flags or SDL_INIT_EVERYTHING) else
             end;
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,SDL_InitSubSystem(Flags) = 0))
   end;

Function F_SDL_WasInit(Arg:Array of PValue):PValue;
   Var C:LongWord; Flags:LongWord; S:TStr;
   begin Flags:=0;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_STR) then begin
             S:=UpperCase(PStr(Arg[C]^.Ptr)^);
             If (S='SDL_INIT_VIDEO') then Flags:=(Flags or SDL_INIT_VIDEO) else
             If (S='SDL_INIT_AUDIO') then Flags:=(Flags or SDL_INIT_AUDIO) else
             If (S='SDL_INIT_TIMER') then Flags:=(Flags or SDL_INIT_TIMER) else
             If (S='SDL_INIT_CDROM') then Flags:=(Flags or SDL_INIT_CDROM) else
             If (S='SDL_INIT_JOYSTICK') then Flags:=(Flags or SDL_INIT_JOYSTICK) else
             If (S='SDL_INIT_EVERYTHING') then Flags:=(Flags or SDL_INIT_EVERYTHING) else
             end;
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end;
   Exit(NewVal(VT_BOO,SDL_WasInit(Flags) = Flags))
   end;

Function F_SDL_Quit_Subsystem(Arg:Array of PValue):PValue;
   Var C:LongWord; Flags:LongWord; S:TStr;
   begin Flags:=0;
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do begin
          If (Arg[C]^.Typ = VT_STR) then begin
             S:=UpperCase(PStr(Arg[C]^.Ptr)^);
             If (S='SDL_INIT_VIDEO') then Flags:=(Flags or SDL_INIT_VIDEO) else
             If (S='SDL_INIT_AUDIO') then Flags:=(Flags or SDL_INIT_AUDIO) else
             If (S='SDL_INIT_TIMER') then Flags:=(Flags or SDL_INIT_TIMER) else
             If (S='SDL_INIT_CDROM') then Flags:=(Flags or SDL_INIT_CDROM) else
             If (S='SDL_INIT_JOYSTICK') then Flags:=(Flags or SDL_INIT_JOYSTICK) else
             If (S='SDL_INIT_EVERYTHING') then Flags:=(Flags or SDL_INIT_EVERYTHING) else
             end;
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end;
   SDL_QuitSubSystem(Flags); Exit(NilVal())
   end;

Function F_SDL_Quit(Arg:Array of PValue):PValue;
   Var C:LongWord;
   begin
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   SDL_Quit(); Exit(NilVal())
   end;

Function F_SDL_SetVideoMode(Arg:Array of PValue):PValue;
   Var C:LongWord; W,H,BPP:LongWord; Flags:LongWord; 
       A,V:PValue; T:PValTrie; Srf:PSDL_Surface; 
       S:TStr; PC:PChar; 
   begin
   W:=0; H:=0; BPP:=0; Flags:=0;
   If (Length(Arg)>=1) then begin
      V:=ValToInt(Arg[0]); W:=PQInt(V^.Ptr)^;
      FreeVal(V); If (Arg[0]^.Tmp) then FreeVal(Arg[0])
      end;
   If (Length(Arg)>=2) then begin
      V:=ValToInt(Arg[1]); H:=PQInt(V^.Ptr)^;
      FreeVal(V); If (Arg[1]^.Tmp) then FreeVal(Arg[1])
      end;
   If (Length(Arg)>=3) then begin
      V:=ValToInt(Arg[2]); BPP:=PQInt(V^.Ptr)^;
      FreeVal(V); If (Arg[2]^.Tmp) then FreeVal(Arg[2])
      end;
   If (Length(Arg)>3) then
      For C:=High(Arg) downto 3 do begin
          If (Arg[C]^.Typ = VT_STR) then begin
             S:=UpperCase(PStr(Arg[C]^.Ptr)^);
             If (S='SDL_SWSURFACE')  then Flags:=(Flags or SDL_SWSURFACE) else
             If (S='SDL_HWSURFACE')  then Flags:=(Flags or SDL_HWSURFACE) else
             If (S='SDL_ASYNCBLIT')  then Flags:=(Flags or SDL_ASYNCBLIT) else
             If (S='SDL_ANYFORMAT')  then Flags:=(Flags or SDL_ANYFORMAT) else
             If (S='SDL_HWPALETTE')  then Flags:=(Flags or SDL_HWPALETTE) else
             If (S='SDL_DOUBLEBUF')  then Flags:=(Flags or SDL_DOUBLEBUF) else
             If (S='SDL_FULLSCREEN') then Flags:=(Flags or SDL_FULLSCREEN) else
             If (S='SDL_OPENGL')     then Flags:=(Flags or SDL_OPENGL) else
             If (S='SDL_OPENGLBLIT') then Flags:=(Flags or SDL_OPENGLBLIT) else
             If (S='SDL_RESIZABLE')  then Flags:=(Flags or SDL_RESIZABLE) else
             If (S='SDL_NOFRAME')    then Flags:=(Flags or SDL_NOFRAME) else
             end;
          If (Arg[C]^.Tmp) then FreeVal(Arg[C])
          end;
   Srf:=SDL_SetVideoMode(W,H,BPP,Flags);
   If (Srf = NIL) then Exit(NilVal());
   If (Not WindowNameSet) then begin
      S:=ExtractFileName(Functions.YukPath); PC:=PChar(S);
      SDL_WM_SetCaption(PC,PC) end;
   A:=EmptyVal(VT_REC); T:=PValTrie(A^.Ptr);
   V:=NewVal(VT_INT,Srf^.W); V^.Tmp:=False; T^.SetVal('W',V);
   V:=NewVal(VT_INT,Srf^.H); V^.Tmp:=False; T^.SetVal('H',V);
   V:=NewVal(VT_INT,Srf^.Flags); V^.Tmp:=False; T^.SetVal('flags',V);
   Exit(A)
   end;

Function F_SDL_EventCheck(Arg:Array of PValue):PValue;
   Var C:LongWord; 
   begin
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   Exit(NewVal(VT_BOO,SDL_PollEvent(NIL)<>0));
   end;

Function F_SDL_WindowName(Arg:Array of PValue):PValue;
   Var C:LongWord; N:AnsiString; PC:PChar; V:PValue;
   begin
   N:=ExtractFileName(Functions.YukPath);
   If (Length(Arg)>1) then
      For C:=High(Arg) downto 1 do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   If (Length(Arg)>0) then begin
      If (Arg[0]^.Typ = VT_STR) then N:=PStr(Arg[0]^.Ptr)^
         else begin
         V:=ValToStr(Arg[0]); N:=PStr(V^.Ptr)^; FreeVal(V) end;
      If (Arg[0]^.Tmp) then FreeVal(Arg[0])
      end;
   PC:=PChar(N); SDL_WM_SetCaption(PC,PC); WindowNameSet:=True;
   Exit(NewVal(VT_STR,N))
   end;

Function F_SDL_EventGet(Arg:Array of PValue):PValue;
   Var C:LongWord; Ev:TSDL_Event; A,V:PValue; T:PValTrie;
   begin
   If (Length(Arg)>0) then
      For C:=High(Arg) downto Low(Arg) do
          If (Arg[C]^.Tmp) then FreeVal(Arg[C]);
   If (SDL_PollEvent(@Ev) = 0) then Exit(NilVal());
   A:=EmptyVal(VT_REC); T:=PValTrie(A^.Ptr);
   If (Ev.Type_ = SDL_QuitEv) then begin
      V:=NewVal(VT_STR,'Quit'); V^.Tmp:=False;
      T^.SetVal('type',V) end else
   If (Ev.Type_ = SDL_MouseButtonDown) or (Ev.Type_ = SDL_MouseButtonUp) then begin
      If (Ev.Type_ = SDL_MouseButtonDown)
         then V:=NewVal(VT_STR,'MouseButtonDown')
         else V:=NewVal(VT_STR,'MouseButtonUp');
      V^.Tmp:=False; T^.SetVal('type',V);
      V:=NewVal(VT_INT,Ev.Button.Which);
      V^.Tmp:=False; T^.SetVal('which',V);
      V:=NewVal(VT_INT,Ev.Button.Button);
      V^.Tmp:=False; T^.SetVal('button',V);
      V:=NewVal(VT_INT,Ev.Button.X);
      V^.Tmp:=False; T^.SetVal('X',V);
      V:=NewVal(VT_INT,Ev.Button.Y);
      V^.Tmp:=False; T^.SetVal('Y',V)
      end else
   If (Ev.Type_ = SDL_MouseMotion) then begin
      V:=NewVal(VT_STR,'MouseMotion');
      V^.Tmp:=False; T^.SetVal('type',V);
      V:=NewVal(VT_INT,Ev.Motion.Which);
      V^.Tmp:=False; T^.SetVal('which',V);
      V:=NewVal(VT_INT,Ev.Motion.X);
      V^.Tmp:=False; T^.SetVal('X',V);
      V:=NewVal(VT_INT,Ev.Motion.Y);
      V^.Tmp:=False; T^.SetVal('Y',V);
      V:=NewVal(VT_INT,Ev.Motion.Xrel);
      V^.Tmp:=False; T^.SetVal('Xrel',V);
      V:=NewVal(VT_INT,Ev.Motion.Yrel);
      V^.Tmp:=False; T^.SetVal('Yrel',V)
      end else ;
   Exit(A)
   end;

end.
