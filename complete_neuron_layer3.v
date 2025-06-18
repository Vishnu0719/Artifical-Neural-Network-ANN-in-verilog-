// Layer 3

module nn_layer_3 #(parameter NUM_NEURONS = 10, data_width = 16, no_weights = 784, weight_int_width = 4)
(
 input clk,
 input rst,
 input [data_width-1:0] in,
 //input [data_width-1:0] weights,
 input [NUM_NEURONS-1:0][data_width-1:0] weights,

 input  [NUM_NEURONS-1:0][data_width-1:0] bias,
   

 output [NUM_NEURONS-1:0][data_width-1:0] layer3_out,
 output [NUM_NEURONS-1:0] o_valid
);

genvar i;

generate

for (i=0; i < NUM_NEURONS; i = i + 1) begin

  neuron #(.data_width(data_width), .no_weights(no_weights), .weight_int_width(weight_int_width))

layer1_neuron (

.clk(clk),
.rst(rst),
.in(in),
.weights(weights[i]),
.bias(bias[i]),
.out(layer3_out[i]),
.out_valid(o_valid[i])

);

end

endgenerate

endmodule


