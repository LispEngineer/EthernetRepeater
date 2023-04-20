// From: https://www.intel.com/content/www/us/en/docs/programmable/683082/22-1/clock-multiplexing.html

/*
Switching from clock A to clock B requires that clock A continue to operate
for at least a few cycles. If clock A stops immediately, the design sticks.
*/

module clock_mux (clk, clk_select, clk_out);

	parameter num_clocks = 3;

	input [num_clocks-1:0] clk;
	input [num_clocks-1:0] clk_select; // one hot
	output clk_out;

	genvar i;

	reg [num_clocks-1:0] ena_r0;
	reg [num_clocks-1:0] ena_r1;
	reg [num_clocks-1:0] ena_r2;
	wire [num_clocks-1:0] qualified_sel;

	// A look-up-table (LUT) can glitch when multiple inputs 
	// change simultaneously. Use the keep attribute to
	// insert a hard logic cell buffer and prevent 
	// the unrelated clocks from appearing on the same LUT.

	wire [num_clocks-1:0] gated_clks /* synthesis keep */;

	initial begin
		ena_r0 = 0;
		ena_r1 = 0;
		ena_r2 = 0;
	end

	generate
		for (i=0; i<num_clocks; i=i+1) begin: lp0
			wire [num_clocks-1:0] tmp_mask;
			assign tmp_mask = {num_clocks{1'b1}} ^ (1 << i);

			assign qualified_sel[i] = clk_select[i] & (~|(ena_r2 & tmp_mask));

			always @(posedge clk[i]) begin
				ena_r0[i] <= qualified_sel[i];    	
				ena_r1[i] <= ena_r0[i];    	
			end

			always @(negedge clk[i]) begin
				ena_r2[i] <= ena_r1[i];    	
			end

			assign gated_clks[i] = clk[i] & ena_r2[i];
    end: lp0
	endgenerate

	// These will not exhibit simultaneous toggle by construction
	assign clk_out = |gated_clks;

endmodule