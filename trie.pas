unit trie;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the Trie to be an object or a class? Obviously, it's   *
 * impossible to have both at the same time. If both symbols are set, *
 * Trie becomes a class. If none are set, compilation error occurs.   *)
//{$DEFINE TRIE_CLASS}
{$DEFINE TRIE_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF TRIE_CLASS}  {$DEFINE TRIETYPE:=Class(TObject)} {$ELSE}
{$IFDEF TRIE_OBJECT} {$DEFINE TRIETYPE:=Object}         {$ELSE}
   {$FATAL No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type ExNotSet = class(Exception);
     
     generic GenericTrie<Tp> = TRIETYPE
     Private
        Type
        PTp = ^Tp;
        PNode = ^TNode;
        TNode = record
           Nxt : Array of PNode;
           Chi : LongWord;
           Val : PTp;
           end;
        Var
        Min, ArrS : LongInt;
        Vals : LongWord;
        Root : PNode;
        {Method}
        Procedure SetVal(Const K:AnsiString;P:LongWord;N:PNode;Const V:Tp);
        Procedure RemVal(Const K:AnsiString;P:LongWord;N:PNode);
        
        Function  IsVal(Const K:AnsiString;P:LongWord;N:PNode):Boolean;
        Function  GetVal(Const K:AnsiString;P:LongWord;N:PNode):Tp;
        
        Procedure FreeNode(N:PNode);
     Public
        Procedure SetVal(Key:AnsiString;Val:Tp);
        Procedure RemVal(Key:AnsiString);
        
        Function  IsVal(Key:AnsiString):Boolean;
        Function  GetVal(Key:AnsiString):Tp;
        
        Function Empty() : Boolean;
        Property Count   : LongWord read Vals;
        
        Procedure Flush();
        
        Constructor Create(argMin, argMax : Char);
        Destructor  Destroy(); {$IFDEF TRIE_CLASS} Override; {$ENDIF}
     end;

implementation

Procedure GenericTrie.SetVal(Const K:AnsiString;P:LongWord;N:PNode;Const V:Tp);
   Var I:LongWord; E:PNode; C:LongWord;
   begin
   If (P<=Length(K)) then begin
      I:=Ord(K[P])-Min;
      If (N^.Nxt[I] = NIL) then begin
         New(E); SetLength(E^.Nxt,ArrS);
         E^.Val:=NIL; E^.Chi:=0;
         For C:=Low(E^.Nxt) to High(E^.Nxt) do E^.Nxt[C]:=NIL;
         N^.Nxt[I]:=E; N^.Chi+=1
         end;
      SetVal(K,P+1,N^.Nxt[I],V)
      end else begin
      If (N^.Val = NIL) then begin New(N^.Val); Vals+=1 end;
      N^.Val^:=V
      end
   end;

Procedure GenericTrie.SetVal(Key:AnsiString;Val:Tp);
   begin SetVal(Key,1,Root,Val) end;

Procedure GenericTrie.RemVal(Const K:AnsiString;P:LongWord;N:PNode);
   Var I:LongWord;
   begin
   If (P<=Length(K)) then begin
      I:=Ord(K[P])-Min;
      If (N^.Nxt[I] = NIL) then Exit();
      RemVal(K,P+1,N^.Nxt[I]);
      If (N^.Nxt[I]^.Chi = 0) and (N^.Nxt[I]^.Val = NIL) then begin
         Dispose(N^.Nxt[I]); N^.Nxt[I]:=NIL;
         N^.Chi-=1
         end
      end else begin
      If (N^.Val <> NIL) then begin
         Dispose(N^.Val); N^.Val:=NIL;
         Vals -= 1 end
      end
   end;

Procedure GenericTrie.RemVal(Key:AnsiString);
   begin RemVal(Key,1,Root) end;

Function GenericTrie.IsVal(Const K:AnsiString;P:LongWord;N:PNode):Boolean;
   Var I:LongWord;
   begin
   If (P<=Length(K)) then begin
      I:=Ord(K[P])-Min;
      If (N^.Nxt[I] = NIL) then Exit(False);
      Exit(IsVal(K,P+1,N^.Nxt[I]))
      end else begin
      Exit(N^.Val <> NIL)
      end;
   end;

Function GenericTrie.IsVal(Key:AnsiString):Boolean;
   begin Exit(IsVal(Key,1,Root)) end;

Function GenericTrie.GetVal(Const K:AnsiString;P:LongWord;N:PNode):Tp;
   Var I:LongWord;
   begin
   If (P<=Length(K)) then begin
      I:=Ord(K[P])-Min;
      If (N^.Nxt[I] = NIL) 
         then Raise ExNotSet.Create('Called GenericTrie.GetVal() with an unset key!');
      Exit(GetVal(K,P+1,N^.Nxt[I]))
      end else begin
      If (N^.Val = NIL)
         then Raise ExNotSet.Create('Called GenericTrie.GetVal() with an unset key!');
      Exit(N^.Val^)
      end;
   end;

Function GenericTrie.GetVal(Key:AnsiString):Tp;
   begin Exit(GetVal(Key,1,Root)) end;

Function GenericTrie.Empty():Boolean;
   begin Exit(Vals>0) end;

Constructor GenericTrie.Create(argMin, argMax : Char);
   Var C:LongWord;
   begin
   {$IFDEF TRIE_CLASS} Inherited Create(); {$ENDIF}
   Min:=ord(argMin); ArrS:=Ord(argMax)-Ord(argMin)+1;
   New(Root); SetLength(Root^.Nxt,ArrS);
   Root^.Chi:=0; Root^.Val:=NIL;
   For C:=Low(Root^.Nxt) to High(Root^.Nxt) do Root^.Nxt[C]:=NIL;
   Vals:=0
   end;

Procedure GenericTrie.FreeNode(N:PNode);
   Var I:LongWord;
   begin
   If (N^.Chi > 0) then
      For I:=Low(N^.Nxt) to High(N^.Nxt) do
          If (N^.Nxt[I]<>NIL) then begin
             FreeNode(N^.Nxt[I]);
             N^.Nxt[I]:=NIL
             end;
   If (N^.Val <> NIL) then begin Dispose(N^.Val); Vals-=1 end;
   Dispose(N)
   end;

Procedure GenericTrie.Flush();
   begin FreeNode(Root) end;

Destructor GenericTrie.Destroy();
   begin
   Flush();
   {$IFDEF TRIE_CLASS} ; Inherited Destroy() {$ENDIF}
   end;

end.