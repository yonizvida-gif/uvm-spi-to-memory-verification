class reg_tran extends uvm_sequence_item;

    rand bit [2:0] address;
    rand bit [7:0] data;
    rand bit       kind;      // 0 = WRITE, 1 = READ

    `uvm_object_utils_begin(reg_tran)
        `uvm_field_int(address, UVM_DEFAULT | UVM_UNSIGNED)
        `uvm_field_int(data,    UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(kind,    UVM_DEFAULT | UVM_UNSIGNED)
    `uvm_object_utils_end

    function new(string name = "reg_tran");
        super.new(name);
    endfunction

    constraint addr_c {
        address inside {[3'h0:3'h4]};
    }

endclass