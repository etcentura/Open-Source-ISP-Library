module isp_gamma_correction
#
(
	parameter 	int 	DATA_WIDTH 			= 8,
	parameter 	int 	CSR_WIDTH 			= 32,
	parameter 	int 	CURVES_NUMBER_UP 	= 3,
	parameter 	int 	CURVES_NUMBER_DN 	= 3,
	parameter   real 	CURVES_STEP_UP 		= 0.1,
	parameter   real 	CURVES_STEP_DN 		= 2,

	// Making true curves parameter
	//Gamma=1 must always exist in the array of gamma values
	parameter 	int 	TRUE_CURVES_NUMBER = 1 + CURVES_NUMBER_UP + CURVES_NUMBER_DN
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
	input 	logic 	[CSR_WIDTH-1:0] 		gamma_curve_select,

	//Output signals signals declaration
	output 	logic 	[DATA_WIDTH-1:0] 		out_stream_data,
	output 	logic 				 			out_valid_data,
	output 	logic 				 			out_first_data,
	output 	logic 				 			out_last_data

);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of isp_gamma_correction's module section

//Declaring local signals

logic 	[DATA_WIDTH-1:0] 		latch_stream_data;
logic 				 			latch_valid_data;
logic 				 			latch_first_data;
logic 				 			latch_last_data;

logic 	[DATA_WIDTH-1:0] 		result_stream_data;
logic 				 			result_valid_data;
logic 				 			result_first_data;
logic 				 			result_last_data;

//Declaring special array type for the gamma values
typedef logic [DATA_WIDTH-1:0] gamma_array_t [TRUE_CURVES_NUMBER][2**DATA_WIDTH];
gamma_array_t gamma_array;

//End of declaring local signals and parameters of isp_gamma_correction's module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of generating errors if some of the values for the parameters are prohibited section

initial begin: error_generation
	if(CURVES_NUMBER_UP == 0)begin
		$error("CURVES_NUMBER_UP must be non-zero value in the module %m");
	end
	
	if(CURVES_NUMBER_DN == 0)begin
		$error("CURVES_NUMBER_DN must be non-zero value in the module %m");
	end

	if(CURVES_STEP_UP == 0)begin
		$error("CURVES_STEP_UP must be non-zero value in the module %m");
	end

	if(CURVES_STEP_DN == 0)begin
		$error("CURVES_STEP_DN must be non-zero value in the module %m");
	end
end

//End of generating errors if some of the values for the parameters are prohibited section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of function to generate cureves values section
function gamma_array_t generate_gamma_values(input int curve_number, input int data_width);
	gamma_array_t result_array;
	
	if(curve_number == 1) begin
		for (int current_pixel_value = 0; current_pixel_value <  2**data_width; current_pixel_value++) begin
			result_array[0][current_pixel_value] = current_pixel_value;
		end
	end
	else begin
		for (int current_curve = 0; current_curve < TRUE_CURVES_NUMBER; current_curve++) begin
			for (int current_pixel_idx = 0; current_pixel_idx < 2**data_width; current_pixel_idx++) begin
				result_array[current_curve][current_pixel_idx] = '0;
			end
		end

		// Generating values for the gamma=1 curve
		for (int current_pixel_value = 0; current_pixel_value < 2**data_width; current_pixel_value++) begin
			result_array[curve_number/2][current_pixel_value] = current_pixel_value;
		end

		//Generating values for the upper curve (gamma < 1)
		for (int current_upper_curves = 0; current_upper_curves < CURVES_NUMBER_UP; current_upper_curves++) begin
			for (int current_pixel_idx = 0; current_pixel_idx < 2**data_width; current_pixel_idx++) begin
				result_array[current_upper_curves][current_pixel_idx] = int'((2**data_width-1)*(real'(current_pixel_idx)/(2**data_width-1))**(real'(CURVES_STEP_UP * (current_upper_curves+1))));
			end
			
		end
		
		// //Generating values for the lower curve (gamma > 1)
		for (int current_lower_curves = CURVES_NUMBER_UP + 1; current_lower_curves < CURVES_NUMBER_UP + 1 + CURVES_NUMBER_DN; current_lower_curves++) begin			
			for (int current_pixel_idx = 0; current_pixel_idx < 2**data_width; current_pixel_idx++) begin
				result_array[current_lower_curves][current_pixel_idx] = int'((2**data_width-1)*(real'(current_pixel_idx)/(2**data_width-1))**(real'(CURVES_STEP_DN * (current_lower_curves - (CURVES_NUMBER_UP + 1) + 1))));
			end
		end
	end

	return result_array;
endfunction
//End of function to generate cureves values section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving lutrom for gamma correction section

always_comb
begin
	gamma_array = generate_gamma_values(TRUE_CURVES_NUMBER, DATA_WIDTH);
end

//End of driving lutrom for gamma correction section
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
//Begin of driving result data registers section
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

			if (latch_valid_data) begin
				if(gamma_curve_select < TRUE_CURVES_NUMBER) begin
					result_stream_data <= gamma_array[gamma_curve_select][latch_stream_data];
				end
				else begin
					result_stream_data <= gamma_array[TRUE_CURVES_NUMBER/2][latch_stream_data];
				end
			end
		end
end
//End of driving result data registers section
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
