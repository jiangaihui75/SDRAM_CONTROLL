
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
    output     [1: 0] 		Dqm,
    output		[7:0]		vga,
    output				    hsync,
    output					vsync,
    input					rx   
	);

wire rst;
wire sclk;
wire vclk;
wire po_flag;
wire [7:0] po_data;
assign Dqm = 2'b00;
assign rst = ~rst_n;
assign Cke = 1'b1;
assign sdclk = sclk;//50 Mhz

  clkgen clk_gen_inst
   (// Clock in ports
    .CLK_IN1(clk),      // IN
    // Clock out ports
    .CLK_OUT1(sclk),     // OUT
    .CLK_OUT2(vclk));    // OUT

	sdram_main_ctrl inst_sdram_main_ctrl (
			.clk (sclk),
			.vclk(vclk),
			.rst (rst),
			.cmd ({Cs_n,Ras_n,Cas_n,We_n,Ba,Addr}),
			.dq(Dq),
			.vga(vga),
			.hsync(hsync),
			.vsync(vsync),
			.wfifo_en(po_flag),
			.wfifo_data(po_data)
		);

	uart_rx inst_uart_rx (
			.sclk    (sclk),
			.rst_n   (rst_n),
			.rx      (rx),
			.po_data (po_data),
			.po_flag (po_flag)
		);



endmodule 