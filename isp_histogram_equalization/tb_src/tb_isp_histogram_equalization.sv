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

//TB related signals
logic 									is_writing_file;

//File related info

string 		filename                        		;
int    		last_slash_pos                  		;
int    		last_dot_pos                    		;
string   	output_file_path                        ;
int      	result_fd                               ;

string result_pathes_template ="../../../../../../../isp_histogram_equalization/results/";
string current_output_dir;

int allowed_resolutions[4][2] = 	'{
										'{640, 		480 	},
										'{640, 		512 	},
										'{1280, 	720		},
										'{1920, 	1080 	}
									};

int current_width, current_height, current_total_bytes;
string current_width_str, current_height_str;

byte file_data_queue_r[$];
string current_original_name;
string 	original_images_names_templates[];
assign original_images_names_templates =     {
												"tank_shooting_",
												"abstract_gradient_",
												"checker_board_",
												"colorful_flowers_",
												"flowers_and_book_",
												"japanese_racing_",
												"Lenna_(test_image)_",
												"mosaic_",
												"mountain_",
												"powerplant_"
                        					};
string input_files_path_template = "../../../../../../../isp_python_image_converter/converted_images/";

//End of declaring local signals and parameters of tb_isp_histogram_equalization module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of function to calculate clog2 of the number depth
function integer clogb2;
    input integer number;
      for (clogb2 = 0; number > 0; clogb2 = clogb2 + 1)
        number = number >> 1;
  endfunction
//End of function to calculate clog2 of the number depth
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
//Begin of reading file section
task read_file(input string file_path, input int total_bytes);
    string path_to_the_file_r;
    int file_descriptor_r;

    path_to_the_file_r = file_path;
    file_descriptor_r = $fopen(path_to_the_file_r, "rb");

    if (file_descriptor_r == 0) begin
        $error("Failed to read files");
        $finish;
    end

    file_data_queue_r.delete();

    for (int i=0; i<total_bytes; ++i) begin
        file_data_queue_r.push_back(byte'($fgetc(file_descriptor_r)));
    end

    $fclose(file_descriptor_r);
endtask
//End of reading file section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of send line task section
task send_one_line(input int current_width);
    for (int i=0; i<current_width; ++i) begin
        @(negedge clk);
        in_valid_data 	<= '1;
        in_stream_data 	<= file_data_queue_r.pop_front();

		if (i == 0) begin
			in_first_data <= '1;
		end
		else begin
			in_first_data <= '0;
		end

		if (i == current_width - 1) begin
			in_last_data <= '1;
		end
		else begin
			in_last_data <= '0;
		end
    end
    
    @(negedge clk);
    in_valid_data <= '0;
	in_first_data <= '0;
	in_last_data <= '0;
endtask
//End of send line task section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of generatring main scenario section
initial begin
	rst_n = '0;
	in_stream_data = '0;
	in_valid_data = '0;
	in_first_data = '0;
	in_last_data = '0;

	bypass_mode = '0;

	in_frame_start = '0;
	in_requested_image_width = '0;
	in_requested_image_height = '0;

	is_writing_file = '0;

	#100ns rst_n = '1;

	foreach (allowed_resolutions[i]) begin
		$display("========================");
		current_width = allowed_resolutions[i][0];
		current_height = allowed_resolutions[i][1];
		current_total_bytes = current_width * current_height;

		in_requested_image_width  = current_width;
		in_requested_image_height = current_height;

		current_width_str = $sformatf("%0d", current_width);
		current_height_str = $sformatf("%0d", current_height);

		foreach (original_images_names_templates[j]) begin
			$display("current original name is");
			$display(original_images_names_templates[j]);

			current_original_name = $sformatf("%s%s_%s/%s%s_%s.data", input_files_path_template, current_width_str, current_height_str, 
																				original_images_names_templates[j], current_width_str, current_height_str);
			$display("current original name is");
			$display(current_original_name);

			current_output_dir = $sformatf("%s%s_%s/%s%s_%s_.data", result_pathes_template, current_width_str, current_height_str,
								original_images_names_templates[j], current_width_str, current_height_str);

			$display("current output name is");
			$display(current_output_dir);

			result_fd  = $fopen(current_output_dir, "wb");
			read_file(current_original_name, current_total_bytes);

			repeat(100) @(posedge clk);
			in_frame_start <= '1;
			repeat(100) @(posedge clk);
			in_frame_start <= '0;
			repeat(500) @(posedge clk);
			for (int i=0; i<current_height; ++i) begin
				send_one_line(current_width);
				repeat(100) @(posedge clk);
			end
			repeat(300) @(posedge clk);
			is_writing_file <= '1;

			read_file(current_original_name, current_total_bytes);
			repeat(100) @(posedge clk);
			in_frame_start <= '1;
			repeat(100) @(posedge clk);
			in_frame_start <= '0;
			repeat(500) @(posedge clk);
			for (int i=0; i<current_height; ++i) begin
				send_one_line(current_width);
				repeat(100) @(posedge clk);
			end

			is_writing_file <= '0;

			$fclose(result_fd);
			$display("========================");
		end
	end
	$finish();
end
//End of generatring main scenario section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of file writing section
initial begin
    while(1) begin
        @(posedge clk);
        if((out_valid_data)&&(is_writing_file)) begin
            $fwrite(result_fd, "%c", out_stream_data);
        end
    end
end
//End of file writing section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of test info analyse section
int test_counter;
initial begin
	while (1) begin
		@(posedge clk) begin
			if(in_frame_start)begin
				test_counter <= '0;
			end
			else if (isp_histogram_equalization_i.cdf_numerator_calculation_flag) begin
				test_counter <= test_counter + isp_histogram_equalization_i.recalc_numerator;
			end
		end
	end
end


//End of test info analyse section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
endmodule
