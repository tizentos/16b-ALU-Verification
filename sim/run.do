# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile the sources.
vlog ../dut/ALU_netlist.v ../lib/gscl45nm.v
vlog +fcover -sv ../tb/interfaces.sv  ../tb/sequences.sv ../tb/coverage.sv ../tb/scoreboard.sv ../tb/modules.sv ../tb/tests.sv  ../tb/tb.sv  
# Simulate the design.
vsim -c top
coverage save -onexit report.ucdb 
run -all
exit
