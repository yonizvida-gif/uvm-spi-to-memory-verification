class spi_to_memory_env extends uvm_env;
    `uvm_component_utils(spi_to_memory_env)

    spi_agent      spi_agt;
    reg_agent      reg_agt;
	
    spi_to_memory_scoreboard scor;

    spi_to_memory_coverage cov;
	
    function new(string name = "spi_to_memory_env", uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        spi_agt = spi_agent::type_id::create("spi_agt", this);
        reg_agt = reg_agent::type_id::create("reg_agt", this);
		
	scor = spi_to_memory_scoreboard::type_id::create("scor", this);
	cov  = spi_to_memory_coverage::type_id::create("cov", this);
    endfunction
	
	function void connect_phase(uvm_phase phase);
		spi_agt.mon1.ap.connect(scor.spi_export);
		reg_agt.mon2.ap.connect(scor.reg_export);

		spi_agt.mon1.ap.connect(cov.spi_export);
		reg_agt.mon2.ap.connect(cov.reg_export);
	endfunction

endclass
