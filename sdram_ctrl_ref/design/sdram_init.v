
/*----------------------------------------------------------------------------------------------------
sdram初始化
cmd真值表		cs_n	ras_n	cas_n	we_n	ba[1:0]	addr[11]	addr[10],addr[9:0]
	NOP			0		1		1		1		X		X			X		X
	PRLL		0		0		1		0		X		x			1		X
	REF			0		0		0		1		X		X			X		X

MR模式寄存器		{ba[1:0],addr[11:0]}	=	{00,00,000,011,0,010}
		
-----------------------------------------------------------------------------------------------------*/


module	sdram_init(
			input	wire		clk,	//50MHZ
			input	wire		rst,
			
			output	reg			init_end_flag,
			output	reg[17:0]	init_cmd
			);
	
	parameter	TRP		=	2,
			TRC		=	4,
			TMRD		=	2;

	parameter	DEY_200US	=	9999,
			PALL_CNT	=	10000,
			REF_ST1		=	10001+TRP,
			REF_ST2		=	10002+TRP+TRC,
			MRD_CNT		=	10003+TRP+TRC+TRC,
			END_INIT_CNT	=	10003+TRP+TRC+TRC+TMRD;
			
	parameter	NOP		=	18'h1c000,//18'b01_1100_0000_0000_0000
			PALL		=	18'h08400,//18'b00_1000_0100_0000_0000
			REF		=	18'h04000,//18'b00_0100_0000_0000_0000
			MR		=	18'h00032;//18'b00_0000_0000_0011_0010
			
	
	reg[15:0]	init_cnt;
	//initial counter
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			init_cnt <= 'd0;
		end
		else if(init_cnt == END_INIT_CNT) begin
			init_cnt <= 'd0;
		end
		else if(init_end_flag == 1'b0)begin
			init_cnt <= init_cnt + 1'b1;
		end
	end
	//initial  end  flag
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			init_end_flag <= 1'b0;
		end
		else if(init_cnt >= END_INIT_CNT) begin
			init_end_flag <= 1'b1;
		end
	end
	//cmd
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			init_cmd <= NOP;
		end
		else if(init_cnt <=DEY_200US) begin
			init_cmd <= NOP;
		end
		else if(init_cnt ==  PALL_CNT) begin
			init_cmd <= PALL;
		end
		else if (init_cnt >PALL_CNT && init_cnt < REF_ST1) begin
			init_cmd <= NOP;
		end
		else if (init_cnt == REF_ST1) begin
			init_cmd <= REF;
		end
		else if (init_cnt >REF_ST1 && init_cnt <REF_ST2) begin
			init_cmd <= NOP;
		end
		else if (init_cnt == REF_ST2) begin
			init_cmd <= REF;
		end
		else if (init_cnt >REF_ST2 && init_cnt < MRD_CNT) begin
			init_cmd <= NOP;
		end
		else if (init_cnt == MRD_CNT) begin
			init_cmd <= MR;
		end
		else if (init_cnt >MRD_CNT ) begin
			init_cmd <= NOP;
		end
	end

	
endmodule		