begin
   // Free args, if any, and leave if no retval expected
   F_(False, Arg); If (Not DoReturn) then Exit(NIL);

   // Attemp to grab sysinfo and return nilval on failure
   If(SysInfo(@SI) <> 0) then Exit(NilVal());
   Exit(NewVal(VT_INT, __FIELD__))
