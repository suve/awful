unit numptrtrie;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the NumTrie to be an object or a class? Obviously, it's *
 * impossible to have both at the same time. If both symbols are set,  *
 * Trie becomes a class. If none are set, compilation error occurs.    *)
//{$DEFINE NUMPTRTRIE_CLASS}
{$DEFINE NUMPTRTRIE_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF NUMPTRTRIE_CLASS}  {$DEFINE NUMPTRTRIETYPE:=Class(TObject)} {$ELSE}
{$IFDEF NUMPTRTRIE_OBJECT} {$DEFINE NUMPTRTRIETYPE:=Object}         {$ELSE}
   {$FATAL numtrie.pas: No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type generic GenericNumPtrTrie<Tp> = NUMPTRTRIETYPE
     Public
        Type
        TEntry = record
           Key : Int64;
           Val : Tp
           end;
        TEntryArr = Array of TEntry;
        TDisposeProc = Procedure(Const V:Tp);
     
     Private
        Type
        QWA = Array[0..7] of NativeUInt;
        
        PNode = ^TNode;
        TNode = record
           Nxt : Array of Pointer;
           Chi : LongWord
           end;
        
        Var
        Vals : LongWord;
        Root : PNode;
        MinKey, MaxKey : Int64;
        
        {Method}
        Procedure SetVal(Const K:QWA; D:LongWord; N:PNode;Const V:Tp);
        Procedure RemVal(Const K:QWA; D:LongWord; N:PNode);
        
        Function  IsVal(Const K:QWA; D:LongWord; N:PNode):Boolean;
        Function  GetVal(Const K:QWA; D:LongWord; N:PNode):Tp;
        
        Procedure ToArray(Var A:TEntryArr; Var I:LongWord; N:PNode; D:LongWord; K:QWord);
        
        Procedure FreeNode(Const N:PNode; Const D:LongWord);
        Procedure FreeNode(Const N:PNode; Const D:LongWord; Const Proc:TDisposeProc);
        
     Public
        {Method}
        Procedure SetVal(Key:Int64; Val:Tp);
        Procedure RemVal(Key:Int64);
        
        Function  IsVal(Key:Int64):Boolean;
        Function  GetVal(Key:Int64):Tp;
        
        Function  ToArray():TEntryArr;
        
        Function  Empty() : Boolean;
        Property  Count   : LongWord read Vals;
        Property  Low     : Int64 read MinKey;
        Property  High    : Int64 read MaxKey;
        
        Procedure Flush();
        Procedure Flush(Const Proc:TDisposeProc);
        
        Constructor Create();
        Destructor  Destroy(); {$IFDEF NUMPTRTRIE_CLASS} Override; {$ENDIF}
     end;

implementation

{$DEFINE NXTMIN:=0}
{$DEFINE NXTMAX:=255}
{$DEFINE NXTSIZ:=256}
{$DEFINE DEPTH:=7}

Procedure GenericNumPtrTrie.SetVal(Const K:QWA;D:LongWord;N:PNode;Const V:Tp);
   Var E:PNode; C:LongWord;
   begin
   If (D < DEPTH) then begin
      If (N^.Nxt[K[D]] = NIL) then begin
         New(E); SetLength(E^.Nxt,NXTSIZ); E^.Chi:=0;
         For C:=NXTMIN to NXTMAX do E^.Nxt[C]:=NIL;
         N^.Nxt[K[D]]:=E; N^.Chi+=1
         end;
      SetVal(K, D+1, N^.Nxt[K[D]], V)
      end else begin
      If (N^.Nxt[K[D]] = NIL) then begin 
         N^.Chi += 1; Self.Vals += 1
         end;
      Tp(N^.Nxt[K[D]]):=V
      end
   end;

Procedure GenericNumPtrTrie.SetVal(Key:Int64;Val:Tp);
   Var K:QWA; C:LongWord;
   begin
   If (Key > MaxKey) then MaxKey := Key;
   If (Key < MinKey) then MinKey := Key;
   For C:=7 downto 1 do begin
       K[C] := QWord(Key) mod 256;
       Key := QWord(Key) div 256
       end;
   K[0] := QWord(Key);
   SetVal(K, 0, Root, Val)
   end;

Procedure GenericNumPtrTrie.RemVal(Const K:QWA; D:LongWord; N:PNode);
   begin
   If (D < DEPTH) then begin
      If (N^.Nxt[K[D]] = NIL) then Exit();
      RemVal(K, D+1, N^.Nxt[K[D]]);
      If (PNode(N^.Nxt[K[D]])^.Chi = 0) then begin
         Dispose(PNode(N^.Nxt[K[D]])); N^.Nxt[K[D]]:=NIL;
         N^.Chi-=1
         end
      end else begin
      If (N^.Nxt[K[D]] <> NIL) then begin
         N^.Chi -= 1; Self.Vals -= 1;
         N^.Nxt[K[D]]:=NIL
         end
      end
   end;

Procedure GenericNumPtrTrie.RemVal(Key:Int64);
   Var K:QWA; C:LongWord;
   begin
   For C:=7 downto 1 do begin
       K[C] := QWord(Key) mod 256;
       Key := QWord(Key) div 256
       end;
   K[0] := QWord(Key);
   RemVal(K, 0, Root)
   end;

Function GenericNumPtrTrie.IsVal(Const K:QWA; D:LongWord; N:PNode):Boolean;
   begin
   If (D < DEPTH) then begin
      If (N^.Nxt[K[D]] = NIL) then Exit(False);
      Exit(IsVal(K, D+1, N^.Nxt[K[D]]))
      end else begin
      Exit(N^.Nxt[K[D]] <> NIL)
      end;
   end;

Function GenericNumPtrTrie.IsVal(Key:Int64):Boolean;
   Var K:QWA; C:LongWord;
   begin
   For C:=7 downto 1 do begin
       K[C] := QWord(Key) mod 256;
       Key := QWord(Key) div 256
       end;
   K[0] := QWord(Key);
   Exit(IsVal(K, 0, Root))
   end;

Function GenericNumPtrTrie.GetVal(Const K:QWA; D:LongWord; N:PNode):Tp;
   begin
   If (D < DEPTH) then begin
      If (N^.Nxt[K[D]] <> NIL)
         then Exit(GetVal(K, D+1, N^.Nxt[K[D]]))
         else Exit(NIL)
      end else
      Exit(Tp(N^.Nxt[K[D]]))
   end;

Function GenericNumPtrTrie.GetVal(Key:Int64):Tp;
   Var K:QWA; C:LongWord;
   begin
   For C:=7 downto 1 do begin
       K[C] := QWord(Key) mod 256;
       Key := QWord(Key) div 256
       end;
   K[0] := QWord(Key);
   Exit(GetVal(K, 0, Root))
   end;

Function GenericNumPtrTrie.Empty():Boolean;
   begin Exit(Self.Vals = 0) end;

Procedure GenericNumPtrTrie.ToArray(Var A:TEntryArr; Var I:LongWord; N:PNode; D:LongWord; K:QWord);
   Var C:LongWord;
   begin
   If (N^.Chi = 0) then Exit();
   K := K * 256;
   If (D < DEPTH) then begin
      For C:=NXTMIN to NXTMAX do
          If (N^.Nxt[C] <> NIL) then
             Self.ToArray(A, I, N^.Nxt[C], D+1, K+C)
      end else begin
      For C:=NXTMIN to NXTMAX do
          If (N^.Nxt[C] <> NIL) then begin
             A[I].Key := K+C; A[I].Val := Tp(N^.Nxt[C]);
             I := I + 1
             end
      end
   end;

Function GenericNumPtrTrie.ToArray():TEntryArr;
   Var Res:Array of TEntry; Idx:LongWord; C:LongWord;
   begin
   SetLength(Res, Self.Vals); Idx := 0;
   If (Root^.Chi > 0) then begin
      For C:=128 to 255 do
          If (Root^.Nxt[C] <> NIL) then
             Self.ToArray(Res, Idx, Root^.Nxt[C], 1, C);
      For C:=000 to 127 do
          If (Root^.Nxt[C] <> NIL) then
             Self.ToArray(Res, Idx, Root^.Nxt[C], 1, C);
      end;
   Exit(Res)
   end;

Procedure GenericNumPtrTrie.FreeNode(Const N:PNode; Const D:LongWord);
   Var I:LongWord;
   begin
   If (N^.Chi = 0) then Exit();
   If (D < DEPTH) then begin
      For I:=NXTMIN to NXTMAX do
          If (N^.Nxt[I]<>NIL) then begin
             FreeNode(N^.Nxt[I], D+1);
             Dispose(PNode(N^.Nxt[I]));
             N^.Nxt[I]:=NIL
             end
      end else begin
      For I:=NXTMIN to NXTMAX do
          If (N^.Nxt[I]<>NIL) then begin
             N^.Nxt[I]:=NIL; Self.Vals -= 1
             end
      end;
   N^.Chi:=0
   end;

Procedure GenericNumPtrTrie.FreeNode(Const N:PNode; Const D:LongWord; Const Proc:TDisposeProc);
   Var I:LongWord;
   begin
   If (N^.Chi = 0) then Exit();
   If (D < DEPTH) then begin
      For I:=NXTMIN to NXTMAX do
          If (N^.Nxt[I]<>NIL) then begin
             FreeNode(N^.Nxt[I], D+1, Proc);
             Dispose(PNode(N^.Nxt[I]));
             N^.Nxt[I]:=NIL
             end
      end else begin
      For I:=NXTMIN to NXTMAX do
          If (N^.Nxt[I]<>NIL) then begin
             Proc(Tp(N^.Nxt));
             N^.Nxt[I]:=NIL; Self.Vals -= 1
             end
      end;
   N^.Chi:=0
   end;

Constructor GenericNumPtrTrie.Create();
   Var C:LongWord;
   begin
   {$IFDEF NUMPTRTRIE_CLASS} Inherited Create(); {$ENDIF}
   New(Root); SetLength(Root^.Nxt, NXTSIZ); Root^.Chi:=0;
   For C:=NXTMIN to NXTMAX do Root^.Nxt[C]:=NIL;
   Self.MinKey := System.High(Int64); Self.MaxKey := System.Low(Int64);
   Self.Vals:=0
   end;

Procedure GenericNumPtrTrie.Flush();
   begin FreeNode(Root, 0) end;

Procedure GenericNumPtrTrie.Flush(Const Proc:TDisposeProc);
   begin FreeNode(Root, 0, Proc) end;

Destructor GenericNumPtrTrie.Destroy();
   begin
   Flush(); Dispose(Root)
   {$IFDEF NUMPTRTRIE_CLASS} ; Inherited Destroy() {$ENDIF}
   end;

end.
