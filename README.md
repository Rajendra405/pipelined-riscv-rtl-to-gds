# Pipelined RISC-V — RTL to GDS

A physical design implementation of a pipelined RV32I RISC-V core, carried from RTL through routing on the Synopsys flow using the SAED 32nm educational PDK.

## Design

A 5-stage pipelined RV32I core with a hazard unit that handles data forwarding, load-use stalls, and branch flushes. The pipelined variant was chosen over the single-cycle and multicycle versions because it makes for a more substantial physical-design project: the pipeline registers require real clock-tree synthesis, the forwarding path into the ALU forms a meaningful critical path, and the register file writes on the negative clock edge while the pipeline runs on the positive edge — a mixed-edge design that has to be handled correctly through the backend.

## Tools

- **VCS + Verdi** — RTL simulation and waveform debug
- **Design Compiler (Graphical/Ultra)** — synthesis
- **IC Compiler II** — floorplan, power planning, placement, CTS, routing
- **PrimeTime** — static timing analysis
- **IC Validator** — physical verification (DRC/LVS)
- **SAED 32nm EDK PDK**, RVT standard cells, typical corner

## Flow and Results

| Stage | Result |
|-------|--------|
| RTL simulation | Functional test passes ("Simulation succeeded"); forwarding and load-use stalls confirmed in the waveform |
| Synthesis | Timing closed at 3.3 ns (~303 MHz); ~7,150 cells, 1,512 flip-flops |
| Floorplan + power | ~65% core utilization; M8/M9 power ring and mesh |
| Placement | 6,599 cells placed, setup clean |
| CTS | Clock tree to 1,512 flops; 0.07 ns skew; setup and hold both closed |
| Routing | Fully routed; 0 setup and 0 hold violations against real extracted parasitics |

The critical path runs from a memory-stage pipeline register, through the hazard unit's forward-select logic, into the forwarding mux and ALU source mux, through the ALU, and back to the PC-update logic — the classic pipeline hazard-resolution path. During CTS, the negative-edge register file and positive-edge pipeline registers are balanced on their respective clock edges, which is a direct realization of the mixed-edge design.

## Repository

- `rtl/` — the full design (core, testbench, and behavioral memories) for simulation, and a synthesis-clean view with the testbench and memories removed
- `scripts/` — synthesis (Design Compiler) and place-and-route (IC Compiler II) scripts
- `sim/` — the RV32I test program and the Verdi waveform-dump script
- `reports/` — synthesis QoR, timing, area, power, and related reports

## Status

Complete through routing, with a timing-clean routed database (GDS, netlist, and parasitics generated). Remaining steps: signoff DRC/LVS in IC Validator, and independent static timing analysis in PrimeTime using the extracted parasitics.

## Note

This was built on an educational PDK for learning and portfolio purposes, and is not intended for fabrication.
