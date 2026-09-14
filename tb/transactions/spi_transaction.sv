class spi_transaction extends uvm_sequence_item;

    rand bit [7:0] address; // MOSI
    rand bit [7:0] data;    // MISO

    `uvm_object_utils_begin(spi_transaction)
        `uvm_field_int(address, UVM_DEFAULT | UVM_UNSIGNED)
        `uvm_field_int(data,    UVM_DEFAULT | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "spi_transaction");
        super.new(name);
    endfunction
	
	constraint addr_c {
		address inside {[0:3]};
	}


endclass