
/*----------------------------------------------------------------------------------------------------
sdram 命令
cmd真值表		cs_n	ras_n	cas_n	we_n	ba[1:0]	addr[11]	addr[10],addr[9:0]
	NOP			0		1		1		1		X		X			X		X
	PRLL		0		0		1		0		X		x			1		X
	REF			0		0		0		1		X		X			X		X

MR模式寄存器		{ba[1:0],addr[11:0]}	=	{00,00,000,011,0,010}
		
-----------------------------------------------------------------------------------------------------*/
module sdram_ref(
	input	wire 		clk,
	input	wire 		rst,
	output	reg	[17:0]	ref_cmd,	
	input	wire 		ini_end,
	output	reg			ref_req,
	input	wire 		ref_en,
	output	reg			ref_end

	);

parameter   REF		=	18'h04000;//18'b00_0100_0000_0000_0000
parameter	NOP		=	18'h1c000;//18'b01_1100_0000_0000_0000
parameter   REF_CNT_END = 780;

reg	[15:0]	ref_cnt;
reg 		ref_dly_flag;
reg [3:0] 	ref_dly_cnt;

always @(posedge clk) begin
	if(rst == 1'b1 ) begin
		ref_cnt <='d0;
	end
	else if (ref_cnt == REF_CNT_END) begin
		ref_cnt <= 'd0;
	end
	else if (ini_end == 1'b1) begin
		ref_cnt <= ref_cnt + 1'b1;
	end
end

always @(posedge clk) begin
	if(rst == 1'b1 ) begin
		ref_req <= 1'b0;
	end
	else if (ref_en == 1'b1 ) begin
		ref_req <= 1'b0;
	end
	else if(ref_cnt == REF_CNT_END) begin
		ref_req <= 1'b1;
	end
end

always @(posedge clk) begin
	if(rst == 1'b1) begin
		ref_cmd <= NOP;
	end
	else if (ref_req == 1'b1 && ref_en == 1'b1 ) begin
		ref_cmd <= REF;
	end
	else begin
		ref_cmd <= NOP;
	end
end

always @(posedge clk ) begin
	if (rst == 1'b1) begin
		ref_dly_flag <= 1'b0;
	end
	else if (ref_cnt == 'd9) begin
		ref_dly_flag <= 1'b0;
	end
	else if (ref_req == 1'b1 && ref_en == 1'b1) begin
		ref_dly_flag <= 1'b1;
	end
end

always @(posedge clk ) begin
	if (rst == 1'b1) begin
		ref_dly_cnt <='d0;
	end
	else if (ref_dly_flag == 1'b1) begin
		ref_dly_cnt <= ref_dly_cnt + 1'b1;
	end
	else begin
		ref_dly_cnt <= 'd0;
	end
end

always @(posedge clk ) begin
	if (rst == 1'b1) begin
		ref_end <= 1'b0;
	end
	else if (ref_dly_cnt == 'd9) begin
		ref_end <= 1'b1;
	end
	else begin
		ref_end <= 1'b0;
	end
end

endmodule