import Vector::*;

import Types::*;

interface CpuRegFile;
    method Word sub(RegNum rn);
    method Action upd(RegNum rn, Word val);
endinterface

// TODO: What do we do with x0?
module mkCpuRegFile(CpuRegFile);
    Reg#(Vector#(32, Word)) rf[2] <- mkCReg(2, replicate('0));

    method sub(rn) = rf[1][rn];

    method Action upd(rn, val);
        rf[0] <= update(rf[0], rn, val);
    endmethod
endmodule
