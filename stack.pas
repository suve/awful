unit stack;

{$MODE OBJFPC} {$COPERATORS ON} 

(* Do you want the Trie to be an object or a class? Obviously, it's   *
 * impossible to have both at the same time. If both symbols are set, *
 * Trie becomes a class. If none are set, compilation error occurs.   *)
//{$DEFINE STACK_CLASS}
{$DEFINE STACK_OBJECT} 

interface
   uses SysUtils;

{$MACRO ON}
{$IFDEF STACK_CLASS}  {$DEFINE STACKTYPE:=Class(TObject)} {$ELSE}
{$IFDEF STACK_OBJECT} {$DEFINE STACKTYPE:=Object}         {$ELSE}
   {$FATAL No OBJECT/CLASS symbol set!} {$ENDIF} {$ENDIF}

Type ExEmptyStack = class(Exception);

     Generic GenericStack<Tp> = STACKTYPE
     Private
        Type
        PNode = ^TNode;
        TNode = record
           Val : Tp;
           Nxt : PNode
           end;
        Var
        Ptr : PNode;
        Size : LongWord;
     Public
        Procedure Push(Val:Tp);
        Function  Peek():Tp;
        Function  Pop():Tp;
        Procedure Flush();
     
        Property Count:LongWord read Size;
        Function Empty():Boolean;
     
        Constructor Create();
        Destructor  Destroy; {$IFDEF STACK_CLASS} Override; {$ENDIF}
     end;

implementation

Procedure GenericStack.Push(Val:Tp);
   Var N:PNode;
   begin
   New(N); N^.Val:=Val; N^.Nxt:=Ptr;
   Ptr:=N; Size+=1
   end;

Function  GenericStack.Peek():Tp;
   begin
   If (Ptr<>NIL)
      then Exit(Ptr^.Val)
      else Raise ExEmptyStack.Create('Called GenericStack.Peek() on an empty stack!')
   end;

Function  GenericStack.Pop():Tp;
   Var V:Tp; M:PNode;
   begin
   If (Ptr<>NIL)
      then begin
      M:=Ptr; Ptr:=Ptr^.Nxt;
      V:=M^.Val; Dispose(M);
      Size-=1; Exit(V)
      end else Raise ExEmptyStack.Create('Called GenericStack.Pop() on an empty stack!')
   end;

Procedure GenericStack.Flush();
   begin While (Size>0) do Pop() end;

Function GenericStack.Empty():Boolean;
   begin Exit(Size=0) end;

Constructor GenericStack.Create();
   begin
   {$IFDEF STACK_CLASS} Inherited Create(); {$ENDIF}
   Ptr:=NIL; Size:=0
   end;

Destructor  GenericStack.Destroy;
   begin
   Flush();
   {$IFDEF STACK_CLASS} Inherited Destroy() {$ENDIF}
   end;

end.
