module apb_master (
    input wire PCLK,
    input wire PRESETn,
    input wire [31:0] PADDR,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    input wire PENABLE,
    input wire PSEL,
    input wire [31:0] PRDATA,
    input wire PREADY,
    input wire PSLVERR,

    output reg [31:0] PRDATA_out,
    output reg PREADY_out,
    output reg PSLVERR_out
);

    // State machine for APB master
   parameter IDLE=2'b00;
   parameter SETUP=2'b01;
  parameter  ACCESS=2'b10;
  
  reg [1:0]state;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            PRDATA_out <= 32'h0000_0000;
            PREADY_out <= 1'b0;
            PSLVERR_out <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (PSEL && !PENABLE) begin
                        state <= SETUP;
                    end
                end
                SETUP: begin
                    if (PSEL && PENABLE) begin
                        state <= ACCESS;
                    end
                end
                ACCESS: begin
                    if (PREADY) begin
                        PRDATA_out <= PRDATA;
                        PREADY_out <= 1'b1;
                        PSLVERR_out <= PSLVERR;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

module apb_slave (
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output reg PREADY,
    output reg PSLVERR
);

    // Internal memory for the slave
    reg [31:0] mem [0:255];

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 32'h0000_0000;
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
        end else begin
            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    // Write operation
                    mem[PADDR[7:0]] <= PWDATA;
                    PREADY <= 1'b1;
                    PSLVERR <= 1'b0;
                end else begin
                    // Read operation
                    PRDATA <= mem[PADDR[7:0]];
                    PREADY <= 1'b1;
                    PSLVERR <= 1'b0;
                end
            end else begin
                PREADY <= 1'b0;
                PSLVERR <= 1'b0;
            end
        end
    end
endmodule

module apb_decoder (
    input wire [31:0] PADDR,
    output reg PSEL1,
    output reg PSEL2,
    output reg PSEL3,
    output reg PSEL4
);

    always @(*) begin
        case (PADDR[31:28])
            4'b0000: begin
                PSEL1 = 1'b1;
                PSEL2 = 1'b0;
                PSEL3 = 1'b0;
                PSEL4 = 1'b0;
            end
            4'b0001: begin
                PSEL1 = 1'b0;
                PSEL2 = 1'b1;
                PSEL3 = 1'b0;
                PSEL4 = 1'b0;
            end
            4'b0010: begin
                PSEL1 = 1'b0;
                PSEL2 = 1'b0;
                PSEL3 = 1'b1;
                PSEL4 = 1'b0;
            end
            4'b0011: begin
                PSEL1 = 1'b0;
                PSEL2 = 1'b0;
                PSEL3 = 1'b0;
                PSEL4 = 1'b1;
            end
            default: begin
                PSEL1 = 1'b0;
                PSEL2 = 1'b0;
                PSEL3 = 1'b0;
                PSEL4 = 1'b0;
            end
        endcase
    end
endmodule
module apb_multiplexer (
    input wire [31:0] PRDATA1,
    input wire [31:0] PRDATA2,
    input wire [31:0] PRDATA3,
    input wire [31:0] PRDATA4,
    input wire PREADY1,
    input wire PREADY2,
    input wire PREADY3,
    input wire PREADY4,
    input wire PSLVERR1,
    input wire PSLVERR2,
    input wire PSLVERR3,
    input wire PSLVERR4,
    input wire PSEL1,
    input wire PSEL2,
    input wire PSEL3,
    input wire PSEL4,
    output reg [31:0] PRDATA,
    output reg PREADY,
    output reg PSLVERR
);

    always @(*) begin
        case ({PSEL1, PSEL2, PSEL3, PSEL4})
            4'b1000: begin
                PRDATA = PRDATA1;
                PREADY = PREADY1;
                PSLVERR = PSLVERR1;
            end
            4'b0100: begin
                PRDATA = PRDATA2;
                PREADY = PREADY2;
                PSLVERR = PSLVERR2;
            end
            4'b0010: begin
                PRDATA = PRDATA3;
                PREADY = PREADY3;
                PSLVERR = PSLVERR3;
            end
            4'b0001: begin
                PRDATA = PRDATA4;
                PREADY = PREADY4;
                PSLVERR = PSLVERR4;
            end
            default: begin
                PRDATA = 32'h0000_0000;
                PREADY = 1'b0;
                PSLVERR = 1'b0;
            end
        endcase
    end
endmodule

module apb_top (
    input wire PCLK,
    input wire PRESETn,
    input wire [31:0] PADDR,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    input wire PENABLE,
    input wire PSEL,
    output wire [31:0] PRDATA,
    output wire PREADY,
    output wire PSLVERR
);

    // Internal signals
    wire PSEL1, PSEL2, PSEL3, PSEL4;
    wire [31:0] PRDATA1, PRDATA2, PRDATA3, PRDATA4;
    wire PREADY1, PREADY2, PREADY3, PREADY4;
    wire PSLVERR1, PSLVERR2, PSLVERR3, PSLVERR4;

    // Instantiate the APB components
    apb_decoder decoder (
        .PADDR(PADDR),
        .PSEL1(PSEL1),
        .PSEL2(PSEL2),
        .PSEL3(PSEL3),
        .PSEL4(PSEL4)
    );

    apb_slave slave1 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL1),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA1),
        .PREADY(PREADY1),
        .PSLVERR(PSLVERR1)
    );

    apb_slave slave2 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL2),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA2),
        .PREADY(PREADY2),
        .PSLVERR(PSLVERR2)
    );

    apb_multiplexer multiplexer (
        .PRDATA1(PRDATA1),
        .PRDATA2(PRDATA2),
        .PRDATA3(PRDATA3),
        .PRDATA4(PRDATA4),
        .PREADY1(PREADY1),
        .PREADY2(PREADY2),
        .PREADY3(PREADY3),
        .PREADY4(PREADY4),
        .PSLVERR1(PSLVERR1),
        .PSLVERR2(PSLVERR2),
        .PSLVERR3(PSLVERR3),
        .PSLVERR4(PSLVERR4),
        .PSEL1(PSEL1),
        .PSEL2(PSEL2),
        .PSEL3(PSEL3),
        .PSEL4(PSEL4),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );
endmodule
