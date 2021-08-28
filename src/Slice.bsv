import GetPut::*;

interface Slice#(type t);
    method Action enq(t value);

    (* always_ready *)
    method Action clear;

    method Action deq;

    method t first;

    (* always_ready *)
    method Maybe#(t) peek;
endinterface

module mkSlice(Slice#(t))
    provisos ( Bits#(t, n_t) );

    Reg#(Maybe#(t)) cr[3] <- mkCReg(3, tagged Invalid);

    method Maybe#(t) peek = cr[2];

    method t first if (cr[0] matches tagged Valid .val);
        return val;
    endmethod

    method Action clear();
        cr[2] <= tagged Invalid;
    endmethod

    method Action deq if (cr[0] matches tagged Valid .*);
        cr[0] <= tagged Invalid;
    endmethod

    method Action enq(t value) if (cr[1] matches tagged Invalid);
        cr[1] <= tagged Valid value;
    endmethod
endmodule
