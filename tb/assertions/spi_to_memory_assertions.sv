module spi_to_memory_assertions (

    input logic       clk,
    input logic       rst,

    // Register interface
    input logic       enable,
    input logic       rd_wr,
    input logic [2:0] addr,
    input logic [7:0] wr_data,
    input logic [7:0] rd_data,

    // Internal DUT status
    input logic       handshake_register,

    // Internal SPI result interface
    input logic       spi_valid,
    input logic [1:0] spi_addr,

    // External SPI signal
    input logic       cs,

    // Channel registers
    input logic [7:0] data_reg0,
    input logic [7:0] data_reg1,
    input logic [7:0] data_reg2,
    input logic [7:0] data_reg3
);


    // ============================================================
    // 1. HANDSHAKE WRITE
    //
    // When the user writes address 4, the Handshake register
    // must contain the written bit on the next clock.
    // ============================================================

    property p_handshake_write;

        @(posedge clk)
        disable iff (rst)

        (enable &&
         (rd_wr == 1'b0) &&
         (addr  == 3'h4))

        |=>

        (handshake_register == $past(wr_data[0]));

    endproperty


    a_handshake_write:
        assert property (p_handshake_write)
        else $error("ASSERTION FAILED: Handshake register did not capture wr_data[0]");



    // ============================================================
    // 2. HANDSHAKE READ
    //
    // Reading address 4 must return:
    //
    // rd_data[0]   = Handshake
    // rd_data[7:1] = 0
    //
    // This also verifies the reserved bits.
    // ============================================================

    property p_handshake_read;

        @(posedge clk)
        disable iff (rst)

        (enable &&
         (rd_wr == 1'b1) &&
         (addr  == 3'h4))

        |=>

        (rd_data == {7'h00, $past(handshake_register)});

    endproperty


    a_handshake_read:
        assert property (p_handshake_read)
        else $error("ASSERTION FAILED: Handshake register READ returned incorrect data");



    // ============================================================
    // 3. FINAL SPI TRANSACTION CLEARS HANDSHAKE
    //
    // When valid data for Channel 3 arrives, the acquisition
    // is complete and the DUT must clear Handshake.
    //
    // A simultaneous user WRITE of Handshake=1 is excluded
    // because the DUT gives that WRITE priority in the RTL.
    // ============================================================

    property p_last_spi_clears_handshake;

        @(posedge clk)
        disable iff (rst)

        (spi_valid &&
         (spi_addr == 2'd3) &&
         !(enable &&
           (rd_wr == 1'b0) &&
           (addr == 3'h4) &&
           wr_data[0]))

        |=>

        (handshake_register == 1'b0);

    endproperty


    a_last_spi_clears_handshake:
        assert property (p_last_spi_clears_handshake)
        else $error("ASSERTION FAILED: Handshake was not cleared after Channel 3 SPI data");



    // ============================================================
    // 4. SPI VALID ONLY AFTER CS IS RELEASED
    //
    // When SPI data is declared valid, the SPI transaction
    // must already be finished and CS must be inactive (HIGH).
    // ============================================================

    property p_spi_valid_cs_high;

        @(posedge clk)
        disable iff (rst)

        spi_valid

        |->

        (cs == 1'b1);

    endproperty


    a_spi_valid_cs_high:
        assert property (p_spi_valid_cs_high)
        else $error("ASSERTION FAILED: spi_valid asserted while CS is LOW");



    // ============================================================
    // 5. CHANNEL REGISTERS ARE READ ONLY FROM USER SIDE
    //
    // data_registers[0:3] may change only because valid SPI
    // data was received for the corresponding channel.
    //
    // Therefore a user WRITE to addresses 0-3 cannot modify them.
    // ============================================================


    // ------------------------------------------------------------
    // Channel 0
    // ------------------------------------------------------------

    property p_data_reg0_spi_only;

        @(posedge clk)
        disable iff (rst)

        ($past(!rst) && $changed(data_reg0))

        |->

        $past(spi_valid && (spi_addr == 2'd0));

    endproperty


    a_data_reg0_spi_only:
        assert property (p_data_reg0_spi_only)
        else $error("ASSERTION FAILED: Channel 0 register changed without SPI data for Channel 0");



    // ------------------------------------------------------------
    // Channel 1
    // ------------------------------------------------------------

    property p_data_reg1_spi_only;

        @(posedge clk)
        disable iff (rst)

        ($past(!rst) && $changed(data_reg1))

        |->

        $past(spi_valid && (spi_addr == 2'd1));

    endproperty


    a_data_reg1_spi_only:
        assert property (p_data_reg1_spi_only)
        else $error("ASSERTION FAILED: Channel 1 register changed without SPI data for Channel 1");



    // ------------------------------------------------------------
    // Channel 2
    // ------------------------------------------------------------

    property p_data_reg2_spi_only;

        @(posedge clk)
        disable iff (rst)

        ($past(!rst) && $changed(data_reg2))

        |->

        $past(spi_valid && (spi_addr == 2'd2));

    endproperty


    a_data_reg2_spi_only:
        assert property (p_data_reg2_spi_only)
        else $error("ASSERTION FAILED: Channel 2 register changed without SPI data for Channel 2");



    // ------------------------------------------------------------
    // Channel 3
    // ------------------------------------------------------------

    property p_data_reg3_spi_only;

        @(posedge clk)
        disable iff (rst)

        ($past(!rst) && $changed(data_reg3))

        |->

        $past(spi_valid && (spi_addr == 2'd3));

    endproperty


    a_data_reg3_spi_only:
        assert property (p_data_reg3_spi_only)
        else $error("ASSERTION FAILED: Channel 3 register changed without SPI data for Channel 3");


endmodule



// ============================================================================
// BIND
//
// Attach the assertion module to spi_to_memory without modifying the DUT.
// ============================================================================

bind spi_to_memory spi_to_memory_assertions spi_to_memory_assertions_i (

    .clk                (clk),
    .rst                (rst),

    .enable             (enable),
    .rd_wr              (rd_wr),
    .addr               (addr),
    .wr_data            (wr_data),
    .rd_data            (rd_data),

    .handshake_register (handshake_register),

    .spi_valid          (spi_valid),
    .spi_addr           (spi_addr),

    .cs                 (cs),

    .data_reg0          (data_registers[0]),
    .data_reg1          (data_registers[1]),
    .data_reg2          (data_registers[2]),
    .data_reg3          (data_registers[3])

);
