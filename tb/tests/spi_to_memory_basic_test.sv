class spi_to_memory_basic_test extends spi_to_memory_base_test;

    `uvm_component_utils(spi_to_memory_basic_test)



    function new(string name = "spi_to_memory_basic_test", uvm_component parent = null);
                 
        super.new(name, parent);

    endfunction




    task run_phase(uvm_phase phase);

        handshake_write_seq hs_seq;
        poll_handshake_seq  poll_seq;
        channel_read_seq    read_seq;


        phase.raise_objection(this);


        // =========================================
        // Wait until reset is finished
        // =========================================

        #200ns;


        // =========================================
        // 1. Start acquisition
        // WRITE Handshake = 1
        // =========================================

        hs_seq = handshake_write_seq::type_id::create(
            "hs_seq"
        );

        hs_seq.start(env.reg_agt.seqr);



        // =========================================
        // 2. Wait until acquisition is complete
        // Poll Handshake until it becomes 0
        // =========================================

        poll_seq = poll_handshake_seq::type_id::create(
            "poll_seq"
        );

        poll_seq.start(env.reg_agt.seqr);



        // =========================================
        // 3. Read Channel0-3
        // =========================================

        read_seq = channel_read_seq::type_id::create(
            "read_seq"
        );

        read_seq.start(env.reg_agt.seqr);



        `uvm_info(
            "TEST",
            "End-to-End acquisition test completed",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask


endclass
