`timescale 1 ns / 1 ps

module overlay_v1_0_data #
(
	parameter integer S_AXI_CTRL_DATA_WIDTH	= 32,
	parameter integer MAX_INPUT_WIDTH = 3840,
	parameter integer MAX_OUTPUT_WIDTH = 1920,
	parameter integer DATA_WIDTH = 32,
	parameter integer ALPHA_WIDTH = 8,
	parameter integer IMAGE_READ_REGISTER_DEPTH = 4,
	parameter integer LOGO_READ_REGISTER_DEPTH = 16,
	parameter integer WRITE_REGISTER_DEPTH = 4
)
(
	/*****************************************************************************
	* internal signals
	*****************************************************************************/
	input wire run,
	input wire reset,
	output wire done,
	input wire logo_valid,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] width,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] heigth,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] hlocation,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] vlocation,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_begin,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_end,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_begin,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_end,
	/*****************************************************************************
	* signals of data ports
	*****************************************************************************/
	input wire  M_AXI_ACLK,
	input wire  M_AXI_ARESETN,

	input wire [DATA_WIDTH-1 : 0] S_AXIS_TDATA_VIDEO,
	input wire S_AXIS_TVALID_VIDEO,
	output wire S_AXIS_TREADY_VIDEO,
	input wire S_AXIS_TLAST_VIDEO,

	input wire [DATA_WIDTH-1 : 0] S_AXIS_TDATA_LOGO,
	input wire S_AXIS_TVALID_LOGO,
	output wire S_AXIS_TREADY_LOGO,
	input wire S_AXIS_TLAST_LOGO,

	input wire [ALPHA_WIDTH-1 : 0] S_AXIS_TDATA_ALPHA,
	input wire S_AXIS_TVALID_ALPHA,
	output wire S_AXIS_TREADY_ALPHA,
	input wire S_AXIS_TLAST_ALPHA,

	output wire [DATA_WIDTH-1 : 0] M_AXIS_TDATA_VIDEO,
	output wire M_AXIS_TVALID_VIDEO,
	input wire M_AXIS_TREADY_VIDEO,
	output wire M_AXIS_TLAST_VIDEO
);

	/*****************************************************************************
	* for byte wise operations
	*****************************************************************************/
	integer byte_index;
	localparam BYTE_NUM = (DATA_WIDTH >> 3);

	/*****************************************************************************
	* location wires and registers
	*****************************************************************************/
	reg [$clog2(MAX_INPUT_WIDTH):0] hlocation_reg;
	reg [$clog2(MAX_INPUT_WIDTH):0] vlocation_reg;

	/*****************************************************************************
	* input buffer wires and registers
	*****************************************************************************/
	reg read_from_logo;
	wire [DATA_WIDTH+ALPHA_WIDTH-1 : 0] pixel_in;
	wire [DATA_WIDTH+ALPHA_WIDTH-1 : 0] logo_in;
	wire [ALPHA_WIDTH-1 : 0] alpha_in;
	wire input_read_not_ready;
	wire logo_read_not_ready;
	wire alpha_read_not_ready;
	wire input_not_ready;
	wire logo_not_ready;
	wire alpha_not_ready;
	wire output_not_ready;

	/*****************************************************************************
	* output buffer wires and registers
	*****************************************************************************/
	reg set_pixel;
	reg [DATA_WIDTH+ALPHA_WIDTH-1 : 0] pixel_out;
	wire write_not_ready;

	/*****************************************************************************
	* I/O Connections assignments
	*****************************************************************************/
	assign S_AXIS_TREADY_VIDEO = (!input_read_not_ready) && run;
	assign S_AXIS_TREADY_LOGO = (!logo_read_not_ready) && run;
	assign S_AXIS_TREADY_ALPHA = (!alpha_read_not_ready) && run;
	assign M_AXIS_TVALID_VIDEO = (!write_not_ready);
	assign M_AXIS_TLAST_VIDEO = done;
	assign hlocation = hlocation_reg;
	assign vlocation = vlocation_reg;

	/*****************************************************************************
	* done signal
	*****************************************************************************/
	assign done = (hlocation_reg == (width - 1)) &&
		(vlocation_reg == (heigth - 1)) && write_not_ready;

	/*****************************************************************************
	* count input location
	*****************************************************************************/
	always @(posedge M_AXI_ACLK)
	begin
		if(M_AXI_ARESETN == 0)
		begin
			hlocation_reg <= 0;
			vlocation_reg <= 0;
		end
		else if((!input_not_ready) && (!output_not_ready) &&
		(
			((!logo_not_ready) && (!alpha_not_ready)) ||
			((vlocation_reg >= logo_vlocation_end) && (hlocation_reg >= logo_hlocation_end)) ||
			(!logo_valid)
		))
		begin
			if(hlocation_reg < (width - 1))
			begin
				hlocation_reg <= hlocation_reg + 1;
				vlocation_reg <= vlocation_reg;
			end
			else if(vlocation_reg < (heigth - 1))
			begin
				hlocation_reg <= 0;
				vlocation_reg <= vlocation_reg + 1;
			end
		end
	end

	/*****************************************************************************
	* FIFO for independent and fast read data from image
	*****************************************************************************/
	FIFO #
	(
	  .RESET_TRIGGER(1),
	  .DATA_WIDTH(DATA_WIDTH),
	  .DATA_DEPTH(IMAGE_READ_REGISTER_DEPTH)
	) IMAGE_READ_FIFO
	(
	  .CLK(M_AXI_ACLK),
	  .RESET((M_AXI_ARESETN == 0) || (reset == 1)),
		.ENABLE(run),
	  .READ((!input_not_ready) && (!output_not_ready) &&
		(
			((!logo_not_ready) && (!alpha_not_ready)) ||
			((vlocation_reg >= logo_vlocation_end) && (hlocation_reg >= logo_hlocation_end)) ||
			(!logo_valid)
		)),
	  .WRITE(S_AXIS_TREADY_VIDEO && S_AXIS_TVALID_VIDEO),
	  .DATA_IN(S_AXIS_TDATA_VIDEO),
	  .DATA_OUT(pixel_in[DATA_WIDTH-1 : 0]),
	  .EMPTY(input_not_ready),
	  .FULL(input_read_not_ready)
	);

	/*****************************************************************************
	* FIFO for independent and fast read data from logo
	*****************************************************************************/
	FIFO #
	(
	  .RESET_TRIGGER(1),
	  .DATA_WIDTH(DATA_WIDTH),
	  .DATA_DEPTH(LOGO_READ_REGISTER_DEPTH)
	) LOGO_READ_FIFO
	(
	  .CLK(M_AXI_ACLK),
	  .RESET((M_AXI_ARESETN == 0) || (reset == 1)),
		.ENABLE(run),
	  .READ(read_from_logo && (!input_not_ready) && (!output_not_ready) &&
			(!logo_not_ready) && (!alpha_not_ready) && logo_valid),
	  .WRITE(S_AXIS_TREADY_LOGO && S_AXIS_TVALID_LOGO),
	  .DATA_IN(S_AXIS_TDATA_LOGO),
	  .DATA_OUT(logo_in[DATA_WIDTH-1 : 0]),
	  .EMPTY(logo_not_ready),
	  .FULL(logo_read_not_ready)
	);

	/*****************************************************************************
	* FIFO for independent and fast read data from alpha
	*****************************************************************************/
	FIFO #
	(
	  .RESET_TRIGGER(1),
	  .DATA_WIDTH(ALPHA_WIDTH),
	  .DATA_DEPTH(LOGO_READ_REGISTER_DEPTH)
	) ALPHA_READ_FIFO
	(
	  .CLK(M_AXI_ACLK),
	  .RESET((M_AXI_ARESETN == 0) || (reset == 1)),
		.ENABLE(run),
	  .READ(read_from_logo && (!input_not_ready) && (!output_not_ready) &&
			(!logo_not_ready) && (!alpha_not_ready) && logo_valid),
	  .WRITE(S_AXIS_TREADY_ALPHA && S_AXIS_TVALID_ALPHA),
	  .DATA_IN(S_AXIS_TDATA_ALPHA),
	  .DATA_OUT(alpha_in),
	  .EMPTY(alpha_not_ready),
	  .FULL(alpha_read_not_ready)
	);

	/*****************************************************************************
	*input pixel of scaler
	*****************************************************************************/
	always @(*)
	begin
		if(
			(hlocation_reg >= logo_hlocation_begin) &&
			(hlocation_reg < logo_hlocation_end) &&
			(vlocation_reg >= logo_vlocation_begin) &&
			(vlocation_reg < logo_vlocation_end) &&
			logo_valid
			)
		begin
			read_from_logo = 1;
			for(byte_index = 0; byte_index < BYTE_NUM; byte_index = byte_index + 1)
			begin
				pixel_out[(byte_index << 3) +: 8] =
					(pixel_in[(byte_index << 3) +: 8] * (255 - alpha_in)) +
					(logo_in[(byte_index << 3) +: 8] * alpha_in);
			end
		end
		else
		begin
			read_from_logo = 0;
			pixel_out = (pixel_in << ALPHA_WIDTH);
		end
	end

	/*****************************************************************************
	* FIFO for independent and fast write data
	*****************************************************************************/
	FIFO #
	(
	  .RESET_TRIGGER(1),
	  .DATA_WIDTH(DATA_WIDTH),
	  .DATA_DEPTH(WRITE_REGISTER_DEPTH)
	) WRITE_FIFO
	(
	  .CLK(M_AXI_ACLK),
	  .RESET((M_AXI_ARESETN == 0) || (reset == 1)),
		.ENABLE(1),
	  .READ(M_AXIS_TREADY_VIDEO && M_AXIS_TVALID_VIDEO),
	  .WRITE((!input_not_ready) && (!output_not_ready) && run &&
		(
			((!logo_not_ready) && (!alpha_not_ready)) ||
			((vlocation_reg >= logo_vlocation_end) && (hlocation_reg >= logo_hlocation_end)) ||
			(!logo_valid)
		)),
		.DATA_IN(pixel_out[DATA_WIDTH+ALPHA_WIDTH-1 : ALPHA_WIDTH]),
	  .DATA_OUT(M_AXIS_TDATA_VIDEO),
	  .EMPTY(write_not_ready),
	  .FULL(output_not_ready)
	);

endmodule
