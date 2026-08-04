`timescale 1ns/1ps

module tb_isp_histogram_equalization();

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of tb_isp_histogram_equalization module section

//Declaring module parameters
parameter 	int 	DATA_WIDTH 			= 8;
parameter 	int 	MAX_IMAGE_WIDTH 	= 1920;
parameter 	int 	MAX_IMAGE_HEIGHT 	= 1080;


//Basic signals declaration
logic 				 					clk;
logic 				 					rst_n;

//Input signals signals declaration
logic 	[DATA_WIDTH-1:0] 				in_stream_data;
logic 				 					in_valid_data;
logic 				 					in_first_data;
logic 				 					in_last_data;
logic 				 					bypass_mode;

logic 				 					in_frame_start;
logic 	[clogb2(MAX_IMAGE_WIDTH)-1:0] 	in_requested_image_width;
logic 	[clogb2(MAX_IMAGE_HEIGHT)-1:0] 	in_requested_image_height;

//Output signals signals declaration
logic 	[DATA_WIDTH-1:0] 				out_stream_data;
logic 				 					out_valid_data;
logic 				 					out_first_data;
logic 				 					out_last_data;

//End of declaring local signals and parameters of tb_isp_histogram_equalization module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of instancing tb_isp_histogram_equalization module section

isp_histogram_equalization 
#
(
	.DATA_WIDTH 				(DATA_WIDTH 	 				),
	.MAX_IMAGE_WIDTH 			(MAX_IMAGE_WIDTH  				),
	.MAX_IMAGE_HEIGHT 			(MAX_IMAGE_HEIGHT 				)
)
								isp_histogram_equalization_i					
(
	//Basic signals declaration
	.clk 						(clk  							),
	.rst_n 						(rst_n 							),

	//Input signals signals declaration
	.in_stream_data 			(in_stream_data  				),
	.in_valid_data 				(in_valid_data 	 				),
	.in_first_data 				(in_first_data 	 				),
	.in_last_data 				(in_last_data 	 				),
	.bypass_mode 				(bypass_mode 	 				),

	.in_frame_start 			(in_frame_start 		 		),
	.in_requested_image_width 	(in_requested_image_width  		),
	.in_requested_image_height	(in_requested_image_height 		),

	//Output signals signals declaration
	.out_stream_data 			(out_stream_data 				),
	.out_valid_data 			(out_valid_data  				),
	.out_first_data 			(out_first_data  				),
	.out_last_data				(out_last_data	 				)

);
//End of instancing tb_isp_histogram_equalization module section
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
//Begin of generatring main scenario section

//End of generatring main scenario section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

endmodule
