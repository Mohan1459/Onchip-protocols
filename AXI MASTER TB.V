AXI master interface Testbench
`timescale 1ns / 1ps

module tb_axi_master;

    // Clock & Reset
    reg ACLK_i = 0;
    reg ARESETn_i = 0;

    // Master to Slave
    wire [31:0] AWADDR_o;
    wire        AWVALID_o;
    wire [3:0]  AWID_o;

    wire        WVALID_o;
    wire [31:0] WDATA_o;
    wire [3:0]  WLEN_o;
    wire        WLAST_o;
    wire [2:0]  WSIZE_o;

    wire        BREADY_o;

    wire        ARVALID_o;
    wire [31:0] ARADDR_o;
    wire [3:0]  ARID_o;

    wire        RREADY_o;

    // Slave to Master
    reg         AWREADY_i;
    reg         WREADY_i;
    reg         ARREADY_i;

    reg  [127:0] RDATA_i;
    reg         RVALID_i;
    reg  [1:0]   RRESP_i;
    reg  [3:0]   RLEN_i;
    reg  [2:0]   RSIZE_i;
    reg         RLAST_i;
    reg  [3:0]   RID_i;

    reg         BVALID_i;
    reg  [1:0]   BRESP_i;
    reg  [3:0]   BID_i;

    // Instantiate DUT
    axi_master uut (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .AWREADY_i(AWREADY_i),
        .WREADY_i(WREADY_i),
        .ARREADY_i(ARREADY_i),
        .RDATA_i(RDATA_i),
        .RVALID_i(RVALID_i),
        .BRESP_i(BRESP_i),
        .AWADDR_o(AWADDR_o),
        .AWVALID_o(AWVALID_o),
        .WVALID_o(WVALID_o),
        .WDATA_o(WDATA_o),
        .WLEN_o(WLEN_o),
        .WLAST_o(WLAST_o),
        .BREADY_o(BREADY_o),
        .ARVALID_o(ARVALID_o),
        .ARADDR_o(ARADDR_o),
        .RREADY_o(RREADY_o),
        .WSIZE_o(WSIZE_o),
        .BVALID_i(BVALID_i),
        .RLEN_i(RLEN_i),
        .RSIZE_i(RSIZE_i),
        .RLAST_i(RLAST_i),
        .RRESP_i(RRESP_i),
        .AWID_o(AWID_o),
        .BID_i(BID_i),
        .ARID_o(ARID_o),
        .RID_i(RID_i)
    );

    // Clock generation
    always #5 ACLK_i = ~ACLK_i;

    // Test sequence
    initial begin
        // Initialize
        AWREADY_i = 0;
        WREADY_i = 0;
        ARREADY_i = 0;
        RVALID_i = 0;
        RDATA_i  = 128'h0;
        RRESP_i  = 2'b00;
        RLEN_i   = 4'd3;
        RSIZE_i  = 3'b010;
        RLAST_i  = 0;
        RID_i    = 4'd2;
        BVALID_i = 0;
        BID_i    = 4'd4;
        BRESP_i  = 2'b00;

        // Apply reset
        #20 ARESETn_i = 1;

        // Simulate slave accepting write address
        #10 AWREADY_i = 1;
        #10 AWREADY_i = 0;

        // Simulate write data accepted
        #10 WREADY_i = 1;
        #100 WREADY_i = 0;

        // Simulate BVALID with correct BID
        #20 BVALID_i = 1;
        #10 BVALID_i = 0;

        // Simulate slave accepting read address
        #20 ARREADY_i = 1;
        #10 ARREADY_i = 0;

        // Simulate RVALID responses
        repeat(4) begin
            #20;
            RVALID_i = 1;
            RLAST_i  = (RLAST_i == 1) ? 0 : 1;  // last beat flag
            RID_i    = 4'd2;  // must match ARID_o
            #10;
            RVALID_i = 0;
        end

        // End simulation
        #100;
        $display("Testbench finished.");
        $finish;
    end
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
