import Types::*;

typedef struct {
    Opcode      opcode;

    RegNum      rs1;
    RegNum      rs2;
    RegNum      rd;

    Funct3      funct3;
    Funct7      funct7;

    Word        immI;
    Word        immS;
    Word        immB;
    Word        immU;
    Word        immJ;
} InstrFields
    deriving (FShow, Bits);

function InstrFields instrFields (
    Instr in
);
    function Bit#(n) extend(Bit#(1) a);
        return a == '1 ? '1 : '0;
    endfunction

    return InstrFields {
        opcode:     in[6:0],
        rs1:        in[19:15],
        rs2:        in[24:20],
        rd:         in[11:7],
        funct3:     in[14:12],
        funct7:     in[31:25],
        immI:       {extend(in[31]), in[30:20]},
        immS:       {extend(in[31]), in[30:25], in[11:7]},
        immB:       {extend(in[31]), in[7], in[30:25], in[11:8], 1'b0},
        immU:       {in[31:12], 12'b0},
        immJ:       {extend(in[31]), in[19:12], in[20], in[30:21], 1'b0}
    };
endfunction

typedef enum {
    RunAuipcLui     = 6'b000001,
    RunJal          = 6'b000010,
    RunJalr         = 6'b000100,
    RunBranch       = 6'b001000,
    RunOp           = 6'b010000,
    RunLoadStore    = 6'b100000
} Run
    deriving (FShow, Bits, Eq);

typedef struct {
    Run         run;

    // Registers
    RegNum      rs1Num;
    RegNum      rs2Num;
    RegNum      rdNum;

    Bool        rs1Use;
    Bool        rs2Use;

    Funct3      funct3;
    Funct7      funct7;
    Word        imm;

    // Control signals
    BStrb       bstrb;
    Bool        loadSigned;
    Bool        writeRd;

    Bool        aluImm;
    Bool        isAuipc;
    Bool        isLoad;
} Decoded
    deriving (FShow, Bits);

function Decoded decodeInstr(Instr instr);
    let fields = instrFields(instr);

    Run run = case (fields.opcode) matches
        'b0?1_0111:     RunAuipcLui;
        'b110_1111:     RunJal;
        'b110_0111:     RunJalr;
        'b110_0011:     RunBranch;      // Bxx
        'b0?0_0011:     RunLoadStore;   // Lx, Sx
        'b0?1_0011:     RunOp;          // OP and OP-IMM
        default:        ?;
    endcase;

    Bool aluImm = fields.opcode[5] == 0;
    Bool isAuipc = fields.opcode[5] == 0;
    Bool isLoad = fields.opcode[5] == 0;

    Word imm = case (run) matches
        RunJalr:        fields.immI;
        RunOp:          fields.immI;
        RunLoadStore:   (isLoad ? fields.immI : fields.immS);
        RunBranch:      fields.immB;
        RunAuipcLui:    fields.immU;
        RunJal:         fields.immJ;
    endcase;

    BStrb bstrb = case (fields.funct3[1:0]) matches
        'b00:       4'b0001;
        'b01:       4'b0011;
        'b10:       4'b1111;
        default:    ?;
    endcase;

    Bool loadSigned = fields.funct3[2] == '0;

    Bool rs1Use = (run == RunJalr || run == RunBranch || run == RunOp || run == RunLoadStore);
    Bool rs2Use = ((run == RunOp && ! aluImm) || (run == RunLoadStore && ! isLoad) || run == RunBranch);

    Bool writeRd =  (run == RunAuipcLui || run == RunJal || run == RunJalr || run == RunOp || (run == RunLoadStore && isLoad));

    return Decoded {
        run: run,

        rs1Use: rs1Use, rs1Num: fields.rs1,
        rs2Use: rs2Use, rs2Num: fields.rs2,
        rdNum: fields.rd,

        funct3: fields.funct3, funct7: fields.funct7, imm: imm,

        bstrb: bstrb, loadSigned: loadSigned,

        writeRd: writeRd,

        aluImm: aluImm,
        isAuipc: isAuipc,
        isLoad: isLoad
    };
endfunction
