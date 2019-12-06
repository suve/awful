unit stack;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the Stack to be an object or a class? Obviously, it's   *
 * impossible to have both at the same time. If both symbols are set, *
 * Stack becomes a class. If none are set, compilation error occurs.   *)
//{$DEFINE STACK_CLASS}
{$DEFINE STACK_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF STACK_CLASS}  {$DEFINE STACKTYPE:=Class(TObject)} {$ELSE}
{$IFDEF STACK_OBJECT} {$DEFINE STACKTYPE:=Object}         {$ELSE}
   {$FATAL No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type
   ExEmptyStack = class(Exception);

   Generic GenericStack<Tp> = STACKTYPE
      Protected Const
         NodeSize = 4096;
         {$DEFINE NodeCapacity := ((NodeSize - SizeOf(Pointer)) div SizeOf(Tp)) }
      
      Protected Type
         PNode = ^TNode;
         TNode = record
            Val : Array[0..(NodeCapacity-1)] of Tp;
            Next : PNode
         end;
         
      Protected Var
         Head : PNode;
         Size : LongWord;
      
      Public {Method}
         Procedure Push(Const Val:Tp);
         
         Function  Peek(Depth:LongInt):Tp;
         Function  Peek():Tp;
         
         Function  Pop():Tp;
         Procedure Purge();
        
         Property Count:LongWord read Size;
         Function Empty():Boolean;
        
         Constructor Create();
         Destructor  Destroy; {$IFDEF STACK_CLASS} Override; {$ENDIF}
   end;

implementation

Procedure GenericStack.Push(Const Val:Tp);
   Var Offset: LongInt; Node: PNode;
   begin
      Offset := Size mod NodeCapacity;
      If (Offset = 0) then begin
         New(Node); Node^.Next:=Head; Head:=Node
      end;

      Head^.Val[Offset] := Val;
      Size += 1
   end;

Function  GenericStack.Peek(Depth:LongInt):Tp;
   Var Node: PNode; HeadSize: LongInt;
   begin
      If (Depth >= Size) then
         Raise ExEmptyStack.Create('Called GenericStack.Peek(Depth) on a shallow stack!');

      HeadSize := Size mod NodeCapacity;
      If (Depth < HeadSize) then Exit(Head^.Val[HeadSize - 1 - Depth]);
      
      Node := Self.Head;
      Depth -= HeadSize;
      
      While (Depth >= NodeCapacity) do begin
         Node := Node^.Next;
         Depth -= NodeCapacity
      end;

      Exit(Head^.Val[NodeCapacity - 1 - Depth])
   end;

Function  GenericStack.Peek():Tp;
   Var Offset: LongInt;
   begin
      If (Head = NIL) then
         Raise ExEmptyStack.Create('Called GenericStack.Peek() on an empty stack!');
         
      Offset := (Size - 1) mod NodeCapacity;
      Exit(Head^.Val[Offset])
   end;

Function  GenericStack.Pop():Tp;
   Var Val:Tp; Mem:PNode; Offset: LongInt;
   begin
      If (Size = 0) then
         Raise ExEmptyStack.Create('Called GenericStack.Pop() on an empty stack!');

      Size -= 1;
      Offset := Size mod NodeCapacity;
      If (Offset > 0) then Exit(Head^.Val[Offset]);
      
      Mem := Head; Head := Head^.Next;
      Val := Mem^.Val[0];
      Dispose(Mem);
      Exit(Val)
   end;

Procedure GenericStack.Purge();
   Var Mem:PNode;
   begin
      While (Head <> NIL) do begin
         Mem := Head; Head := Head^.Next;
         Dispose(Mem)
      end;
      Size := 0
   end;

Function GenericStack.Empty():Boolean;
   begin Exit(Size = 0) end;

Constructor GenericStack.Create();
   begin
      {$IFDEF STACK_CLASS} Inherited Create(); {$ENDIF}
      Head:=NIL; Size:=0
   end;

Destructor  GenericStack.Destroy;
   begin
      Purge();
      {$IFDEF STACK_CLASS} Inherited Destroy() {$ENDIF}
   end;

end.
