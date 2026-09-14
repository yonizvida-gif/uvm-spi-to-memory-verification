class handshake_write_seq extends uvm_sequence #(reg_tran);

    `uvm_object_utils(handshake_write_seq)


    function new(string name = "handshake_write_seq");
        super.new(name);
    endfunction


    task body();

        reg_tran tr;


        tr = reg_tran::type_id::create("write_handshake");


        start_item(tr);

        if(!tr.randomize() with {
            kind    == 1'b0;    // WRITE
            address == 3'h4;    // Handshake register
            data    == 8'h01;   // Start acquisition
        })
            `uvm_error("HS_WRITE_SEQ", "Handshake WRITE randomization failed")
                       
        finish_item(tr);


        `uvm_info("HS_WRITE_SEQ", "Handshake WRITE completed: address=4 data=1",  UVM_LOW)
                                  

    endtask


endclass
