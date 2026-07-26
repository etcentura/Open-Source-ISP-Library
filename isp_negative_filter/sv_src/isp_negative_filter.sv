module isp_negative_filter
#
(
	parameter 	int 	DATA_WIDTH 	= 8,
	parameter 	int 	CSR_WIDTH 	= 32,
	parameter 	int 	SYNC_RESET 	= 0
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

	input 	logic 	[CSR_WIDTH-1:0] 		in_range_start_csr,
	input 	logic 	[CSR_WIDTH-1:0] 		in_range_finish_csr,
	input 	logic 	[CSR_WIDTH-1:0] 		in_mode_csr,

	//Output signals signals declaration
	output 	logic 	[DATA_WIDTH-1:0] 		out_stream_data,
	output 	logic 				 			out_valid_data,
	output 	logic 				 			out_first_data,
	output 	logic 				 			out_last_data

);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of csr mode register description section
/*
in_mode_csr register bits
0 		- enable bypass mode: 	0 - DIS, 		1 - EN
1 		- enable range mode: 	0 - DIS, 		1 - EN
2 		- select range mode: 	0 - outside, 	1 - inside (only if in_mode_csr[1] is 1)
31:3 	- reserved
*/
//End of csr mode register description section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of isp_negative_filter's module section

//Declaring local parameters

localparam 	int 	MAX_PIX_VALUE 	= 2**DATA_WIDTH-1;

//Declaring local signals
logic 							is_bypass_mode_enabled;
logic 							is_range_mode_enabled;
logic 							is_range_inside_check;

logic 	[DATA_WIDTH-1:0] 		latch_stream_data;
logic 				 			latch_valid_data;
logic 				 			latch_first_data;
logic 				 			latch_last_data;

logic 	[DATA_WIDTH-1:0] 		result_stream_data;
logic 				 			result_valid_data;
logic 				 			result_first_data;
logic 				 			result_last_data;


//End of declaring local signals and parameters of isp_negative_filter's module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of parsing csr bits section

always_comb
begin
	is_bypass_mode_enabled 	= in_mode_csr[0];
	is_range_mode_enabled 	= in_mode_csr[1];
	is_range_inside_check 	= in_mode_csr[2];
end

//End of parsing csr bits section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of latching input data section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			latch_stream_data 	<= '0;
			latch_valid_data 	<= '0;
			latch_first_data 	<= '0;
			latch_last_data 	<= '0;
		end
	else
		begin
			latch_stream_data 	<= in_stream_data;
			latch_valid_data 	<= in_valid_data;
			latch_first_data 	<= in_first_data;
			latch_last_data 	<= in_last_data;
		end
end
//End of latching input data section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving range selection section
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

			if(is_range_mode_enabled) begin
				if (is_range_inside_check) begin
					if ((latch_stream_data >= in_range_start_csr) && (latch_stream_data <= in_range_finish_csr)) begin
						result_stream_data 	<= MAX_PIX_VALUE - latch_stream_data;
					end else begin
						result_stream_data 	<= latch_stream_data;
					end
				end else begin
					if ((latch_stream_data <= in_range_start_csr) || (latch_stream_data >= in_range_finish_csr)) begin
						result_stream_data 	<= MAX_PIX_VALUE - latch_stream_data;
						
					end else begin
						result_stream_data 	<= latch_stream_data;
					end
				end
			end
			else begin
				result_stream_data 	<= MAX_PIX_VALUE - latch_stream_data;
			end
		end
end
//End of driving range selection section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving bypass mode section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			out_stream_data <= '0;
			out_valid_data 	<= '0;
			out_first_data 	<= '0;
			out_last_data 	<= '0;
		end
	else
		begin
			if (is_bypass_mode_enabled) begin
				out_stream_data <= latch_stream_data;
				out_valid_data 	<= latch_valid_data;
				out_first_data 	<= latch_first_data;
				out_last_data 	<= latch_last_data;
			end
			else begin
				out_stream_data <= result_stream_data;
				out_valid_data 	<= result_valid_data;
				out_first_data 	<= result_first_data;
				out_last_data 	<= result_last_data;
			end
		end
end
//End of driving bypass mode section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
endmodule
