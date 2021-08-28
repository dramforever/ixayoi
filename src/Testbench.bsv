import FIFO::*;
import SpecialFIFOs::*;
import BRAM::*;
import Vector::*;

import Types::*;
import Cpu::*;

module mkTestbench(Empty);
    BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 1024;
    cfg.loadFormat = tagged Hex "../ram.txt";

    BRAM2PortBE#(Bit#(10), Word, 4) bram <- mkBRAM2ServerBE(cfg);

    Cpu cpu <- mkCpu;

    rule handleFetchReq;
        let req <- cpu.fetchReq;
        bram.portB.request.put(BRAMRequestBE {
            writeen: '0,
            responseOnWrite: False,
            address: req[11:2],
            datain: ?
        });
    endrule

    rule handleFetchResp;
        let data <- bram.portB.response.get;
        cpu.fetchResp('hdec0de1c);
    endrule

    // (* descending_urgency = "handleMemReq, handleFetchReq" *)
    rule handleMemReq;
        let req <- cpu.memReq;

        if (req.write && req.addr == 'd4) $finish;
        bram.portA.request.put(BRAMRequestBE {
            writeen: req.write ? req.bstrb : '0,
            responseOnWrite: True,
            address: req.addr[11:2],
            datain: req.data
        });
    endrule

    rule handleMemResp;
        let data <- bram.portA.response.get;
        cpu.memResp(data);
    endrule

    rule timer;
        $display("--------------------");
        let t <- $time;
        if (t > 1000) $finish;
    endrule
endmodule
