class reg_ro_seq extends uvm_sequence #(reg_tran);

    `uvm_object_utils(reg_ro_seq)


    function new(string name = "reg_ro_seq");
        super.new(name);
    endfunction


    task body();

        reg_tran tr;
        reg_tran rsp;

        bit [7:0] original_data;
        bit [7:0] write_data;


        // =========================================
        // Test all read-only registers 0-3
        // =========================================

        for(int ro_addr = 0; ro_addr < 4; ro_addr++) begin


            `uvm_info("REG_RO_SEQ", $sformatf("Testing read-only register %0d", ro_addr), UVM_LOW)


            // =====================================
            // 1. READ original value
            // =====================================

            tr = reg_tran::type_id::create($sformatf("read_before_write_%0d", ro_addr));

            start_item(tr);

            if(!tr.randomize() with {
                kind    == 1'b1;
                address == ro_addr;
            })
                `uvm_error("REG_RO_SEQ", "READ before WRITE randomization failed")

            finish_item(tr);

            get_response(rsp);

            original_data = rsp.data;

            `uvm_info("REG_RO_SEQ", $sformatf("Register %0d original value = 0x%0h", ro_addr, original_data), UVM_LOW)


            // =====================================
            // 2. Generate a different value
            // =====================================

            write_data = ~original_data;


            // =====================================
            // 3. Attempt WRITE to RO register
            // =====================================

            tr = reg_tran::type_id::create($sformatf("write_read_only_%0d", ro_addr));

            start_item(tr);

            if(!tr.randomize() with {
                kind    == 1'b0;
                address == ro_addr;
                data    == write_data;
            })
                `uvm_error("REG_RO_SEQ", "Read-only WRITE randomization failed")

            finish_item(tr);

            `uvm_info("REG_RO_SEQ", $sformatf("Attempted WRITE to read-only register %0d: data=0x%0h", ro_addr, write_data), UVM_LOW)


            // =====================================
            // 4. READ register again
            // =====================================

            tr = reg_tran::type_id::create($sformatf("read_after_write_%0d", ro_addr));

            start_item(tr);

            if(!tr.randomize() with {
                kind    == 1'b1;
                address == ro_addr;
            })
                `uvm_error("REG_RO_SEQ", "READ after WRITE randomization failed")

            finish_item(tr);

            get_response(rsp);


            // =====================================
            // 5. Verify register did not change
            // =====================================

            if(rsp.data != original_data)
                `uvm_error("REG_RO_SEQ", $sformatf("Read-only register %0d changed. Expected 0x%0h, got 0x%0h", ro_addr, original_data, rsp.data))
            else
                `uvm_info("REG_RO_SEQ", $sformatf("READ-ONLY TEST PASS: register %0d remained 0x%0h", ro_addr, rsp.data), UVM_LOW)

        end


        `uvm_info("REG_RO_SEQ", "All read-only registers 0-3 passed", UVM_LOW)

    endtask


endclass
