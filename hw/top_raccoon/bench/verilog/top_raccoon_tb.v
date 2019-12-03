module top_raccoon_tb;

    localparam BOOTROM_FILE = "";
    localparam BOOTROM_SIZE = 32'h1000; // KB = 4096 bytes
    
    localparam MEM_FILE = "";
    localparam MEM_SIZE = 32'h02000000; // Set default memory size to 32MB
        
    vlog_tb_utils vlog_tb_utils0();

    ////////////////////////////////////////////////////////////////////////
    //
    // JTAG VPI interface
    //
    ////////////////////////////////////////////////////////////////////////

    wire tms;
    wire tck;
    wire tdi;
    wire tdo;

    reg enable_jtag_vpi;
    initial enable_jtag_vpi = $test$plusargs("enable_jtag_vpi");

    jtag_vpi jtag_vpi0
        (
            .tms        (tms),
            .tck        (tck),
            .tdi        (tdi),
            .tdo        (tdo),
            .enable     (enable_jtag_vpi),
            .init_done  (top_raccoon_tb.dut.wb_rst)
        );

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
                top_raccoon_tb.wb_ram.ram0.mem[i] = 32'h00000000;
        end
        
        if($value$plusargs("elf_bootrom_load=%s", elf_bootrom_file)) begin
            $display("Loading ELF BOOT ROM Memory");
            $elf_load_file(elf_bootrom_file);

            mem_words = $elf_get_size/4;
            $display("Loading %d words", mem_words);
            for(i=0; i < mem_words; i = i+1)
                top_raccoon_tb.dut.wb_bfm_bootrom0.ram0.mem[i] = $elf_read_32(i*4);
        end else
            $display("No ELF Boot ROM file specified");
        
        if($value$plusargs("elf_ram_load=%s", elf_ram_file)) begin
            $display("Loading ELF RAM Memory");
            $elf_load_file(elf_ram_file);

            mem_words = $elf_get_size/4;
            $display("Loading %d words", mem_words);
            for(i=0; i < mem_words; i = i+1)
                top_raccoon_tb.wb_ram.ram0.mem[i] = $elf_read_32(i*4);
        end else
            $display("No ELF RAM Memory file specified");        

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
    
    ////////////////////////////////////////////////////////////////////////
    //
    // External RAM Memory
    //
    ////////////////////////////////////////////////////////////////////////
    
    wire        wb_mem_clk_o;
    wire        wb_mem_rst_o;
    wire [$clog2(MEM_SIZE)-1:0] wb_mem_adr_o;
    wire        wb_mem_cyc_o;
    wire [31:0] wb_mem_dat_o;
    wire [3:0]  wb_mem_sel_o;
    wire        wb_mem_stb_o;
    wire        wb_mem_we_o;
    wire [2:0]  wb_mem_cti_o;
    wire [1:0]  wb_mem_bte_o;
    wire        wb_mem_ack_i;
    wire        wb_mem_rty_i;
    wire        wb_mem_err_i;
    wire [31:0] wb_mem_dat_i;
    
    // Simple wishbone memory that is currently hard coded to use 32 bits and
    // has a Wishbone B3 interface for burst accesses.
    assign wb_mem_clk_o = syst_clk;
    assign wb_mem_rst_o = syst_rst;
    
    assign wb_mem_rty_i = 1'b0;

    wb_ram
        #(.depth (MEM_SIZE),
            .memfile(MEM_FILE))
            //.aw(MEM_ADDR_WIDTH))
        wb_ram
        (// Wishbone interface
            .wb_clk_i (wb_mem_clk_o),
            .wb_rst_i (wb_mem_rst_o),
            .wb_adr_i (wb_mem_adr_o),
            .wb_stb_i (wb_mem_stb_o),
            .wb_cyc_i (wb_mem_cyc_o),
            .wb_cti_i (wb_mem_cti_o),
            .wb_bte_i (wb_mem_bte_o),
            .wb_we_i  (wb_mem_we_o) ,
            .wb_sel_i (wb_mem_sel_o),
            .wb_dat_i (wb_mem_dat_o),
            .wb_dat_o (wb_mem_dat_i),
            .wb_ack_o (wb_mem_ack_i),
            .wb_err_o (wb_mem_err_i));

    ////////////////////////////////////////////////////////////////////////
    //
    // DUT
    //
    ////////////////////////////////////////////////////////////////////////
    
    top_raccoon
        #(.BOOTROM_FILE(BOOTROM_FILE),
          .BOOTROM_SIZE(BOOTROM_SIZE),
          .MEM_SIZE(MEM_SIZE))
        dut
        (.clk     (syst_clk),
         .rst_sys (syst_rst),
         .rst_dbg (syst_rst),
         .rst_cpu (syst_rst),         
         
         .tms_pad_i (tms),
         .tck_pad_i (tck),
         .tdi_pad_i (tdi),
         .tdo_pad_o (tdo),
         
         // External bus Master
         .wb_ext_mem_adr_o(wb_mem_adr_o),
         .wb_ext_mem_cyc_o(wb_mem_cyc_o),
         .wb_ext_mem_dat_o(wb_mem_dat_o),
         .wb_ext_mem_sel_o(wb_mem_sel_o),
         .wb_ext_mem_stb_o(wb_mem_stb_o),
         .wb_ext_mem_we_o(wb_mem_we_o),
         .wb_ext_mem_cti_o(wb_mem_cti_o),
         .wb_ext_mem_bte_o(wb_mem_bte_o),
         .wb_ext_mem_ack_i(wb_mem_ack_i),
         .wb_ext_mem_rty_i(wb_mem_rty_i),
         .wb_ext_mem_err_i(wb_mem_err_i),
         .wb_ext_mem_dat_i(wb_mem_dat_i)         
         );

endmodule
