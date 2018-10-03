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
      Ind : Array of PToken; // Array of indexing tokens
      Case TTokenType of
         TK_AVAL .. TK_AREF: 
            (Nam : PStr);
         
         TK_AFLY:
            (Exp : PExpr);
         
         TK_BADT:
            (Ptr : Pointer); // For compatibility
   end;
    
   TToken = record
      Case Typ : TTokenType of
         TK_EXPR:
            (Exp : PExpr);
         TK_CONS, TK_LITE:
            (Val : PValue);
         TK_VARI, TK_REFE:
            (Nam : PStr);
         TK_AVAL, TK_AREF, TK_AFLY:
            (atk : PArrTk);
         TK_BADT: // Unused
            (Ptr : Pointer); // Left for compatibility
   end;
   
   TExpr = record
      //Lin : LongWord;      // Line number
      Fun : TBuiltIn;        // Pointer to built-in func
      Ref : Boolean;         // Reference-modifying?
      Num : LongInt;         // Number of tokens / arguments
      Tok : Array of PToken; // Array of tokens in expression
      Arg : Array of PValue  // Array of arguments to pass to function
   end;
   
   TStaticVar = record
      Nam : AnsiString; // Variable name
      Val : PValue      // Variable value
   end;
   
   TProc = record
      Nam : AnsiString;          // Function name
      Fil : LongWord;            // File number
      Lin : LongWord;            // Line number
      Num : LongWord;            // Number of expressions
      Exp : Array of PExpr;      // Array of expressions
      Arg : Array of AnsiString; // Argument name array
      Glo : Array of AnsiString; // Global-vars array
      Stv : Array of TStaticVar; // Static-vars array
   end;

Procedure FreeToken(Const T:PToken);
Procedure FreeExpr(Const E:PExpr);
Procedure FreeProc(Var P:TProc);


implementation

Procedure FreeToken(Const T:PToken);
   Var C:LongWord;
   begin
      Case (T^.Typ) of
         TK_EXPR: 
            FreeExpr(T^.Exp);
            
         TK_CONS: 
            ; // Pointer to a value in const trie. Value will be freed when flushing consts
            
         TK_LITE:
            AnnihilateVal(T^.Val);
            
         TK_VARI, TK_REFE:
            Dispose(T^.Nam);
            
         TK_AVAL, TK_AREF:
            begin
               Dispose(T^.atk^.Nam); 
               For C:=Low(T^.atk^.Ind) to High(T^.atk^.Ind) do FreeToken(T^.atk^.Ind[C]);
               {SetLength(T^.atk^.Ind, 0);} Dispose(T^.atk)
            end;
            
         TK_AFLY:
            begin
               FreeExpr(T^.atk^.Exp); 
               For C:=Low(T^.atk^.Ind) to High(T^.atk^.Ind) do FreeToken(T^.atk^.Ind[C]);
               {SetLength(T^.atk^.Ind, 0);} Dispose(T^.atk)
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
      If (Length(P.Stv)>0) then
         For C:=Low(P.Stv) to High(P.Stv) do
            AnnihilateVal(P.Stv[C].Val);
      {SetLength(P.Exp, 0); SetLength(P.Arg, 0); SetLength(P.Stv, 0);}
   end;

end.
