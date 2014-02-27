unit dyntrie;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the Trie to be an object or a class? Obviously, it's   *
 * impossible to have both at the same time. If both symbols are set, *
 * Trie becomes a class. If none are set, compilation error occurs.   *)
//{$DEFINE DYNTRIE_CLASS}
{$DEFINE DYNTRIE_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF DYNTRIE_CLASS}  {$DEFINE DYNTRIETYPE:=Class(TObject)} {$ELSE}
{$IFDEF DYNTRIE_OBJECT} {$DEFINE DYNTRIETYPE:=Object}         {$ELSE}
   {$FATAL trie.pas: No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type ExNotSet = class(Exception);
     
     generic GenericDynTrie<Tp> = DYNTRIETYPE
     Private
        Type
        PTp = ^Tp;
        
        PNodeFan = ^TNodeFan;
        PNode = ^TNode;
        
        TNodeFan = record
           Nod : Array[0..15] of PNode;
           Cnt : LongWord;
           end;
        
        TNode = record
           Fan : Array[0..15] of PNodeFan;
           Cnt : LongWord;
           Val : PTp;
           end;
        
        Var
        Vals : LongWord;
        Root : PNode;
        
        {Method}
        Procedure SetVal(Const K:AnsiString;P:LongWord;N:PNode;Const V:Tp);
        Procedure RemVal(Const K:AnsiString;P:LongWord;N:PNode);
        
        Function  IsVal(Const K:AnsiString;P:LongWord;N:PNode):Boolean;
        Function  GetVal(Const K:AnsiString;P:LongWord;N:PNode):Tp;
        
        Function  NextKey(N:PNode;C:LongWord;Const K:AnsiString;Var R:AnsiString):Boolean;
        
        Function  GetVal(N:PNode):Tp;
        Function  RemVal(N:PNode):Tp;
        Procedure FreeNode(N:PNode);
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
        
        Constructor Create();
        Constructor Create(Dummy1,Dummy2:Char);
        Destructor  Destroy(); {$IFDEF DYNTRIE_CLASS} Override; {$ENDIF}
     end;

implementation

Procedure GenericDynTrie.SetVal(Const K:AnsiString;P:LongWord;N:PNode;Const V:Tp);
   Var F,I:LongWord; E:PNode; C:LongWord;
   begin
   If (P<=Length(K)) then begin
      F:=Ord(K[P]) div 16; I:=Ord(K[P]) mod 16;
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
      SetVal(K,P+1,N^.Fan[F]^.Nod[I],V)
      end else begin
      If (N^.Val = NIL) then begin New(N^.Val); Self.Vals+=1 end;
      N^.Val^:=V
      end
   end;

Procedure GenericDynTrie.SetVal(Const Key:AnsiString;Const Val:Tp);
   begin SetVal(Key,1,Root,Val) end;

Procedure GenericDynTrie.RemVal(Const K:AnsiString;P:LongWord;N:PNode);
   Var F,I:LongWord;
   begin
   If (P<=Length(K)) then begin
      F:=Ord(K[P]) div 16; I:=Ord(K[P]) mod 16;
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
         Dispose(N^.Val); N^.Val:=NIL;
         Self.Vals -= 1 end
      end
   end;

Procedure GenericDynTrie.RemVal(Const Key:AnsiString);
   begin RemVal(Key,1,Root) end;

Function GenericDynTrie.IsVal(Const K:AnsiString;P:LongWord;N:PNode):Boolean;
   Var F,I:LongWord;
   begin
   If (P<=Length(K)) then begin
      F:=Ord(K[P]) div 16; I:=Ord(K[P]) mod 16;
      If (N^.Fan[F] = NIL) then Exit(False);
      If (N^.Fan[F]^.Nod[I] = NIL) then Exit(False);
      Exit(IsVal(K,P+1,N^.Fan[F]^.Nod[I]))
      end else begin
      Exit(N^.Val <> NIL)
      end;
   end;

Function GenericDynTrie.IsVal(Const Key:AnsiString):Boolean;
   begin Exit(IsVal(Key,1,Root)) end;

Function GenericDynTrie.GetVal(Const K:AnsiString;P:LongWord;N:PNode):Tp;
   Var F,I:LongWord;
   begin
   If (P<=Length(K)) then begin
      F:=Ord(K[P]) div 16; I:=Ord(K[P]) mod 16;
      If (N^.Fan[F] = NIL) or (N^.Fan[F]^.Nod[I] = NIL)
         then Raise ExNotSet.Create('Called GenericDynTrie.GetVal() with an unset key!');
      Exit(GetVal(K,P+1,N^.Fan[F]^.Nod[I]))
      end else begin
      If (N^.Val = NIL)
         then Raise ExNotSet.Create('Called GenericDynTrie.GetVal() with an unset key!');
      Exit(N^.Val^)
      end;
   end;

Function GenericDynTrie.GetVal(Const Key:AnsiString):Tp;
   begin Exit(GetVal(Key,1,Root)) end;

Function GenericDynTrie.Empty():Boolean;
   begin Exit(Self.Vals = 0) end;

Function GenericDynTrie.GetVal(N:PNode):Tp;
   Var F,I:LongWord;
   begin
   If (N^.Val <> NIL) Then Exit(N^.Val^);
   If (N^.Cnt = 0) then
      Raise ExNotSet.Create('Called GenericDynTrie.GetVal() on an empty trie!');
   For F:=0 to 15 do
       If (N^.Fan[F] <> NIL) then
          For I:=0 to 15 do
              If (N^.Fan[F]^.Nod[I] <> NIL) then
                 Exit(GetVal(N^.Fan[F]^.Nod[I]))
   end;

Function GenericDynTrie.GetVal():Tp;
   begin Exit(GetVal(Root)) end;

Function GenericDynTrie.RemVal(N:PNode):Tp;
   Var F,I:LongWord; R:Tp;
   begin
   If (N^.Val <> NIL) Then begin
      R:=N^.Val^; Dispose(N^.Val); N^.Val:=NIL; Self.Vals-=1;
      Exit(R)
      end;
   If (N^.Cnt = 0) then
      Raise ExNotSet.Create('Called GenericDynTrie.RemVal() on an empty trie!');
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

Function GenericDynTrie.RemVal():Tp;
   begin Exit(RemVal(Root)) end;

Function GenericDynTrie.NextKey(N:PNode;C:LongWord;Const K:AnsiString;Var R:AnsiString):Boolean;
   Var L,F,I,sI,sF:LongWord;
   begin
   If (N^.Cnt = 0) then Exit(False);
   L := Length(K);
   If (L >= C) then begin
      F:=Ord(K[C]) div 16; I:=Ord(K[C]) mod 16;
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

Function GenericDynTrie.NextKey(Const K:AnsiString):AnsiString;
   Var R:AnsiString;
   begin R:='';
   If NextKey(Root,1,K,R) then Exit(R) else Exit('') end;

Function GenericDynTrie.ToArray():TEntryArr;
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

Procedure GenericDynTrie.FreeNode(N:PNode);
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
   If (N^.Val <> NIL) then begin Dispose(N^.Val); Self.Vals-=1 end
   end;

Constructor GenericDynTrie.Create();
   Var C:LongWord;
   begin
   {$IFDEF DYNTRIE_CLASS} Inherited Create(); {$ENDIF}
   New(Root); Root^.Cnt:=0; Root^.Val:=NIL;
   For C:=0 to 15 do Root^.Fan[C]:=NIL;
   Self.Vals:=0
   end;

Constructor GenericDynTrie.Create(Dummy1,Dummy2:Char);
   Var C:LongWord;
   begin
   {$IFDEF DYNTRIE_CLASS} Inherited Create(); {$ENDIF}
   New(Root); Root^.Cnt:=0; Root^.Val:=NIL;
   For C:=0 to 15 do Root^.Fan[C]:=NIL;
   Self.Vals:=0
   end;

Procedure GenericDynTrie.Flush();
   begin FreeNode(Root) end;

Destructor GenericDynTrie.Destroy();
   begin
   Flush(); Dispose(Root);
   {$IFDEF DYNTRIE_CLASS} ; Inherited Destroy() {$ENDIF}
   end;

end.
