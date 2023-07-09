// +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
// |00|01|02|03|04|05|06|07|08|09|0a|0b|0c|0d|0e|0f|
// +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
// |40|41|42|43|44|45|46|47|48|49|4a|4b|4c|4d|4e|4f|
// +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

module lcd #(
	parameter WIDTH1 = 16,
	parameter WIDTH2 = 16,
	parameter HEIGHT = 2
)(
	input  wire CLK,
	input  wire RST,
	input  wire [WIDTH1*8-1:0] line1,
	input  wire [WIDTH2*8-1:0] line2,
	input  wire two_line,
	input  wire start,
	output reg  LCD_E,
	output reg  LCD_RS,
	output reg  [7:0] LCD_DATA
);
	//_______________INIT MODULE REGISTERS_______________//
	initial LCD_E    = 0;
	initial LCD_DATA = 0;
	initial LCD_RS   = 0;
	//---------------------------------------------------//
	//_______________CONFIGURE STATE MACHINE_____________//
	localparam STATE_IDLE  = 3'd0;
	localparam STATE_INIT  = 3'd1;
	localparam STATE_HOME  = 3'd2;
	localparam STATE_TX1   = 3'd3;
	localparam STATE_TX2   = 3'd4;
	localparam STATE_DONE  = 3'd5;
	reg [2:0] state = STATE_IDLE;

	//---------------------------------------------------//

	//_______________SETUP MGMT REGISTERS________________//
	localparam LINE1_ADDR = 7'h00;
	localparam LINE2_ADDR = 7'h40;
	localparam INIT_CTR = 2;
	localparam HOME_CTR = 3;
	localparam LINE_WIDTH = 16;
	reg [7:0] init [$clog2(INIT_CTR):0];
	reg [7:0] home [$clog2(HOME_CTR):0];
	initial begin
		init[0] = 8'h38; //Set 8 bit 2 line disp
		init[1] = 8'h0e; //disp on
		home[0] = 8'h01; //clear disp
		home[1] = 8'h02; //return home
		home[2] = 8'h06; //set entry mode
	end
	//---------------------------------------------------//

	//_______CREATE SPACE FOR LINE INITIAL ADDRESSES_____//
	wire [16+WIDTH1*8-1:0] rline1;
	assign rline1 = {1'b1, 7'h00, 8'h06, line1};
	wire [16+WIDTH2*8-1:0] rline2;
	assign rline2 = {1'b1, 7'h40, 8'h06, line2};
	//---------------------------------------------------//

	//______________HANDLE MESSAGE COUNT_________________//
	reg [$clog2(32):0] msg_clk = 0;
	reg [$clog2(16):0] msg_ctr = 0;
	always @(*) msg_ctr = (msg_clk)/2;
	always @(posedge CLK) begin
		if( state == STATE_IDLE ) begin
			if( start ) state = STATE_INIT;
		end
		if( state == STATE_INIT ) begin
			if( msg_clk >= 2*INIT_CTR-1 ) begin
				msg_clk <= 0;
				state <= STATE_HOME;
			end
			else msg_clk <= msg_clk + 1;
		end
		else if( state == STATE_HOME ) begin
			if( msg_clk >= 2*HOME_CTR-1 ) begin
				msg_clk <= 0;
				state <= STATE_TX1;
			end
			else msg_clk <= msg_clk + 1;
		end
		else if( state == STATE_TX1  ) begin
			if( msg_clk >= 2*(WIDTH1+2)-1 ) begin
				msg_clk <= 0;
				if( two_line ) state <= STATE_TX2;
				else begin 
					state <= STATE_DONE;
				end
			end
			else msg_clk <= msg_clk + 1;
		end
		else if( state == STATE_TX2  ) begin
			if( msg_clk >= 2*(WIDTH2+2)-1 ) begin
				msg_clk <= 0;
				state <= STATE_DONE;
			end
			else msg_clk <= msg_clk + 1;
		end
		else if( state == STATE_DONE ) begin
			if( start ) state = STATE_HOME;
		end
	end
	//---------------------------------------------------//

	//______________CHANGE LCD ENABLE____________________//
	always @(msg_clk) begin
		LCD_E = msg_clk;
	end
	always @(posedge LCD_E) begin
		if( state == STATE_IDLE ) begin
			LCD_DATA = init[0];
			LCD_RS = 0;
		end
		if( state == STATE_INIT ) begin
			LCD_DATA = init[msg_ctr];
			LCD_RS = 0;
		end
		if( state == STATE_HOME ) begin
			LCD_DATA = home[msg_ctr];
			LCD_RS = 0;
		end
		if( state == STATE_TX1  )  begin
			LCD_DATA = rline1[8*(WIDTH1+2)-8*msg_ctr-1-:8];
			if( msg_ctr < 2 ) LCD_RS = 0;
			else LCD_RS = 1;
		end
		if( state == STATE_TX2  )  begin
			LCD_DATA = rline2[8*(WIDTH2+2)-8*msg_ctr-1-:8];
			if( msg_ctr < 2 ) LCD_RS = 0;
			else LCD_RS = 1;
		end
		if( state == STATE_DONE ) begin
			LCD_DATA = home[0];
			LCD_RS = 0;
		end
	end
	//---------------------------------------------------//

endmodule
