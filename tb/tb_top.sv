module tb_top;

  import uvm_pkg::*;
  import tb_pkg::*;

  logic clk;
  logic rst;

  spi_if spi_vif();
  reg_if reg_vif(clk);

  spi_to_memory dut (
    .clk     (clk),
    .rst     (rst),

    .miso    (spi_vif.miso),
    .mosi    (spi_vif.mosi),
    .sclk    (spi_vif.sclk),
    .cs      (spi_vif.cs),

    .addr    (reg_vif.addr),
    .wr_data (reg_vif.wr_data),
    .rd_data (reg_vif.rd_data),
    .enable  (reg_vif.enable),
    .rd_wr   (reg_vif.rd_wr)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz
  end

  initial begin
    rst = 1;
    repeat (5) @(negedge clk);
    rst = 0;
    
  end

  initial begin
    uvm_config_db#(virtual spi_if)::set(null, "*", "spi_vif", spi_vif);
           
    uvm_config_db#(virtual reg_if)::set(null, "*", "reg_vif", reg_vif);   

	
    run_test();
  end

endmodule
