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
logic 	[CSR_WIDTH-1:0] 		in_mode_csr = '0;

logic 	[DATA_WIDTH-1:0] 		out_stream_data;
logic 				 			out_valid_data;
logic 				 			out_first_data;
logic 				 			out_last_data;

//File related info
parameter 	COLNUM		 =   640                	;
parameter 	LINNUM		 =   512                	;
parameter   TOTAL_BYTES  =   COLNUM * LINNUM    	;  

string 		filename                        		;
int    		last_slash_pos                  		;
int    		last_dot_pos                    		;
string   	output_file_path                        ;
int      	result_fd                               ;

string result_pathes_template  = "../../../../../../../isp_negative_filter/results/640_512";

byte file_data_queue_r[$];
string 	original_images_paths[];
assign original_images_paths =     {
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/tank_shooting_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/abstract_gradient_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/checker_board_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/colorful_flowers_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/flowers_and_book_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/japanese_racing_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/Lenna_(test_image)_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/mosaic_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/mountain_640_512.data",
                            			"../../../../../../../isp_python_image_converter/converted_images/640_512/powerplant_640_512.data"
                        			};



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
task read_file(input string file_path);
    string path_to_the_file_r;
    int file_descriptor_r;

    path_to_the_file_r = file_path;
    file_descriptor_r = $fopen(path_to_the_file_r, "rb");

    if (file_descriptor_r == 0) begin
        $error("Failed to read files");
        $finish;
    end

    file_data_queue_r.delete();

    for (int i=0; i<TOTAL_BYTES; ++i) begin
        file_data_queue_r.push_back(byte'($fgetc(file_descriptor_r)));
    end

    $fclose(file_descriptor_r);
endtask
//End of reading file section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of send line task section
task send_one_line();
    for (int i=0; i<COLNUM; ++i) begin
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

	#100ns rst_n = '1;

	foreach (original_images_paths[i]) begin
		last_slash_pos = -1;
        last_dot_pos = -1;

		// Manual search for last slash
      	for (int j = 0; j < original_images_paths[i].len(); j++) begin
      	    if (original_images_paths[i][j] == "/") begin
      	        last_slash_pos = j;
      	    end
      	end

      	for (int j = 0; j < original_images_paths[i].len(); j++) begin
      	    if (original_images_paths[i][j] == ".") begin
      	        last_dot_pos = j;
      	    end
      	end

		if (last_slash_pos == -1) begin
       	    $error("Failed to parse filename");
       	    $finish();
       	end

		$display("Found slash at %d", last_slash_pos);
      	if (last_slash_pos != -1) begin
      	    filename = original_images_paths[i].substr(last_slash_pos + 1, last_dot_pos-1);
      	end
      	else begin
      	    filename = original_images_paths[i];
      	end

		output_file_path = $sformatf("%s/%s.data", result_pathes_template, filename);

		$display("Current file input path is %s", original_images_paths[i]);
      	$display("Current file name is %s", filename);
      	$display("Current file output path is %s", output_file_path);

      	result_fd  = $fopen(output_file_path, "wb");
      	read_file(original_images_paths[i]);

		repeat(100) @(posedge clk);
        for (int i=0; i<LINNUM; ++i) begin
            send_one_line();
            repeat(100) @(posedge clk);
        end

		$fclose(result_fd);
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
