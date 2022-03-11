
`timescale 1ns/1ps

module tb_top_sdram (); /* this is automatically generated */

	reg srst;
	reg clk;
	reg tb_wfifo_en;
	reg [7:0] tb_wfifo_data;
	reg tb_ini_end;
	reg tb_sdram_read_rst;
	reg sclk;

	// clock
	initial begin
		clk = 0;
		forever #(10) clk = ~clk;
	end

	// reset
	initial begin
		srst <= 0;
		#200
		repeat (5) @(posedge sclk);
		srst <= 1;
		repeat (1) @(posedge sclk);
	end

	initial begin
		tb_wfifo_en =0;
		tb_wfifo_data =0;
		tb_sdram_read_rst =1;
		force sclk = inst_top_sdram.sclk;
		force tb_ini_end = inst_top_sdram.inst_sdram_main_ctrl.ini_end;
		force inst_top_sdram.inst_sdram_main_ctrl.wfifo_en =tb_wfifo_en;
		force inst_top_sdram.inst_sdram_main_ctrl.wfifo_data = tb_wfifo_data;
		force inst_top_sdram.inst_sdram_main_ctrl.inst_sdram_read.rst = tb_sdram_read_rst;//仿真时关闭模块内部复位，非仿真时恢复复位否则工程出错
		gen_wfifo();
		@(posedge sclk);
		tb_sdram_read_rst =0;
	end

	// (*NOTE*) replace reset, clock, others

	wire [15 : 0] Dq;
	wire [11 : 0] Addr;
	wire  [1 : 0] Ba;
	wire          sdclk;
	wire          Cke;
	wire          Cs_n;
	wire          Ras_n;
	wire          Cas_n;
	wire          We_n;
	wire   [1: 0] Dqm;

	top_sdram inst_top_sdram(
			.clk   (clk),
			.rst_n (srst),
			.Dq    (Dq),
			.Addr  (Addr),
			.Ba    (Ba),
			.sdclk (sdclk),
			.Cke   (Cke),
			.Cs_n  (Cs_n),
			.Ras_n (Ras_n),
			.Cas_n (Cas_n),
			.We_n  (We_n),
			.Dqm   (Dqm)
		);


	sdram_model_plus inst_sdram_model_plus (
			.Dq    (Dq),
			.Addr  (Addr),
			.Ba    (Ba),
			.Clk   (sdclk),
			.Cke   (Cke),
			.Cs_n  (Cs_n),
			.Ras_n (Ras_n),
			.Cas_n (Cas_n),
			.We_n  (We_n),
			.Dqm   (Dqm),
			.Debug (1'b1)
		);


task gen_wfifo;
	integer r,c;
	begin
		@(posedge tb_ini_end);
		repeat (5) @(posedge sclk);
		for (r=0;r<480;r=r+1)begin
			for(c=0;c<640;c=c+1) begin
				@(posedge sclk);
				tb_wfifo_en =1;
				tb_wfifo_data = c[7:0];
			end
			@(posedge clk)
			tb_wfifo_en =0;
			repeat (1000) @(posedge sclk);
		end
	end
endtask

endmodule
