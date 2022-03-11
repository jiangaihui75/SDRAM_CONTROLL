

`timescale 1ns/1ps

module tb_top_sdram (); /* this is automatically generated */

	reg srst;
	reg clk;

	// clock
	initial begin
		clk = 0;
		forever #(10) clk = ~clk;
	end

	// reset
	initial begin
		srst <= 0;
		#200
		repeat (5) @(posedge clk);
		srst <= 1;
		repeat (1) @(posedge clk);
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



endmodule
