#include <stdint.h>
#include <signal.h>

#include "verilated_vcd_c.h"
#include "Vzet_ng_soc_core_tb.h"

using namespace std;

static bool done;

vluint64_t main_time = 0;       // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.

double sc_time_stamp () {       // Called by $time in Verilog
  return main_time;           // converts to double, to match
  // what SystemC does
}

// Keyboard handler
void INThandler(int signal)
{
	printf("\nCaught ctrl-c\n");
	done = true;
}

int main(int argc, char **argv, char **env)
{
  // Get all values typed on command line
  Verilated::commandArgs(argc, argv);

  // Create instance of testbench
  Vzet_ng_soc_core_tb* top = new Vzet_ng_soc_core_tb;

  // Add VCD support
  VerilatedVcdC * tfp = 0;
  const char *vcd = Verilated::commandArgsPlusMatch("vcd=");
  if (vcd[0]) {
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->open ("trace.vcd");
  }

  // Get the timeout value from the command line
  vluint64_t timeout = 0;
  const char *arg_timeout = Verilated::commandArgsPlusMatch("timeout=");
  if (arg_timeout[0])
    timeout = atoi(arg_timeout+9);

  // This catches keyboard interrupts like ctrl-c
  signal(SIGINT, INThandler);

  // First initial values of clock and reset signals
  top->clk = 1;
  top->rst = 1;

  // This is our main simulation loop
  while (!(done || Verilated::gotFinish())) {
    // Here we can set hold time for reset signal
	if (main_time == 100) {
      printf("Releasing reset\n");
      top->rst = 0;
    }

    // Verilator must now evaluate signal changes
	top->eval();

    // If VCD requested, then dump the values
    if (tfp)
      tfp->dump(main_time);

    // Put additional module/c++ support here

    // Allow for timeout value to be specified
    if (timeout && (main_time >= timeout)) {
      printf("Timeout: Exiting at time %lu\n", main_time);
      done = true;
    }

    // Now let's toggle clock one more time
    top->clk = !top->clk;

    // Add one more time step
    main_time+=20;
  }

  // Be sure to close the VCD file at the end
  if (tfp)
    tfp->close();
  exit(0);
}
