package tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"


    // ============================================================
    // Transactions
    // ============================================================

    `include "spi_transaction.sv"
    `include "reg_tran.sv"


    // ============================================================
    // Sequences
    // ============================================================

    `include "handshake_write_seq.sv"
    `include "poll_handshake_seq.sv"
    `include "channel_read_seq.sv"
    `include "reg_ro_seq.sv"
    `include "busy_retrigger_seq.sv"


    // ============================================================
    // Register Agent
    // ============================================================

    `include "reg_sequencer.sv"
    `include "reg_driver.sv"
    `include "reg_monitor.sv"
    `include "reg_agent.sv"


    // ============================================================
    // SPI Agent
    // ============================================================

    `include "spi_driver.sv"
    `include "spi_monitor.sv"
    `include "spi_agent.sv"


    // ============================================================
    // Scoreboard + Coverage + Environment
    // ============================================================

    `include "spi_to_memory_scoreboard.sv"
    `include "spi_to_memory_coverage.sv"
    `include "spi_to_memory_env.sv"


    // ============================================================
    // Tests
    // ============================================================

    `include "spi_to_memory_base_test.sv"
    `include "spi_to_memory_basic_test.sv"
    `include "spi_to_memory_ro_test.sv"
    `include "spi_to_memory_repeat_test.sv"
    `include "spi_to_memory_busy_test.sv"


endpackage