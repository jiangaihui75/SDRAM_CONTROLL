
module sdram_main_ctrl(
		input		wire 		clk,
		input		wire 		rst,
		output		wire [17:0]	cmd,
		inout		wire [15:0]	dq
	);
parameter 		IDLE = 6'b00_0001;
parameter		INI	 = 6'b00_0010;
parameter		SW	 = 6'b00_0100;
parameter		REF	 = 6'b00_1000;
parameter		WRITE= 6'b01_0000;
parameter		READ = 6'b10_0000;

reg	[5:0] state;
wire 		ini_flag;// active low 
wire 		ini_end;
wire 		ref_req;
wire 		ref_en; // to ref module
wire 		w_req;
wire 		w_en;
wire 		r_req;
wire 		r_en;
wire 		ref_end ;//from ref module
wire 		write_data_end,write_ref_break_end;// from write module
wire 		read_data_end , read_ref_break_end;//from read module
wire [17:0]	ref_cmd;
wire [17:0]	init_cmd;
wire 		wfifo_en;
wire [7:0]	wfifo_data;
wire [17:0]	w_cmd;
wire 		oe;
wire [15:0]	w_dq;

always @(posedge clk) begin
	if(rst == 1'b1) begin
		state <= IDLE;
	end
	else case (state)
		IDLE : begin
			state <= INI;
		end
		INI : begin
			if(ini_end == 1'b1) begin
				state <= SW;
			end
		end
		SW : begin
			if(ref_req == 1'b1 ) begin
				state <= REF;
			end
			else if (w_req == 1'b1 && ref_req == 1'b0) begin
				state <= WRITE;
			end
			else if(r_req == 1'b1 && w_req == 1'b0 && ref_req == 1'b0) begin
				state <= READ;
			end
		end
		REF : begin
			if(ref_end == 1'b1) begin
				state <= SW;
			end
		end
		WRITE : begin
			if(write_data_end == 1'b1 || write_ref_break_end == 1'b1) begin
				state <= SW;
			end
		end
		READ : begin
			if (read_data_end == 1'b1 || read_ref_break_end == 1'b1 ) begin
				state <= SW;
			end
		end
	endcase 
end

assign ini_flag = (state == INI)?1'b0:1'b1;
assign ref_en = (state == SW) & (ref_req == 1'b1);
assign w_en = (state == SW) & (w_req == 1'b1) & (ref_req == 1'b0);
assign r_en = (state == SW) & (r_req == 1'b1) & (w_req == 1'b0) & (ref_req == 1'b0);



assign cmd[17:14] = ref_cmd[17:14] & init_cmd[17:14] & w_cmd[17:14];//{cs_n	ras_n	cas_n	we_n}

assign cmd[13:0] = ref_cmd[13:0] | init_cmd[13:0] | w_cmd[13:0];

assign oe = (state==WRITE)?1'b1:1'b0;

assign dq = oe?w_dq:16'dz;

	sdram_ref inst_sdram_ref (
			.clk     (clk),
			.rst     (rst),
			.ref_cmd (ref_cmd),
			.ini_end (ini_end),
			.ref_req (ref_req),
			.ref_en  (ref_en),
			.ref_end (ref_end)
		);

	sdram_init inst_sdram_init (
			.clk           (clk),
			.rst           (rst),
			.init_end_flag (ini_end),
			.init_cmd      (init_cmd)
		);
	sdram_write inst_sdram_write (
			.clk                 (clk),
			.rst                 (rst),
			.wfifo_en            (wfifo_en),
			.wfifo_data          (wfifo_data),
			.w_req               (w_req),
			.w_en                (w_en),
			.write_ref_break_end (write_ref_break_end),
			.write_data_end      (write_data_end),
			.w_cmd               (w_cmd),
			.ref_req             (ref_req),
			.w_dq                (w_dq)
		);


endmodule 