class reg_agent extends uvm_agent;
    `uvm_component_utils(reg_agent)

    reg_driver    drv;
    reg_sequencer seqr;
    reg_monitor   mon2;

    function new(string name = "reg_agent", uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Monitor always exists
        mon2 = reg_monitor::type_id::create("mon2", this);

        // Driver + Sequencer only in ACTIVE mode
        if(get_is_active() == UVM_ACTIVE) begin
            drv  = reg_driver::type_id::create("drv", this);
            seqr = reg_sequencer::type_id::create("seqr", this);
        end

    endfunction


    function void connect_phase(uvm_phase phase);

        if(get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end

    endfunction

endclass