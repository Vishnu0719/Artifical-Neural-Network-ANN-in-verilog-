

// Layer 1

module nn_layer_1 #(parameter NUM_NEURONS = 30, data_width = 16, no_weights = 784, weight_int_width = 4)
(
 input clk,
 input rst,
 input [data_width-1:0] in,
 input [data_width-1:0] weights,
 input [2*data_width-1:0] bias,
    

 output [NUM_NEURONS-1:0][data_width-1:0] out,
 output valid_out
);

wire [NUM_NEURONS-1:0] out_valid;

genvar i;

generate

for (i=0; i < NUM_NEURONS; i = i + 1) begin

  neuron #(.data_width(data_width), .no_weights(no_weights), .weight_int_width(weight_int_width))

layer1_neuron (

.clk(clk),
.rst(rst),
.in(in[i]),
.weights(weights),
.bias(bias),
.out(out[i]),
.valid_out(out_valid[i])

);

end

endgenerate

assign valid_out = (out_valid == (2 ** NUM_NEURONS) - 1) ? 1 : 0;

endmodule


