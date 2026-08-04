module isp_histogram_equalization
#
(
	parameter 	int 	DATA_WIDTH 			= 8,
	parameter 	int 	MAX_IMAGE_WIDTH 	= 8,
	parameter 	int 	MAX_IMAGE_HEIGHT 	= 8

)

(
	//Basic signals declaration
	input 	logic 				 					clk,
	input 	logic 				 					rst_n,

	//Input signals signals declaration
	input 	logic 	[DATA_WIDTH-1:0] 				in_stream_data,
	input 	logic 				 					in_valid_data,
	input 	logic 				 					in_first_data,
	input 	logic 				 					in_last_data,
	input 	logic 				 					bypass_mode,

	input 	logic 				 					in_frame_start,

	input 	logic 	[clogb2(MAX_IMAGE_WIDTH)-1:0] 	in_requested_image_width,
	input 	logic 	[clogb2(MAX_IMAGE_HEIGHT)-1:0] 	in_requested_image_height,

	//Output signals signals declaration
	output 	logic 	[DATA_WIDTH-1:0] 				out_stream_data,
	output 	logic 				 					out_valid_data,
	output 	logic 				 					out_first_data,
	output 	logic 				 					out_last_data

);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of function to calculate the address width based on specified RAM depth
function integer clogb2;
    input integer number;
      for (clogb2 = 0; number > 0; clogb2 = clogb2 + 1)
        number = number >> 1;
  endfunction
//End of function to calculate the address width based on specified RAM depth
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of isp_histogram_equalization's module section

//Declaring local parameters

localparam 	int 	MAX_PIX_VALUE 		= 2**DATA_WIDTH-1;
localparam 	int 	TOTAL_PIXELS 		= MAX_IMAGE_WIDTH*MAX_IMAGE_HEIGHT;
localparam 	int 	PIXELS_SUM_WIDTH 	= clogb2(TOTAL_PIXELS);

//Counters to spectate current row
logic 	[clogb2(MAX_IMAGE_WIDTH)-1:0]  					counter_current_col;
logic 	[clogb2(MAX_IMAGE_HEIGHT)-1:0] 					counter_current_row;

//Declaring local signals
logic 	[DATA_WIDTH-1:0] 								latch_stream_data;
logic 				 									latch_valid_data;
logic 				 									latch_first_data;
logic 				 									latch_last_data;

//Delay signals to get data from the second ram
logic 													latch_valid_data_d_0;
logic 													latch_first_data_d_0;
logic 													latch_last_data_d_0;

logic 													latch_valid_data_d_1;
logic 													latch_first_data_d_1;
logic 													latch_last_data_d_1;

//Resulting data from the second ram
logic 	[DATA_WIDTH-1:0] 								result_stream_data_from_ram;
logic 	[DATA_WIDTH-1:0] 								result_stream_data;
logic 				 									result_valid_data;
logic 				 									result_first_data;
logic 				 									result_last_data;

//Delay singals
logic 	[DATA_WIDTH-1:0] 								latch_stream_data_d_0;
logic 				 									latch_valid_data_d_0;

logic 	[DATA_WIDTH-1:0] 								latch_stream_data_d_1;
logic 				 									latch_valid_data_d_1;

//Add one singnals
logic 	[DATA_WIDTH-1:0] 								addone_ram_address;
logic 				 									addone_ram_write_flag;
logic 	[PIXELS_SUM_WIDTH-1:0]							addone_cumulative_hist_val;

//RAM related singals
logic   [DATA_WIDTH-1:0]   								ram_addra_passed;
logic   [PIXELS_SUM_WIDTH-1:0] 							ram_dataa_passed;
logic   												ram_wea_passed;

logic   [DATA_WIDTH-1:0]   								ram_addrb_passed;
logic   [PIXELS_SUM_WIDTH-1:0] 							ram_datab_passed;
logic   												ram_web_passed;

logic 	[PIXELS_SUM_WIDTH-1:0] 							ram_collect_hist_douta;
logic 	[PIXELS_SUM_WIDTH-1:0] 							ram_collect_hist_doutb;

//Flag to control ram ports
logic 													are_ports_fsm_controlled;

//FSM signals
logic 	[DATA_WIDTH-1:0] 								fsm_timing_counter;
logic 													fsm_first_frame_done;
enum 	logic 	[7:0] 					{
											IDLE, 
											CLEAR_RAM,
											AWAIT_GATHERING,
											AWAIT_LATENCY,
											FIND_MIN_CUMSUM,
											AWAIT_ASSERTION,
											RECALCULATE_CDF
										} 		
														state, next_state;

//CDF minimum
logic 													cdf_find_flag;
logic 													cdf_find_flag_d_0;
logic 													cdf_find_flag_d_1;

logic 													cdf_recalc_flag;
logic 													cdf_recalc_flag_d_0;
logic 													cdf_recalc_flag_d_1;

logic 													cdf_numerator_calculation_flag;
logic 													cdf_numerator_exp_calculation_flag;

logic 	[PIXELS_SUM_WIDTH-1:0] 							cdf_minimum;

//Signals for calculating a new cdf
logic 	[PIXELS_SUM_WIDTH-1:0] 							recalc_numerator;
logic 	[PIXELS_SUM_WIDTH + DATA_WIDTH - 1:0] 			recalc_numerator_expanded;
logic 	[PIXELS_SUM_WIDTH-1:0] 							recalc_denominator;

logic 	[DATA_WIDTH-1:0] 								recalc_division_value;
logic 													recalc_division_write;
logic 	[DATA_WIDTH-1:0] 								recalc_division_address;


//End of declaring local signals and parameters of isp_histogram_equalization's module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of fsm driving section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			state <= IDLE;
		end
	else
		begin
			state <= next_state;
		end
end

always_comb
begin
	case (state)
		IDLE:
			begin
				next_state = IDLE;
				if(in_frame_start) begin
					next_state = CLEAR_RAM;
				end
			end
		CLEAR_RAM:
			begin
				next_state = CLEAR_RAM;
				if(fsm_timing_counter == 2**DATA_WIDTH-1) begin
					next_state = AWAIT_GATHERING;
				end
			end
		AWAIT_GATHERING:
			begin
				next_state = AWAIT_GATHERING;
				if((counter_current_row == in_requested_image_height - 1) && (latch_last_data))begin
					next_state = AWAIT_LATENCY;
				end
			end
		AWAIT_LATENCY:
			begin
				next_state = AWAIT_LATENCY;
				if (fsm_timing_counter == 5) begin
					next_state = FIND_MIN_CUMSUM;
				end
			end
		FIND_MIN_CUMSUM:
			begin
				next_state = FIND_MIN_CUMSUM;
				if(fsm_timing_counter == 2**DATA_WIDTH-1) begin
					next_state = AWAIT_ASSERTION;
				end
			end
		AWAIT_ASSERTION:
			begin
				next_state = AWAIT_ASSERTION;
				if (fsm_timing_counter == 5) begin
					next_state = RECALCULATE_CDF;
				end
			end
		RECALCULATE_CDF:
			begin
				next_state = RECALCULATE_CDF;
				if(fsm_timing_counter == 2**DATA_WIDTH-1) begin
					next_state = IDLE;
				end
			end
		default:
			begin
				next_state = IDLE;
			end
	endcase
end

always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			fsm_first_frame_done <= '0;
		end
	else
		begin
			if((state == RECALCULATE_CDF) && (fsm_timing_counter == 2**DATA_WIDTH-1)) begin
				fsm_first_frame_done <= '1;
			end
		end
end

always_ff @(posedge clk)
begin
	case (state)
		CLEAR_RAM:
			begin
				fsm_timing_counter <= fsm_timing_counter + 1;
			end
		AWAIT_LATENCY, AWAIT_ASSERTION:
			begin
				if (fsm_timing_counter == 5) begin
					fsm_timing_counter <= '0;
				end
				else begin
					fsm_timing_counter <= fsm_timing_counter + 1;
				end
			end
		FIND_MIN_CUMSUM, RECALCULATE_CDF:
			begin
				if(fsm_timing_counter == 2**DATA_WIDTH-1) begin
					fsm_timing_counter <= '0;
				end
				else begin
					fsm_timing_counter <= fsm_timing_counter + 1;
				end
			end
		default:
			begin
				fsm_timing_counter <= '0;
			end
	endcase
end

always_ff @(posedge clk)
begin
	case (state)
		FIND_MIN_CUMSUM:
			begin
				cdf_find_flag <= '1;
			end
		default:
			begin
				cdf_find_flag <= '0;
			end
	endcase

	cdf_find_flag_d_0 <= cdf_find_flag;
	cdf_find_flag_d_1 <= cdf_find_flag_d_0;
end


always_ff @(posedge clk)
begin
	case (state)
		RECALCULATE_CDF:
			begin
				cdf_recalc_flag <= '1;
			end
		default:
			begin
				cdf_recalc_flag <= '0;
			end
	endcase

	cdf_recalc_flag_d_0 <= cdf_recalc_flag;
	cdf_recalc_flag_d_1 <= cdf_recalc_flag_d_0;
end
//End of fsm driving section
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
//Begin of driving counters section section
always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			counter_current_col <= '0;
			counter_current_row <= '0;
		end
	else
		begin
			if (in_frame_start) begin
				counter_current_col <= '0;
				counter_current_row <= '0;
			end
			else begin
				if(latch_valid_data) begin
					counter_current_col <= counter_current_col + 1;
				end
				else begin
					counter_current_col <= '0;
				end

				if(latch_last_data) begin
					if(counter_current_row == in_requested_image_height - 1) begin
						counter_current_row <= '0;
					end
					else begin
						counter_current_row <= counter_current_row + 1;
					end
				end
			end
			
		end
end
//End of driving counters section section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of delaying data to be stored into the histogram ram section
always_ff @(posedge clk)
begin
	latch_stream_data_d_0 <= latch_stream_data;
	latch_valid_data_d_0 <= latch_valid_data;

	latch_stream_data_d_1 <= latch_stream_data_d_0;
	latch_valid_data_d_1 <= latch_valid_data_d_0;
end
//End of delaying data to be stored into the histogram ram section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of adding one into the current cummulation histogram section
logic 	[DATA_WIDTH-1:0] 				addone_ram_address;
logic 				 					addone_ram_write_flag;
logic 	[PIXELS_SUM_WIDTH-1:0]			addone_cumulative_hist_val;

always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			addone_ram_address <= '0;
			addone_ram_write_flag <= '0;
			addone_cumulative_hist_val <= '0;
		end
	else
		begin
			addone_ram_write_flag <= '0;
			if(latch_valid_data_d_1) begin
				addone_ram_address <= latch_stream_data_d_1;
				addone_ram_write_flag <= '1;
				addone_cumulative_hist_val <= ram_collect_hist_douta + 1;
			end
		end
end
//End of adding one into the current cummulation histogram section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of ram port b arbitre section
always_comb
begin
	are_ports_fsm_controlled = '0;
	if((state == CLEAR_RAM) || (state == FIND_MIN_CUMSUM)) begin
		are_ports_fsm_controlled = '1;
	end

	if (are_ports_fsm_controlled) begin
		if(state == CLEAR_RAM) begin
			ram_addra_passed = fsm_timing_counter;
			ram_dataa_passed = '0;
			ram_wea_passed ='1;
			
			ram_addrb_passed = '0;
			ram_datab_passed = '0;
			ram_web_passed = '0;
		end
		else if((state == FIND_MIN_CUMSUM) || (state == RECALCULATE_CDF)) begin
			ram_addra_passed = fsm_timing_counter;
			ram_dataa_passed = '0;
			ram_wea_passed ='0;
			
			ram_addrb_passed = '0;
			ram_datab_passed = '0;
			ram_web_passed = '0;
		end
	end
	else begin
		ram_addra_passed = latch_stream_data;
		ram_dataa_passed = '0;
		ram_wea_passed = '0;

		ram_addrb_passed = addone_ram_address;
		ram_datab_passed = addone_cumulative_hist_val;
		ram_web_passed = addone_ram_write_flag;

	end
end
//End of ram port b arbitre section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of instancing ram to collect histogram info section
isp_histogram_ram
#
(
    .RAM_DATA_WIDTH	(PIXELS_SUM_WIDTH 			),
    .RAM_ADDR_WIDTH	(DATA_WIDTH 				)
)
					isp_histogram_ram_i_gather
(
    .clka 			(clk 						),
    .rsta 			(rst_n 						),
    .rstb 			(rst_n 						),
    .wea 			(ram_wea_passed 			),
    .web 			(ram_web_passed 			),
    .ena 			('1 						),
    .enb 			('1 						),
    .regcea 		('1 						),
    .regceb 		('1 						),

    .addra 			(ram_addra_passed 			),
    .addrb 			(ram_addrb_passed 			),
    .dina 			(ram_dataa_passed 			),
    .dinb 			(ram_datab_passed 			),
    .douta 			(ram_collect_hist_douta 	),
    .doutb 			(ram_collect_hist_doutb 	)
);
//End of instancing ram to collect histogram info section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of recalculating cdf section
always_ff @(posedge clk)
begin
	case (state)
		IDLE, CLEAR_RAM:
			begin
				cdf_minimum <= 2**PIXELS_SUM_WIDTH-1;
			end
		default:
			begin
				if(cdf_find_flag_d_1) begin
					if(ram_collect_hist_douta < cdf_minimum)begin
						cdf_minimum <= ram_collect_hist_douta;
					end
				end
			end
	endcase
end

always_ff @(posedge clk)
begin
	case (state)
		IDLE, CLEAR_RAM:
			begin
				recalc_numerator <= '0;
				cdf_numerator_calculation_flag <= '0;
			end
		default:
			begin
				cdf_numerator_calculation_flag <= '0;

				if(cdf_recalc_flag_d_1) begin
					cdf_numerator_calculation_flag <= '1;
					if(ram_collect_hist_douta < cdf_minimum)begin
						recalc_numerator <= '0;
					end
					else begin
						recalc_numerator <= ram_collect_hist_douta - cdf_minimum;
					end
				end
			end
	endcase
end

always_ff @(posedge clk)
begin
	cdf_numerator_exp_calculation_flag <= cdf_numerator_calculation_flag;
	recalc_numerator_expanded <= {recalc_numerator, 8'd0};
end

always_ff @(posedge clk)
begin
	recalc_division_write <= '0;
	recalc_division_address <= '0;
	if(cdf_numerator_exp_calculation_flag) begin
		recalc_division_value <= recalc_numerator_expanded/recalc_denominator;
		recalc_division_write <= '1;
		recalc_division_address <= recalc_division_address + 1;
	end
end

always_ff @(posedge clk)
begin
	recalc_denominator <= in_requested_image_width * in_requested_image_height;
end
//End of recalculating cdf section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of ram instancing to store the new histogram section
isp_histogram_ram
#
(
    .RAM_DATA_WIDTH	(DATA_WIDTH 				),
    .RAM_ADDR_WIDTH	(DATA_WIDTH 				)
)
					isp_histogram_ram_i_store
(
    .clka 			(clk 							),
    .rsta 			(rst_n 							),
    .rstb 			(rst_n 							),
    .wea 			(recalc_division_write 			),
    .web 			('0 							),
    .ena 			('1 							),
    .enb 			('1 							),
    .regcea 		('1 							),
    .regceb 		('1 							),

    .addra 			(recalc_division_address 		),
    .addrb 			(latch_stream_data 				),
    .dina 			(recalc_division_value 			),
    .dinb 			('0								),
    .douta 			( 								),
    .doutb 			(result_stream_data_from_ram 	)
);
//End of ram instancing to store the new histogram section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of delaying signals to correctly get results from the second ram section
always_ff @(posedge clk) 
begin
	latch_valid_data_d_0 <= '0;
	latch_first_data_d_0 <= '0;
	latch_last_data_d_0 <= '0;

	latch_valid_data_d_1 <= '0;
	latch_first_data_d_1 <= '0;
	latch_last_data_d_1 <= '0;

	if(fsm_first_frame_done) begin
		latch_valid_data_d_0 <= latch_valid_data;
		latch_first_data_d_0 <= latch_first_data;
		latch_last_data_d_0 <= latch_last_data;

		latch_valid_data_d_1 <= latch_valid_data_d_0;
		latch_first_data_d_1 <= latch_first_data_d_0;
		latch_last_data_d_1 <= latch_last_data_d_0;
	end
end
//End of delaying signals to correctly get results from the second ram section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving result register section
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
			result_stream_data <= result_stream_data_from_ram;
			result_valid_data <= latch_valid_data_d_1;
			result_first_data <= latch_first_data_d_1;
			result_last_data <= latch_last_data_d_1;
		end
end
//End of driving result register section
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
