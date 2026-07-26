`timescale 1ns/1ps

module tb_isp_negative_filter();

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of tb_isp_negative_filter module section

//Declaring module parameters
	parameter 	int 	DATA_WIDTH 	= 8;
	parameter 	int 	CSR_WIDTH 	= 32;
	parameter 	int 	SYNC_RESET 	= 0;


//Declaring module singals
logic 				 			clk;
logic 				 			rst_n;
logic 	[DATA_WIDTH-1:0] 		in_stream_data;
logic 				 			in_valid_data;
logic 				 			in_first_data;
logic 				 			in_last_data;

logic 	[CSR_WIDTH-1:0] 		in_range_start_csr;
logic 	[CSR_WIDTH-1:0] 		in_range_finish_csr;
logic 	[CSR_WIDTH-1:0] 		in_mode_csr;

logic 	[DATA_WIDTH-1:0] 		out_stream_data;
logic 				 			out_valid_data;
logic 				 			out_first_data;
logic 				 			out_last_data;

//End of declaring local signals and parameters of tb_isp_negative_filter module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of instancing tb_isp_negative_filter module section

isp_negative_filter
#
(
	.DATA_WIDTH 	(DATA_WIDTH),
	.CSR_WIDTH 		(CSR_WIDTH),
	.SYNC_RESET 	(SYNC_RESET)
)


i_isp_negative_filter
(
	.clk 					(clk),
	.rst_n 					(rst_n),
	.in_stream_data 		(in_stream_data),
	.in_valid_data 			(in_valid_data),
	.in_first_data 			(in_first_data),
	.in_last_data 			(in_last_data),
	.in_range_start_csr 	(in_range_start_csr),
	.in_range_finish_csr 	(in_range_finish_csr),
	.in_mode_csr 			(in_mode_csr),
	.out_stream_data 		(out_stream_data),
	.out_valid_data 		(out_valid_data),
	.out_first_data 		(out_first_data),
	.out_last_data 			(out_last_data)

);
//End of instancing tb_isp_negative_filter module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of generatring clk clock section

initial
begin : clk_generation_process
	clk = 0;
	forever #10 clk=~clk;
end

//End of generatring clk clock section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of generating main scenario section

initial
begin : main
	rst_n = '0;
	in_stream_data = '0;
	in_valid_data = '0;
	in_first_data = '0;
	in_last_data = '0;

	#100ns rst_n = '1;

	
end

//End of generating main scenario section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
endmodule
