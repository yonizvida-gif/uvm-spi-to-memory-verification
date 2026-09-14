class reg_driver extends uvm_driver #(reg_tran);
    `uvm_component_utils(reg_driver)

    virtual reg_if reg_vif;

    function new(string name = "reg_driver", uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", reg_vif))
            `uvm_fatal("NO_VIF", "Failed to get reg_vif")
			
    endfunction


    task run_phase(uvm_phase phase);

       reg_tran rsp;

       // Initial values
       @(reg_vif.drv_cb);

       reg_vif.drv_cb.enable  <= 1'b0;
       reg_vif.drv_cb.rd_wr   <= 1'b0;
       reg_vif.drv_cb.addr    <= 3'h0;
       reg_vif.drv_cb.wr_data <= 8'h00;


       forever begin

           // Get request from sequence
           seq_item_port.get_next_item(req);


           // Drive transaction
           @(reg_vif.drv_cb);

           reg_vif.drv_cb.enable <= 1'b1;
           reg_vif.drv_cb.rd_wr  <= req.kind;
           reg_vif.drv_cb.addr   <= req.address;

           if(req.kind == 1'b0)
               reg_vif.drv_cb.wr_data <= req.data;


           // DUT samples transaction at the posedge
            @(reg_vif.drv_cb);


           // READ
           if(req.kind == 1'b1) begin
 
	       rsp = reg_tran::type_id::create("rsp");
               rsp.set_id_info(req);

               rsp.kind    = req.kind;
               rsp.address = req.address;
               rsp.data    = reg_vif.drv_cb.rd_data;

           end


           // End transaction
           reg_vif.drv_cb.enable <= 1'b0;


           // Return response only for READ
           if(req.kind == 1'b1)
               seq_item_port.item_done(rsp);
           else
               seq_item_port.item_done();

       end

   endtask

endclass
