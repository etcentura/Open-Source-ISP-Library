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

logic 	[CSR_WIDTH-1:0] 		in_range_start_csr = 64;
logic 	[CSR_WIDTH-1:0] 		in_range_finish_csr = 128;
logic 	[CSR_WIDTH-1:0] 		in_mode_csr;

logic 	[DATA_WIDTH-1:0] 		out_stream_data;
logic 				 			out_valid_data;
logic 				 			out_first_data;
logic 				 			out_last_data;

//File related info

string 		filename                        		;
int    		last_slash_pos                  		;
int    		last_dot_pos                    		;
string   	output_file_path                        ;
int      	result_fd                               ;

string result_pathes_template ="../../../../../../../isp_image_cutter/results/";
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
    end
    
    @(negedge clk);
    in_valid_data <= '0;
endtask
//End of send line task section
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

	in_mode_csr = '0;

	#100ns rst_n = '1;

	for (int enable_range_mode = 0; enable_range_mode < 2; enable_range_mode++)
		begin
			in_mode_csr[1] = enable_range_mode;
			for (int enable_iside_range = 0; enable_iside_range < 2; enable_iside_range++) begin
				in_mode_csr[2] = enable_iside_range && in_mode_csr[1];
				foreach (allowed_resolutions[i]) begin
					current_width = allowed_resolutions[i][0];
					current_height = allowed_resolutions[i][1];
					current_total_bytes = current_width * current_height;

					current_width_str = $sformatf("%0d", current_width);
					current_height_str = $sformatf("%0d", current_height); 

					foreach (original_images_names_templates[j]) begin
						$display("current original name is");
						$display(original_images_names_templates[j]);
						$display("current in_mode_csr[0] is");
						$display(in_mode_csr[0]);
						$display("current in_mode_csr[1] is");
						$display(in_mode_csr[1]);

						current_original_name = $sformatf("%s%s_%s/%s%s_%s.data", input_files_path_template, current_width_str, current_height_str, 
																					original_images_names_templates[j], current_width_str, current_height_str);
						$display("current original name is");
						$display(current_original_name);
						

						if(in_mode_csr[1]) begin
							if(in_mode_csr[2]) begin
								current_output_dir = $sformatf("%s%s_%s/%s%s_%s_ranged_inside.data", result_pathes_template, current_width_str, current_height_str,
																	original_images_names_templates[j], current_width_str, current_height_str);
							end
							else begin
								current_output_dir = $sformatf("%s%s_%s/%s%s_%s_ranged_outside.data", result_pathes_template, current_width_str, current_height_str,
																	original_images_names_templates[j], current_width_str, current_height_str);
							end
						end
						else begin
							current_output_dir = $sformatf("%s%s_%s/%s%s_%s.data", result_pathes_template, current_width_str, current_height_str,
																	original_images_names_templates[j], current_width_str, current_height_str);
						end
						$display("current output name is");
						$display(current_output_dir);

						result_fd  = $fopen(current_output_dir, "wb");
						read_file(current_original_name, current_total_bytes);

						repeat(100) @(posedge clk);
						for (int i=0; i<current_height; ++i) begin
							send_one_line(current_width);
							repeat(100) @(posedge clk);
						end

						$fclose(result_fd);
					end
				end	
			end
		end

	
	$finish();
end
//End of generating main scenario section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of file writing section
initial begin
    while(1) begin
        @(posedge clk);
        if (out_valid_data) begin
            $fwrite(result_fd, "%c", out_stream_data);
        end
    end
end
//End of file writing section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
endmodule
