import Types::*;

function Word alu(
    Word a,
    Word b,
    Bool imm,
    Funct3 funct3,
    Funct7 funct7);

    case (imm ? '0 : funct7) matches
    'b000_0000:
        case (funct3) matches
        'b000:      return a + b;
        'b001:      return a << b[4:0];
        'b010:      return { '0, pack(SWord'(unpack(a)) < SWord'(unpack(b))) };
        'b011:      return { '0, pack(a < b) };
        'b100:      return a ^ b;
        'b101:      return a >> b[4:0];
        'b110:      return a | b;
        'b111:      return a & b;
        endcase
    'b010_0000:
        case (funct3) matches
        'b000:      return a - b;
        'b101:      return pack(SWord'(unpack(a)) >> b[4:0]);
        default:    return ?;
        endcase
    default:        return ?;
    endcase
endfunction

function Bool branch(
    Word a,
    Word b,
    Funct3 funct3);

    let { op, isUnsigned, invertOut } = Tuple3#(Bit#(1), Bool, Bool)'(unpack(funct3));

    let res = case (op) matches
        'b0: (a == b);
        'b1: (isUnsigned ? (a < b) : (SWord'(unpack(a)) < SWord'(unpack(b))));
    endcase;

    return invertOut ? ! res : res;
endfunction
