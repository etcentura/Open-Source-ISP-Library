module isp_negative_wrapper
#
(
    parameter       int         ISP_IDX     =       0                       ,       //Module index to be used in generation
    parameter       int         IN_DWIDTH   =       8                       ,       //Input data width: bits per pixel
    parameter       string      IS_COMB     =       "N"                     ,       //Use comb or seq logic: "Y" - comb, "N" - seq
    parameter       string      IS_RST_SYNC =       "N"                     ,       //Use comb or seq logic: "Y" - sync rst_n, "N" - async
    parameter       int         PIPE_NUM    =       1                               //The number of pipes for the P&R quality of the output data
)

(
    //Basic signals declaration
    input		    logic	                            clk                 ,       // CLK signal
    input		    logic	                            rst_n               ,       // Negedge rst signal
    //Input data signals
    input		    logic		                        stream_valid_i      ,       // Any stream bus input valid flag
    input		    logic	    [IN_DWIDTH - 1 : 0] 	stream_data_i       ,       // Any stream bus input data
    //Input data signals
    output		    logic		                        stream_valid_o      ,       // Any stream bus input valid flag
    output		    logic	    [IN_DWIDTH - 1 : 0] 	stream_data_o               // Any stream bus input data
);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of internal signals and parameters declaration section

//Input data latch register
logic		                        stream_valid_i_reg      ;       // Any stream bus input valid flag
logic	    [IN_DWIDTH - 1 : 0] 	stream_data_i_reg       ;       // Any stream bus input data

//End of internal signals and parameters declaration section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of checking input parameters secntion section
initial begin
    if(IN_DWIDTH <= 0) begin
        $error("Parameter IN_DWIDTH must NOT be equal or less than 0");
    end

    if((IS_COMB != "Y") && (IS_COMB != "N")) begin
        $error("Value for the parameter IS_COMB is only allowed equal to 'Y' or 'N' string value");
    end

    if((IS_RST_SYNC != "Y") && (IS_RST_SYNC != "N")) begin
        $error("Value for the parameter IS_RST_SYNC is only allowed equal to 'Y' or 'N' string value");
    end

    if(PIPE_NUM == 0) begin
        $warning("PIPE_NUM == 0, no additional pipe will be used for output signal");
    end

    $display("%m setup with parameter ISP_IDX     : %d", ISP_IDX    );
    $display("%m setup with parameter IN_DWIDTH   : %d", IN_DWIDTH  );
    $display("%m setup with parameter IS_COMB     : %s", IS_COMB    );
    $display("%m setup with parameter IS_RST_SYNC : %s", IS_RST_SYNC);
    $display("%m setup with parameter PIPE_NUM    : %d", PIPE_NUM   );
end
//End of checking input parameters secntion section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of latching input data section
generate
    if(IS_RST_SYNC == "N") begin
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
//Begin of SECTIONNAME section



//End of SECTIONNAME section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
endmodule