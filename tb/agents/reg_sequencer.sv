class reg_sequencer  extends uvm_sequencer #(reg_tran);
	`uvm_component_utils(reg_sequencer )
	
	function new(string name = "reg_sequencer", uvm_component parent);
		super.new(name,parent);
	endfunction
	
endclass
