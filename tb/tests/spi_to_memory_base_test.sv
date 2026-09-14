class spi_to_memory_base_test extends uvm_test;

    `uvm_component_utils(spi_to_memory_base_test)


    spi_to_memory_env env;


    function new(string name = "spi_to_memory_base_test", uvm_component parent = null);
                 
        super.new(name, parent);

    endfunction



    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // Both agents are ACTIVE in unit-level verification
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.spi_agt", "is_active", UVM_ACTIVE);
            
	uvm_config_db#(uvm_active_passive_enum)::set(this, "env.reg_agt", "is_active", UVM_ACTIVE);


        env = spi_to_memory_env::type_id::create("env", this);
            

    endfunction



endclass
