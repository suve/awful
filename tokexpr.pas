unit tokexpr;

{$INCLUDE defines.inc}

interface
   uses FuncInfo, Values;

Type
   TTokenType = (
      TK_EXPR, 
      TK_CONS, TK_LITE, 
      TK_VARI, TK_REFE, 
      TK_AVAL, TK_AREF, TK_AFLY,
      TK_BADT
   );
     
   PExpr = ^TExpr;
   PToken = ^TToken;
   Array_PExpr = Array of PExpr;
     
   PArrTk = ^TArrTk;
   TArrTk = record
      Ptr : Pointer;        // Token to be indexed
      Ind : Array of PToken // Array of indexing tokens
   end;
     
   TToken = record
      Typ : TTokenType; // Token type
      Ptr : Pointer     // Pointer to actual data, needs to be typecasted
   end;
     
    TExpr = record
      //Lin : LongWord;      // Line number
      Fun : TBuiltIn;        // Pointer to built-in func
      Ref : Boolean;         // Reference-modifying?
      Num : LongInt;         // Number of tokens / arguments
      Tok : Array of PToken; // Array of tokens in expression
      Arg : Array of PValue  // Array of arguments to pass to function
   end;
     
   TProc = record
      Fil : LongWord;            // File number
      Lin : LongWord;            // Line number
      Num : LongWord;            // Number of expressions
      Exp : Array of PExpr;      // Array of expressions
      Arg : Array of AnsiString; // Argument name array
   end;

Procedure FreeToken(Const T:PToken);
Procedure FreeExpr(Const E:PExpr);
Procedure FreeProc(Var P:TProc);

implementation

Procedure FreeToken(Const T:PToken);
   Var atk:PArrTk; C:LongWord;
   begin
      Case (T^.Typ) of
         TK_EXPR: 
            FreeExpr(PExpr(T^.Ptr));
            
         TK_CONS: 
            ; // Pointer to a value in const trie. Value will be freed when flushing consts
            
         TK_LITE:
            AnnihilateVal(PValue(T^.Ptr));
            
         TK_VARI, TK_REFE:
            Dispose(PStr(T^.Ptr));
            
         TK_AVAL, TK_AREF:
            begin
               atk:=PArrTk(T^.Ptr); Dispose(PStr(atk^.Ptr)); 
               For C:=Low(atk^.Ind) to High(atk^.Ind) do FreeToken(atk^.Ind[C]);
               {SetLength(atk^.Ind, 0);} Dispose(atk)
            end;
            
         TK_AFLY:
            begin
               atk:=PArrTk(T^.Ptr); FreeExpr(PExpr(atk^.Ptr)); 
               For C:=Low(atk^.Ind) to High(atk^.Ind) do FreeToken(atk^.Ind[C]);
               {SetLength(atk^.Ind, 0);} Dispose(atk)
            end;
            
         TK_BADT:
            ; // Bad token. Holds no data. Unused.
      end;
      Dispose(T)
   end;

Procedure FreeExpr(Const E:PExpr);
   Var C:LongWord;
   begin
      If (Length(E^.Tok)>0) then
         For C:=Low(E^.Tok) to High(E^.Tok) do
            FreeToken(E^.Tok[C]);
      {SetLength(E^.Tok, 0); SetLength(E^.Arg,0);}
      Dispose(E)
   end;

Procedure FreeProc(Var P:TProc);
   Var C:LongWord;
   begin
      If (Length(P.Exp)>0) then
         For C:=Low(P.Exp) to High(P.Exp) do
            FreeExpr(P.Exp[C]);
      {SetLength(P.Exp, 0); SetLength(P.Arg, 0)}
   end;

end.
