AXI mster verilog code
module axi_master(
    input ACLK_i,
    input ARESETn_i,

    input AWREADY_i,
    input WREADY_i,
    input ARREADY_i,
    input [127:0] RDATA_i,
    input RVALID_i,
    input [1:0] BRESP_i,
    input BVALID_i,
    input [3:0] RLEN_i,
    input [2:0] RSIZE_i,
    input RLAST_i,
    input [1:0] RRESP_i,
    input [3:0] BID_i,
    input [3:0] RID_i,

    output reg [31:0] AWADDR_o,
    output reg        AWVALID_o,
    output reg [3:0]  AWID_o,

    output reg        WVALID_o,
    output reg [31:0] WDATA_o,
    output reg [3:0]  WLEN_o,
    output reg        WLAST_o,
    output reg [2:0]  WSIZE_o,

    output reg        BREADY_o,

    output reg        ARVALID_o,
    output reg [31:0] ARADDR_o,
    output reg [3:0]  ARID_o,

    output reg        RREADY_o
);

    // Internal Registers
    reg [31:0] Addr = 32'h10101010;
    reg [127:0] data = {32'hABCDEF77, 32'hABCDEF6C, 32'h0EFDAB8C, 32'h7FEABAAC};
    reg [31:0] raddr = 32'hBCEDF123;

    reg [3:0] wtx_id = 4'd4;
    reg [3:0] rtx_id = 4'd2;
    reg  start_addr;
  always@(posedge ACLK_i or negedge ARESETn_i)begin
    if(!ARESETn_i)begin
      start_addr<=1'b0;
    end
    else begin
      if(Addr!==32'hxxxxxxxx)begin
        start_addr<=1'b1;
      end
        else begin
          start_addr<=1'b0;
        end
      end
    end
    // WRITE ADDRESS CHANNEL
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            AWVALID_o <= 0;
            AWID_o    <= 0;
            wtx_id<=4'd0;
            AWADDR_o<=32'hxxxxxxxx;
        end else begin
          if (start_addr==1'b1) begin
                AWVALID_o <= 1;
                AWADDR_o  <= Addr;
                AWID_o    <= wtx_id;
            end else if (AWVALID_o && AWREADY_i) begin
                AWVALID_o <= 0;
            end
        end
    end

    // WRITE DATA CHANNEL
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            WVALID_o <= 0;
            WDATA_o  <= 0;
            WLEN_o   <= 4'd3;
            WSIZE_o  <= 3'b010; // 4 bytes
            WLAST_o  <= 0;
        end else begin
            if (!WVALID_o && data != 128'h0) begin
                WVALID_o <= 1;
                WDATA_o  <= data[31:0];
                WLAST_o  <= (WLEN_o == 0);
            end else if (WVALID_o && WREADY_i) begin
                WVALID_o <= 0;
                if (WLEN_o == 0) begin
                    WLAST_o <= 0;
                    data    <= 0;
                end else begin
                    WLEN_o <= WLEN_o - 1;
                    data   <= {32'd0, data[127:32]};
                end
            end
        end
    end

    // WRITE RESPONSE CHANNEL
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            BREADY_o <= 0;
        end else begin
            if (BVALID_i && BRESP_i == 2'b00) begin
                BREADY_o <= 1;
                if (BID_i == wtx_id) begin
                    wtx_id <= wtx_id + 1;
                end
            end else begin
                BREADY_o <= 0;
            end
        end
    end

    // READ ADDRESS CHANNEL
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            ARVALID_o <= 0;
            ARADDR_o  <= 0;
            ARID_o    <= 0;
        end else begin
            if (!ARVALID_o && Addr != 32'h00000000) begin
                ARVALID_o <= 1;
                ARADDR_o  <= raddr;
                ARID_o    <= rtx_id;
            end else if (ARVALID_o && ARREADY_i) begin
                ARVALID_o <= 0;
            end
        end
    end

    // READ DATA CHANNEL
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            RREADY_o <= 0;
        end else begin
            if (RVALID_i) begin
                RREADY_o <= 1;
                if (RID_i == rtx_id && RLAST_i) begin
                    rtx_id <= rtx_id + 1;
                end
            end else begin
                RREADY_o <= 0;
            end
        end
    end

endmodule
