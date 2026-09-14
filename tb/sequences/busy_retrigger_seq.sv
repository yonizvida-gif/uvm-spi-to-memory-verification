class busy_retrigger_seq extends uvm_sequence #(reg_tran);

    `uvm_object_utils(busy_retrigger_seq)

    function new(string name = "busy_retrigger_seq");
        super.new(name);
    endfunction


    task body();

        reg_tran tr;
        reg_tran rsp;


        // =========================================
        // 1. READ Handshake and verify DUT is busy
        // =========================================

        tr = reg_tran::type_id::create("check_busy");

        start_item(tr);

        if(!tr.randomize() with {
            kind    == 1'b1;
            address == 3'h4;
        })
            `uvm_error("BUSY_SEQ", "Handshake READ randomization failed")

        finish_item(tr);

        get_response(rsp);


        if(rsp.data[0] != 1'b1)
            `uvm_fatal("BUSY_SEQ", $sformatf("DUT is not busy. Expected Handshake=1, got %0b", rsp.data[0]))

        `uvm_info("BUSY_SEQ", "DUT is busy - Handshake = 1", UVM_LOW)


        // =========================================
        // 2. WRITE Handshake = 1 again while busy
        // =========================================

        tr = reg_tran::type_id::create("retrigger_busy");

        start_item(tr);

        if(!tr.randomize() with {
            kind    == 1'b0;
            address == 3'h4;
            data    == 8'h01;
        })
            `uvm_error("BUSY_SEQ", "Busy retrigger WRITE randomization failed")

        finish_item(tr);


        `uvm_info("BUSY_SEQ", "Second Handshake=1 written while DUT is busy - SPI master should ignore retrigger", UVM_LOW)

    endtask

endclass
