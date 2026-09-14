class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_if spi_vif;

    uvm_analysis_port #(spi_transaction) ap;

    function new(string name = "spi_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
            `uvm_fatal("NO_VIF", "Failed to get spi_vif");
    endfunction


    task run_phase(uvm_phase phase);

        spi_transaction tr;
        logic [7:0] mosi_mon;
        logic [7:0] miso_mon;

        forever begin

            mosi_mon = 8'h00;
            miso_mon = 8'h00;

            // Start of SPI transaction
            @(negedge spi_vif.cs);

            // Capture address from MOSI
            for(int i=7; i>=0; i--) begin
                @(posedge spi_vif.sclk);
                mosi_mon[i] = spi_vif.mosi;
            end

            // Capture data from MISO
            for(int j=7; j>=0; j--) begin
                @(posedge spi_vif.sclk);
                miso_mon[j] = spi_vif.miso;
            end

            tr = spi_transaction::type_id::create("tr");

            tr.address = mosi_mon;
            tr.data    = miso_mon;

            ap.write(tr);

            //tr.print();

        end

    endtask

endclass
