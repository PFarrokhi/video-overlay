
`timescale 1 ns / 1 ps

module overlay_v1_0_ctrl #
(
	parameter integer S_AXI_CTRL_DATA_WIDTH	= 32,
	parameter integer S_AXI_CTRL_ADDR_WIDTH	= 8
)
(
	/*****************************************************************************
	* internal signals
	*****************************************************************************/
	output wire run,
	output wire reset,
	input wire done,
	output wire logo_valid,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] width,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] heigth,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] hlocation,
	input wire [S_AXI_CTRL_DATA_WIDTH-1:0] vlocation,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_begin,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_end,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_begin,
	output wire [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_end,

	/*****************************************************************************
	* signals of control port
	*****************************************************************************/
	input wire S_AXI_ACLK,
	input wire S_AXI_ARESETN,
	input wire [S_AXI_CTRL_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
	input wire S_AXI_AWVALID,
	output wire S_AXI_AWREADY,
	input wire [S_AXI_CTRL_DATA_WIDTH-1 : 0] S_AXI_WDATA,
	input wire S_AXI_WVALID,
	output wire S_AXI_WREADY,
	output wire [1 : 0] S_AXI_BRESP,
	output wire S_AXI_BVALID,
	input wire S_AXI_BREADY,
	input wire [S_AXI_CTRL_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
	input wire S_AXI_ARVALID,
	output wire S_AXI_ARREADY,
	output wire [S_AXI_CTRL_DATA_WIDTH-1 : 0] S_AXI_RDATA,
	output wire S_AXI_RVALID,
	input wire S_AXI_RREADY
);

	/*****************************************************************************
	* control port I/O signals
	*****************************************************************************/
	reg [S_AXI_CTRL_ADDR_WIDTH-1 : 0] axi_awaddr;
	reg axi_awready;
	reg axi_wready;
	reg axi_bvalid;
	reg [S_AXI_CTRL_ADDR_WIDTH-1 : 0] axi_araddr;
	reg axi_arready;
	reg [S_AXI_CTRL_DATA_WIDTH-1 : 0] axi_rdata;
	reg [1 : 0] axi_rresp;
	reg axi_rvalid;

	/*****************************************************************************
	* control registers
	*****************************************************************************/
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] control_reg;
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] width_reg;
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] heigth_reg;
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_begin_reg;
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] logo_hlocation_end_reg;
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_begin_reg;
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] logo_vlocation_end_reg;

	/*****************************************************************************
	* control register wires and registers
	*****************************************************************************/
	wire slv_reg_rden;
	wire slv_reg_wren;
	reg [S_AXI_CTRL_DATA_WIDTH-1:0] reg_data_out;
	reg	aw_en;

	/*****************************************************************************
	* I/O connections assignments
	*****************************************************************************/
	assign run = control_reg[0];
	assign reset = control_reg[1];
	assign logo_valid = control_reg[3];
	assign width = width_reg;
	assign heigth = heigth_reg;
	assign logo_hlocation_begin = logo_hlocation_begin_reg;
	assign logo_hlocation_end = logo_hlocation_end_reg;
	assign logo_vlocation_begin = logo_vlocation_begin_reg;
	assign logo_vlocation_end = logo_vlocation_end_reg;
	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP = 0;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RDATA = axi_rdata;
	assign S_AXI_RVALID	= axi_rvalid;

	/*****************************************************************************
	* write address ready
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
      axi_awready <= 1'b0;
      aw_en <= 1'b1;
    end
	  else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
    begin
      axi_awready <= 1'b1;
      aw_en <= 1'b0;
    end
    else if (S_AXI_BREADY && axi_bvalid)
    begin
      aw_en <= 1'b1;
      axi_awready <= 1'b0;
    end
    else
    begin
      axi_awready <= 1'b0;
    end
  end

	/*****************************************************************************
	* write address
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
      axi_awaddr <= 0;
    end
	  else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
    begin
      axi_awaddr <= S_AXI_AWADDR;
    end
	end

	/*****************************************************************************
	* write data ready
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
      axi_wready <= 1'b0;
    end
	  else if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
    begin
      axi_wready <= 1'b1;
    end
    else
    begin
      axi_wready <= 1'b0;
    end
	end

	/*****************************************************************************
	* write enable
	*****************************************************************************/
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	/*****************************************************************************
	* write data
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
			control_reg <= 0;
			width_reg <= 0;
			heigth_reg <= 0;
    end
	  else if (slv_reg_wren)
    begin
			case(axi_awaddr >> 2)
			0: control_reg <= S_AXI_WDATA;
			1: width_reg <= S_AXI_WDATA;
			2: heigth_reg <= S_AXI_WDATA;
			9: logo_hlocation_begin_reg <= S_AXI_WDATA;
			10: logo_hlocation_end_reg <= S_AXI_WDATA;
			11: logo_vlocation_begin_reg <= S_AXI_WDATA;
			12: logo_vlocation_end_reg <= S_AXI_WDATA;
			endcase
    end
		else if(reset)
		begin
			control_reg <= 0;
		end
		else if(done == 1)
		begin
			control_reg <= 4'h4;
		end
  end

	/*****************************************************************************
	* response
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
      axi_bvalid  <= 0;
    end
	  else if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
    begin
      axi_bvalid <= 1'b1;
    end
    else if (S_AXI_BREADY && axi_bvalid)
    begin
      axi_bvalid <= 1'b0;
    end
	end

	/*****************************************************************************
	* read address and read address ready
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
      axi_arready <= 1'b0;
      axi_araddr  <= 32'b0;
    end
	  else if (~axi_arready && S_AXI_ARVALID)
    begin
      axi_arready <= 1'b1;
      axi_araddr  <= S_AXI_ARADDR;
    end
    else
    begin
      axi_arready <= 1'b0;
    end
	end

	/*****************************************************************************
	* read data valid
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
      axi_rvalid <= 0;
    end
	  else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
    begin
      axi_rvalid <= 1'b1;
    end
    else if (axi_rvalid && S_AXI_RREADY)
    begin
      axi_rvalid <= 1'b0;
    end
	end

	/*****************************************************************************
	* read enable
	*****************************************************************************/
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

	/*****************************************************************************
	* read data value
	*****************************************************************************/
	always @(*)
	begin
	  case (axi_araddr >> 2)
    0: reg_data_out = control_reg;
    1: reg_data_out = width_reg;
    2: reg_data_out = heigth_reg;
    5: reg_data_out = hlocation;
    6: reg_data_out = vlocation;
		9: reg_data_out = logo_hlocation_begin_reg;
		10: reg_data_out = logo_hlocation_end_reg;
		11: reg_data_out = logo_vlocation_begin_reg;
		12: reg_data_out = logo_vlocation_end_reg;
    default: reg_data_out = 0;
	  endcase
	end

	/*****************************************************************************
	* read data
	*****************************************************************************/
	always @(posedge S_AXI_ACLK)
	begin
	  if (S_AXI_ARESETN == 1'b0)
    begin
      axi_rdata  <= 0;
    end
	  else if (slv_reg_rden)
    begin
      axi_rdata <= reg_data_out;
    end
  end

endmodule
