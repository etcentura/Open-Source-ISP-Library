module isp_cutter_correction_wrapper
#
(
	parameter 	int 	DATA_WIDTH 	= 8,
	parameter 	int 	CSR_WIDTH 	= 32
)

(
	//Basic signals declaration
	input 	logic 				 			clk,
	input 	logic 				 			rst_n,

	//Input signals signals declaration
	input 	logic 	[DATA_WIDTH-1:0] 		in_stream_data,
	input 	logic 				 			in_valid_data,
	input 	logic 				 			in_first_data,
	input 	logic 				 			in_last_data,
	input 	logic 				 			bypass_mode,

	input 	logic 	[CSR_WIDTH-1:0] 		in_range_cut_start_value,
	input 	logic 	[CSR_WIDTH-1:0] 		in_range_cut_finish_value,
	input 	logic 	[CSR_WIDTH-1:0] 		in_range_clipping_value,
	input 	logic 				 			in_untouched_pixels_bypass,
	input 	logic 	[CSR_WIDTH-1:0] 		in_untouched_pixels_value,

	//Output signals signals declaration
	output 	logic 	[DATA_WIDTH-1:0] 		out_stream_data,
	output 	logic 				 			out_valid_data,
	output 	logic 				 			out_first_data,
	output 	logic 				 			out_last_data

);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of isp_cutter_correction_wrapper's module section

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


//End of declaring local signals and parameters of isp_cutter_correction_wrapper's module section
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
//Begin of result data nad signals driving section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			result_stream_data 	<= '0;
			result_valid_data 	<= '0;
			result_first_data 	<= '0;
			result_last_data 	<= '0;
		end
	else
		begin
			result_valid_data 	<= latch_valid_data;
			result_first_data 	<= latch_first_data;
			result_last_data 	<= latch_last_data;

			if((latch_stream_data >= in_range_cut_start_value) && (latch_stream_data <= in_range_cut_finish_value)) begin
				result_stream_data 	<= in_range_clipping_value;
			end
			else begin
				if (in_untouched_pixels_bypass) begin
					result_stream_data 	<= latch_stream_data;
				end else begin
					result_stream_data 	<= in_untouched_pixels_value;
				end
			end
		end
end
//End of result data nad signals driving section
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
			if(bypass_mode) begin
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
