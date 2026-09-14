class spi_driver extends uvm_driver #(spi_transaction);

    `uvm_component_utils(spi_driver)

    virtual spi_if spi_vif;

    logic [7:0] mosi_drv;
    logic [7:0] slave_memory [3:0];

    int transaction_count;
    int acquisition_count;


    function new(string name = "spi_driver", uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
            `uvm_fatal("NO_VIF", "Failed to get spi_vif")

    endfunction


    task run_phase(uvm_phase phase);

        transaction_count = 0;
        acquisition_count = 1;

        // Random data for first acquisition
        randomize_slave_memory();

        // Initial MISO value
        spi_vif.miso <= 1'b0;


        forever begin

            mosi_drv = 8'h00;

            // Wait for start of SPI transaction
            // CS is active LOW
            @(negedge spi_vif.cs);


            // =========================================
            // Capture 8-bit SPI address from MOSI
            // =========================================

            for(int i = 7; i >= 0; i--) begin
                @(posedge spi_vif.sclk);
                mosi_drv[i] = spi_vif.mosi;
            end


            `uvm_info("SPI_DRV", $sformatf("Acquisition %0d: SPI address received = %0d", acquisition_count, mosi_drv), UVM_LOW)


            // =========================================
            // Send 8-bit data on MISO
            // =========================================

            for(int j = 7; j >= 0; j--) begin
                @(negedge spi_vif.sclk);
                spi_vif.drv_cb.miso <= slave_memory[mosi_drv[1:0]][j];
            end


            `uvm_info("SPI_DRV", $sformatf("Acquisition %0d: SPI data sent address=%0d data=0x%0h", acquisition_count, mosi_drv[1:0], slave_memory[mosi_drv[1:0]]), UVM_LOW)


            // Wait until current SPI transaction ends
            wait(spi_vif.cs == 1'b1);


            // One SPI transaction completed
            transaction_count++;


            // =========================================
            // 4 SPI transactions = one acquisition
            // =========================================

            if(transaction_count == 4) begin

                `uvm_info("SPI_DRV", $sformatf("Acquisition %0d completed", acquisition_count), UVM_LOW)

                transaction_count = 0;
                acquisition_count++;

                // Prepare new random data for next acquisition
                randomize_slave_memory();

            end

        end

    endtask


    // =============================================
    // Generate new random SPI slave data
    // =============================================

    task randomize_slave_memory();

        foreach(slave_memory[i]) begin
            slave_memory[i] = $urandom_range(0, 255);
        end

        `uvm_info("SPI_DRV", $sformatf("Acquisition %0d new data: CH0=0x%0h CH1=0x%0h CH2=0x%0h CH3=0x%0h", acquisition_count, slave_memory[0], slave_memory[1], slave_memory[2], slave_memory[3]), UVM_LOW)

    endtask


endclass
