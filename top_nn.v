

`include "include.v"

module nn #(parameter weight_int_width = 4, data_width = 16)

(
 input clk,
 input rst,
 input [data_width-1:0] in,
 input [data_width-1:0] weights,
 input [2*data_width-1:0] bias,
    

 
output out,
output valid_out

);

wire [`layer1_neurons-1:0] valid_out_1;
wire [`layer1_neurons*`data_width-1:0] out1;
reg  [`layer1_neurons*`data_width-1:0] reg_1;
reg [`data_width-1:0] sr_out1;
reg sr_out1_valid;


nn_layer_1 #(.NUM_NEURONS(`layer1_neurons), .data_width(`data_width), .no_weights(`layer1_weights), .weight_int_width(weight_int_width))

 layer1 (

 .clk(clk),
 .rst(rst),
 .in(in),
 .weights(weights),
 .bias(bias),
 .out(out1),
 .valid_out(valid_out_1)
);


reg state1;

integer  count1;

parameter START = 'd0;
parameter COMPUTE = 'd1;

always @(posedge clk) begin

if(rst) begin

state1 <= START;
count1 <= 0;

sr_out1_valid <= 0;

end


else begin

case (state1)

START: begin


 count1 <= 0;
 sr_out1_valid <= 0;

 if(valid_out_1[0] == 1'b1) begin

  reg_1 <= out1;
  state1 <= COMPUTE;
end

end

COMPUTE: begin

 
sr_out1 <= reg_1[`data_width-1:0];
reg_1 <= reg_1 >> `data_width;
count1 <= count1 + 1'b1;
sr_out1_valid <= 1;

if(count1 == `layer1_neurons) begin

state1 <= START;
sr_out1_valid <= 0;

end

end

endcase

end 

end


wire [`layer2_neurons-1:0] valid_out_2;
wire [`layer2_neurons*`data_width-1:0] out2;
reg  [`layer2_neurons*`data_width-1:0] reg_2;
reg [`data_width-1:0] sr_out2;
reg sr_out2_valid;



nn_layer_2 #(.NUM_NEURONS(`layer2_neurons), .data_width(`data_width), .no_weights(`layer2_weights), .weight_int_width(weight_int_width))

 layer2 (

 .clk(clk),
 .rst(rst),
 .in(sr_out1),
 .weights(weights),
 .bias(bias),
 .out(out2),
 .valid_out(valid_out_2)
);




reg state2, count2;



always @(posedge clk) begin

if(rst) begin

state2 <= START;
count2 <= 0;

sr_out2_valid <= 0;

end



else begin

case (state2)

START: begin


 count2 <= 0;
 sr_out2_valid <= 0;

 if(valid_out_2[0] == 1'b1) begin

  reg_2 <= out2;
  state2 <= COMPUTE;
end
end

COMPUTE: begin

 
sr_out2 <= reg_2[`data_width-1:0];
reg_2 <= reg_2 >> `data_width;
count2 <= count2 + 1'b1;
sr_out2_valid <= 1;

if(count2 == `layer2_neurons) begin

state2 <= START;
sr_out2_valid <= 0;

end

end

endcase

end 

end


wire [`layer3_neurons-1:0] valid_out_3;
wire [`layer3_neurons*`data_width-1:0] out3;
reg  [`layer3_neurons*`data_width-1:0] reg_3;
reg [`data_width-1:0] sr_out3;
reg sr_out3_valid;

nn_layer_3 #(.NUM_NEURONS(`layer3_neurons), .data_width(`data_width), .no_weights(`layer3_weights), .weight_int_width(weight_int_width))

 layer3 (

 .clk(clk),
 .rst(rst),
 .in(sr_out2),
 .weights(weights),
 .bias(bias),
 .out(out3),
 .valid_out(valid_out_3)
);


reg state3, count3;



always @(posedge clk) begin

if(rst) begin

state3 <= START;
count3 <= 0;

sr_out3_valid <= 0;

end



else begin

case (state3)

START: begin


 count3 <= 0;
 sr_out3_valid <= 0;

 if(valid_out_3[0] == 1'b1) begin

  reg_3 <= out3;
  state3 <= COMPUTE;
end

end
COMPUTE: begin

 
sr_out3 <= reg_3[`data_width-1:0];
reg_3 <= reg_3 >> `data_width;
count3 <= count3 + 1'b1;
sr_out3_valid <= 1;

if(count3 == `layer3_neurons) begin

state3 <= START;
sr_out3_valid <= 0;

end

end

endcase

end 

end

 max_find #(.no_neurons(`layer3_neurons),  .data_width(`data_width))

nn_mf
(
 .clk(clk),
 .in(out3),
 .in_valid(valid_out_3),
 .out(out),
 .out_valid(valid_out)
);



endmodule
























    

 
 


