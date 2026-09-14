class spi_agent extends uvm_agent;
	`uvm_component_utils(spi_agent)
	
	spi_driver drv;
	
	spi_monitor mon1;
	
	
	function new(string name = "spi_agent", uvm_component parent);
		super.new(name,parent);
	endfunction
	
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	
		if(get_is_active() == UVM_ACTIVE) begin
			drv = spi_driver::type_id::create("drv",this);
		end
		
		mon1 = spi_monitor::type_id::create("mon1",this);
	endfunction
	

endclass
	