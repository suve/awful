unit numtrie;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the NumTrie to be an object or a class? Obviously, it's *
 * impossible to have both at the same time. If both symbols are set,  *
 * Trie becomes a class. If none are set, compilation error occurs.    *)
//{$DEFINE NUMTRIE_CLASS}
{$DEFINE NUMTRIE_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF NUMTRIE_CLASS}  {$DEFINE NUMTRIETYPE:=Class(TObject)} {$ELSE}
{$IFDEF NUMTRIE_OBJECT} {$DEFINE NUMTRIETYPE:=Object}         {$ELSE}
   {$FATAL numtrie.pas: No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type ExNotSet = class(Exception);
     
     generic GenericNumTrie<Tp> = NUMTRIETYPE
     Public
        Type
        TEntry = record
           Key : Int64;
           Val : Tp
           end;
        TEntryArr = Array of TEntry;
     
     Private
        Type
        QWA = Array[0..7] of NativeUInt;
        
        PTp = ^Tp;
        
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
        
        //Function  NextKey(Const K:QWA; D:LongWord; N:PNode; Var I:Int64):Boolean;
        Procedure ToArray(Var A:TEntryArr; Var I:LongWord; N:PNode; D:LongWord; K:QWord);
        
        {Function  GetVal(N:PNode):Tp;
        Function  RemVal(N:PNode):Tp;}
        Procedure FreeNode(N:PNode; D:LongWord);
        
     Public
        {Method}
        Procedure SetVal(Key:Int64; Val:Tp);
        Procedure RemVal(Key:Int64);
        
        Function  IsVal(Key:Int64):Boolean;
        Function  GetVal(Key:Int64):Tp;
        
        {Function  GetVal():Tp;
        Function  RemVal():Tp;}
        
        //Function  NextKey(K:Int64):Int64;
        Function  ToArray():TEntryArr;
        
        Function  Empty() : Boolean;
        Property  Count   : LongWord read Vals;
        Property  Low     : Int64 read MinKey;
        Property  High    : Int64 read MaxKey;
        
        Procedure Flush();
        
        Constructor Create();
        Destructor  Destroy(); {$IFDEF NUMTRIE_CLASS} Override; {$ENDIF}
     end;

implementation

{$DEFINE NXTMIN:=0}
{$DEFINE NXTMAX:=255}
{$DEFINE NXTSIZ:=256}
{$DEFINE DEPTH:=7}

Procedure GenericNumTrie.SetVal(Const K:QWA;D:LongWord;N:PNode;Const V:Tp);
   Var E:PNode; C:LongWord; Vp:PTp;
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
         New(Vp); N^.Nxt[K[D]]:=Vp;
         N^.Chi += 1; Self.Vals += 1
         end;
      PTp(N^.Nxt[K[D]])^:=V
      end
   end;

Procedure GenericNumTrie.SetVal(Key:Int64;Val:Tp);
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

Procedure GenericNumTrie.RemVal(Const K:QWA; D:LongWord; N:PNode);
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
         Dispose(PTp(N^.Nxt[K[D]])); N^.Nxt[K[D]]:=NIL;
         N^.Chi -= 1; Self.Vals -= 1
         end
      end
   end;

Procedure GenericNumTrie.RemVal(Key:Int64);
   Var K:QWA; C:LongWord;
   begin
   For C:=7 downto 1 do begin
       K[C] := QWord(Key) mod 256;
       Key := QWord(Key) div 256
       end;
   K[0] := QWord(Key);
   RemVal(K, 0, Root)
   end;

Function GenericNumTrie.IsVal(Const K:QWA; D:LongWord; N:PNode):Boolean;
   begin
   If (D < DEPTH) then begin
      If (N^.Nxt[K[D]] = NIL) then Exit(False);
      Exit(IsVal(K, D+1, N^.Nxt[K[D]]))
      end else begin
      Exit(N^.Nxt[K[D]] <> NIL)
      end;
   end;

Function GenericNumTrie.IsVal(Key:Int64):Boolean;
   Var K:QWA; C:LongWord;
   begin
   For C:=7 downto 1 do begin
       K[C] := QWord(Key) mod 256;
       Key := QWord(Key) div 256
       end;
   K[0] := QWord(Key);
   Exit(IsVal(K, 0, Root))
   end;

Function GenericNumTrie.GetVal(Const K:QWA; D:LongWord; N:PNode):Tp;
   begin
   If (D < DEPTH) then begin
      If (N^.Nxt[K[D]] = NIL) 
         then Raise ExNotSet.Create('Called GenericNumTrie.GetVal() with an unset key!');
      Exit(GetVal(K, D+1, N^.Nxt[K[D]]))
      end else begin
      If (N^.Nxt[K[D]] = NIL)
         then Raise ExNotSet.Create('Called GenericNumTrie.GetVal() with an unset key!');
      Exit(PTp(N^.Nxt[K[D]])^)
      end;
   end;

Function GenericNumTrie.GetVal(Key:Int64):Tp;
   Var K:QWA; C:LongWord;
   begin
   For C:=7 downto 1 do begin
       K[C] := QWord(Key) mod 256;
       Key := QWord(Key) div 256
       end;
   K[0] := QWord(Key);
   Exit(GetVal(K, 0, Root))
   end;

Function GenericNumTrie.Empty():Boolean;
   begin Exit(Self.Vals = 0) end;
{
Function GenericNumTrie.GetVal(N:PNode):Tp;
   Var C:LongWord;
   begin
   If (N^.Val <> NIL) Then Exit(N^.Val^);
   If (N^.Chi = 0) then
      Raise ExNotSet.Create('Called GenericNumTrie.GetVal() on an empty trie!');
   For C:=NXTMIN to NXTMAX do
       If (N^.Nxt[C]<>NIL) then Exit(GetVal(N^.Nxt[C]))
   end;

Function GenericNumTrie.GetVal():Tp;
   begin Exit(GetVal(Root)) end;

Function GenericNumTrie.RemVal(N:PNode):Tp;
   Var C:LongWord; R:Tp;
   begin
   If (N^.Val <> NIL) Then begin
      R:=N^.Val^; Dispose(N^.Val); N^.Val:=NIL; Self.Vals-=1;
      Exit(R)
      end;
   If (N^.Chi = 0) then
      Raise ExNotSet.Create('Called GenericNumTrie.RemVal() on an empty trie!');
   For C:=System.Low(N^.Nxt) to System.High(N^.Nxt) do
       If (N^.Nxt[C]<>NIL) then begin
          R:=RemVal(N^.Nxt[C]);
          If (N^.Nxt[C]^.Val = NIL) and (N^.Nxt[C]^.Chi = 0) then begin
             Dispose(N^.Nxt[C]); N^.Nxt[C]:=NIL; N^.Chi-=1
             end;
          Exit(R)
          end
   end;

Function GenericNumTrie.RemVal():Tp;
   begin Exit(RemVal(Root)) end;
}
Procedure GenericNumTrie.ToArray(Var A:TEntryArr; Var I:LongWord; N:PNode; D:LongWord; K:QWord);
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
             A[I].Key := K+C; A[I].Val := PTp(N^.Nxt[C])^;
             I := I + 1
             end
      end
   end;

Function GenericNumTrie.ToArray():TEntryArr;
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

Procedure GenericNumTrie.FreeNode(N:PNode; D:LongWord);
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
             Dispose(PTp(N^.Nxt[I])); N^.Nxt[I]:=NIL;
             Self.Vals -= 1
             end
      end;
   N^.Chi:=0
   end;

Constructor GenericNumTrie.Create();
   Var C:LongWord;
   begin
   {$IFDEF NUMTRIE_CLASS} Inherited Create(); {$ENDIF}
   New(Root); SetLength(Root^.Nxt, NXTSIZ); Root^.Chi:=0;
   For C:=NXTMIN to NXTMAX do Root^.Nxt[C]:=NIL;
   Self.MinKey := System.High(Int64); Self.MaxKey := System.Low(Int64);
   Self.Vals:=0;
   end;

Procedure GenericNumTrie.Flush();
   begin FreeNode(Root, 0) end;

Destructor GenericNumTrie.Destroy();
   begin
   Flush(); Dispose(Root);
   {$IFDEF NUMTRIE_CLASS} ; Inherited Destroy() {$ENDIF}
   end;

end.
