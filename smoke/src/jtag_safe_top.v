module jtag_safe_top;
  wire cfgmclk;

  STARTUPE2 #(
    .PROG_USR("FALSE"),
    .SIM_CCLK_FREQ(0.0)
  ) startup_i (
    .CFGCLK(),
    .CFGMCLK(cfgmclk),
    .EOS(),
    .PREQ(),
    .CLK(1'b0),
    .GSR(1'b0),
    .GTS(1'b0),
    .KEYCLEARB(1'b1),
    .PACK(1'b0),
    .USRCCLKO(1'b0),
    .USRCCLKTS(1'b1),
    .USRDONEO(1'b1),
    .USRDONETS(1'b1)
  );

  (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)
  reg [7:0] heartbeat = 8'h00;

  always @(posedge cfgmclk) begin
    heartbeat <= heartbeat + 8'h01;
  end
endmodule
