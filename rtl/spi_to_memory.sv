//! { signal: [
//!     {                             node: '.IJ....'},
//!  { name: "start",    wave: "010..................."},
//!   ['spi',
//!  { name: "cs",    wave: "1..0...............1..." },
//!  { name: "sclk",  wave: "P.P.P.P.P.P.P.P.P.P.P.P.P" },
//!  { name: "mosi",  wave: "x...0.....4.x...........", data: [ "addr"] },
//!  { name: "miso",  wave: "x...........3.......x...", data: ["data"] },
//!  ],
//!  {},
//!  {},
//!  ['Data Out',
//!  { name: "address[1:0]",  wave: "x..x..x.x..........4x..", data: ["addr"] },
//!  { name: "data[7:0]",  wave: "x..x..x.x..........3x..", data: ["data"] },
//!  { name: "valid", wave: "0..................10.." }
//!  ],
//! ],
//!    edge: [
//!      'I+J 160 ns'
//!   ],
//!  head:{
//!     text:'WaveDrom spi example for a read cycle for a single address',
//!     tick:0,
//!     every:2
//!   }}




//! {
//!   signal: [
//!     { name: "clk",        wave: "P.....",                                           period: 2  },
//!     { name: "enable", wave: "01010.",                                           period: 2  },
//!     { name: "wr",     wave: "010...",                                           period: 2  },
//!     { name: "addr",   wave: "x.2.x.2.x...",   data: ["addr","addr"] },
//!     { name: "data",   wave: "x.2.x..x....",   data: ["write data"] },
//!     { name: "rd_data",wave: "x.......2.x.",   data: ["read data"] },
//!   ],
//!   head:{
//!     text:'WaveDrom Memory Example',
//!     tick:0,
//!     every:2
//!   }
//! }


//! *Describing the behavior of the DUT from memory side*
//! 1. When the user writes the value 1 to the handshake bit, the DUT is read through the SPI to the addresses 0x-0-0x3. When the information of the above-mentioned 4 channels are stored in the 4 registers indicated in the Reg Bank (below), handshake will remain in 1 until the operation of storing the 4 channels in the registers is valid, when handshake drops to 0 (reset will by by the DUT), this means that the information in the registers is valid and therefore the user needs to read the information from the 4 registers , then to restart the reading of the spi in the DUT the user must reset the handshake register bit and this operation will be carried out as described over and over again
module spi_to_memory (
    input clk, //! 100 MHz
    input rst,  //! Active high reset

    // SPI interface signals
    input miso, //! Master In Slave Out
    output reg mosi, //! Master Out Slave In
    output reg sclk, //! 6.25 MHz 
    output reg cs, //! Active low
   
    
    // Memory interface signals
    input [2:0] addr,  //! Address for operation from user
    input [7:0] wr_data, //! Data provided by user for write operation
    output reg [7:0] rd_data, //! Data to send to user for read operation
    input enable, //! Enable signal from user for operation
    input rd_wr //! Operation type from user, 0-write, 1-read
);

    // Internal registers for SPI data storage
    reg [7:0] data_registers [3:0]; // Array of 4 data registers
    reg handshake_register; // Handshake register to manage SPI read start
    reg start_spi;
    reg start;
    reg prev_sclk;
    // Local signals for SPI master interface
	wire [1:0] spi_addr;
    wire [7:0] spi_data;
    wire spi_valid;

    // Instantiate the SPI master module
    spi_master spi (
        .clk(clk),
        .rst(rst),
        .start(start),
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk),
        .cs(cs),
        .addr(spi_addr),
        .data(spi_data),
        .valid(spi_valid)
    );

    // Control logic for reading SPI data and handling memory operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            data_registers[0] <= 8'h00;
            data_registers[1] <= 8'h00;
            data_registers[2] <= 8'h00;
            data_registers[3] <= 8'h00;
            handshake_register <= 1'b0;
            start <= 1'b0;
            prev_sclk <= 1'b0;
            start_spi<= 1'b0;
            rd_data <= 8'h0;
        end 
        else begin
            // Handle incoming valid SPI data
            if (spi_valid) begin
                data_registers[spi_addr] <= spi_data;
                if(spi_addr==2'h3)//last register
                    handshake_register <= 1'b0;  // Set handshake on valid SPI data receipt
            end

            // Memory operations driven by the user
            if (enable) begin
                if (rd_wr == 1'b1) begin
                    // Read operation: load data from the selected register to rd_data
                    if(addr<3'h4)
                        rd_data <= data_registers[addr];
                    else if(addr==3'h4)
                        rd_data <={7'h0,handshake_register};
                    else
                        rd_data <= 8'h0;
                end 
                else begin
                    // Write operation: store user provided data to the selected register
                    if (addr==3'h4)//RW only for handshake_register
                    handshake_register <= wr_data[0];
                    start_spi <= wr_data[0];
                end
            end
        end
        prev_sclk <= sclk;
        if (!prev_sclk && sclk) begin
            if (start_spi) begin
                start <= 1'b1; // Start SPI read based on some user trigger
                start_spi <= 1'b0; // Reset handshake after triggering SPI read
            end else begin
                start <= 1'b0;
            end
        end
    end

    // // Optional: SPI read initiation based on handshake or other user signal
    // always_ff @(posedge sclk) begin
    //     if (start_spi) begin
    //         start <= 1'b1; // Start SPI read based on some user trigger
    //         start_spi <= 1'b0; // Reset handshake after triggering SPI read
    //     end else begin
    //         start <= 1'b0;
    //     end
    // end
endmodule
