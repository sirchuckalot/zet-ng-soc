Zet Next Generation SoC
=======================

This repository contains all source code, test benches, bitfiles, ROMs and scripts used in the Zet Next Generation SoC. This Zet Next Generation System on Chip is based upon the FuseSoC v1.9.2 framework build system.

The target is to first develop 32-bit zet-ng-generic reference design. We will first start with simulating the system as the first target. Once simulations have been verified, we can then port over to supported board hardware. Additional board ports will be based upon this reference design as they become available.

## Explanation of directories

    cores    - External and Internal cores dependency library
    hw       - Reference designs
    ├─────── - zet-ng-generic
    └─────── - top_woodchuck
    

## How to use

### Prerequisites
Currently, this project is being development on Ubuntu 18.04.3 LTS distribution. So, you must start with this Linux distribution in order to get the best results. Any other OS distributions have not been tested and your mileage may very.

The following directory structure will have been created when the prerequisite steps have been completed. The project sources can be found in the cloned zet-ng-soc repository directory (from now on called `$ZET-NG-SOC_ROOT`). The zet-ng-soc-workspace is where all linting, compiling, building and simulating takes place (from now on called `$WORKSPACE`). All further FuseSoC commands will be run from within `$WORKSPACE` unless otherwise stated. The directory structure will look like this:

    ├──zet-ng-soc
    └──zet-ng-soc-workspace

1. Make sure you have [FuseSoC](https://github.com/olofk/fusesoc) installed or install it with `pip install fusesoc`
2. Initialize the FuseSoC base library with `fusesoc init`
3. Clone the zet-ng-soc repository `git clone https://github.com/sirchuckalot/zet-ng-soc`
4. Make workspace directory `mkdir zet-ng-soc-workspace`
5. Change into the workspace directory `cd zet-ng-soc-workspace`
6. Add the zet-ng-soc directory as a FuseSoC core library `fusesoc library add zet-ng-soc ../zet-ng-soc`
7. Install latest stable Verilator version

It is recommended to compile and install Verilator v4.020 from latest stable git branch sources. Instructions on how to install latest stable Verilator version can be found at: [https://www.veripool.org/projects/verilator/wiki/Installing](https://www.veripool.org/projects/verilator/wiki/Installing) 

### Additional dependencies
Required glip dependencies:

    sudo apt-get install libboost-all-dev
    sudo apt-get install libusb-1.0-0-dev

Required opensocdebug dependencies:

    sudo apt-get install check
    sudo apt-get install libzmq*
    sudo apt-get install libczmq*

When glip libraries don’t install and osd-target-run is missing, try the following for hints:

[https://www.lowrisc.org/docs/debug-v0.3/osdsoftware/](https://www.lowrisc.org/docs/debug-v0.3/osdsoftware/)

## Running simulations of the system
Currently the zet-ng-soc can only be simulated using Verilator. When running a Verilator simulation, use FuseSoC to launch the simulation. To select what to run, use the `fusesoc run` command with the `--target` parameter. These commands must be run all be run from within `$WORKSPACE` directory.

### To run in simulation
From `$WORKSPACE` directory, simulation can be run:

    fusesoc run --target=sim zet-ng-soc

There are several targets that support different compile- and run-time options. To see all options for a target run:

    fusesoc run --target=$TARGET zet-ng-soc --help

To list all available targets, run:

    fusesoc core show zet-ng-soc

## Debugging using the Open SoC Debug System
This debug infrastructure has been based upon: [https://opensocdebug.org/](https://opensocdebug.org/). Additional design decisions was based upon ideas from: [https://www.optimsoc.org/](https://www.optimsoc.org/) and [https://www.lowrisc.org/](https://www.lowrisc.org/) projects.

Currently, the debug infrastructure for zet-ng-soc us being developed. All FuseSoC debug commands must be run from within `$WORKSPACE` directory. Only memory loading in simulation is currently supported at the moment:

1. Start the simulation with `fusesoc run --target=sim zet-ng-soc`
2. In another terminal window, run `osd-target-run -e file-name -b tcp` Check `osd-target-run --help` for additional instructions
3. You can verify memory has been loaded `osd-target-run --verify-memload -e file -b tcp`

## Linting the sources

    fusesoc run --target=lint zet-ng-soc    

Credits
-------
Most of the work is (C) Copyright 2008, 2009, 2010 Zeus Gomez Marmolejo. All zet-ng-soc hardware and software source files are released under the GNU GPLv3 license. Read the LICENSE file included.

  Special thanks to people that helped significantly to this project:
   - Sebastien Bourdeauducq to his DRAM memory controller
   - Donna Polehn for adding mouse and shadow BIOS support
   - Yury Savchuk for improving the timer and improving the processor
   - Charley Picker for SDRAM video support and Altera DE2 board port
