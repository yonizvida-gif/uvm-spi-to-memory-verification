interface spi_if ();
	
	logic cs;
   	logic sclk;
   	logic mosi;
   	logic miso;

	//Clocking Block 
    	clocking mon_cb @(posedge sclk);
      		default input #1ns output #1ns;
      		input cs,mosi,miso;  
    	endclocking

	clocking drv_cb @(negedge sclk);
      		//default input #0ns output #0ns;
      		input cs,mosi;  
		output miso;
    	endclocking
	
	modport dut_mp(
		input miso,
		output cs,sclk,mosi
	);
	
	

endinterface
