class channel_read_seq extends uvm_sequence #(reg_tran);

    `uvm_object_utils(channel_read_seq)


    bit [7:0] channel_data [3:0];


    function new(string name = "channel_read_seq");
        super.new(name);
    endfunction


    task body();

        reg_tran tr;
        reg_tran rsp;


        for(int i = 0; i < 4; i++) begin


            tr = reg_tran::type_id::create($sformatf("read_channel_%0d", i));


            start_item(tr);

            if(!tr.randomize() with {
                kind    == 1'b1;    // READ
                address == i;
            })
                `uvm_error("CHANNEL_READ_SEQ", "Channel READ randomization failed")
                        
            finish_item(tr);


            // Receive rd_data from register driver
            get_response(rsp);


            channel_data[i] = rsp.data;


            `uvm_info("CHANNEL_READ_SEQ", $sformatf("Channel %0d READ: data = 0x%0h", i, rsp.data), UVM_LOW)         
                

        end


        `uvm_info("CHANNEL_READ_SEQ", "Finished reading Channel0-3", UVM_LOW)
                 
    endtask


endclass
