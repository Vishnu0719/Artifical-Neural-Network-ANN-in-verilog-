// Required modules for the datapath

// multiplier


module mul #(parameter data_width = 16)
(
    input clk,
    input rst,
    input mul_en,
    input [data_width-1:0] in0, 
    input [data_width-1:0] in1,
    output reg [2*data_width-1:0] out
);

always @(posedge clk or posedge rst) begin

  if (rst) out <= 0;
  else if (mul_en) out <= $signed(in0) * $signed(in1);

end

endmodule


// accumulator


module acc_count #(parameter data_width = 16)
(
    input clk,
    input rst,
    input acc_en,
    input [2*data_width-1:0] in0,
    input [2*data_width-1:0] in1,
    output reg [2*data_width-1:0] sum
);

wire [2*data_width-1:0] sum_reg;

assign sum_reg = in0 + in1;

always @(posedge clk or posedge rst) begin

if (rst) sum <= 0;

else if (acc_en) begin
    

if ((in0[2*data_width-1] == in1[2*data_width-1]) && (sum_reg[2*data_width-1] != in0[2*data_width-1])) begin

   if (sum_reg[2*data_width-1]) sum <= {1'b0, {(2*data_width-1){1'b1}}}; // saturate to highest value (positive overflow (inputs are positive & o/p is -ve))

   else if (!sum_reg[2*data_width-1])  sum <= {1'b1, {(2*data_width-1){1'b0}}};  // saturate to lowest value (negative overflow (inputs are -ve & o/p is +ve)



end else sum <= sum_reg;

end 

end

endmodule 

// bias adder

module bias_add #(parameter data_width = 16)
(
    input clk,
    input rst,
    input bias_add_en,
    input [2*data_width-1:0] in0,
    input [2*data_width-1:0] in1,
    output reg [2*data_width-1:0] sum
);

wire [2*data_width-1:0] sum_reg;

assign sum_reg = in0 + in1;

always @(posedge clk or posedge rst) begin

if (rst) sum <= 0;

else if (bias_add_en) begin
    

if ((in0[2*data_width-1] == in1[2*data_width-1]) && (sum_reg[2*data_width-1] != in0[2*data_width-1])) begin

   if (sum_reg[2*data_width-1]) sum <= {1'b0, {(2*data_width-1){1'b1}}}; // saturate to highest value (positive overflow (inputs are positive & o/p is -ve))

   else if (!sum_reg[2*data_width-1])  sum <= {1'b1, {(2*data_width-1){1'b0}}};  // saturate to lowest value (negative overflow (inputs are -ve & o/p is +ve)

end else sum <= sum_reg;

end 

end

endmodule 

// ReLu activation

module relu #(parameter data_width=16, weight_int_width=4)
(
    input clk,
    input rst,
    input act_en,
    input   [2*data_width-1:0]   in,
    output  reg [data_width-1:0]  out
);

always @(posedge clk or posedge rst) begin
    if (rst) 
        out <= 0;
    else if (act_en) begin
        if ($signed(in) >= 0) begin
            if (|in[2*data_width-1 -: (weight_int_width+1)]) // Overflow to sign bit of integer part
                out <= {1'b0, {(data_width-1){1'b1}}}; // Positive saturate
            else
                out <= in[data_width-1:0]; // Ensure proper width
        end 
        else 
            out <= 0;      
    end
end

endmodule





// memories


// 1. weight memory

module weight_memory #(parameter num_weights = 784, 
                        parameter data_width = 16)
(
    input clk,
    input [data_width-1:0] w_in,
    input [$clog2(num_weights)-1:0] waddr,
    input [$clog2(num_weights)-1:0] raddr,
    input rd, 
    input wr,
    output reg [data_width-1:0] w_out
);

reg [data_width-1:0] mem [num_weights-1:0];

always @(posedge clk) begin
    if(wr) 
        mem[waddr] <= w_in;
    else if(rd) 
        w_out <= mem[raddr];
end

endmodule

// Input memory

module input_memory #(parameter num_inputs = 784, 
                        parameter data_width = 16)
(
    input clk,
    input [data_width-1:0] in,
    input [$clog2(num_inputs)-1:0] waddr,
    input [$clog2(num_inputs)-1:0] raddr,
    input rd, 
    input wr,
    output reg [data_width-1:0] out
);

reg [data_width-1:0] in_mem [num_inputs-1:0];

always @(posedge clk) begin
    if(wr) 
        in_mem[waddr] <= in;
    else if(rd) 
        out <= in_mem[raddr];
end

endmodule

//2. Bias register

module bias_reg #(parameter data_width = 16)
(
    input clk,
    input rst,
    input en,
    input [2*data_width-1:0] in,
    output reg [2*data_width-1:0] out
);

always @(posedge clk or posedge rst) begin
    if(rst) 
        out <= 0;
    else if (en) 
        out <= {in[data_width-1:0],{data_width{1'b0}}};
end

endmodule



// Neuron Datapath


module neuron #(parameter no_weights = 784, num_inputs = 784, data_width = 16, weight_int_width = 4)
(
    input clk,
    input rst,
    input [data_width-1:0] in,
    input [data_width-1:0] weights,
    input [2*data_width-1:0] bias,
    

    
    output [data_width-1:0] out, 
    output reg out_valid     
);

parameter address_width = $clog2(no_weights);

reg [$clog2(no_weights)+1:0] waddr;
reg [$clog2(no_weights)+1:0] raddr;
reg [data_width-1:0] w_in;

reg rd, wr;

reg in_rd, in_wr;

reg [$clog2(no_weights)+1:0] in_waddr;
reg [$clog2(no_weights)+1:0] in_raddr;



wire [data_width-1:0] mul_in;
wire [data_width-1:0] mul_input;
wire [2*data_width-1:0] mul_reg_out;
wire [2*data_width-1:0] acc_reg_out;
wire [2*data_width-1:0] bias_reg_out;
wire [2*data_width-1:0] biasadd_reg_out;
  
//wire count_done;
  //state machine outputs
  
    reg mul_en;
    reg acc_en;
    reg bias_add_en;
    reg act_en;
    reg bias_en;


  reg [$clog2(no_weights)+1:0] count;
  
reg signal_valid;
  

// writing in the memory

always @(posedge clk) begin
  
if(rst || waddr == no_weights - 1) waddr <= 0;


else if (wr) begin
 
    w_in <= weights;
    waddr <= waddr + 1;
    
end

end


//reading from the memory

always @(posedge clk) begin
if(rst || raddr == no_weights - 1) raddr <= 0;
else if (rd) raddr <= raddr + 1;
end

always @(posedge clk) begin
if(rst || in_raddr == no_weights - 1) in_raddr <= 0;
else if (in_rd) in_raddr <= in_raddr + 1;
end

always @(posedge clk) begin
  
if(rst || in_waddr == no_weights - 1) in_waddr <= 0;
  
else if (in_wr) in_waddr <= in_waddr + 1;

end



weight_memory #(.num_weights(no_weights), .data_width(data_width)) neuron_wm (
    .clk(clk),
    .w_in(weights),
    .waddr(waddr),
    .raddr(raddr),
    .rd(rd),
    .wr(wr),
    .w_out(mul_in)
);

input_memory #(.num_inputs(num_inputs), .data_width(data_width))
neuron_im(
    .clk(clk),
    .in(in),
    .waddr(in_waddr),
    .raddr(in_raddr),
    .rd(in_rd), 
    .wr(in_wr),
    .out(mul_input)
);


mul #(.data_width(data_width)) neuron_mul (
    .clk(clk),
    .rst(rst),
    .mul_en(mul_en),
    .in0(mul_input),
    .in1(mul_in),
    .out(mul_reg_out)
);

acc_count #(.data_width(data_width)) neuron_acc (
    .clk(clk),
    .rst(rst),
    .acc_en(acc_en),
    .in0(mul_reg_out),
    .in1(acc_reg_out),
    .sum(acc_reg_out)     
);

bias_add #(.data_width(data_width)) neuron_bias_add (
    .clk(clk),
    .rst(rst),
    .bias_add_en(bias_add_en),
    .in0(acc_reg_out),
    .in1(bias_reg_out),
    .sum(biasadd_reg_out)
);

relu #(.data_width(data_width), .weight_int_width(weight_int_width)) neuron_relu (
    .clk(clk),
    .rst(rst),
    .act_en(act_en),
    .in(biasadd_reg_out),
    .out(out)  
);

bias_reg #(.data_width(data_width)) neuron_bias_reg (
    .clk(clk),
    .rst(rst),
    .en(bias_en),
    .in(bias),
    .out(bias_reg_out)
);


// counter for accumulator

always @(posedge clk or posedge rst) begin

if (rst || (count == no_weights - 1)) count <= 0;
else if (acc_en) count <= count + 1'b1;

end



always @(posedge clk) begin

signal_valid <= out ? 1'b1 : 1'b0;
out_valid <= signal_valid;

end

// fsm state

reg [2:0] state_r, next_state;

parameter LOAD = 3'b000;
parameter READ = 3'b001;  
parameter MULTIPLY = 3'b010;
parameter ACCUMULATE = 3'b011;
parameter BIASADD = 3'b100;
parameter ACTIVATION = 3'b101;

reg done, next_done;

always @(posedge clk or posedge rst) begin

if(rst) begin
state_r <= LOAD;
done  <= 0;

end else begin
state_r <= next_state;
done <= next_done;

end
end

always @(*) begin



mul_en = 1'b0;
acc_en = 1'b0;
bias_add_en = 1'b0;
act_en = 1'b0;
bias_en = 1'b0;
rd = 1'b0;
wr = 1'b0;
in_wr = 1'b0;
in_rd = 1'b1;




next_state = state_r;
next_done =  done;

case(state_r)

LOAD: begin
            wr = 1'b1; 
            in_wr = 1'b1; 
            rd = 1'b0;  
            in_rd = 1'b0;
            bias_en = 1'b1;
            next_done = 1'b0;
            if (waddr == no_weights - 1) next_state = READ;  
            else next_state =  LOAD;
        end

READ: begin
            wr = 1'b0; 
            in_wr = 1'b0; 
            rd = 1'b1;
            in_rd = 1'b1; 
            next_state = MULTIPLY;  
        end

MULTIPLY: begin
 
          wr = 1'b0;
          rd = 1'b1;
          in_rd = 1'b1;

          mul_en = 1'b1;
          next_state = ACCUMULATE;
          
          end

ACCUMULATE: begin
          
            rd = 1'b1;

            mul_en = 1'b1;
         
            acc_en = 1'b1;
           
         if (count == no_weights - 1) next_state = BIASADD;
    
         else next_state = ACCUMULATE;

          end
        

BIASADD:  begin

          //bias_en = 1'b1;
          rd =  1'b0;

          bias_add_en = 1'b1;

          next_state = ACTIVATION;

          end



ACTIVATION:  begin

             act_en = 1'b1;
           
             
if (out_valid) begin
 
        next_done =  1'b1;
        next_state = LOAD;

end

 end

endcase

end

endmodule
