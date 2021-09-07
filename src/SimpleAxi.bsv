typedef enum {
    RespOkay    = 2'b00,
    RespExOkay  = 2'b01,
    RespSlvErr  = 2'b10,
    RespDecErr  = 2'b11
} XResp
    deriving (FShow, Bits);

typedef struct {
    data_t      data;
    XResp       resp;
} RResp#(type data_t)
    deriving (FShow, Bits);

typedef struct {
    data_t      data;
    strb_t      strb;
} WReq#(type data_t, type strb_t)
    deriving (FShow, Bits);

interface AxiLiteMasterWrite#(type addr_t, type data_t, type strb_t);
    (* always_ready *) method addr_t    awaddr;
    (* always_ready *) method Bool      awvalid;
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       awready     ((* port = "awready" *) Bool data);

    (* always_ready *) method data_t    wdata;
    (* always_ready *) method strb_t    wstrb;
    (* always_ready *) method Bool      wvalid;
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       wready      ((* port = "wready" *) Bool data);

    (* always_ready *) method Bool      bready;
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       bvalid      ((* port = "bvalid" *) Bool data);
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       bresp       ((* port = "bresp" *) XResp data);
endinterface

interface AxiLiteMasterRead#(type addr_t, type data_t);
    (* always_ready *) method addr_t    araddr;
    (* always_ready *) method Bool      arvalid;
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       arready     ((* port = "arready" *) Bool data);

    (* always_ready *) method Bool      rready;
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       rvalid      ((* port = "rvalid" *) Bool data);
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       rdata       ((* port = "rdata" *) data_t data);
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       rresp       ((* port = "rresp" *) XResp data);
endinterface

interface AxiLiteMaster#(type addr_t, type data_t, type strb_t);
    (* prefix = "" *)
    interface AxiLiteMasterWrite#(addr_t, data_t, strb_t) write;

    (* prefix = "" *)
    interface AxiLiteMasterRead#(addr_t, data_t) read;
endinterface

typedef enum {
    BurstFixed  = 2'b00,
    BurstIncr   = 2'b01,
    BurstWrap   = 2'b10
} AXBurst
    deriving (FShow, Bits);

typedef Bit#(8) AXLen;

typedef struct {
    addr_t      addr;
    AXBurst     burst;
    AXLen       len;
} RReq#(type addr_t)
    deriving (FShow, Bits);

interface AxiBurstMasterRead#(type addr_t, type data_t);
    (* always_ready *) method addr_t    araddr;
    (* always_ready *) method AXBurst   arburst;
    (* always_ready *) method AXLen     arlen;
    (* always_ready *) method Bool      arvalid;
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       arready     ((* port = "arready" *) Bool data);

    (* always_ready *) method Bool      rready;
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       rvalid      ((* port = "rvalid" *) Bool data);
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       rdata       ((* port = "rdata" *) data_t data);
    (* prefix = "" *)
    (* always_ready, always_enabled *)
    method Action                       rresp       ((* port = "rresp" *) XResp data);
endinterface
