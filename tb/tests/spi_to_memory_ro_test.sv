class spi_to_memory_ro_test extends spi_to_memory_base_test;

    `uvm_component_utils(spi_to_memory_ro_test)


    function new(string name = "spi_to_memory_ro_test", uvm_component parent = null);
        
        super.new(name, parent);

    endfunction


    task run_phase(uvm_phase phase);

        handshake_write_seq hs_seq;
        poll_handshake_seq  poll_seq;
        channel_read_seq    read_seq;
        reg_ro_seq          ro_seq;


        phase.raise_objection(this);


        // Wait until reset is finished
        #200ns;


        // =========================================
        // 1. Start acquisition
        // =========================================

        hs_seq = handshake_write_seq::type_id::create(
            "hs_seq"
        );

        hs_seq.start(env.reg_agt.seqr);


        // =========================================
        // 2. Wait until acquisition completes
        // =========================================

        poll_seq = poll_handshake_seq::type_id::create(
            "poll_seq"
        );

        poll_seq.start(env.reg_agt.seqr);


        // =========================================
        // 3. Read all channels normally
        // =========================================

        read_seq = channel_read_seq::type_id::create(
            "read_seq"
        );

        read_seq.start(env.reg_agt.seqr);


        // =========================================
        // 4. Test read-only behavior
        // =========================================

        ro_seq = reg_ro_seq::type_id::create(
            "ro_seq"
        );

        ro_seq.start(env.reg_agt.seqr);


        `uvm_info(
            "RO_TEST",
            "Read-only register test completed",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask


endclass
