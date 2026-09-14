`uvm_analysis_imp_decl(_spi_cov)
`uvm_analysis_imp_decl(_reg_cov)


class spi_to_memory_coverage extends uvm_component;

    `uvm_component_utils(spi_to_memory_coverage)


    // ============================================================
    // Analysis inputs
    // ============================================================

    uvm_analysis_imp_spi_cov #(spi_transaction, spi_to_memory_coverage) spi_export;
    uvm_analysis_imp_reg_cov #(reg_tran,        spi_to_memory_coverage) reg_export;


    // ============================================================
    // Sample variables
    //
    // The covergroups sample these variables.
    // ============================================================

    bit [7:0] spi_addr_sample;

    bit [2:0] reg_addr_sample;
    bit       reg_kind_sample;

    bit       handshake_value_sample;

    bit       busy_retrigger_sample;


    // ============================================================
    // Internal state
    //
    // Used only to recognize a retrigger while an acquisition
    // is already active.
    //
    // This is NOT a reference model and does not check correctness.
    // ============================================================

    bit operation_active_cov;
    bit spi_done_cov;


    // ============================================================
    // SPI COVERAGE
    // ============================================================

    covergroup spi_cg;

        option.per_instance = 1;


        // --------------------------------------------------------
        // Cover all four legal SPI addresses
        // --------------------------------------------------------

        spi_address_cp : coverpoint spi_addr_sample {

            bins address_0 = {8'h00};
            bins address_1 = {8'h01};
            bins address_2 = {8'h02};
            bins address_3 = {8'h03};


            // Check that we observed the complete SPI address order
            bins address_sequence = (8'h00 => 8'h01 => 8'h02 => 8'h03);


            // Other SPI addresses are not part of the legal
            // functional coverage space.
            // The scoreboard is responsible for detecting errors.
            ignore_bins other_addresses = {[8'h04:8'hFF]};

        }

    endgroup



    // ============================================================
    // REGISTER INTERFACE COVERAGE
    // ============================================================

    covergroup reg_cg;

        option.per_instance = 1;


        // --------------------------------------------------------
        // Register addresses
        //
        // 0-3 = Channel registers
        // 4   = Handshake register
        // --------------------------------------------------------

        reg_address_cp : coverpoint reg_addr_sample {

            bins channel_registers[] = {[3'h0:3'h3]};
            bins handshake_register  = {3'h4};

            ignore_bins unused_addresses = {[3'h5:3'h7]};

        }


        // --------------------------------------------------------
        // Register operation
        //
        // kind = 0 -> WRITE
        // kind = 1 -> READ
        // --------------------------------------------------------

        reg_operation_cp : coverpoint reg_kind_sample {

            bins write_operation = {1'b0};
            bins read_operation  = {1'b1};

        }


        // --------------------------------------------------------
        // Cross coverage
        //
        // Checks which operation was performed on each address.
        //
        // Examples:
        //
        // Address 0 + READ
        // Address 0 + WRITE
        // Address 1 + READ
        // Address 1 + WRITE
        // ...
        // Address 4 + READ
        // Address 4 + WRITE
        // --------------------------------------------------------

        reg_address_operation_cross : cross reg_address_cp, reg_operation_cp;
                                            

    endgroup



    // ============================================================
    // HANDSHAKE COVERAGE
    // ============================================================

    covergroup handshake_cg;

        option.per_instance = 1;


        // --------------------------------------------------------
        // Handshake READ value
        //
        // 1 -> acquisition is still active
        // 0 -> acquisition completed / DUT idle
        // --------------------------------------------------------

        handshake_value_cp : coverpoint handshake_value_sample {

            bins handshake_low  = {1'b0};
            bins handshake_high = {1'b1};

        }

    endgroup



    // ============================================================
    // BUSY RETRIGGER COVERAGE
    // ============================================================

    covergroup busy_retrigger_cg;

        option.per_instance = 1;


        // This covergroup is sampled only when a second
        // Handshake=1 WRITE occurs while an acquisition
        // is already active.
        busy_retrigger_cp : coverpoint busy_retrigger_sample {

            bins retrigger_while_busy = {1'b1};

        }

    endgroup



    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function new(string name = "spi_to_memory_coverage", uvm_component parent = null);
                 
        super.new(name, parent);


        // Create analysis ports
        spi_export = new("spi_export", this);
        reg_export = new("reg_export", this);


        // Create covergroups
        spi_cg            = new();
        reg_cg            = new();
        handshake_cg      = new();
        busy_retrigger_cg = new();

    endfunction



    // ============================================================
    // BUILD PHASE
    // ============================================================

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        operation_active_cov = 1'b0;
        spi_done_cov         = 1'b0;

        spi_addr_sample        = 8'h00;
        reg_addr_sample        = 3'h0;
        reg_kind_sample        = 1'b0;
        handshake_value_sample = 1'b0;
        busy_retrigger_sample  = 1'b0;

    endfunction



    // ============================================================
    // SPI MONITOR INPUT
    // ============================================================

    function void write_spi_cov(spi_transaction spi_tx);


        // --------------------------------------------------------
        // Sample SPI address
        // --------------------------------------------------------

        spi_addr_sample = spi_tx.address;

        spi_cg.sample();


        // --------------------------------------------------------
        // Address 3 is the final SPI transaction in an acquisition.
        //
        // We use this only for recognizing the Busy state.
        // No functional checking is performed here.
        // --------------------------------------------------------

        if(spi_tx.address == 8'h03)
            spi_done_cov = 1'b1;

    endfunction



    // ============================================================
    // REGISTER MONITOR INPUT
    // ============================================================

    function void write_reg_cov(reg_tran reg_tx);


        // --------------------------------------------------------
        // Sample every register transaction
        // --------------------------------------------------------

        reg_addr_sample = reg_tx.address;
        reg_kind_sample = reg_tx.kind;

        reg_cg.sample();


        // ========================================================
        // WRITE
        // ========================================================

        if(reg_tx.kind == 1'b0) begin


            // ----------------------------------------------------
            // WRITE Handshake = 1
            // ----------------------------------------------------

            if((reg_tx.address == 3'h4) &&
               (reg_tx.data[0] == 1'b1)) begin


                // -----------------------------------------------
                // An operation is already active.
                //
                // This is the Busy Retrigger scenario.
                // -----------------------------------------------

                if(operation_active_cov) begin

                    busy_retrigger_sample = 1'b1;

                    busy_retrigger_cg.sample();

                    `uvm_info("COV_BUSY", "Covered Handshake retrigger while operation is active", UVM_HIGH)

                end


                // -----------------------------------------------
                // First Handshake=1 starts an acquisition.
                // -----------------------------------------------

                else begin

                    operation_active_cov = 1'b1;
                    spi_done_cov         = 1'b0;

                end

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

                handshake_value_sample = reg_tx.data[0];

                handshake_cg.sample();


                // -----------------------------------------------
                // When all SPI transactions were received and
                // Handshake becomes 0, the operation is finished.
                // -----------------------------------------------

                if(operation_active_cov &&
                   spi_done_cov &&
                   (reg_tx.data[0] == 1'b0)) begin

                    operation_active_cov = 1'b0;
                    spi_done_cov         = 1'b0;

                end

            end

        end

    endfunction



    // ============================================================
    // REPORT PHASE
    // ============================================================

    function void report_phase(uvm_phase phase);

        real spi_coverage;
        real reg_coverage;
        real handshake_coverage;
        real busy_coverage;


        spi_coverage       = spi_cg.get_inst_coverage();
        reg_coverage       = reg_cg.get_inst_coverage();
        handshake_coverage = handshake_cg.get_inst_coverage();
        busy_coverage      = busy_retrigger_cg.get_inst_coverage();


        `uvm_info("COVERAGE", $sformatf("SPI coverage             = %0.2f%%", spi_coverage), UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("Register coverage        = %0.2f%%", reg_coverage), UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("Handshake coverage       = %0.2f%%", handshake_coverage), UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("Busy retrigger coverage  = %0.2f%%", busy_coverage), UVM_LOW)

    endfunction


endclass
