{ mkShell, bluespec, verilog }:

mkShell {
  nativeBuildInputs = [ bluespec verilog ];
}
