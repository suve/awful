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
      Protected Type
         PNode = ^TNode;
         TNode = record
            Val : Tp;
            Nxt : PNode
         end;
         
      Protected Var
         Ptr : PNode;
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
   Var N:PNode;
   begin
      New(N); N^.Val:=Val; N^.Nxt:=Ptr;
      Ptr:=N; Size+=1
   end;

Function  GenericStack.Peek(Depth:LongInt):Tp;
   Var Node : PNode;
   begin
      Node := Self.Ptr;
      
      While (Depth > 0) and (Node <> NIL) do begin
         Node := Node^.Nxt;
         Depth -= 1
      end;
      
      If (Node <> NIL)
         then Exit(Node^.Val)
         else Raise ExEmptyStack.Create('Called GenericStack.Peek(Depth) on a shallow stack!')
   end;

Function  GenericStack.Peek():Tp;
   begin
      If (Ptr<>NIL)
         then Exit(Ptr^.Val)
         else Raise ExEmptyStack.Create('Called GenericStack.Peek() on an empty stack!')
   end;

Function  GenericStack.Pop():Tp;
   Var Val:Tp; Mem:PNode;
   begin
      If (Ptr <> NIL) then begin
         Mem := Ptr; Ptr := Ptr^.Nxt;
         Val := Mem^.Val; Dispose(Mem);
         Size-=1; Exit(Val)
      end else
         Raise ExEmptyStack.Create('Called GenericStack.Pop() on an empty stack!')
   end;

Procedure GenericStack.Purge();
   Var Mem:PNode;
   begin
      While (Ptr <> NIL) do begin
         Mem := Ptr; Ptr := Ptr^.Nxt;
         Dispose(Mem)
      end;
      Size := 0
   end;

Function GenericStack.Empty():Boolean;
   begin Exit(Size = 0) end;

Constructor GenericStack.Create();
   begin
      {$IFDEF STACK_CLASS} Inherited Create(); {$ENDIF}
      Ptr:=NIL; Size:=0
   end;

Destructor  GenericStack.Destroy;
   begin
      Purge();
      {$IFDEF STACK_CLASS} Inherited Destroy() {$ENDIF}
   end;

end.
