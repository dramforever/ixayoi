import FIFO::*;
import BRAM::*;
import Vector::*;
import SpecialFIFOs::*;

import Types::*;
import SimpleAxi::*;

interface InstrCache;
    method Action fetchReq(Word addr);
    method ActionValue#(Word) fetchResp;

    method ActionValue#(RReq#(Word)) axiReq;
    method Action axiResp(RResp#(Word) resp);
endinterface

typedef Bit#(6)     IC_Offset;
typedef Bit#(10)    IC_Index;
typedef Bit#(16)    IC_Tag;
typedef Bit#(14)    IC_Addr;

function Tuple3#(IC_Tag, IC_Index, IC_Offset) addrToIC(Word addr);
    return tuple3(addr[31:16], addr[15:6], addr[5:0]);
endfunction

typedef enum {
    ICS_Reset,
    ICS_Pipe,
    ICS_Refill,
    ICS_RefillDone
} IC_State
    deriving (FShow, Eq, Bits);

module mkInstrCache(InstrCache);
    FIFO#(RReq#(Word))              axiReqFIFO <- mkBypassFIFO;

    BRAM1Port#(IC_Index, Maybe#(IC_Tag)) tagMem <- mkBRAM1Server(defaultValue);
    BRAM1Port#(IC_Addr, Word)       dataMem <- mkBRAM1Server(defaultValue);

    FIFO#(Word)                     tagPipe <- mkPipelineFIFO;

    Reg#(IC_State)                  state <- mkReg(ICS_Reset);

    Reg#(Word)                      curAddr <- mkReg(?);
    Reg#(Bit#(4))                   curWid <- mkReg(0);


    Reg#(IC_Index)                  resetCounter <- mkReg(0);

    rule clearTagMem (state == ICS_Reset);
        tagMem.portA.request.put(BRAMRequest {
            write: True,
            address: resetCounter,
            responseOnWrite: False,
            datain: tagged Invalid
        });
        resetCounter <= resetCounter + 1;
        if (resetCounter + 1 == 0) begin
            state <= ICS_Pipe;
        end
    endrule

    rule tagMemResp (state == ICS_Pipe);
        tagPipe.deq;
        let foundTag <- tagMem.portA.response.get;
        match { .tag, .index, .offset } = addrToIC(tagPipe.first);

        (* split *) if (tagged Valid tag == foundTag) begin
            dataMem.portA.request.put(BRAMRequest {
                write: False,
                address: { index, offset[5:2] },
                responseOnWrite: False,
                datain: ?
            });
        end else begin
            axiReqFIFO.enq(RReq {
                addr: { tagPipe.first[31:6], 6'b0 },
                burst: BurstIncr,
                len: 15
            });
            tagMem.portA.request.put(BRAMRequest {
                write: True,
                address: index,
                responseOnWrite: False,
                datain: tagged Valid tag
            });
            state <= ICS_Refill;
            curAddr <= tagPipe.first;
        end
    endrule

    rule refillDone (state == ICS_RefillDone);
        match { .tag, .index, .offset } = addrToIC(curAddr);

        dataMem.portA.request.put(BRAMRequest {
            write: False,
            address: { index, offset[5:2] },
            responseOnWrite: False,
            datain: ?
        });
        state <= ICS_Pipe;
    endrule

    method Action fetchReq(Word addr) if (state == ICS_Pipe);
        match { .tag, .index, .offset } = addrToIC(addr);
        tagMem.portA.request.put(BRAMRequest {
            write: False,
            address: index,
            responseOnWrite: False,
            datain: ?
        });
        tagPipe.enq(addr);
    endmethod

    method ActionValue#(Word) fetchResp = dataMem.portA.response.get;

    method ActionValue#(RReq#(Word)) axiReq;
        axiReqFIFO.deq;
        return axiReqFIFO.first;
    endmethod

    method Action axiResp(RResp#(Word) resp) if (state == ICS_Refill);
        match { .tag, .index, .offset } = addrToIC(curAddr);

        dataMem.portA.request.put(BRAMRequest {
            write: True,
            address: { index, curWid },
            responseOnWrite: False,
            datain: resp.data
        });

        curWid <= curWid + 1;

        if (curWid + 1 == 0) begin
            state <= ICS_RefillDone;
        end
    endmethod
endmodule
