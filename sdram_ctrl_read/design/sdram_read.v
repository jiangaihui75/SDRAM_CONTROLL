
/*----------------------------------------------------------------------------------------------------
sdram 命令
cmd真值表		cs_n	ras_n	cas_n	we_n	ba[1:0]	addr[11]	addr[10],addr[9:0]
	NOP			0		1		1		1		X		X			X		X
	PRLL		0		0		1		0		X		x			1		X
	REF			0		0		0		1		X		X			X		X
	WR          0		1		0		0		v 		v 			v 		v
	ACT         0		0		1		1		v 		v 			v 		v
	RD 			0		1		0		0		v 		v 			v 		v

MR模式寄存器		{ba[1:0],addr[11:0]}	=	{00,00,000,011,0,010}
		
-----------------------------------------------------------------------------------------------------*/

module sdram_read (
	input	wire 		clk,
	input	wire 		vclk,//25mhz vga clk @60 640x480
	input	wire 		rst,
	output	wire 		r_req,
	input	wire 		r_en,
	output	wire 		read_ref_break_end,
	output	wire 		read_data_end,
	output	wire [17:0]	r_cmd,
	input	wire 		ref_req,
	input	wire [15:0]	r_dq,
	output	wire 		vga_start,
	input	wire 		vga_rd_en,
	output	wire [7:0]	vga_rd_data
	);

//当fifo内部缓存的数据大于8bit的1024个数据时，即可启动写SDRAM


parameter IDLE = 5'b0_0001;
parameter WREQ = 5'b0_0010;
parameter ACTIVE = 5'b0_0100;
parameter READ = 5'b0_1000;
parameter PREC	= 5'b1_0000;

parameter	NOP		=	18'h1c000;//18'b01_1100_0000_0000_0000
parameter	ACT 	=   18'b00_1100_0000_0000_0000;
parameter	WR 		=	18'b01_0000_0000_0000_0000;
parameter 	PALL	=	18'h08400;//18'b00_1000_0100_0000_0000
parameter	RD      =   18'b01_0100_0000_0000_0000;

reg [4:0]	state;
reg 		sd_read_start;
wire [10:0]	wr_data_count;
wire [10:0]	rd_data_count;
reg 		act_end;
reg [2:0]	act_cnt;
reg	[17:0]	cmd;
wire [1:0]	bank_addr;
reg [11:0]	sd_row_cnt;
reg 		sd_row_end;
reg [1:0]	burst_cnt;
reg [6:0]	burst_col_cnt;
reg			fifo_rd_en;
wire [15:0] fifo_rd_data;
reg 		sd_row_end_flag;
reg [4:0]	pre_cnt;
reg 		pre_end;
reg 		ref_break;


wire 		wfifo_en;
wire [15:0]	wfifo_data;
reg  [4:0]	read_state_dly;
reg 		vga_fifo_ready;

assign bank_addr = 2'b00;
//state
always @(posedge clk) begin
	if (rst == 1'b1) begin
		state <= IDLE;
	end
	else case(state)
		IDLE : begin
			if(sd_read_start == 1'b1) begin
				state <= WREQ;
			end
		end
		WREQ : begin
			if(r_en == 1'b1) begin
				state <= ACTIVE;
			end
		end
		ACTIVE : begin
			if(act_end == 1'b1) begin
				state <= READ;
			end
		end
		READ : begin
			if (sd_row_end == 1'b1 || (ref_req == 1'b1 && burst_cnt == 'd3)) begin
				state <= PREC;
			end
		end
		PREC : begin
			if(pre_end == 1'b1 && sd_row_end_flag == 1'b1) begin
				state <= IDLE;
			end
			else if (pre_end == 1'b1 && ref_break == 1'b1) begin
				state <= WREQ;
			end
		end
		default : state <= IDLE;
	endcase
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		sd_read_start <= 1'b0;
	end
	else if (state != IDLE) begin
		sd_read_start <= 1'b0;
	end
	else if (state == IDLE && wr_data_count <512) begin
		sd_read_start <= 1'b1;
	end
end
assign r_req = (state == WREQ);

always @(posedge clk) begin
	if (rst == 1'b1) begin
		act_cnt <='d0;
	end
	else if (state == ACTIVE && act_cnt == 'd3) begin
		act_cnt <= 'd0;
	end
	else if (state == ACTIVE) begin
		act_cnt <= act_cnt + 1'b1;
	end
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		act_end <= 1'b0;
	end
	else if (act_cnt != 'd2) begin
		act_end <= 1'b0;
	end
	else if (act_cnt == 'd2) begin
		act_end <= 1'b1;
	end
end
//cmd
always @(posedge clk) begin
	if (rst == 1'b1) begin
		cmd <= NOP;
	end
	else if (state == ACTIVE && act_cnt == 'd0) begin
		cmd <= {ACT[17:14],bank_addr,sd_row_cnt};
	end
	else if (state == READ && burst_cnt == 'd0) begin
		cmd <= {RD[17:14],bank_addr,{3'b000,burst_col_cnt,2'b00}};
	end
	else if (state == PREC && pre_cnt == 'd0) begin
		cmd <= PALL;
	end
	else begin
		cmd <= NOP;
	end
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		burst_cnt <='d0;
	end
	else if (state == READ) begin
		burst_cnt <= burst_cnt + 1'b1;
	end
	else begin
		burst_cnt <= 'd0;
	end
end
always @(posedge clk) begin
	if (rst == 1'b1) begin
		burst_col_cnt <= 'd0;
	end
	else if(sd_row_end == 1'b1) begin
		burst_col_cnt <= 'd0;
	end
	else if (state == READ && burst_cnt == 'd3) begin
		burst_col_cnt <= burst_col_cnt + 1'b1;
	end
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		sd_row_end <='d0;
	end
	else if (burst_col_cnt == 'd127 &&burst_cnt == 'd2 && state == READ) begin
		sd_row_end <= 1'b1;
	end
	else begin
		sd_row_end <= 1'b0;
	end
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		sd_row_cnt <='d0;
	end
	else if(sd_row_cnt == 'd299 && sd_row_end == 1'b1) begin
		sd_row_cnt <='d0;
	end
	else if (state == READ && sd_row_end == 1'b1) begin
		sd_row_cnt  <= sd_row_cnt + 1'b1;
	end
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		fifo_rd_en <= 1'b0;
	end
	else if (state == READ) begin
		fifo_rd_en <= 1'b1;
	end
	else begin
		fifo_rd_en <= 1'b0;
	end
end


always @(posedge clk) begin
	if (rst == 1'b1) begin
		sd_row_end_flag <= 1'b0;
	end
	else if (state == PREC && pre_cnt == 'd8) begin
		sd_row_end_flag <= 1'b0;
	end
	else if (state == READ && sd_row_end == 1'b1) begin
		sd_row_end_flag <= 1'b1;
	end
end
always @(posedge clk) begin
	if (rst == 1'b1) begin
		pre_cnt <='d0;
	end
	else if(state == PREC && pre_cnt == 'd8)begin
		 pre_cnt <= 'd0;
	end
	else if (state == PREC) begin
		pre_cnt <= pre_cnt + 1'b1;
	end
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		pre_end <= 1'b0;
	end
	else if (state == PREC && pre_cnt == 'd7) begin
		pre_end <= 1'b1;
	end
	else begin
		pre_end <= 1'b0;
	end
end


always @(posedge clk) begin
	if(rst == 1'b1) begin
		ref_break <= 1'b0;
	end
	else if (state == PREC && pre_cnt == 'd8) begin
		ref_break <= 1'b0;
	end
	else if(state == READ && burst_cnt == 'd3  && sd_row_end != 1'b1 && ref_req == 1'b1) begin
		ref_break <= 1'b1;
	end
end

assign read_ref_break_end = (state == PREC) & ref_break & pre_end;
assign read_data_end = (state == PREC) & sd_row_end_flag & pre_end;
assign r_cmd = cmd;

asfifo_w2048x16r4096x8 rdbuffer (
  .wr_clk(clk), // input wr_clk
  .rd_clk(vclk), // input rd_clk
  .din(wfifo_data), // input [15 : 0] din
  .wr_en(wfifo_en), // input wr_en
  .rd_en(vga_rd_en), // input rd_en
  .dout(vga_rd_data), // output [7 : 0] dout
  .full(full), // output full
  .empty(empty), // output empty
  .rd_data_count(rd_data_count), // output [10 : 0] rd_data_count
  .wr_data_count(wr_data_count) // output [10 : 0] wr_data_count
);

assign wfifo_data = r_dq;
assign wfifo_en = read_state_dly[4];

always @(posedge clk) begin
	read_state_dly <= {read_state_dly[3:0],state[3]};
end


always @(posedge vclk) begin
	if (rst == 1'b1) begin
		vga_fifo_ready <= 1'b0;
	end
	else if (rd_data_count > 640) begin
		vga_fifo_ready <= 1'b1;
	end
end

assign vga_start = vga_fifo_ready;

endmodule