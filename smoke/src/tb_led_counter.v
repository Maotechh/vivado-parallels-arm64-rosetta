module tb_led_counter;
  reg clk = 1'b0;
  reg rst = 1'b1;
  wire [3:0] led;

  led_counter dut (
    .clk(clk),
    .rst(rst),
    .led(led)
  );

  always #5 clk = ~clk;

  initial begin
    repeat (5) @(posedge clk);
    rst = 1'b0;
    repeat (30) @(posedge clk);
    if (dut.counter == 24'h0) begin
      $fatal(1, "counter did not advance");
    end
    $display("SMOKE_SIM_PASS");
    $finish;
  end
endmodule
