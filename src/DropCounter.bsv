interface DropCounter#(type ctr_t);
    method Action flush;
    method Action request;
    method ActionValue#(Bool) response;
endinterface

module mkDropCounter(DropCounter#(ctr_t))
    provisos ( Bits#(ctr_t, ctr_t_n), Eq#(ctr_t), Arith#(ctr_t), Bounded#(ctr_t) );
    Reg#(Tuple2#(ctr_t, ctr_t)) cr[2] <- mkCReg(2, minBound);

    method Action flush;
        match { .infl, .disc } = cr[0];
        cr[0] <= tuple2(infl, infl);
    endmethod

    method ActionValue#(Bool) response if (tpl_1(cr[0]) != minBound);
        match { .infl, .disc } = cr[0];
        if (disc == minBound) begin
            cr[0] <= tuple2(infl - 1, minBound);
            return True;
        end else begin
            cr[0] <= tuple2(infl - 1, disc - 1);
            return False;
        end
    endmethod

    method Action request if (tpl_1(cr[1]) != maxBound);
        match { .infl, .disc } = cr[1];
        cr[1] <= tuple2(infl + 1, disc);
    endmethod
endmodule
