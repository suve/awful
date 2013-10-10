unit scapegoat;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the Scapegoat to be an object or a class? Obviously, it's   *
 * impossible to have both at the same time. If both symbols are set,      *
 * Scapegoat becomes a class. If none are set, compilation error occurs.   *)
//{$DEFINE SCAPEGOAT_CLASS}
{$DEFINE SCAPEGOAT_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF SCAPEGOAT_CLASS}  {$DEFINE SCAPEGOATTYPE:=Class(TObject)} {$ELSE}
{$IFDEF SCAPEGOAT_OBJECT} {$DEFINE SCAPEGOATTYPE:=Object}         {$ELSE}
   {$FATAL scapegoat.pas: No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type ExNotSet = class(Exception);
     
     Generic GenericScapegoat<Tp> = SCAPEGOATTYPE
     Private
        Type
        PNode = ^TNode;
        TNode = record
           Key : Int64;
           Val : Tp;
           Le, Ri : PNode
           end;
        
        Var
        MinKey, MaxKey : Int64;
        Vals, MaxVals : LongWord;
        Alfa, InvAlfa : Double;
        Root : PNode;
     
        {Method}
        Procedure SetAlfa(Val:Double);
        
        Function  NodeHeight(N:PNode):LongWord;
        Function  NodeSize(N:PNode):LongWord;
        Procedure DeleteNode(Var N:PNode);
        Procedure FreeNode(Var N:PNode);
        
        Function  Flatten(Top, Head : PNode):PNode;
        Function  BuildTree(Size: LongWord; Head : PNode):PNode;
        Function  RebuildTree(Size : LongWord; Scapegoat : PNode):PNode;
        
        Function  IsVal(K:Int64; N:PNode):Boolean;
        Function  GetVal(K:Int64; N:PNode):Tp;
        Function  SetVal(K:Int64; V:Tp; Var N:PNode):LongWord;
        Procedure RemVal(K:Int64; Var N:PNode);
        
        Procedure SetValNaive(K:Int64; V:Tp; Var N:PNode);
        Procedure Rebalance(Depth:LongWord; Var N:PNode);
     Public
        Type
        TEntry = record
           Key : Int64;
           Val : Tp
           end;
        TEntryArr = Array of TEntry;
        
     Private
        Procedure FillArray(Var A:TEntryArr; Var I:LongWord; N:PNode);
        Procedure Print(D:LongWord; N:PNode);
        
     Public
        Property Alpha : Double read Alfa write SetAlfa;
        Property Count : LongWord read Vals;
        Property Low  : Int64 read MinKey;
        Property High : Int64 read MaxKey;
        
        Procedure AddVal(Val:Tp);
        Function  IsVal(Key:Int64):Boolean;
        Function  GetVal(Key:Int64):Tp;
        Procedure SetVal(Key:Int64; Val:Tp);
        Procedure RemVal(Key:Int64);
        
        Procedure SetValNaive(Key:Int64; Val:Tp);
        Procedure Rebalance(Depth:LongWord);
        Procedure Rebalance();
        
        Function  ToArray():TEntryArr;
        
        Function  Empty():Boolean;
        Procedure Flush();
        
        Procedure Print();
        
        Constructor Create(vAlpha:Double);
        Destructor Destroy; {$IFDEF SCAPEGOAT_CLASS} Override; {$ENDIF}
     end;

implementation
   uses Math;

Function GenericScapegoat.Empty():Boolean;
   begin Exit(Vals = 0) end;

Function GenericScapegoat.Flatten(Top, Head : PNode):PNode;
   begin
   If (Top = NIL) then Exit(Head);
   Top^.Ri := Flatten(Top^.Ri, Head);
   Exit(Flatten(Top^.Le, Top))
   end;

Function GenericScapegoat.BuildTree(Size: LongWord; Head : PNode):PNode;
   Var R, S : PNode;
   begin
   If (Size = 0) then begin
      Head^.Le := NIL; Exit(Head)
      end;
   Size -= 1;
   R := BuildTree( Ceil(Size/2), Head);
   S := BuildTree(Floor(Size/2), R^.Ri);
   R^.Ri := S^.Le; S^.Le := R;
   Exit(S)
   end;

Function GenericScapegoat.RebuildTree(Size : LongWord; Scapegoat : PNode):PNode;
   Var Dummy, Ptr : PNode;
   begin
   New(Dummy);
   Ptr := Flatten(Scapegoat, Dummy);
   BuildTree(Size, Ptr);
   Ptr := Dummy^.Le;
   Dispose(Dummy);
   Exit(Ptr)
   end;

Function GenericScapegoat.NodeHeight(N:PNode):LongWord;
   Var L, R : LongWord;
   begin
   If (N^.Le <> NIL) then L := NodeHeight(N^.Le)+1 else L:=0;
   If (N^.Ri <> NIL) then R := NodeHeight(N^.Ri)+1 else R:=0;
   If (L > R) then Exit(L) else Exit(R)
   end;

Function GenericScapegoat.NodeSize(N:PNode):LongWord;
   Var Res : LongWord;
   begin
   Res := 1;
   If (N^.Le <> NIL) then Res += NodeSize(N^.Le);
   If (N^.Ri <> NIL) then Res += NodeSize(N^.Ri);
   Exit(Res)
   end;

Procedure GenericScapegoat.FreeNode(Var N:PNode);
   begin
   If (N^.Le <> NIL) then FreeNode(N^.Le);
   If (N^.Ri <> NIL) then FreeNode(N^.Ri);
   Dispose(N); N:=NIL; Vals -= 1
   end;

Procedure GenericScapegoat.AddVal(Val:Tp);
   begin SetVal(MaxKey + 1, Val) end;

Function GenericScapegoat.IsVal(K:Int64; N:PNode):Boolean;
   begin
   If (N = NIL) then Exit(False);
   Case CompareValue(K, N^.Key) of
      -1: Exit(IsVal(K, N^.Le));
       0: Exit(True);
      +1: Exit(IsVal(K, N^.Ri));
   end end;
   
Function GenericScapegoat.IsVal(Key:Int64):Boolean;
   begin Exit(IsVal(Key, Self.Root)) end;

Function GenericScapegoat.GetVal(K:Int64; N:PNode):Tp;
   begin
   If (N = NIL) then Raise ExNotSet.Create('Called GenericScapegoat.GetVal() with an unset key!');
   Case CompareValue(K, N^.Key) of
      -1: Exit(GetVal(K, N^.Le));
       0: Exit(N^.Val);
      +1: Exit(GetVal(K, N^.Ri));
   end end;
   
Function GenericScapegoat.GetVal(Key:Int64):Tp;
   begin Exit(GetVal(Key, Self.Root)) end;

Function GenericScapegoat.SetVal(K:Int64; V:Tp; Var N:PNode):LongWord;
   Var LeSize, RiSize, TotSize : LongWord;
   begin
   If (N = NIL) then begin
      New(N); N^.Le := NIL; N^.Ri := NIL;
      N^.Key := K; N^.Val := V;
      Vals += 1; If (Vals > MaxVals) then MaxVals := Vals;
      If (MinKey > K) then MinKey:=K else
      If (MaxKey < K) then MaxKey:=K;
      Exit(1)
      end;
   Case CompareValue(K, N^.Key) of
      -1: begin LeSize := SetVal(K, V, N^.Le); RiSize := 0 end;
       0: begin N^.Val := V; Exit(0) end;
      +1: begin RiSize := SetVal(K, V, N^.Ri); LeSize := 0 end;
      end;
   If (LeSize = 0) then begin
      If (RiSize = 0) then Exit(0);
      If (N^.Le <> NIL) then LeSize:=NodeSize(N^.Le)
      end else
   If (RiSize = 0) then If (N^.Ri <> NIL) then RiSize:=NodeSize(N^.Ri);
   TotSize := LeSize + RiSize + 1;
   If (LeSize >= Alfa * TotSize) or (RiSize >= Alfa * TotSize) then begin
      N := RebuildTree(TotSize, N); Exit(0)
      end else Exit(TotSize)
   end;

Procedure GenericScapegoat.SetVal(Key:Int64; Val:Tp);
   begin SetVal(Key, Val, Self.Root) end;

Procedure GenericScapegoat.SetValNaive(K:Int64; V:Tp; Var N:PNode);
   begin
   If (N = NIL) then begin
      New(N); N^.Le := NIL; N^.Ri := NIL;
      N^.Key := K; N^.Val := V;
      Vals += 1; If (Vals > MaxVals) then MaxVals := Vals;
      If (MinKey > K) then MinKey:=K else
      If (MaxKey < K) then MaxKey:=K;
      Exit()
      end;
   Case CompareValue(K, N^.Key) of
      -1: SetValNaive(K, V, N^.Le);
       0: N^.Val := V;
      +1: SetValNaive(K, V, N^.Ri);
   end end;

Procedure GenericScapegoat.SetValNaive(Key:Int64; Val:Tp);
   begin SetValNaive(Key, Val, Self.Root) end;

Procedure GenericScapegoat.Rebalance(Depth:LongWord; Var N:PNode);
   begin
   If (Depth > 0) then begin
      If (N^.Le <> NIL) then Rebalance(Depth-1, N^.Le);
      If (N^.Ri <> NIL) then Rebalance(Depth-1, N^.Ri)
      end else N := RebuildTree(NodeSize(N), N)
   end;

Procedure GenericScapegoat.Rebalance(Depth:LongWord);
   begin Rebalance(Depth, Root) end;

Procedure GenericScapegoat.Rebalance();
   begin 
   If (Root = NIL) then Exit();
   Root := RebuildTree(NodeSize(Root), Root)
   end;

Procedure GenericScapegoat.DeleteNode(Var N:PNode);
   Var Kids : LongWord; Suc, Mem : PNode;
   begin
   Vals -= 1; Kids := 0;
   If (N^.Le <> NIL) then Kids += 1;
   If (N^.Ri <> NIL) then Kids += 1;
   Case Kids of
      0: begin
         Dispose(N); N:=NIL
         end; 
      1: begin
         Mem:=N;
         If (N^.Le <> NIL) then N:=N^.Le else N:=N^.Ri;
         Dispose(Mem)
         end;
      2: begin
         Suc := N^.Ri; Mem := N;
         While (Suc^.Le <> NIL) do begin 
            Mem:=Suc; Suc:=Suc^.Le
            end;
         N^.Key := Suc^.Key; N^.Val := Suc^.Val;
         If (N <> Mem)
            then If (Suc^.Ri <> NIL) then Mem^.Le := Suc^.Ri else Mem^.Le := NIL 
            else N^.Ri := Suc^.Ri;
         Dispose(Suc)
         end;
   end end;

Procedure GenericScapegoat.RemVal(K:Int64; Var N:PNode);
   begin
   If (N = NIL) then Exit();
   Case CompareValue(K, N^.Key) of
      -1: RemVal(K, N^.Le);
       0: DeleteNode(N); 
      +1: RemVal(K, N^.Ri);
   end end;
   
Procedure GenericScapegoat.RemVal(Key : Int64);
   begin
   RemVal(Key, Self.Root);
   If (Root <> NIL) and (Vals < Alfa * MaxVals) then begin
      Root := RebuildTree(Vals, Root);
      MaxVals := Vals
      end;
   end;

Procedure GenericScapegoat.FillArray(Var A:TEntryArr; Var I:LongWord; N:PNode);
   begin
   If (N^.Le <> NIL) then FillArray(A, I, N^.Le);
   A[I].Key := N^.Key; A[I].Val := N^.Val;  I+=1;
   If (N^.Ri <> NIL) then FillArray(A, I, N^.Ri)
   end;

Function GenericScapegoat.ToArray():TEntryArr;
   Var A:Array of TEntry; Index:LongWord;
   begin
   If (Root = NIL) then begin
      SetLength(A,0); Exit(A)
      end;
   SetLength(A,Vals); Index:=0;
   FillArray(A,Index,Root);
   Exit(A)
   end;

Procedure GenericScapegoat.SetAlfa(Val:Double);
   begin
   If (Val < 0.505) then Val := 0.505 else
   If (Val > 0.995) then Val := 0.995;
   Alfa := Val; InvAlfa := 1/Alfa
   end;

Procedure GenericScapegoat.Flush();
   begin
   If (Root <> NIL) then FreeNode(Root);
   Vals := 0; MaxVals := 0
   end;

Constructor GenericScapegoat.Create(vAlpha:Double);
   begin
   {$IFDEF SCAPEGOAT_CLASS} Inherited Create(); {$ENDIF}
   MinKey := 0; MaxKey := -1; Vals := 0; MaxVals := 0;
   Root := NIL; Alpha := vAlpha
   end;

Destructor GenericScapegoat.Destroy; 
   begin
   Self.Flush();
   {$IFDEF SCAPEGOAT_CLASS} Inherited Destroy() {$ENDIF}
   end;

Procedure GenericScapegoat.Print(D:LongWord; N:PNode);
   begin
   If (N^.Ri <> NIL) then Print(D+1, N^.Ri);
   Writeln(StringOfChar(#9,D), N^.Key);
   If (N^.Le <> NIL) then Print(D+1, N^.Le)
   end;

Procedure GenericScapegoat.Print();
   begin
   If (Root <> NIL) then Print(0, Root)
      else Writeln('EMPTY')
   end;

end.
