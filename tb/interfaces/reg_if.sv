interface reg_if(input logic clk);

    logic [2:0] addr;
    logic [7:0] wr_data;
    logic [7:0] rd_data;

    logic enable;
    logic rd_wr;    // 0 = WRITE, 1 = READ


    // Driver drives on falling edge
	clocking drv_cb @(negedge clk);
		default input #1step output #0;

		output enable, rd_wr, wr_data, addr;
		input  rd_data;
	endclocking


    // Monitor samples on rising edge
    clocking mon_cb @(posedge clk);
        default input #0 output #0;

        input enable, rd_wr, addr, wr_data, rd_data;
    endclocking


    modport dut_mp (
        input  clk,
        input  enable,
        input  rd_wr,
        input  addr,
        input  wr_data,
        output rd_data
    );

endinterface
