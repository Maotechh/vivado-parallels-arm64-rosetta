module led_counter (
  input wire clk,
  input wire rst,
  output reg [3:0] led
);
  reg [23:0] counter = 24'h0;

  always @(posedge clk) begin
    if (rst) begin
      counter <= 24'h0;
      led <= 4'h0;
    end else begin
      counter <= counter + 24'h1;
      led <= counter[23:20];
    end
  end
endmodule
