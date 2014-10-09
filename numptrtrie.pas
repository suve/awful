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

Type
   generic GenericNumPtrTrie<Tp> = NUMPTRTRIETYPE
      Public Type
         TEntry = record
            Key : Int64;
            Val : Tp
         end;
         TEntryArr = Array of TEntry;
         TDisposeProc = Procedure(Const V:Tp);
     
      Protected Type
         PNode = ^TNode;
         TNode = record
            Nxt : Array of Pointer;
            Chi : LongWord
         end;
        
      Protected Var
         Vals : LongWord;
         Root : PNode;
         MinKey, MaxKey : Int64;
        
      Protected {Method}
         Procedure RemVal(Const K:PByte; Const D:LongWord; Const N:PNode);
        
         Procedure ToArray(Var A:TEntryArr; Var I:LongWord; Const N:PNode; Const D:LongWord; K:QWord);
        
         Procedure FreeNode(Const N:PNode; Const D:LongWord);
         Procedure FreeNode(Const N:PNode; Const D:LongWord; Const Proc:TDisposeProc);
        
      Public {Method}
         Procedure SetVal(Const Key:Int64; Const Val:Tp);
         Procedure RemVal(Const Key:Int64);
        
         Function  IsVal(Const Key:Int64):Boolean;
         Function  GetVal(Const Key:Int64):Tp;
        
         Function  ToArray():TEntryArr;
        
         Function  Empty() : Boolean;
         Property  Count   : LongWord read Vals;
         Property  Low     : Int64 read MinKey;
         Property  High    : Int64 read MaxKey;
        
         Procedure Purge();
         Procedure Purge(Const Proc:TDisposeProc);
        
         Constructor Create();
         Destructor  Destroy(); {$IFDEF NUMPTRTRIE_CLASS} Override; {$ENDIF}
   end;

implementation

{$DEFINE NXTMIN:=0}
{$DEFINE NXTMAX:=255}
{$DEFINE NXTSIZ:=256}
{$DEFINE DEPTH:=7}

{$IF     DEFINED(ENDIAN_LITTLE)}
   {$DEFINE OFFSET := DEPTH - D }
   {$NOTE Using little endian byte offset formula.}
{$ELSEIF DEFINED(ENDIAN_BIG   )}
   {$DEFINE OFFSET := D }
   {$NOTE Using big endian byte offset formula.}
{$ELSE}
   {$FATAL The fuck kind of endian is this?}
{$ENDIF}

Procedure GenericNumPtrTrie.SetVal(Const Key:Int64;Const Val:Tp);
   Var D,C:LongInt; N,E:PNode;
   begin
      If (Key > MaxKey) then MaxKey := Key;
      If (Key < MinKey) then MinKey := Key;
      
      N := Root;
      D := 0;
      
      While (D < DEPTH) do begin
         If (N^.Nxt[PByte(@Key)[OFFSET]] = NIL) then begin
            New(E); SetLength(E^.Nxt,NXTSIZ); E^.Chi:=0;
            For C:=NXTMIN to NXTMAX do E^.Nxt[C]:=NIL;
            N^.Nxt[PByte(@Key)[OFFSET]]:=E; N^.Chi+=1
         end;
         N := N^.Nxt[PByte(@Key)[OFFSET]];
         D += 1
      end;
         
      If (N^.Nxt[PByte(@Key)[OFFSET]] = NIL) then begin 
         N^.Chi += 1; Self.Vals += 1
      end;
      Tp(N^.Nxt[PByte(@Key)[OFFSET]]):=Val
   end;

Procedure GenericNumPtrTrie.RemVal(Const K:PByte; Const D:LongWord; Const N:PNode);
   begin
      If (D < DEPTH) then begin
         If (N^.Nxt[K[OFFSET]] = NIL) then Exit();
         RemVal(K, D+1, N^.Nxt[K[OFFSET]]);
         If (PNode(N^.Nxt[K[OFFSET]])^.Chi = 0) then begin
            Dispose(PNode(N^.Nxt[K[OFFSET]])); N^.Nxt[K[OFFSET]]:=NIL;
            N^.Chi-=1
         end
      end else begin
         If (N^.Nxt[K[OFFSET]] <> NIL) then begin
            N^.Chi -= 1; Self.Vals -= 1;
            N^.Nxt[K[OFFSET]]:=NIL
         end
      end
   end;

Procedure GenericNumPtrTrie.RemVal(Const Key:Int64);
   begin RemVal(@Key, 0, Root) end;

Function GenericNumPtrTrie.IsVal(Const Key:Int64):Boolean;
   Var D:LongInt; N : PNode;
   begin
      N := Root;
      D := 0;
      
      While (D < DEPTH) do begin
         If (N^.Nxt[PByte(@Key)[OFFSET]] = NIL) then Exit(False);
         N := N^.Nxt[PByte(@Key)[OFFSET]];
         D += 1
      end;
      Exit(N^.Nxt[PByte(@Key)[OFFSET]] <> NIL)
   end;

Function GenericNumPtrTrie.GetVal(Const Key:Int64):Tp;
   Var D:LongInt; N:PNode;
   begin
      N := Root;
      D := 0;
      
      While (D < DEPTH) do begin
         If (N^.Nxt[PByte(@Key)[OFFSET]] = NIL) then Exit(NIL);
         N := N^.Nxt[PByte(@Key)[OFFSET]];
         D += 1
      end;
      Exit(Tp(N^.Nxt[PByte(@Key)[OFFSET]]))
   end;

Function GenericNumPtrTrie.Empty():Boolean;
   begin Exit(Self.Vals = 0) end;

Procedure GenericNumPtrTrie.ToArray(Var A:TEntryArr; Var I:LongWord; Const N:PNode; Const D:LongWord; K:QWord);
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
   Var Idx:LongWord; C:LongWord;
   begin
      SetLength(Result, Self.Vals); Idx := 0;
      If (Root^.Chi > 0) then begin
         For C:=128 to 255 do
            If (Root^.Nxt[C] <> NIL) then
               Self.ToArray(Result, Idx, Root^.Nxt[C], 1, C);
         For C:=000 to 127 do
            If (Root^.Nxt[C] <> NIL) then
               Self.ToArray(Result, Idx, Root^.Nxt[C], 1, C);
      end
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

Procedure GenericNumPtrTrie.Purge();
   begin FreeNode(Root, 0) end;

Procedure GenericNumPtrTrie.Purge(Const Proc:TDisposeProc);
   begin FreeNode(Root, 0, Proc) end;

Destructor GenericNumPtrTrie.Destroy();
   begin
      Purge(); Dispose(Root)
      {$IFDEF NUMPTRTRIE_CLASS} ; Inherited Destroy() {$ENDIF}
   end;

end.
