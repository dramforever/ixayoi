# Ixayoi

*(This is a work in progress)*

A relatively simple pipelined RISC-V core, written in [Bluespec SystemVerilog][bsc].

[bsc]: https://github.com/B-Lang-org/bsc

## Build instructions

Requires [Bluespec Compiler][bsc] and GNU Make.

```console
$ mkdir build
$ make -f ../Makefile -C build sim              # Run simulation
$ make -f ../Makefile -C build ixayoi_axi_bsv.v # Generating Verilog
```

## Design

Ixayoi uses a desigin similar to the classic 5-stage pipeline, but expands it to 7 stages for pipelined memory access:

- `A`: Address: Generates instruction fetch requests
- `F`: Fetch: Handles instruction fetch responses
- `D`: Decode
- `E`: Execute: Handles arithmetic, address calculation and branches
- `M`: Memory: Generates data memory requests
- `L`: Load: Handles data memory responses. Named 'load' because load operations get their results here.
- `W`: Writeback

## Memory access

Ixayoi's `mkCpu` module exposes the following methods for connecting to memory/cache.

```bsv
interface Cpu;
    method ActionValue#(Word) fetchReq;
    method Action fetchResp(Word data);

    method ActionValue#(BusReq) memReq;
    method Action memResp(Word data);
endinterface
```

An instruction cache module, `mkInstrCache`, can handle raw fetch requests from the pipeline and, when needed, send out burst requests to an AXI bus.

A wrapper, `src/ixayoi_axi_bsv.bsv`, wraps around the two to provide one AXI4 interface for instruction memory access and one AXI4-Lite interface for data memory access. Yet another wrapper `verilog/ixayoi_axi.v` has ports with `X_INTERFACE_INFO` and `X_INTERFACE_PARAMETER` attributes for use in other block designs in Vivado IP Integrator.

# About the name

'*Ixayoi*' (pronounced *i-za-yo-i*, /izajo.i/) is the name of this project. It *may* have come from a certain <ruby>十六夜 <rp>(</rp><rt>いざよい</rt><rp>)</rp>.

# Todo list

- [ ] L1 I-cache
- [ ] `fence.i`
- [ ] CSR
- [ ] Interrupts, `ecall` and `ebreak`
- [ ] Error handling (Bus error / Invalid instruction)
