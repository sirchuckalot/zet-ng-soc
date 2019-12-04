`default_nettype none

module top_ao486_simple_tb;
    
    localparam BOOTROM_FILE = "";
    localparam BOOTROM_SIZE = 32'h1000; // KB = 4096 bytes
    
    localparam MEM_FILE = "";
    localparam MEM_SIZE = 32'h02000000; // Set default memory size to 32MB
    //localparam MEM_SIZE = 32'hffff_ffff; // Set default memory size to 4GB
        
    vlog_tb_utils vlog_tb_utils0();
    
    // CPU Memory BUS Master
    wire        wb_cpu_mem_clk_i;
    wire        wb_cpu_mem_rst_i;
    wire [31:0] wb_cpu_mem_adr_o;
    wire        wb_cpu_mem_cyc_o;
    wire [31:0] wb_cpu_mem_dat_o;
    wire [3:0]  wb_cpu_mem_sel_o;
    wire        wb_cpu_mem_stb_o;
    wire        wb_cpu_mem_we_o;
    wire [2:0]  wb_cpu_mem_cti_o;
    wire [1:0]  wb_cpu_mem_bte_o;
    wire        wb_cpu_mem_ack_i;
    wire        wb_cpu_mem_rty_i;
    wire        wb_cpu_mem_err_i;
    wire [31:0] wb_cpu_mem_dat_i;
    
    // CPU IO BUS Master
    wire        wb_cpu_io_clk_i;
    wire        wb_cpu_io_rst_i;
    wire [31:0] wb_cpu_io_adr_o;
    wire        wb_cpu_io_cyc_o;
    wire [31:0] wb_cpu_io_dat_o;
    wire [3:0]  wb_cpu_io_sel_o;
    wire        wb_cpu_io_stb_o;
    wire        wb_cpu_io_we_o;
    wire [2:0]  wb_cpu_io_cti_o;
    wire [1:0]  wb_cpu_io_bte_o;
    wire        wb_cpu_io_ack_i;
    wire        wb_cpu_io_rty_i;
    wire        wb_cpu_io_err_i;
    wire [31:0] wb_cpu_io_dat_i;

    ////////////////////////////////////////////////////////////////////////
    //
    // ELF program loading
    //
    ////////////////////////////////////////////////////////////////////////
    
    integer mem_words;
    integer i;
    reg [31:0] mem_word;
    
    reg [1023:0] elf_bootrom_file;
    reg [1023:0] elf_ram_file;

    initial begin
        $display("");
        $display("Starting Simulation");
        $display("");
        if ($test$plusargs("clear_ram")) begin
            $display("Clearing %d RAM words", MEM_SIZE/4);
            for(i=0; i < MEM_SIZE/4; i = i+1)
                top_ao486_simple_tb.wb_ram.ram0.mem[i] = 32'h00000000;
        end
        
        $display("");
        
        if($value$plusargs("elf_bootrom_load=%s", elf_bootrom_file)) begin
            $display("Loading ELF BOOT ROM Memory");
            $elf_load_file(elf_bootrom_file);

            mem_words = $elf_get_size/4;
            $display("Loading %d words", mem_words);
            for(i=0; i < mem_words; i = i+1)
                top_ao486_simple_tb.wb_ram.ram0.mem[i] = $elf_read_32(i*4);
        end else
            $display("No ELF Boot ROM file specified");
        
        $display("");
        
        if($value$plusargs("elf_ram_load=%s", elf_ram_file)) begin
            $display("Loading ELF RAM Memory");
            $elf_load_file(elf_ram_file);

            mem_words = $elf_get_size/4;
            $display("Loading %d words", mem_words);
            for(i=0; i < mem_words; i = i+1)
                top_ao486_simple_tb.wb_ram.ram0.mem[i] = $elf_read_32(i*4);
        end else
            $display("No ELF RAM Memory file specified");
        
        $display("");
        
        if($test$plusargs("first_instruction")) begin
            $display("Loading First Instruction into RAM");
            $display("mem[25'h1ff_fff0/4] = 32'heb_03_eb_03");
            wb_ram.ram0.mem[25'h1ff_fff0/4] = 32'heb_03_eb_03;
            //$elf_load_file(elf_ram_file);

            //mem_words = $elf_get_size/4;
            //$display("Loading %d words", mem_words);
            //for(i=0; i < mem_words; i = i+1)
            //    top_ao486_simple_tb.wb_ram.ram0.mem[i] = $elf_read_32(i*4);
        end else
            $display("First Instruction not loaded into RAM");

    end

    ////////////////////////////////////////////////////////////////////////
    //
    // Clock and reset generation
    //
    ////////////////////////////////////////////////////////////////////////
    
    reg syst_clk = 1;
    reg syst_rst = 1;

    always #5 syst_clk <= ~syst_clk;
    initial #100 syst_rst <= 0;
    
    assign wb_cpu_mem_clk_i = syst_clk;
    assign wb_cpu_mem_rst_i = syst_rst;
    
    ////////////////////////////////////////////////////////////////////////
    //
    // External RAM Memory
    //
    ////////////////////////////////////////////////////////////////////////
        
    wb_ram #(
        .depth (MEM_SIZE),
        .memfile(MEM_FILE))
        //.aw(MEM_ADDR_WIDTH))
    wb_ram
        (// Wishbone interface
         .wb_clk_i (wb_cpu_mem_clk_i),
         .wb_rst_i (wb_cpu_mem_rst_i),
         .wb_adr_i (wb_cpu_mem_adr_o[24:0]),
         .wb_stb_i (wb_cpu_mem_stb_o),
         .wb_cyc_i (wb_cpu_mem_cyc_o),
         .wb_cti_i (wb_cpu_mem_cti_o),
         .wb_bte_i (wb_cpu_mem_bte_o),
         .wb_we_i  (wb_cpu_mem_we_o) ,
         .wb_sel_i (wb_cpu_mem_sel_o),
         .wb_dat_i (wb_cpu_mem_dat_o),
         .wb_dat_o (wb_cpu_mem_dat_i),
         .wb_ack_o (wb_cpu_mem_ack_i),
         .wb_err_o (wb_cpu_mem_err_i));
        
    assign wb_cpu_mem_rty_i = 1'b0;
    
    ////////////////////////////////////////////////////////////////////////
    //
    // ao486 cpu
    //
    ////////////////////////////////////////////////////////////////////////

        ao486_cpu_wb_wrapper #(
                .AW(32),
                .DW(32)
            ) cpu_wb_wrapper (
                .cpu_clk_i(wb_cpu_mem_clk_i),
                .cpu_rst_i(wb_cpu_mem_rst_i),

                // CPU Memory Master Interface
                .wbm_cpu_mem_adr_o(wb_cpu_mem_adr_o),
                .wbm_cpu_mem_dat_o(wb_cpu_mem_dat_o),
                .wbm_cpu_mem_sel_o(wb_cpu_mem_sel_o),
                .wbm_cpu_mem_we_o(wb_cpu_mem_we_o),
                .wbm_cpu_mem_cyc_o(wb_cpu_mem_cyc_o),
                .wbm_cpu_mem_stb_o(wb_cpu_mem_stb_o),
                .wbm_cpu_mem_cti_o(wb_cpu_mem_cti_o),
                .wbm_cpu_mem_bte_o(wb_cpu_mem_bte_o),
                .wbm_cpu_mem_dat_i(wb_cpu_mem_dat_i),
                .wbm_cpu_mem_ack_i(wb_cpu_mem_ack_i),
                .wbm_cpu_mem_err_i(wb_cpu_mem_err_i),
                .wbm_cpu_mem_rty_i(wb_cpu_mem_rty_i),

                // CPU IO Master Interface
                .wbm_cpu_io_adr_o(wb_cpu_io_adr_o),
                .wbm_cpu_io_dat_o(wb_cpu_io_dat_o),
                .wbm_cpu_io_sel_o(wb_cpu_io_sel_o),
                .wbm_cpu_io_we_o(wb_cpu_io_we_o),
                .wbm_cpu_io_cyc_o(wb_cpu_io_cyc_o),
                .wbm_cpu_io_stb_o(wb_cpu_io_stb_o),
                .wbm_cpu_io_cti_o(wb_cpu_io_cti_o),
                .wbm_cpu_io_bte_o(wb_cpu_io_bte_o),
                .wbm_cpu_io_dat_i(wb_cpu_io_dat_i),
                .wbm_cpu_io_ack_i(wb_cpu_io_ack_i),
                .wbm_cpu_io_err_i(wb_cpu_io_err_i),
                .wbm_cpu_io_rty_i(wb_cpu_io_rty_i),

                // CPU PIC Interrupts
                .interrupt_do(),
                .interrupt_vector(),
                .interrupt_done()
            );
endmodule
