# UVM SPI-to-Memory Verification

A reusable UVM verification environment for an SPI-to-Memory RTL design.

The project verifies an RTL block that starts an SPI acquisition through a memory-mapped Handshake register, reads four SPI channel values, stores them in read-only registers, and exposes the results through a register interface.

The environment includes a reactive SPI slave model, end-to-end scoreboard checking, functional coverage, cross coverage, SystemVerilog Assertions, and multiple directed test scenarios.

---

## DUT Overview

The DUT contains:

- A register interface for software-style access
- A Handshake register at address `4`
- Four read-only channel registers at addresses `0-3`
- An SPI master that performs four SPI transactions
- Internal storage for the four received channel values

A normal acquisition is:

```text
WRITE Handshake = 1
        |
        v
SPI transaction address 0
SPI transaction address 1
SPI transaction address 2
SPI transaction address 3
        |
        v
Store received data in Channel0-3
        |
        v
Handshake returns to 0
        |
        v
READ Channel0-3
```

The DUT is the SPI master.  
The UVM SPI agent behaves as a reactive SPI slave and drives `MISO` in response to the address transmitted by the DUT.

---

## Verification Architecture

The environment contains two UVM agents:

### SPI Agent

The SPI agent monitors the SPI bus and models the external SPI slave.

- `spi_driver`
  - Reactive slave behavior
  - Waits for DUT-generated SPI transactions
  - Samples the transmitted address
  - Returns randomized channel data on `MISO`
  - Generates new channel data for each acquisition

- `spi_monitor`
  - Reconstructs SPI transactions
  - Sends observed transactions to both:
    - Scoreboard
    - Functional coverage

The SPI agent does not require a sequencer because the DUT is the SPI master and initiates the transfers.

### Register Agent

The register agent actively drives and monitors the DUT register interface.

- `reg_sequencer`
- `reg_driver`
- `reg_monitor`

The register monitor sends every observed register transaction to both:

- Scoreboard
- Functional coverage

---

## UVM Test Structure

All tests inherit from:

```text
spi_to_memory_base_test
```

The base test creates the environment and configures both agents as active.

The derived tests contain only the scenario-specific sequence flow.

```text
uvm_test
   |
   +-- spi_to_memory_base_test
          |
          +-- spi_to_memory_basic_test
          +-- spi_to_memory_ro_test
          +-- spi_to_memory_repeat_test
          +-- spi_to_memory_busy_test
```

---

## Sequences

The environment uses small reusable sequences:

| Sequence | Purpose |
|---|---|
| `handshake_write_seq` | Writes `Handshake = 1` to start an acquisition |
| `poll_handshake_seq` | Polls the Handshake register until the DUT completes the acquisition |
| `channel_read_seq` | Reads Channel0-3 after completion |
| `reg_ro_seq` | Attempts writes to all four read-only channel registers and verifies that they remain unchanged |
| `busy_retrigger_seq` | Writes `Handshake = 1` again while the DUT is already busy |

The polling sequence avoids relying on a fixed acquisition delay and waits for the actual DUT status.

---

## Test Scenarios

### Basic End-to-End Test

Class:

```text
spi_to_memory_basic_test
```

Flow:

```text
Handshake WRITE
-> Poll Handshake
-> SPI acquisition
-> Handshake completion
-> Read Channel0-3
-> End-to-end data comparison
```

The scoreboard learns the expected data directly from the SPI monitor and compares it against the values later read from the channel registers.

![Basic end-to-end waveform](docs/images/basic_end_to_end_waveform.png)

---

### Read-Only Register Test

Class:

```text
spi_to_memory_ro_test
```

After a valid acquisition, the test attempts to write to every channel register:

```text
Channel0
Channel1
Channel2
Channel3
```

Each register is read before and after the write attempt to verify that software writes do not modify the stored SPI data.

![Functional coverage - RO test](docs/images/functional_coverage_ro_test.png)

The register address/operation cross reaches full coverage in this test.

![Register cross coverage](docs/images/register_cross_coverage.png)

---

### Repeated Acquisition Test

Class:

```text
spi_to_memory_repeat_test
```

Runs 10 complete acquisition cycles.

Each acquisition receives a new randomized set of SPI slave data.

The purpose of this test is to verify that the complete flow remains stable across repeated operations and that old reference data is correctly replaced by the next acquisition.

---

### Busy Retrigger Test

Class:

```text
spi_to_memory_busy_test
```

The test starts a normal acquisition and then writes `Handshake = 1` again while the operation is still active.

The environment verifies that the second trigger does not restart the reference model or create an additional SPI acquisition.

![Busy retrigger waveform](docs/images/busy_retrigger_waveform.png)

A successful run completes with no UVM errors or fatals.

![Busy test pass](docs/images/uvm_busy_test_pass.png)

---

## End-to-End Scoreboard

The `spi_to_memory_scoreboard` receives transactions from both monitors.

### SPI side

The scoreboard:

- Verifies the SPI address sequence `0 -> 1 -> 2 -> 3`
- Stores the received SPI data as the golden reference
- Detects illegal or unexpected SPI transactions
- Detects extra SPI traffic after an acquisition is complete

### Register side

The scoreboard:

- Detects the start of a new acquisition through the Handshake write
- Tracks acquisition progress
- Verifies that Handshake remains high while SPI activity is still in progress
- Accepts the short DUT delay between the final SPI transfer and Handshake clearing
- Compares Channel0-3 register reads against the data observed on SPI
- Recognizes writes to the read-only channel registers
- Handles a Handshake retrigger while the DUT is busy without resetting the reference model

This creates an end-to-end check from the SPI bus to the software-visible register interface.

---

## Functional Coverage

Functional coverage is implemented in:

```text
spi_to_memory_coverage.sv
```

The coverage collector receives the same monitor transactions as the scoreboard.

### SPI Coverage

Covers:

- Address `0`
- Address `1`
- Address `2`
- Address `3`
- Transition sequence:

```text
0 -> 1 -> 2 -> 3
```

### Register Coverage

Covers:

- Register addresses `0-4`
- READ operation
- WRITE operation
- Address x operation cross

The cross verifies which READ/WRITE combinations were exercised for each register address.

### Handshake Coverage

Covers both observed states:

```text
Handshake = 0
Handshake = 1
```

### Busy Retrigger Coverage

Covers the case in which:

```text
Handshake = 1
```

is written while an acquisition is already active.

Observed functional coverage results:

| Test | SPI | Register | Handshake | Busy Retrigger |
|---|---:|---:|---:|---:|
| Basic | 100% | 86.67% | 100% | 0% |
| RO | 100% | 100% | 100% | 0% |
| Busy | 100% | 86.67% | 100% | 100% |
| Repeat | 100% | 86.67% | 100% | 0% |

The differences are intentional because each directed test targets a different part of the functional space.

---

## SystemVerilog Assertions

Assertions are kept outside the RTL and attached to the DUT using `bind`.

File:

```text
tb/assertions/spi_to_memory_assertions.sv
```

The assertions check:

- Handshake register write behavior
- Handshake register read behavior
- Reserved Handshake read bits
- Handshake clearing after the final SPI channel
- `spi_valid` / `CS` relationship
- Channel registers changing only as a result of valid SPI data

The DUT source files are not modified to add the assertions.

![Busy test assertion coverage](docs/images/busy_test_assertion_coverage.png)

The captured assertion run completed with zero assertion failures.

---

## Project Structure

```text
uvm-spi-to-memory-verification/
|
|-- rtl/
|   |-- spi_master.sv
|   `-- spi_to_memory.sv
|
|-- tb/
|   |
|   |-- interfaces/
|   |   |-- spi_if.sv
|   |   `-- reg_if.sv
|   |
|   |-- transactions/
|   |   |-- spi_transaction.sv
|   |   `-- reg_tran.sv
|   |
|   |-- agents/
|   |   |-- spi_agent.sv
|   |   |-- spi_driver.sv
|   |   |-- spi_monitor.sv
|   |   |-- reg_agent.sv
|   |   |-- reg_driver.sv
|   |   |-- reg_monitor.sv
|   |   `-- reg_sequencer.sv
|   |
|   |-- sequences/
|   |   |-- handshake_write_seq.sv
|   |   |-- poll_handshake_seq.sv
|   |   |-- channel_read_seq.sv
|   |   |-- reg_ro_seq.sv
|   |   `-- busy_retrigger_seq.sv
|   |
|   |-- env/
|   |   |-- spi_to_memory_env.sv
|   |   |-- spi_to_memory_scoreboard.sv
|   |   `-- spi_to_memory_coverage.sv
|   |
|   |-- assertions/
|   |   `-- spi_to_memory_assertions.sv
|   |
|   |-- tests/
|   |   |-- spi_to_memory_base_test.sv
|   |   |-- spi_to_memory_basic_test.sv
|   |   |-- spi_to_memory_ro_test.sv
|   |   |-- spi_to_memory_repeat_test.sv
|   |   `-- spi_to_memory_busy_test.sv
|   |
|   |-- tb_pkg.sv
|   `-- top.sv
|
|-- docs/
|   `-- images/
|       |-- basic_end_to_end_waveform.png
|       |-- busy_retrigger_waveform.png
|       |-- functional_coverage_ro_test.png
|       |-- register_cross_coverage.png
|       |-- uvm_busy_test_pass.png
|       `-- busy_test_assertion_coverage.png
|
|-- spi.fl
|-- Makefile
`-- README.md
```

---

## Running the Simulation

The project is configured for Synopsys VCS and Verdi.

### Basic test

```bash
make run TEST=spi_to_memory_basic_test
```

### Read-only test

```bash
make run TEST=spi_to_memory_ro_test
```

### Repeat test

```bash
make run TEST=spi_to_memory_repeat_test
```

### Busy retrigger test

```bash
make run TEST=spi_to_memory_busy_test
```

### Open simulation GUI

```bash
make gui TEST=spi_to_memory_basic_test
```

### Run coverage and open in Verdi

```bash
make cov_gui TEST=spi_to_memory_ro_test
```

or:

```bash
make cov_gui TEST=spi_to_memory_busy_test
```

---

## Verification Results

The implemented test suite was exercised with:

```text
UVM_ERROR : 0
UVM_FATAL : 0
```

for the completed directed test scenarios.

The environment verifies both protocol-level activity and the complete end-to-end data path from SPI acquisition to software-visible channel registers.

---

## Key Verification Concepts Demonstrated

This project demonstrates practical use of:

- UVM components and hierarchy
- Base-test inheritance
- Active agents
- Reactive slave modeling
- Sequence / sequencer / driver communication
- Analysis ports
- Multiple analysis subscribers
- End-to-end scoreboarding
- Reference-model state tracking
- Polling-based synchronization
- Functional coverage
- Transition bins
- Cross coverage
- SystemVerilog Assertions
- `bind`
- Directed corner-case testing
- Repeated randomized acquisitions
