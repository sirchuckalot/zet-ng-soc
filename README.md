Zet Next Generation SoC
=======================

This package contains all source code, test benches, bitfiles, ROMs and scripts used in the Zet Next Generation SoC. This next generation System on Chip is based upon the FuseSoC v1.5 framework build system.

The target is to first develop 32-bit zet-ng-generic reference design. Additional board ports will be based upon this reference design as they become available.

**Explanation of directories**

    cores    - Cores library in Verilog source code
    systems  - Different boards supported (implementation dependent files)

DOWNLOADING SOURCES
-------------------

    git clone https://github.com/sirchuckalot/zet-ng-soc

BUILDING THE SYSTEM
-------------------

SIMULATING THE SYSTEM
---------------------

Credits
-------
  Most of the work is (C) Copyright 2008, 2009, 2010 Zeus Gomez Marmolejo. All hardware and software source files are released under the GNU GPLv3 license. Read the LICENSE file included.

  Special thanks to people that helped significantly to this project:
   - Sebastien Bourdeauducq to his DRAM memory controller
   - Donna Polehn for adding mouse and shadow BIOS support
   - Yury Savchuk for improving the timer and improving the processor
   - Charley Picker for SDRAM video support and Altera DE2 board port
