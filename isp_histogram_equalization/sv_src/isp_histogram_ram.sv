module isp_histogram_ram
#
(
    parameter 	int 	RAM_DATA_WIDTH 			= 8,
    parameter 	int 	RAM_ADDR_WIDTH 			= 8,
)

(
    input   logic                           clka,
    input   logic                           rsta,
    input   logic                           rstb,
    input   logic                           wea,
    input   logic                           web,
    input   logic                           ena,
    input   logic                           enb,
    input   logic                           regcea,
    input   logic                           regceb,

    input   logic   [RAM_ADDR_WIDTH-1:0]    addra,
    input   logic   [RAM_ADDR_WIDTH-1:0]    addrb,
    input   logic   [RAM_DATA_WIDTH-1:0]    dina,
    input   logic   [RAM_DATA_WIDTH-1:0]    dinb,
    output  logic   [RAM_DATA_WIDTH-1:0]    douta,
    output  logic   [RAM_DATA_WIDTH-1:0]    doutb
);

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of declaring local signals and parameters of isp_histogram_ram's module section
logic [RAM_DATA_WIDTH-1:0] ram [2**RAM_ADDR_WIDTH];
logic [RAM_DATA_WIDTH-1:0] ram_data_a;
logic [RAM_DATA_WIDTH-1:0] ram_data_b;
logic [RAM_DATA_WIDTH-1:0] douta_reg;
logic [RAM_DATA_WIDTH-1:0] doutb_reg;
//End of declaring local signals and parameters of isp_histogram_ram's module section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving core ram section
always @(posedge clka) begin
    if (ena) begin
        if (wea) begin
            ram[addra] <= dina;
        end
        ram_data_a <= ram[addra];
    end
end

always @(posedge clka) begin
    if (enb) begin
        if (web) begin
            ram[addrb] <= dinb;
        end
        ram_data_b <= ram[addrb];
    end
end
//End of driving core ram section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//Begin of driving output registers section


always @(posedge clka or negedge rsta) begin
    if (!rsta)
        douta_reg <= '0;
    else if (regcea)
        douta_reg <= ram_data_a;
end

always @(posedge clka or negedge rstb) begin
    if (!rstb)
        doutb_reg <= '0;
    else if (regceb)
        doutb_reg <= ram_data_b;
end

assign douta = douta_reg;
assign doutb = doutb_reg;
//End of driving output registers section
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
endmodule