`uvm_analysis_imp_decl(_spi)
`uvm_analysis_imp_decl(_reg)


class spi_to_memory_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(spi_to_memory_scoreboard)


    // Analysis inputs
    uvm_analysis_imp_spi #(spi_transaction, spi_to_memory_scoreboard) spi_export;
    uvm_analysis_imp_reg #(reg_tran,        spi_to_memory_scoreboard) reg_export;


    // Golden memory
    logic [7:0] ref_mem [3:0];
    bit         ref_valid [3:0];


    // Expected SPI address sequence: 0 -> 1 -> 2 -> 3
    int expected_spi_addr;


    // Operation status
    bit operation_active;
    bit spi_done;




    function new(string name = "spi_to_memory_scoreboard", uvm_component parent);

        super.new(name, parent);

        spi_export = new("spi_export", this);
        reg_export = new("reg_export", this);

    endfunction



    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        expected_spi_addr = 0;

        operation_active = 1'b0;
        spi_done         = 1'b0;


        foreach(ref_mem[i]) begin
            ref_mem[i]   = 8'h00;
            ref_valid[i] = 1'b0;
        end

    endfunction



    // ============================================================
    // SPI MONITOR INPUT
    // ============================================================

    function void write_spi(spi_transaction spi_tx);


        // --------------------------------------------------------
        // SPI is allowed only during an active acquisition
        // --------------------------------------------------------

        if(!operation_active) begin

            `uvm_error("SCB_SPI", "SPI transaction detected without an active Handshake operation")


            return;

        end


        // --------------------------------------------------------
        // After receiving addresses 0-3, no additional SPI
        // transaction is allowed until a new acquisition starts
        // --------------------------------------------------------

        if(spi_done) begin

            `uvm_error("SCB_SPI", $sformatf("Extra SPI transaction detected after acquisition completed. Address=%0d data=0x%0h", spi_tx.address, spi_tx.data))


            return;

        end


        // --------------------------------------------------------
        // Check SPI address order
        // --------------------------------------------------------

        if(spi_tx.address != expected_spi_addr) begin

            `uvm_error("SCB_SPI", $sformatf("SPI address mismatch. Expected %0d, got %0d", expected_spi_addr, spi_tx.address))


        end

        else begin

            `uvm_info("SCB_SPI", $sformatf("SPI transaction PASS: address=%0d data=0x%0h", spi_tx.address, spi_tx.data), UVM_LOW)

        end


        // --------------------------------------------------------
        // Legal SPI addresses are 0-3
        // --------------------------------------------------------

        if(spi_tx.address < 4) begin


            // Save SPI data as golden reference
            ref_mem[spi_tx.address]   = spi_tx.data;
            ref_valid[spi_tx.address] = 1'b1;


            // Address 3 means all four SPI transactions arrived
            if(spi_tx.address == 3) begin

                spi_done = 1'b1;

                expected_spi_addr = 0;

                `uvm_info("SCB_SPI", "All four SPI transactions were received", UVM_LOW)

            end

            else begin

                expected_spi_addr = spi_tx.address + 1;

            end

        end

        else begin

            `uvm_error("SCB_SPI", $sformatf("Illegal SPI address: %0d", spi_tx.address))

        end

    endfunction



    // ============================================================
    // REGISTER MONITOR INPUT
    // ============================================================

    function void write_reg(reg_tran reg_tx);


        // ========================================================
        // WRITE
        // ========================================================

        if(reg_tx.kind == 1'b0) begin


            // ----------------------------------------------------
            // WRITE to Handshake register
            // ----------------------------------------------------

            if(reg_tx.address == 3'h4) begin


                `uvm_info("SCB_REG", $sformatf("Handshake WRITE detected: %0b", reg_tx.data[0]), UVM_LOW)


                // Optional information for reserved bits
                if(reg_tx.data[7:1] != 7'h00)
                    `uvm_info("SCB_REG", $sformatf("WRITE attempt to reserved bits detected: bits[7:1]=0x%0h - DUT should ignore them", reg_tx.data[7:1]), UVM_LOW)


                // ------------------------------------------------
                // Handshake = 1
                // ------------------------------------------------

                if(reg_tx.data[0] == 1'b1) begin


                    // --------------------------------------------
                    // DUT is already busy
                    //
                    // Important:
                    // Do NOT reset the reference model here.
                    // The second trigger should be ignored.
                    // --------------------------------------------

                    if(operation_active) begin

                        `uvm_info("SCB_BUSY", "Handshake=1 written while operation is already active - retrigger should be ignored", UVM_LOW)

                    end


                    // --------------------------------------------
                    // Start a new acquisition
                    // --------------------------------------------

                    else begin

                        operation_active = 1'b1;
                        spi_done         = 1'b0;

                        expected_spi_addr = 0;


                        // Old reference data is no longer valid
                        foreach(ref_valid[i])
                            ref_valid[i] = 1'b0;


                        `uvm_info("SCB_REG", "New acquisition started", UVM_LOW)

                    end

                end

            end


            // ----------------------------------------------------
            // WRITE attempt to read-only Channel registers 0-3
            // ----------------------------------------------------

            else if(reg_tx.address < 4) begin

                `uvm_info("SCB_REG", $sformatf("WRITE to read-only register %0d detected - DUT should ignore it", reg_tx.address), UVM_LOW)

            end


            // ----------------------------------------------------
            // Illegal register address
            // ----------------------------------------------------

            else begin

                `uvm_error("SCB_REG", $sformatf("Illegal register address: %0d", reg_tx.address))


            end

        end



        // ========================================================
        // READ
        // ========================================================

        else begin


            // ----------------------------------------------------
            // READ Handshake register
            // ----------------------------------------------------

            if(reg_tx.address == 3'h4) begin


                // ------------------------------------------------
                // No operation currently active
                // ------------------------------------------------

                if(!operation_active) begin

                    if(reg_tx.data[0] != 1'b0) begin

                        `uvm_error("SCB_HS", $sformatf("Handshake mismatch. Expected 0, got %0b", reg_tx.data[0]))


                    end

                    else begin

                        `uvm_info("SCB_HS", "Handshake READ PASS: 0 - DUT is idle", UVM_LOW)

                    end

                end


                // ------------------------------------------------
                // SPI operation still running
                // ------------------------------------------------

                else if(!spi_done) begin

                    if(reg_tx.data[0] != 1'b1) begin

                        `uvm_error("SCB_HS", "Handshake went LOW before all SPI transactions completed")


                    end

                    else begin

                        `uvm_info("SCB_HS", "Handshake READ PASS: 1 - SPI still busy", UVM_HIGH)

                    end

                end


                // ------------------------------------------------
                // All SPI transactions already arrived
                //
                // DUT may still need some time before clearing
                // Handshake to 0
                // ------------------------------------------------

                else begin

                    if(reg_tx.data[0] == 1'b1) begin

                        `uvm_info("SCB_HS", "Handshake still HIGH after final SPI transaction - waiting for DUT completion", UVM_LOW)

                    end

                    else begin

                        operation_active = 1'b0;

                        `uvm_info("SCB_HS", "Handshake READ PASS: 0 - operation completed", UVM_LOW)

                    end

                end

            end



            // ----------------------------------------------------
            // READ Channel registers 0-3
            // ----------------------------------------------------

            else if(reg_tx.address < 4) begin


                // Reading channels before completion
                if(operation_active) begin

                    `uvm_error("SCB_REG", $sformatf("Register %0d read before Handshake indicated completion", reg_tx.address))


                end


                // No SPI reference exists
                else if(!ref_valid[reg_tx.address]) begin

                    `uvm_error("SCB_REG", $sformatf("Register %0d read before SPI reference data was received", reg_tx.address))


                end


                // Compare actual register data to SPI reference
                else if(reg_tx.data != ref_mem[reg_tx.address]) begin

                    `uvm_error("SCB_DATA", $sformatf("Register %0d mismatch. Expected 0x%0h, got 0x%0h", reg_tx.address, ref_mem[reg_tx.address], reg_tx.data))


                end


                else begin

                    `uvm_info("SCB_DATA", $sformatf("Register %0d PASS: 0x%0h", reg_tx.address, reg_tx.data), UVM_LOW)

                end

            end


            // ----------------------------------------------------
            // Illegal register address
            // ----------------------------------------------------

            else begin

                `uvm_error("SCB_REG", $sformatf("Illegal register address: %0d", reg_tx.address))


            end

        end

    endfunction


endclass
