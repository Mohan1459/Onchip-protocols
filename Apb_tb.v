module apb_tb;
    reg PCLK;
    reg PRESETn;
    reg [31:0] PADDR;
    reg PWRITE;
    reg [31:0] PWDATA;
    reg PENABLE;
    reg PSEL;

    wire [31:0] PRDATA;
    wire PREADY;
    wire PSLVERR;

    // Instantiate the APB top module
    apb_top uut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    // Clock generation
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Initialize signals
        PRESETn = 0; // Assert reset
        PADDR = 32'h0000_0000;
        PWRITE = 0;
        PWDATA = 32'h0000_0000;
        PENABLE = 0;
        PSEL = 0;

        #20; // Wait for 20ns
        PRESETn = 1; // Deassert reset

        // Test case 1: Write operation
        #10;
        PADDR = 32'h0000_1000;
        PWRITE = 1; // Write operation
        PWDATA = 32'h1234_5678;
        PSEL = 1; // Select slave
        PENABLE = 1; // Enable transaction

        #20; // Wait for 20ns
        PENABLE = 0;
        PSEL = 0;

        // Test case 2: Read operation
        #10;
        PADDR = 32'h0000_1000;
        PWRITE = 0; // Read operation
        PSEL = 1; // Select slave
        PENABLE = 1; // Enable transaction

        #20; // Wait for 20ns
        PENABLE = 0;
        PSEL = 0;

        // End simulation
        #100;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | PADDR: %h | PWRITE: %b | PWDATA: %h | PRDATA: %h | PREADY: %b | PSLVERR: %b",
                 $time, PADDR, PWRITE, PWDATA, PRDATA, PREADY, PSLVERR);
    end
  initial begin
    $dumpfile("apb_waveform.vcd"); // Save waveform to this file
    $dumpvars(0, apb_tb); // Dump all signals in the testbench
end
endmodule
