module ixayoi_axi(
    clk, resetn,

    mi_axi_araddr,
    mi_axi_arvalid,
    mi_axi_arready,
    mi_axi_rready,
    mi_axi_rvalid,
    mi_axi_rdata,
    mi_axi_rresp,
    md_axi_awaddr,
    md_axi_awvalid,
    md_axi_awready,
    md_axi_wdata,
    md_axi_wstrb,
    md_axi_wvalid,
    md_axi_wready,
    md_axi_bready,
    md_axi_bvalid,
    md_axi_bresp,
    md_axi_araddr,
    md_axi_arvalid,
    md_axi_arready,
    md_axi_rready,
    md_axi_rvalid,
    md_axi_rdata,
    md_axi_rresp
);
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF MI:MD, ASSOCIATED_RESET resetn" *)
    input  clk;

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  resetn;

    (* X_INTERFACE_PARAMETER = "PROTOCOL AXI4LITE, READ_WRITE_MODE READ_ONLY" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MI ARADDR" *)     output [31 : 0] mi_axi_araddr;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MI ARVALID" *)    output mi_axi_arvalid;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MI ARREADY" *)    input  mi_axi_arready;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MI RREADY" *)     output mi_axi_rready;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MI RVALID" *)     input  mi_axi_rvalid;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MI RDATA" *)      input  [31 : 0] mi_axi_rdata;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MI RRESP" *)      input  [1 : 0] mi_axi_rresp;

    (* X_INTERFACE_PARAMETER = "PROTOCOL AXI4LITE, READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD AWADDR" *)     output [31 : 0] md_axi_awaddr;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD AWVALID" *)    output md_axi_awvalid;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD AWREADY" *)    input  md_axi_awready;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD WDATA" *)      output [31 : 0] md_axi_wdata;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD WSTRB" *)      output [3 : 0] md_axi_wstrb;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD WVALID" *)     output md_axi_wvalid;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD WREADY" *)     input  md_axi_wready;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD BREADY" *)     output md_axi_bready;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD BVALID" *)     input  md_axi_bvalid;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD BRESP" *)      input  [1 : 0] md_axi_bresp;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD ARADDR" *)     output [31 : 0] md_axi_araddr;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD ARVALID" *)    output md_axi_arvalid;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD ARREADY" *)    input  md_axi_arready;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD RREADY" *)     output md_axi_rready;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD RVALID" *)     input  md_axi_rvalid;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD RDATA" *)      input  [31 : 0] md_axi_rdata;
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 MD RRESP" *)      input  [1 : 0] md_axi_rresp;

    ixayoi_axi_bsv ixayoi_axi_bsv_i (
        .CLK(clk), .RST_N(resetn),
        .mi_axi_araddr(mi_axi_araddr),
        .mi_axi_arvalid(mi_axi_arvalid),
        .mi_axi_arready(mi_axi_arready),
        .mi_axi_rready(mi_axi_rready),
        .mi_axi_rvalid(mi_axi_rvalid),
        .mi_axi_rdata(mi_axi_rdata),
        .mi_axi_rresp(mi_axi_rresp),
        .md_axi_awaddr(md_axi_awaddr),
        .md_axi_awvalid(md_axi_awvalid),
        .md_axi_awready(md_axi_awready),
        .md_axi_wdata(md_axi_wdata),
        .md_axi_wstrb(md_axi_wstrb),
        .md_axi_wvalid(md_axi_wvalid),
        .md_axi_wready(md_axi_wready),
        .md_axi_bready(md_axi_bready),
        .md_axi_bvalid(md_axi_bvalid),
        .md_axi_bresp(md_axi_bresp),
        .md_axi_araddr(md_axi_araddr),
        .md_axi_arvalid(md_axi_arvalid),
        .md_axi_arready(md_axi_arready),
        .md_axi_rready(md_axi_rready),
        .md_axi_rvalid(md_axi_rvalid),
        .md_axi_rdata(md_axi_rdata),
        .md_axi_rresp(md_axi_rresp)
    );

endmodule
