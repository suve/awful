unit tokexpr;

interface
   uses Values;

Type TTokenType = (
     TK_EXPR, TK_CONS, TK_LITE, TK_VARI, TK_REFE, TK_AVAL, TK_AREF, TK_BADT);
     
     PExpr = ^TExpr;
     PToken = ^TToken;
     Array_PExpr = Array of PExpr;
     
     PArrTk = ^TArrTk;
     TArrTk = record
     Nam : TStr;
     Ind : Array of PToken
     end;
     
     TToken = record
     Typ : TTokenType;
     Ptr : Pointer
     end;
     
     TExpr = record
     //Lin : LongWord;
     Fun : PFunc;
     Tok : Array of PToken
     end;
     
     TProc = record
     Nu : LongWord;
     Ex : Array of PExpr;
     Ar : Array of AnsiString;
     end;

Procedure FreeToken(T:PToken);
Procedure FreeExpr(E:PExpr);
Procedure FreeProc(Var P:TProc);

implementation

Procedure FreeToken(T:PToken);
   Var atk:PArrTk; C:LongWord;
   begin
   Case (T^.Typ) of
      TK_EXPR: 
         FreeExpr(PExpr(T^.Ptr));
      TK_CONS: 
         ; // Pointer to a value in const trie. Value will be freed when flushing consts
      TK_LITE:
         FreeVal(PValue(T^.Ptr));
      TK_VARI, TK_REFE:
         Dispose(PStr(T^.Ptr));
      TK_AVAL, TK_AREF: begin
         atk:=PArrTk(T^.Ptr); 
         For C:=Low(atk^.Ind) to High(atk^.Ind) do FreeToken(atk^.Ind[C]);
         SetLength(atk^.Ind, 0); Dispose(atk)
         end;
      TK_BADT:
         ; // Bad token. Holds no data. Unused.
      end;
   Dispose(T)
   end;

Procedure FreeExpr(E:PExpr);
   Var C:LongWord;
   begin
   If (Length(E^.Tok)>0) then
      For C:=Low(E^.Tok) to High(E^.Tok) do
          FreeToken(E^.Tok[C]);
   SetLength(E^.Tok, 0); Dispose(E)
   end;

Procedure FreeProc(Var P:TProc);
   Var C:LongWord;
   begin
   If (Length(P.Ex)>0) then
      For C:=Low(P.Ex) to High(P.Ex) do
          FreeExpr(P.Ex[C]);
   SetLength(P.Ex, 0); SetLength(P.Ar, 0)
   end;

end.
