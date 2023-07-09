TESTBENCH=testbench.v
MODULE=lcd.v

sim: testbench.out
	vvp $<

gui: sim
	gtkwave top.vcd 

testbench.out: $(TESTBENCH) $(MODULE)
	iverilog -o $@ -D VCD_OUTPUT=top_tb -D SIM $(TESTBENCH) $(MODULE)

.PHONY: clean
clean: 
	rm -f testbench.out top.vcd

