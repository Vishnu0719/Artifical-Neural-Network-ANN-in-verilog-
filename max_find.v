module max_find #(parameter no_neurons = 10, data_width = 16)
(
 input clk,
 input [(no_neurons*data_width)-1:0] in,
 input in_valid,
 output reg [31:0] out,
 output reg out_valid
);


reg [data_width-1:0] max_reg;
reg [(no_neurons*data_width)-1:0] data_reg;
integer count;

reg [1:0] state_r;

parameter START = 2'b00;
parameter COMPUTE = 2'b01;
parameter END  = 2'b10;

always @(posedge clk) begin

out_valid <= 1'b0;

case(state_r)

START: begin 

if (in_valid) begin

max_reg <= in[data_width-1:0];
count <= 1'b1;
data_reg <= in;
out <= 0;

end

if (count != 0) state_r <= COMPUTE;

end

COMPUTE: begin

count <= count + 1'b1;

if (data_reg [count*data_width+:data_width] > max_reg) begin

 max_reg <= data_reg [count*data_width+:data_width];

 out <= count;

end

if (count == no_neurons) state_r <= END;

else state_r <= COMPUTE;

end

END: begin

 count <= 0;
 out_valid <= 1'b1;

 end
endcase
end
endmodule

