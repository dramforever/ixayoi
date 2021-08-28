import FIFO::*;
import Vector::*;
import SpecialFIFOs::*;

import Types::*;
import Instr::*;
import Slice::*;
import Alu::*;
import CpuRegFile::*;

typedef struct {
    Word    addr;
    Word    data;
    BStrb   bstrb;
    Bool    write;
} BusReq
    deriving (FShow, Bits);

interface Cpu;
    method ActionValue#(Word) fetchReq;
    method Action fetchResp(Word data);

    method ActionValue#(BusReq) memReq;
    method Action memResp(Word data);

    method Word instrCount;
endinterface

typedef struct {
    Instr   instr;
    Word    npc;
} ControlDecode
    deriving (FShow, Bits);

typedef struct {
    Decoded decoded;

    Word    npc;
    Word    rs1Val;
    Word    rs2Val;
} ControlExecute
    deriving (FShow, Bits);

typedef struct {
    Decoded decoded;

    Word    npc;
    Word    exResult;
    Word    rs2Val;
} ControlMem
    deriving (FShow, Bits);

typedef struct {
    Word    npc;
    Bool    write;
    RegNum  regNum;
    Word    data;
} ControlWrite
    deriving (FShow, Bits);

(* synthesize *)
module mkCpu(Cpu);
    Slice#(ControlDecode)   decodeFIFO <- mkSlice;
    Slice#(ControlExecute)  executeFIFO <- mkSlice;
    Slice#(ControlMem)      memFIFO <- mkSlice;
    Slice#(ControlMem)      loadFIFO <- mkSlice;
    Slice#(ControlWrite)    writeFIFO <- mkSlice;

    CpuRegFile              regFile <- mkCpuRegFile;

    FIFO#(Word)             fetchReqFIFO <- mkBypassFIFO;
    FIFO#(Instr)            fetchRespFIFO <- mkBypassFIFO;

    FIFO#(BusReq)           memReqFIFO <- mkBypassFIFO;
    FIFO#(Word)             memRespFIFO <- mkBypassFIFO;

    Reg#(Word)              instrCounter <- mkReg('d0);

    // Fetch stage

    Reg#(Word)  fetchPc <- mkReg('hd000_0000);
    Reg#(Word)  realPc <- mkReg('hd000_0000);

    FIFO#(Word) inFlight <- mkSizedFIFO(16);

    rule fetchReqRule;
        $display("[%9d] [%08h] [ A . . . . . . ] fetch req", $time, fetchPc);
        fetchPc <= fetchPc + 4;
        inFlight.enq(fetchPc);
        fetchReqFIFO.enq(fetchPc);
    endrule

    (* execution_order = "fetchRespRule, fetchReqRule" *)
    rule fetchRespRule;
        fetchRespFIFO.deq;
        if (inFlight.first == realPc) begin
            $display("[%9d] [%08h] [ . F . . . . . ] fetch resp %08h", $time, realPc, fetchRespFIFO.first);
            decodeFIFO.enq(ControlDecode {
                instr: fetchRespFIFO.first,
                npc: realPc
            });
            realPc <= realPc + 4;
        end
        inFlight.deq;
    endrule

    // Decode stage

    function Maybe#(Word) readReg(RegNum rn);
        let result = tagged Valid regFile.sub(rn);

        if (writeFIFO.peek matches tagged Valid .item) begin
            if (item.write && item.regNum == rn)
                result = tagged Valid item.data;
        end

        // TODO: Refactor this
        if (loadFIFO.peek matches tagged Valid .item) begin
            if (item.decoded.rdNum == rn && item.decoded.writeRd) begin
                if (item.decoded.run matches RunLoadStore)
                    result = tagged Invalid;
                else
                    result = tagged Valid item.exResult;
            end
        end

        if (memFIFO.peek matches tagged Valid .item) begin
            if (item.decoded.rdNum == rn && item.decoded.writeRd) begin
                if (item.decoded.run matches RunLoadStore)
                    result = tagged Invalid;
                else
                    result = tagged Valid item.exResult;
            end
        end

        if (rn == '0) begin
            result = tagged Valid '0;
        end

        return result;
    endfunction

    function Maybe#(Word) readRegIf(RegNum rn, Bool willUse);
        return willUse ? readReg(rn): tagged Valid (?);
    endfunction

    function Decoded decodedRaw = decodeInstr(decodeFIFO.first.instr);

    function Maybe#(Tuple2#(Word, Word)) getRegs;
        if (readRegIf(decodedRaw.rs1Num, decodedRaw.rs1Use) matches tagged Valid .rs1Val
            &&& readRegIf(decodedRaw.rs2Num, decodedRaw.rs2Use) matches tagged Valid .rs2Val)
            return tagged Valid tuple2(rs1Val, rs2Val);
        else
            return tagged Invalid;
    endfunction

    rule decodeInstr (getRegs matches tagged Valid { .rs1Val, .rs2Val });
        $display("[%9d] [%08h] [ . . D . . . . ] decode", $time, decodeFIFO.first.npc);

        decodeFIFO.deq;
        executeFIFO.enq(ControlExecute {
            decoded: decodedRaw,
            npc: decodeFIFO.first.npc,
            rs1Val: rs1Val,
            rs2Val: rs2Val
        });
    endrule

    // Execute stage
    function exInp = executeFIFO.first;
    function exDec = exInp.decoded;

    rule executeAuipcLui (exDec.run == RunAuipcLui);
        $display("[%9d] [%08h] [ . . . E . . . ] ex auipc/lui", $time, exInp.npc);
        executeFIFO.deq;

        memFIFO.enq(ControlMem {
            decoded: exDec,
            npc: exInp.npc,
            exResult: exDec.imm + (exDec.isAuipc ? exInp.npc : '0),
            rs2Val: ?
        });
    endrule

    (* preempts = "executeJal, (fetchReqRule, fetchRespRule)" *)
    rule executeJal (exDec.run == RunJal);
        let target = exInp.npc + exDec.imm;

        $display("[%9d] [%08h] [ . . . E . . . ] ex jal %08h", $time, exInp.npc, target);
        executeFIFO.deq;

        fetchPc <= target;
        realPc <= target;

        decodeFIFO.clear;

        memFIFO.enq(ControlMem {
            decoded: exDec,
            npc: exInp.npc,
            exResult: exInp.npc + 4,
            rs2Val: ?
        });
    endrule

    (* preempts = "executeJalr, (fetchReqRule, fetchRespRule)" *)
    rule executeJalr (exDec.run == RunJalr);
        let target = exInp.rs1Val + exDec.imm;

        $display("[%9d] [%08h] [ . . . E . . . ] ex jalr %08h", $time, exInp.npc, target);
        executeFIFO.deq;

        fetchPc <= target;
        realPc <= target;

        decodeFIFO.clear;

        memFIFO.enq(ControlMem {
            decoded: exDec,
            npc: exInp.npc,
            exResult: exInp.npc + 4,
            rs2Val: ?
        });
    endrule

    function branchTaken =
        branch(exInp.rs1Val, exInp.rs2Val, exDec.funct3);

    (* preempts = "executeBranchTaken, (fetchReqRule, fetchRespRule)" *)
    rule executeBranchTaken (exDec.run == RunBranch && branchTaken);
        let target = exInp.npc + exDec.imm;

        $display("[%9d] [%08h] [ . . . E . . . ] ex branch taken %08h", $time, exInp.npc, target);
        executeFIFO.deq;

        fetchPc <= target;
        realPc <= target;

        decodeFIFO.clear;

        memFIFO.enq(ControlMem {
            decoded: exDec,
            npc: exInp.npc,
            exResult: ?,
            rs2Val: ?
        });
    endrule

    rule executeBranchNotTaken (exDec.run == RunBranch && ! branchTaken);
        $display("[%9d] [%08h] [ . . . E . . . ] ex branch not taken", $time, exInp.npc);
        executeFIFO.deq;
    endrule

    function aluResult = alu(
        exInp.rs1Val,
        exDec.aluImm ? exDec.imm: exInp.rs2Val,
        exDec.aluImm,
        exDec.funct3,
        exDec.funct7
    );

    rule executeOp (exDec.run == RunOp);
        $display("[%9d] [%08h] [ . . . E . . . ] ex op, result = %08h", $time, exInp.npc, aluResult);
        executeFIFO.deq;

        memFIFO.enq(ControlMem {
            decoded: exDec,
            npc: exInp.npc,
            exResult: aluResult,
            rs2Val: ?
        });
    endrule

    rule executeLoadStore (exDec.run == RunLoadStore);
        $display("[%9d] [%08h] [ . . . E . . . ] ex load/store addr", $time, exInp.npc);
        executeFIFO.deq;

        memFIFO.enq(ControlMem {
            decoded: exDec,
            npc: exInp.npc,
            exResult: exInp.rs1Val + exDec.imm,
            rs2Val: exInp.rs2Val
        });
    endrule

    // Memory stage
    function memInp = memFIFO.first;
    function memDec = memInp.decoded;

    rule memNonMem (memDec.run != RunLoadStore);
        $display("[%9d] [%08h] [ . . . . M . . ] no mem", $time, memInp.npc);
        memFIFO.deq;

        if (memDec.writeRd) begin
            loadFIFO.enq(memInp);
        end
    endrule

    function BusReq adjustBusReq(BusReq req);
        return BusReq {
            addr: req.addr & (~ 'b11),
            data: req.data << { req.addr[1:0], 3'b000 },
            bstrb: req.bstrb << req.addr[1:0],
            write: req.write
        };
    endfunction

    rule memMem (memDec.run == RunLoadStore);
        $display("[%9d] [%08h] [ . . . . M . . ] load/store %08h", $time, memInp.npc, memInp.exResult);
        memFIFO.deq;

        memReqFIFO.enq(adjustBusReq(BusReq {
            addr: memInp.exResult,
            data: memInp.rs2Val,
            bstrb: memDec.bstrb,
            write: ! memDec.isLoad
        }));

        loadFIFO.enq(memInp);
    endrule

    // Load stage
    function loadInp = loadFIFO.first;
    function loadDec = loadInp.decoded;

    rule loadNonMem (loadDec.run != RunLoadStore);
        $display("[%9d] [%08h] [ . . . . . L . ] no mem", $time, loadInp.npc);
        loadFIFO.deq;

        writeFIFO.enq(ControlWrite {
            npc: loadInp.npc,
            write: loadDec.writeRd,
            regNum: loadDec.rdNum,
            data: loadInp.exResult
        });
    endrule

    function Word adjustLoad(Word data, Bit#(2) shift, BStrb bstrb, Bool loadSigned);
        data = data >> { shift, 3'b000 };
        Vector#(4, Bit#(8)) bytes = unpack(data);
        Vector#(4, Bit#(8)) result = replicate(?);

        bit sign = ?;

        for (Integer i = 0; i < 4; i = i + 1) begin
            if (bstrb[i] == 1) begin
                sign = bytes[i][7];
                result[i] = bytes[i];
            end else begin
                if (loadSigned)
                    result[i] = pack(replicate(sign));
                else
                    result[i] = '0;
            end
        end

        return pack(result);
    endfunction

    rule loadMem (loadDec.run == RunLoadStore);
        $display("[%9d] [%08h] [ . . . . . L . ] load/store done", $time, loadInp.npc);
        loadFIFO.deq;
        memRespFIFO.deq;

        writeFIFO.enq(ControlWrite {
            npc: loadInp.npc,
            write: loadDec.isLoad,
            regNum: loadDec.rdNum,
            data: adjustLoad(memRespFIFO.first, loadInp.exResult[1:0], loadDec.bstrb, loadDec.loadSigned)
        });
    endrule

    // Writeback stage
    function writeInp = writeFIFO.first;
    rule writeback;
        writeFIFO.deq;
        if (writeInp.write) begin
            $display("[%9d] [%08h] [ . . . . . . W ] wb reg[%2d] <- %08h", $time,
                writeInp.npc, writeInp.regNum, writeInp.data);

            regFile.upd(writeInp.regNum, writeInp.data);
        end else begin
            $display("[%9d] [%08h] [ . . . . . . W ] wb nothing", $time, writeInp.npc);
        end
        instrCounter <= instrCounter + 1;
    endrule

    method ActionValue#(Word) fetchReq;
        fetchReqFIFO.deq;
        return fetchReqFIFO.first;
    endmethod

    method Action fetchResp(Instr data) = fetchRespFIFO.enq(data);

    method ActionValue#(BusReq) memReq;
        memReqFIFO.deq;
        return memReqFIFO.first;
    endmethod

    method Action memResp(Word data) = memRespFIFO.enq(data);

    method instrCount = instrCounter._read;
endmodule
