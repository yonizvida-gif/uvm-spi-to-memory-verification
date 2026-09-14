class reg_monitor extends uvm_monitor;
    `uvm_component_utils(reg_monitor)

    virtual reg_if reg_vif;

    uvm_analysis_port #(reg_tran) ap;


    function new(string name = "reg_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", reg_vif))
            `uvm_fatal("NO_VIF", "Failed to get reg_vif")
			
    endfunction


    task run_phase(uvm_phase phase);

        reg_tran tr;

        forever begin

            @(reg_vif.mon_cb);

            if(reg_vif.mon_cb.enable) begin

                tr = reg_tran::type_id::create("tr");

                tr.kind    = reg_vif.mon_cb.rd_wr;
                tr.address = reg_vif.mon_cb.addr;

                // WRITE
                if(tr.kind == 1'b0)
                    tr.data = reg_vif.mon_cb.wr_data;

                // READ
                else
                    tr.data = reg_vif.mon_cb.rd_data;

                ap.write(tr);

                //tr.print();

            end

        end

    endtask

endclass
