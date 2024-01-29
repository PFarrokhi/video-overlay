`timescale 1 ns / 1 ps

module overlay_v1_0 #
(
	parameter integer MAX_INPUT_WIDTH = 3840,
	parameter integer MAX_OUTPUT_WIDTH = 1920,
	parameter integer S_AXI_CTRL_DATA_WIDTH	= 32,
	parameter integer S_AXI_CTRL_ADDR_WIDTH	= 8,
	parameter integer DATA_WIDTH = 32,
	parameter integer ALPHA_WIDTH = 8,
	parameter integer IMAGE_READ_REGISTER_DEPTH = 4,
	parameter integer LOGO_READ_REGISTER_DEPTH = 16,
	parameter integer WRITE_REGISTER_DEPTH = 4
)
(
	// diffrent clock domain between slave and master require double clock FIFO
	input wire axi_aclk,
	input wire axi_aresetn,

	/*****************************************************************************
	* control port signals
	*****************************************************************************/
	// input wire s_axi_ctrl_aclk,
	// input wire s_axi_ctrl_aresetn,
	input wire [S_AXI_CTRL_ADDR_WIDTH-1 : 0] s_axi_ctrl_awaddr,
	input wire s_axi_ctrl_awvalid,
	output wire s_axi_ctrl_awready,
	input wire [S_AXI_CTRL_DATA_WIDTH-1 : 0] s_axi_ctrl_wdata,
	input wire s_axi_ctrl_wvalid,
	output wire s_axi_ctrl_wready,
	output wire [1 : 0] s_axi_ctrl_bresp,
	output wire s_axi_ctrl_bvalid,
	input wire s_axi_ctrl_bready,
	input wire [S_AXI_CTRL_ADDR_WIDTH-1 : 0] s_axi_ctrl_araddr,
	input wire s_axi_ctrl_arvalid,
	output wire s_axi_ctrl_arready,
	output wire [S_AXI_CTRL_DATA_WIDTH-1 : 0] s_axi_ctrl_rdata,
	output wire s_axi_ctrl_rvalid,
	input wire s_axi_ctrl_rready,

	/*****************************************************************************
	* data ports signals
	*****************************************************************************/
	// input wire data_axi_aclk,
	// input wire data_axi_aresetn,
	input wire [DATA_WIDTH-1 : 0] s_axis_tdata_video,
	input wire s_axis_tvalid_video,
	output wire s_axis_tready_video,
	input wire s_axis_tlast_video,

	input wire [DATA_WIDTH-1 : 0] s_axis_tdata_logo,
	input wire s_axis_tvalid_logo,
	output wire s_axis_tready_logo,
	input wire s_axis_tlast_logo,

	input wire [ALPHA_WIDTH-1 : 0] s_axis_tdata_alpha,
	input wire s_axis_tvalid_alpha,
	output wire s_axis_tready_alpha,
	input wire s_axis_tlast_alpha,

	output wire [DATA_WIDTH-1 : 0] m_axis_tdata_video,
	output wire m_axis_tvalid_video,
	input wire m_axis_tready_video,
	output wire m_axis_tlast_video
);

	/*****************************************************************************
	* internal signals
	*****************************************************************************/
	wire run;
	wire reset;
	wire done;
	wire logo_valid;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] width;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] heigth;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] dst_width;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] dst_heigth;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] hlocation;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] vlocation;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] hlocation_out;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] vlocation_out;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_begin;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_end;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_begin;
	wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_end;

	/*****************************************************************************
	* control ports module
	*****************************************************************************/
	overlay_v1_0_ctrl #
	(
		.S_AXI_CTRL_DATA_WIDTH(S_AXI_CTRL_DATA_WIDTH),
		.S_AXI_CTRL_ADDR_WIDTH(S_AXI_CTRL_ADDR_WIDTH)
	) overlay_v1_0_ctrl_inst
	(
		.run(run),
		.reset(reset),
		.done(done),
		.logo_valid(logo_valid),
		.width(width),
		.heigth(heigth),
		.hlocation(hlocation),
		.vlocation(vlocation),
		.logo_hlocation_begin(logo_hlocation_begin),
		.logo_hlocation_end(logo_hlocation_end),
		.logo_vlocation_begin(logo_vlocation_begin),
		.logo_vlocation_end(logo_vlocation_end),
		.S_AXI_ACLK(axi_aclk),
		.S_AXI_ARESETN(axi_aresetn),
		.S_AXI_AWADDR(s_axi_ctrl_awaddr),
		.S_AXI_AWVALID(s_axi_ctrl_awvalid),
		.S_AXI_AWREADY(s_axi_ctrl_awready),
		.S_AXI_WDATA(s_axi_ctrl_wdata),
		.S_AXI_WVALID(s_axi_ctrl_wvalid),
		.S_AXI_WREADY(s_axi_ctrl_wready),
		.S_AXI_BRESP(s_axi_ctrl_bresp),
		.S_AXI_BVALID(s_axi_ctrl_bvalid),
 		.S_AXI_BREADY(s_axi_ctrl_bready),
		.S_AXI_ARADDR(s_axi_ctrl_araddr),
		.S_AXI_ARVALID(s_axi_ctrl_arvalid),
		.S_AXI_ARREADY(s_axi_ctrl_arready),
		.S_AXI_RDATA(s_axi_ctrl_rdata),
		.S_AXI_RVALID(s_axi_ctrl_rvalid),
		.S_AXI_RREADY(s_axi_ctrl_rready)
	);

	/*****************************************************************************
	* data ports module
	*****************************************************************************/
	overlay_v1_0_data #
	(
		.S_AXI_CTRL_DATA_WIDTH(S_AXI_CTRL_DATA_WIDTH),
		.MAX_INPUT_WIDTH(MAX_INPUT_WIDTH),
		.MAX_OUTPUT_WIDTH(MAX_OUTPUT_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ALPHA_WIDTH(ALPHA_WIDTH),
		.IMAGE_READ_REGISTER_DEPTH(IMAGE_READ_REGISTER_DEPTH),
		.LOGO_READ_REGISTER_DEPTH(LOGO_READ_REGISTER_DEPTH),
		.WRITE_REGISTER_DEPTH(WRITE_REGISTER_DEPTH)
	) overlay_v1_0_data_inst
	(
		.run(run),
		.reset(reset),
		.done(done),
		.logo_valid(logo_valid),
		.width(width),
		.heigth(heigth),
		.hlocation(hlocation),
		.vlocation(vlocation),
		.logo_hlocation_begin(logo_hlocation_begin),
		.logo_hlocation_end(logo_hlocation_end),
		.logo_vlocation_begin(logo_vlocation_begin),
		.logo_vlocation_end(logo_vlocation_end),
		.M_AXI_ACLK(axi_aclk),
		.M_AXI_ARESETN(axi_aresetn),
		.S_AXIS_TDATA_VIDEO(s_axis_tdata_video),
		.S_AXIS_TVALID_VIDEO(s_axis_tvalid_video),
		.S_AXIS_TREADY_VIDEO(s_axis_tready_video),
		.S_AXIS_TLAST_VIDEO(s_axis_tlast_video),
		.S_AXIS_TDATA_LOGO(s_axis_tdata_logo),
		.S_AXIS_TVALID_LOGO(s_axis_tvalid_logo),
		.S_AXIS_TREADY_LOGO(s_axis_tready_logo),
		.S_AXIS_TLAST_LOGO(s_axis_tlast_logo),
		.S_AXIS_TDATA_ALPHA(s_axis_tdata_alpha),
		.S_AXIS_TVALID_ALPHA(s_axis_tvalid_alpha),
		.S_AXIS_TREADY_ALPHA(s_axis_tready_alpha),
		.S_AXIS_TLAST_ALPHA(s_axis_tlast_alpha),
		.M_AXIS_TDATA_VIDEO(m_axis_tdata_video),
		.M_AXIS_TVALID_VIDEO(m_axis_tvalid_video),
		.M_AXIS_TREADY_VIDEO(m_axis_tready_video),
		.M_AXIS_TLAST_VIDEO(m_axis_tlast_video)
	);

endmodule
