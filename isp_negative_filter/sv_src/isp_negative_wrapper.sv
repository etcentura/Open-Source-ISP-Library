module isp_negative_wrapper
#
(
    parameter       int         ISP_IDX     =       0                           ,       // Module index to be used in generation
    parameter       int         IN_DWIDTH   =       8                           ,       // Input data width: bits per pixel
    parameter       bit         IS_COMB     =       1'b0                        ,       // Use comb or seq logic: "1" - comb, "0" - seq
    parameter       bit         IS_RST_SYNC =       1'b0                        ,       // Use comb or seq logic: "1" - sync rst_n, "0" - async
    parameter       int         PIPE_NUM    =       1                                   // The number of pipes for the P&R quality of the output data
)

(
    //Basic signals declaration
    input		    logic	                            clk                     ,       // CLK signal
    input		    logic	                            rst_n                   ,       // Negedge rst signal
    //Input data signals
    input		    logic		                        stream_valid_i          ,       // Any stream bus input valid flag
    input		    logic	    [IN_DWIDTH - 1 : 0] 	stream_data_i           ,       // Any stream bus input data
    //Input data signals
    output		    logic		                        stream_valid_o          ,       // Any stream bus input valid flag
    output		    logic	    [IN_DWIDTH - 1 : 0] 	stream_data_o                   // Any stream bus input data
);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of internal signals and parameters declaration section

//Maximum value for the selected datawidth
localparam  int                             max_pix_value = 2**IN_DWIDTH - 1    ;       // Maximum value for the selected data width

//Input data latch register
logic		                                stream_valid_i_reg                  ;       // Any stream bus registered valid flag
logic	    [IN_DWIDTH - 1 : 0] 	        stream_data_i_reg                   ;       // Any stream bus registered data

//Calculation signal
logic		                                stream_valid_calc                   ;       // Any stream bus calculated valid flag
logic	    [IN_DWIDTH - 1 : 0] 	        stream_data_calc                    ;       // Any stream bus calculated data

//Pipe signals (if presented)
logic		                                stream_valid_pipe[PIPE_NUM]         ;       // Any stream bus piped valid flag
logic	    [IN_DWIDTH - 1 : 0] 	        stream_data_pipe[PIPE_NUM]          ;       // Any stream bus piped data
//End of internal signals and parameters declaration section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of checking input parameters secntion section
initial begin
    if(IN_DWIDTH <= 0) begin
        $error("Parameter IN_DWIDTH must NOT be equal or less than 0");
    end

    if(PIPE_NUM == 0) begin
        $warning("PIPE_NUM == 0, no additional pipe will be used for output signal");
    end

    $display("%m setup with parameter ISP_IDX     : %d", ISP_IDX    );
    $display("%m setup with parameter IN_DWIDTH   : %d", IN_DWIDTH  );
    $display("%m setup with parameter IS_COMB     : %d", IS_COMB    );
    $display("%m setup with parameter IS_RST_SYNC : %d", IS_RST_SYNC);
    $display("%m setup with parameter PIPE_NUM    : %d", PIPE_NUM   );
end
//End of checking input parameters secntion section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of latching input data section
generate
    if(IS_RST_SYNC == 1'b0) begin
        always_ff @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                begin
                    stream_valid_i_reg      <= '0;
                end
            else
                begin
                    stream_valid_i_reg      <= '0;
                    if(stream_valid_i) begin
                        stream_valid_i_reg  <= '1;
                        stream_data_i_reg   <= stream_data_i;
                    end
                end
        end
    end
    else begin
        always_ff @(posedge clk)
        begin
            if(!rst_n)
                begin
                    stream_valid_i_reg      <= '0;
                end
            else
                begin
                    stream_valid_i_reg      <= '0;
                    if(stream_valid_i) begin
                        stream_valid_i_reg  <= '1;
                        stream_data_i_reg   <= stream_data_i;
                    end
                end
        end
    end
endgenerate
//End of latching input data section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of main calculations section
generate
    if(IS_COMB == 1'b1) begin
        always_comb
        begin
            stream_valid_calc = stream_valid_i_reg;
            stream_data_calc = max_pix_value - stream_data_i_reg;
        end
    end
    else begin
        if(IS_RST_SYNC == 1'b0) begin
            always_ff @(posedge clk or negedge rst_n)
            begin
                if(!rst_n)
                    begin
                        stream_valid_calc      <= '0;
                    end
                else
                    begin
                        stream_valid_calc      <= '0;
                        if(stream_valid_i_reg) begin
                            stream_valid_calc  <= '1;
                            stream_data_calc   <= max_pix_value - stream_data_i_reg;
                        end
                    end
            end
        end
        else begin
            always_ff @(posedge clk)
            begin
                if(!rst_n)
                    begin
                        stream_valid_calc      <= '0;
                    end
                else
                    begin
                        stream_valid_calc      <= '0;
                        if(stream_valid_i_reg) begin
                            stream_valid_calc  <= '1;
                            stream_data_calc   <= max_pix_value - stream_data_i_reg;
                        end
                    end
            end
        end
    end
endgenerate
//End of main calculations section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of output latching the result section
generate
    if(PIPE_NUM > 0) begin
         if(PIPE_NUM == 1) begin
            always_ff @(posedge clk)
            begin
                stream_valid_pipe[0]        <= stream_valid_calc        ;
                stream_data_pipe[0]         <= stream_data_calc         ;
            end
         end
         else begin
            always_ff @(posedge clk)
            begin
                stream_valid_pipe[0]        <= stream_valid_calc        ;
                stream_data_pipe[0]         <= stream_data_calc         ;

                for (int i = 1; i < PIPE_NUM; i++) begin
                    stream_valid_pipe[i]    <= stream_valid_pipe[i-1]   ;
                    stream_data_pipe[i]     <= stream_data_pipe[i-1]    ;
                end
            end
         end
    end
endgenerate
//End of output latching the result section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of generating output signals section
generate
    if(PIPE_NUM > 0) begin
        if(PIPE_NUM == 1) begin
            always_ff @(posedge clk)
            begin
                stream_valid_o  <= stream_valid_pipe[0];
                stream_data_o   <= stream_data_pipe[0];
            end
        end
        else begin
            always_ff @(posedge clk)
            begin
                stream_valid_o  <= stream_valid_pipe[PIPE_NUM - 1];
                stream_data_o   <= stream_data_pipe[PIPE_NUM - 1];
            end
        end
    end
    else begin
        always_ff @(posedge clk)
        begin
            stream_valid_o  <= stream_valid_calc;
            stream_data_o   <= stream_data_calc;
        end
    end
endgenerate
//End of generating output signals section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
endmodule