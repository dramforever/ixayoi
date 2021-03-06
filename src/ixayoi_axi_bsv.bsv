import FIFO::*;
import FIFOF::*;

import Types::*;
import SimpleAxi::*;
import Cpu::*;
import InstrCache::*;

interface IxayoiAxi;
    (* prefix = "mi_axi" *)
    interface AxiBurstMasterRead#(Word, Word)        ibus;

    (* prefix = "md_axi" *)
    interface AxiLiteMaster#(Word, Word, BStrb)     dbus;

    (* always_ready *)
    method UInt#(64) instret;
endinterface

function Action enableAction(Bool con, Action act);
action
    if (con) act;
endaction
endfunction

module mkAxiBurstMasterReadFIFO(
    FIFOF#(RReq#(addr_t)) arFIFO,
    FIFOF#(RResp#(data_t)) rFIFO,
    AxiBurstMasterRead#(addr_t, data_t) ifc
)
    provisos ( Bits#(data_t, nb_data_t) );

    Wire#(data_t)   rdataWire <- mkBypassWire;
    Wire#(XResp)    rrespWire <- mkBypassWire;
    function r = RResp { data: rdataWire, resp: rrespWire };

    method araddr = arFIFO.first.addr;
    method arburst = arFIFO.first.burst;
    method arlen = arFIFO.first.len;
    method arvalid = arFIFO.notEmpty;
    method arready(data) = enableAction(data && arFIFO.notEmpty, arFIFO.deq);

    method rready = rFIFO.notFull;
    method rdata(data) = rdataWire._write(data);
    method rresp(data) = rrespWire._write(data);
    method rvalid(data) = enableAction(data && rFIFO.notFull, rFIFO.enq(r));
endmodule

module mkAxiLiteMasterReadFIFO(
    FIFOF#(addr_t) arFIFO,
    FIFOF#(RResp#(data_t)) rFIFO,
    AxiLiteMasterRead#(addr_t, data_t) ifc
)
    provisos ( Bits#(data_t, nb_data_t) );

    Wire#(data_t)   rdataWire <- mkBypassWire;
    Wire#(XResp)    rrespWire <- mkBypassWire;
    function r = RResp { data: rdataWire, resp: rrespWire };

    method araddr = arFIFO.first;
    method arvalid = arFIFO.notEmpty;
    method arready(data) = enableAction(data && arFIFO.notEmpty, arFIFO.deq);

    method rready = rFIFO.notFull;
    method rdata(data) = rdataWire._write(data);
    method rresp(data) = rrespWire._write(data);
    method rvalid(data) = enableAction(data && rFIFO.notFull, rFIFO.enq(r));
endmodule

module mkAxiLiteMasterWriteFIFO(
    FIFOF#(addr_t) awFIFO,
    FIFOF#(WReq#(data_t, strb_t)) wFIFO,
    FIFOF#(XResp) bFIFO,
    AxiLiteMasterWrite#(addr_t, data_t, strb_t) ifc
);

    Wire#(XResp)    brespWire <- mkBypassWire;

    method awaddr = awFIFO.first;
    method awvalid = awFIFO.notEmpty;
    method awready(data) = enableAction(data && awFIFO.notEmpty, awFIFO.deq);

    method wdata = wFIFO.first.data;
    method wstrb = wFIFO.first.strb;
    method wvalid = wFIFO.notEmpty;
    method wready(data) = enableAction(data && wFIFO.notEmpty, wFIFO.deq);

    method bready = bFIFO.notFull;
    method bresp(data) = brespWire._write(data);
    method bvalid(data) = enableAction(data && bFIFO.notFull, bFIFO.enq(brespWire));
endmodule

(* synthesize *)
module ixayoi_axi_bsv(IxayoiAxi);
    Cpu cpu <- mkCpu;
    InstrCache icache <- mkInstrCache;

    FIFOF#(RReq#(Word))         i_ar    <- mkGFIFOF(False, True);
    FIFOF#(RResp#(Word))        i_r     <- mkGFIFOF(True, False);

    FIFOF#(Word)                d_ar    <- mkGFIFOF(False, True);
    FIFOF#(Word)                d_aw    <- mkGFIFOF(False, True);
    FIFOF#(WReq#(Word, BStrb))  d_w     <- mkGFIFOF(False, True);
    FIFOF#(RResp#(Word))        d_r     <- mkGFIFOF(True, False);
    FIFOF#(XResp)               d_b     <- mkGFIFOF(True, False);

    AxiBurstMasterRead#(Word, Word) ibusFIFO <- mkAxiBurstMasterReadFIFO(i_ar, i_r);
    AxiLiteMasterRead#(Word, Word) ibusReadFIFO <- mkAxiLiteMasterReadFIFO(d_ar, d_r);
    AxiLiteMasterWrite#(Word, Word, BStrb) ibusWriteFIFO <- mkAxiLiteMasterWriteFIFO(d_aw, d_w, d_b);

    rule handleFetchReq;
        let req <- cpu.fetchReq;
        icache.fetchReq(req);
    endrule

    rule handleFetchResp;
        let resp <- icache.fetchResp;
        cpu.fetchResp(resp);
    endrule

    rule handleAxiReq;
        let req <- icache.axiReq;
        i_ar.enq(req);
    endrule

    rule handleAxiResp;
        i_r.deq;
        icache.axiResp(i_r.first);
    endrule

    FIFO#(Bool)     isWriteFIFO <- mkSizedFIFO(16);

    rule handleMemReq;
        let req <- cpu.memReq;
        if (req.write) begin
            d_aw.enq(req.addr);
            d_w.enq(WReq { data: req.data, strb: req.bstrb });
            isWriteFIFO.enq(True);
        end else begin
            d_ar.enq(req.addr);
            isWriteFIFO.enq(False);
        end
    endrule

    rule handleMemB (isWriteFIFO.first);
        isWriteFIFO.deq;
        d_b.deq;
        cpu.memResp(?);
    endrule

    rule handleMemR (! isWriteFIFO.first);
        isWriteFIFO.deq;
        d_r.deq;
        cpu.memResp(d_r.first.data);
    endrule

    interface ibus = ibusFIFO;
    interface dbus = interface AxiLiteMaster;
        interface read = ibusReadFIFO;
        interface write = ibusWriteFIFO;
    endinterface;

    method instret = cpu.instret;
endmodule
