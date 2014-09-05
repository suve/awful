unit dynptrtrie;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the Trie to be an object or a class? Obviously, it's   *
 * impossible to have both at the same time. If both symbols are set, *
 * Trie becomes a class. If none are set, compilation error occurs.   *)
//{$DEFINE DYNPTRTRIE_CLASS}
{$DEFINE DYNPTRTRIE_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF DYNPTRTRIE_CLASS}  {$DEFINE DYNPTRTRIETYPE:=Class(TObject)} {$ELSE}
{$IFDEF DYNPTRTRIE_OBJECT} {$DEFINE DYNPTRTRIETYPE:=Object}         {$ELSE}
   {$FATAL trie.pas: No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type
   TNibble = 0..15;
   TByte = bitpacked record
      Lo, Hi : TNibble
   end;

Type generic GenericDynPtrTrie<Tp> = DYNPTRTRIETYPE
     Public
        Type
        TDisposeProc = Procedure(Const V:Tp);
        
     Private
        Type
        PNodeFan = ^TNodeFan;
        PNode = ^TNode;
        
        TNodeFan = record
           Nod : Array[0..15] of PNode;
           Cnt : LongWord;
           end;
        
        TNode = record
           Fan : Array[0..15] of PNodeFan;
           Cnt : LongWord;
           Val : Tp;
           end;
        
        Var
        Vals : LongWord;
        Root : PNode;
        
        {Method}
        Procedure RemVal(Const K:AnsiString;Const P:LongInt;Const N:PNode);
        
        Function  NextKey(Const N:PNode;Const C:LongWord;Const K:AnsiString;Var R:AnsiString):Boolean;
        
        Function  GetVal(Const N:PNode):Tp;
        Function  RemVal(Const N:PNode):Tp;
        Procedure FreeNode(Const N:PNode);
        Procedure FreeNode(Const N:PNode;Const Proc:TDisposeProc);
     
     Public
        Type
        TEntry = record
           Key : AnsiString;
           Val : Tp
           end;
        TEntryArr = Array of TEntry;
        
        {Method}
        Procedure SetVal(Const Key:AnsiString;Const Val:Tp);
        Procedure RemVal(Const Key:AnsiString);
        
        Function  IsVal(Const Key:AnsiString):Boolean;
        Function  GetVal(Const Key:AnsiString):Tp;
        
        Function  GetVal():Tp;
        Function  RemVal():Tp;
        
        Function  NextKey(Const K:AnsiString):AnsiString;
        Function  ToArray():TEntryArr;
        
        Function  Empty() : Boolean;
        Property  Count   : LongWord read Vals;
        
        Procedure Flush();
        Procedure Flush(Const Proc:TDisposeProc);
        
        Constructor Create();
        Destructor  Destroy(); {$IFDEF DYNPTRTRIE_CLASS} Override; {$ENDIF}
     end;

implementation


Procedure GenericDynPtrTrie.SetVal(Const Key:AnsiString;Const Val:Tp);
   Var L,P,F,I,C:LongInt; N,E:PNode; 
   begin 
   L:=Length(Key); P := 1; N := Root;
   While (P <= L) do begin
      F:=TByte(Key[P]).Hi; I := TByte(Key[P]).Lo;
      
      If (N^.Fan[F] = NIL) then begin
         New(N^.Fan[F]); N^.Fan[F]^.Cnt := 0;
         For C:=0 to 15 do N^.Fan[F]^.Nod[C]:=NIL;
         N^.Cnt += 1
         end;
         
      If (N^.Fan[F]^.Nod[I] = NIL) then begin
         New(E); E^.Val:=NIL; E^.Cnt:=0;
         For C:=0 to 15 do E^.Fan[C]:=NIL;
         N^.Fan[F]^.Nod[I]:=E; N^.Fan[F]^.Cnt += 1
         end;
      
      N := N^.Fan[F]^.Nod[I];
      P += 1
      end;
      
   If (N^.Val = NIL) then Self.Vals += 1;
      N^.Val:=Val
   end;

Procedure GenericDynPtrTrie.RemVal(Const K:AnsiString;Const P:LongInt;Const N:PNode);
   Var F,I:LongInt;
   begin
   If (P<=Length(K)) then begin
      F:=TByte(K[P]).Hi; I := TByte(K[P]).Lo;
      If (N^.Fan[F] = NIL) then Exit();
      If (N^.Fan[F]^.Nod[I] = NIL) then Exit();
      RemVal(K,P+1,N^.Fan[F]^.Nod[I]);
      If (N^.Fan[F]^.Nod[I]^.Cnt = 0) and (N^.Fan[F]^.Nod[I]^.Val = NIL) then begin
         Dispose(N^.Fan[F]^.Nod[I]); N^.Fan[F]^.Nod[I]:=NIL;
         N^.Fan[F]^.Cnt -= 1;
         If (N^.Fan[F]^.Cnt = 0) then begin
            Dispose(N^.Fan[F]); N^.Fan[F] := NIL;
            N^.Cnt -= 1
            end
         end
      end else begin
      If (N^.Val <> NIL) then begin
         N^.Val:=NIL; Self.Vals -= 1
         end
      end
   end;

Procedure GenericDynPtrTrie.RemVal(Const Key:AnsiString);
   begin RemVal(Key,1,Root) end;

Function GenericDynPtrTrie.IsVal(Const Key:AnsiString):Boolean;
   Var L,P,F,I:LongInt; N:PNode;
   begin
   L := Length(Key); P := 1; N := Root;
   While (P <= L) do begin
      F:=TByte(Key[P]).Hi; I := TByte(Key[P]).Lo;
      If (N^.Fan[F] = NIL) or (N^.Fan[F]^.Nod[I] = NIL) then Exit(False);
      N := N^.Fan[F]^.Nod[I];
      P += 1
      end;
   Exit(N^.Val <> NIL)
   end;

Function GenericDynPtrTrie.GetVal(Const Key:AnsiString):Tp;
   Var L,P,F,I:LongInt; N:PNode;
   begin
   L := Length(Key); P := 1; N := Root;
   While (P <= L) do begin
      F:=TByte(Key[P]).Hi; I := TByte(Key[P]).Lo;
      If (N^.Fan[F] = NIL) or (N^.Fan[F]^.Nod[I] = NIL) then Exit(NIL);
      N := N^.Fan[F]^.Nod[I];
      P += 1
      end;
   Exit(N^.Val)
   end;

Function GenericDynPtrTrie.Empty():Boolean;
   begin Exit(Self.Vals = 0) end;

Function GenericDynPtrTrie.GetVal(Const N:PNode):Tp;
   Var F,I:LongWord;
   begin
   If (N^.Val <> NIL) Then Exit(N^.Val);
   If (N^.Cnt = 0) then Exit(NIL);
   For F:=0 to 15 do
       If (N^.Fan[F] <> NIL) then
          For I:=0 to 15 do
              If (N^.Fan[F]^.Nod[I] <> NIL) then
                 Exit(GetVal(N^.Fan[F]^.Nod[I]))
   end;

Function GenericDynPtrTrie.GetVal():Tp;
   begin Exit(GetVal(Root)) end;

Function GenericDynPtrTrie.RemVal(Const N:PNode):Tp;
   Var F,I:LongWord; R:Tp;
   begin
   If (N^.Val <> NIL) Then begin
      R:=N^.Val; N^.Val:=NIL; Self.Vals-=1;
      Exit(R)
      end;
   If (N^.Cnt = 0) then Exit(NIL);
   For F:=0 to 15 do
       If (N^.Fan[F] <> NIL) then
          For I:=0 to 15 do
              If (N^.Fan[F]^.Nod[I] <> NIL) then begin
                 R:=RemVal(N^.Fan[F]^.Nod[I]);
                 If (N^.Fan[F]^.Nod[I]^.Val = NIL) and (N^.Fan[F]^.Nod[I]^.Cnt = 0) then begin
                    Dispose(N^.Fan[F]^.Nod[I]); N^.Fan[F]^.Nod[I]:=NIL; N^.Fan[F]^.Cnt -= 1;
                    If (N^.Fan[F]^.Cnt = 0) then begin
                        Dispose(N^.Fan[F]); N^.Fan[F] := NIL; N^.Cnt -= 1
                    end end;
                 Exit(R)
                 end
   end;

Function GenericDynPtrTrie.RemVal():Tp;
   begin Exit(RemVal(Root)) end;

Function GenericDynPtrTrie.NextKey(Const N:PNode;Const C:LongWord;Const K:AnsiString;Var R:AnsiString):Boolean;
   Var L,F,I,sI,sF:LongWord;
   begin
   If (N^.Cnt = 0) then Exit(False);
   L := Length(K);
   If (L >= C) then begin
      F:=TByte(K[C]).Hi; I := TByte(K[C]).Lo;
      If (N^.Fan[F]<>NIL) and (N^.Fan[F]^.Nod[I] <> NIL) then begin
         If (NextKey(N^.Fan[F]^.Nod[I],C+1,K,R)) then begin
            R:=Chr(F*16+I)+R; Exit(True)
         end end;
      If (I < 15) then begin sI:=I+1; sF:=F end
                  else begin sI:=0; sF:=F+1 end
      end else begin
      sF:=0; sI:=0
      end;
   For F:=sF to 15 do
       If (N^.Fan[F] <> NIL) then begin
          For i:=sI to 15 do
              If (N^.Fan[F]^.Nod[I] <> NIL) then
                 If (N^.Fan[F]^.Nod[I]^.Val<>NIL)
                    then begin 
                    R:=Chr(F*16+I)+R; Exit(True)
                    end else begin
                    If (NextKey(N^.Fan[F]^.Nod[I],C+1,'',R)) then begin
                       R:=Chr(F*16+I)+R; Exit(True)
                    end end;
          sI := 0
          end;
   Exit(False)
   end;

Function GenericDynPtrTrie.NextKey(Const K:AnsiString):AnsiString;
   Var R:AnsiString;
   begin R:='';
   If NextKey(Root,1,K,R) then Exit(R) else Exit('') end;

Function GenericDynPtrTrie.ToArray():TEntryArr;
   Var Res:Array of TEntry; K:AnsiString;
   begin
   If (IsVal('')) then begin
      SetLength(Res,1);
      Res[0].Key:=''; Res[0].Val := GetVal('')
      end else SetLength(Res,0);
   K:=NextKey('');
   While (K<>'') do begin
      SetLength(Res,Length(Res)+1);
      Res[High(Res)].Key := K;
      Res[High(Res)].Val := GetVal(K);
      K:=NextKey(K)
      end;
   Exit(Res)
   end;

Procedure GenericDynPtrTrie.FreeNode(Const N:PNode);
   Var F,I:LongWord;
   begin
   If (N^.Cnt > 0) then begin
      For F:=0 to 15 do
          If (N^.Fan[F]<>NIL) then begin
             If (N^.Fan[F]^.Cnt > 0) then
                For I:=0 to 15 do 
                    If (N^.Fan[F]^.Nod[I] <> NIL) then begin
                       FreeNode(N^.Fan[F]^.Nod[I]);
                       Dispose(N^.Fan[F]^.Nod[I]);
                       end;
             Dispose(N^.Fan[F]);
             N^.Fan[F]:=NIL
             end;
      N^.Cnt:=0;
      end;
   If (N^.Val <> NIL) then Self.Vals -= 1
   end;

Procedure GenericDynPtrTrie.FreeNode(Const N:PNode;Const Proc:TDisposeProc);
   Var F,I:LongWord;
   begin
   If (N^.Cnt > 0) then begin
      For F:=0 to 15 do
          If (N^.Fan[F]<>NIL) then begin
             If (N^.Fan[F]^.Cnt > 0) then
                For I:=0 to 15 do 
                    If (N^.Fan[F]^.Nod[I] <> NIL) then begin
                       FreeNode(N^.Fan[F]^.Nod[I],Proc);
                       Dispose(N^.Fan[F]^.Nod[I])
                       end;
             Dispose(N^.Fan[F]);
             N^.Fan[F]:=NIL
             end;
      N^.Cnt:=0;
      end;
   If (N^.Val <> NIL) then begin
      Proc(N^.Val); Self.Vals-=1
      end
   end;

Constructor GenericDynPtrTrie.Create();
   Var C:LongWord;
   begin
   {$IFDEF DYNPTRTRIE_CLASS} Inherited Create(); {$ENDIF}
   New(Root); Root^.Cnt:=0; Root^.Val:=NIL;
   For C:=0 to 15 do Root^.Fan[C]:=NIL;
   Self.Vals:=0
   end;

Procedure GenericDynPtrTrie.Flush();
   begin FreeNode(Root); Root^.Val := NIL end;

Procedure GenericDynPtrTrie.Flush(Const Proc:TDisposeProc);
   begin FreeNode(Root,Proc); Root^.Val := NIL end;

Destructor GenericDynPtrTrie.Destroy();
   begin
   Flush(); Dispose(Root);
   {$IFDEF DYNPTRTRIE_CLASS} ; Inherited Destroy() {$ENDIF}
   end;

end.
