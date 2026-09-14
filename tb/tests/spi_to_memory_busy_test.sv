class spi_to_memory_busy_test extends spi_to_memory_base_test;

    `uvm_component_utils(spi_to_memory_busy_test)


    function new(string name = "spi_to_memory_busy_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction



    task run_phase(uvm_phase phase);

        handshake_write_seq hs_seq;
        busy_retrigger_seq  busy_seq;
        poll_handshake_seq  poll_seq;
        channel_read_seq    read_seq;


        phase.raise_objection(this);

        #200ns;


        // =========================================
        // 1. Start normal acquisition
        // =========================================

        hs_seq = handshake_write_seq::type_id::create("hs_seq");
        hs_seq.start(env.reg_agt.seqr);


        // =========================================
        // 2. Write Handshake=1 again while busy
        // =========================================

        busy_seq = busy_retrigger_seq::type_id::create("busy_seq");
        busy_seq.start(env.reg_agt.seqr);


        // =========================================
        // 3. Wait for original acquisition to finish
        // =========================================

        poll_seq = poll_handshake_seq::type_id::create("poll_seq");
        poll_seq.start(env.reg_agt.seqr);


        // =========================================
        // 4. Read Channel0-3
        // =========================================

        read_seq = channel_read_seq::type_id::create("read_seq");
        read_seq.start(env.reg_agt.seqr);


        `uvm_info("BUSY_TEST", "Busy retrigger test completed successfully", UVM_LOW)

        phase.drop_objection(this);

    endtask

endclass
