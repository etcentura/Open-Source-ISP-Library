module isp_universal_programmable_lut
#
(
	parameter 	int 	DATA_WIDTH 	= 8
)

(
	//Basic signals declaration
	input 	logic 				 	clk,
	input 	logic 				 	rst_n,

	//Input signals signals declaration
	input 	logic 	[DATA_WIDTH-1:0] 		in_stream_data,
	input 	logic 				 			in_valid_data,
	input 	logic 				 			in_first_data,
	input 	logic 				 			in_last_data,
	input 	logic 				 			in_bypass_mode,

	input 	logic 	[DATA_WIDTH-1:0] 		in_pixel_addr,
	input 	logic 	[DATA_WIDTH-1:0] 		in_pixel_value,
	input 	logic 	[DATA_WIDTH-1:0] 		in_pixel_rewrite,

	//Output signals signals declaration
	output 	logic 	[DATA_WIDTH-1:0] 		out_stream_data,
	output 	logic 				 			out_valid_data,
	output 	logic 				 			out_first_data,
	output 	logic 				 			out_last_data

);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of isp_universal_programmable_lut's module section

//Declaring local parameters

localparam 	int 	MAX_PIX_VALUE 	= 2**DATA_WIDTH-1;

//Declaring local signals

logic 	[DATA_WIDTH-1:0] 		latch_stream_data;
logic 				 			latch_valid_data;
logic 				 			latch_first_data;
logic 				 			latch_last_data;

logic 	[DATA_WIDTH-1:0] 		result_stream_data;
logic 				 			result_valid_data;
logic 				 			result_first_data;
logic 				 			result_last_data;

//Lut registers storage
logic 	[DATA_WIDTH-1:0] 		pixel_lut_storage[2**DATA_WIDTH];
//End of declaring local signals and parameters of isp_universal_programmable_lut's module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving input data and valids latching section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			latch_stream_data  	<= '0;
			latch_valid_data  	<= '0;
			latch_first_data  	<= '0;
			latch_last_data  	<= '0;
		end
	else
		begin
			latch_stream_data  	<= in_stream_data;
			latch_valid_data  	<= in_valid_data;
			latch_first_data  	<= in_first_data;
			latch_last_data  	<= in_last_data;
		end
end
//End of driving input data and valids latching section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving lut storage section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for (int lut_idx = 0; lut_idx < 2**DATA_WIDTH; lut_idx++) begin
				pixel_lut_storage[lut_idx] <= lut_idx;
			end
		end
	else
		begin
			if(in_pixel_rewrite)begin
				pixel_lut_storage[in_pixel_addr] <= in_pixel_value;
			end
		end
end
//End of driving lut storage section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving result register data section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			result_stream_data <= '0;
			result_valid_data <= '0;
			result_first_data <= '0;
			result_last_data <= '0;
		end
	else
		begin
			result_valid_data <= latch_valid_data;
			result_first_data <= latch_first_data;
			result_last_data <= latch_last_data;

			if (latch_valid_data) begin
				result_stream_data <= pixel_lut_storage[latch_stream_data];
			end
			
		end
end
//End of driving result register data section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of output data and signals driving section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			out_stream_data 	<= '0;
			out_valid_data 		<= '0;
			out_first_data 		<= '0;
			out_last_data 		<= '0;
		end
	else
		begin
			if(in_bypass_mode) begin
				out_stream_data 	<= latch_stream_data;
				out_valid_data 		<= latch_valid_data;
				out_first_data 		<= latch_first_data;
				out_last_data 		<= latch_last_data;
			end
			else begin
				out_stream_data 	<= result_stream_data;
				out_valid_data 		<= result_valid_data;
				out_first_data 		<= result_first_data;
				out_last_data 		<= result_last_data;
			end
			
		end
end
//End of output data and signals driving section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

endmodule
