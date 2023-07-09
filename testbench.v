`timescale 1 ns / 10 ps

module top_tb();
	reg clk = 0;
	reg rst = 0;
	reg st  = 0;

	//LCD Control Lines
	wire LCD_E;
	wire LCD_RS;
	wire [7:0] LCD_DATA;

	initial begin
		#100
		st = 1;
		#40 //Keep high for multiple clock signals
		st = 0;
	end

	lcd #(
		.WIDTH1(5),
		.WIDTH2(5),
		.HEIGHT(2)
	)lcdm(
		.CLK(clk),
		.RST(rst),
		.line1("Hello"),
		.line2("World"),
		.two_line(1'b1),
		.start(st),
		.LCD_E(LCD_E),
		.LCD_RS(LCD_RS),
		.LCD_DATA(LCD_DATA) );


	//sim time: 10000 * 1 ns = 10 us;
	localparam DURATION = 10000; //total sim time
	////////////////////////////////////////////////////////////////
	//                       GENERATE CLOCK                       //
	//      1 / (( 2 * 41.67) * 1 ns) = 11,999,040.08 MHz         //
	always begin
		#10
		clk = ~clk;
	end

	////////////////////////////////////////////////////////////////
	//                        RUN SIMULATION                      //
	initial begin
		//create sim value change dump file
		$dumpfile("top.vcd");
		//0 means dump all variable levels to watch
		$dumpvars(0, top_tb);

		//Wait for a given amount of time for sim to end
		#(DURATION)

		$display("Finished!");
		$finish;
	end

endmodule
