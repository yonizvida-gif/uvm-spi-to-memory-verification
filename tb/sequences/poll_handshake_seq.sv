class poll_handshake_seq extends uvm_sequence #(reg_tran);

    `uvm_object_utils(poll_handshake_seq)


    int max_polls = 200;


    function new(string name = "poll_handshake_seq");
        super.new(name);
    endfunction


    task body();

        reg_tran tr;
        reg_tran rsp;

        bit handshake_done;
        int poll_count;


        handshake_done = 1'b0;
        poll_count      = 0;


        while(!handshake_done && poll_count < max_polls) begin


            tr = reg_tran::type_id::create($sformatf("handshake_read_%0d", poll_count));
                    
                


            start_item(tr);

            if(!tr.randomize() with {
                kind    == 1'b1;    // READ
                address == 3'h4;    // Handshake register
            })
                `uvm_error("POLL_HS_SEQ", "Handshake READ randomization failed")
                          

            finish_item(tr);


            // Driver returns rd_data through response
            get_response(rsp);


            `uvm_info("POLL_HS_SEQ", $sformatf("Poll %0d: Handshake = %0b", poll_count, rsp.data[0]), UVM_HIGH)
                
                    
                    
                        


            // Handshake = 0 means acquisition completed
            if(rsp.data[0] == 1'b0) begin

                handshake_done = 1'b1;

            end

            else begin

                poll_count++;

                // Small interval between polls
                #100ns;

            end

        end


        if(!handshake_done) begin

            `uvm_fatal("POLL_HS_SEQ",
                $sformatf(
                    "Handshake did not return to 0 after %0d polls",
                    max_polls
                ))

        end


        `uvm_info("POLL_HS_SEQ",
                  "Acquisition completed - Handshake returned to 0",
                  UVM_LOW)

    endtask


endclass
