
module top_sdram(
	input					clk,
	input					rst_n,
	inout      [15 : 0] 	Dq,
    output     [11 : 0] 	Addr,
    output     [1 : 0] 		Ba,
    output     				sdclk,
    output              	Cke,
    output 					Cs_n,
    output 					Ras_n,
    output					Cas_n,
    output 					We_n,
    output     [1: 0] 		Dqm       
	);

wire rst;
assign Dqm = 2'b00;
assign rst = ~rst_n;
assign Cke = 1'b1;
assign sdclk = clk;//50 Mhz

	sdram_main_ctrl inst_sdram_main_ctrl (
			.clk (clk),
			.rst (rst),
			.cmd ({Cs_n,Ras_n,Cas_n,We_n,Ba,Addr}),
			.dq(Dq)
		);


endmodule 