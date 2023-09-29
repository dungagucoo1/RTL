`define almost_full_cfg 3
`define almost_empty_cfg 2
`define AW_fifo 4
`define DW_fifo 32
`define AW 3
`define DW 32
interface dstm
    #(
        parameter WIDTH = `DW_fifo
    );
    logic valid;
    logic ready;
    logic [WIDTH-1:0] data;
    
    modport mst
    (
        output valid,
        output data,
        input ready
    );
    modport slv
    (
        input valid,
        input data,
        output ready
    );
endinterface
//----------------------------------
interface fifo_stalvl
    ();
    logic full, almost_full;
    logic empty, almost_empty;
    
    modport mst
    (
        output full, almost_full,
        output empty, almost_empty
    );
    modport slv
    (
        input full, almost_full,
        input empty, almost_empty
    );
endinterface
//----------------------------------
interface apb_intf
    #(
    parameter AW = `AW,
    parameter DW = `DW
    )
    ();
    
    logic pclk;
    logic [AW - 1:0] paddr;
    logic pwrite;
    logic psel;
    logic penable;
    logic [DW - 1:0] pwdata;
    logic preset_n;
    
    reg [DW - 1:0] prdata;
    logic pready; 
    modport slv
    (
        input preset_n,
        input pclk,
        input paddr,
        input pwrite,
        input psel,
        input penable,
        input pwdata,
        
        output prdata,
//        output pready
        input pready
    );
    modport mst
    (
        input preset_n,
        input pclk,
        output paddr,
        output pwrite,
        output psel,
        output penable,
        output pwdata,
        
        input prdata,
//        input pready
        output pready
    );
endinterface
//----------------------------------
interface cfg_sta
    #(parameter AW = `AW_fifo)
    ();
    logic [AW-1:0] almost_full;
    logic [AW-1:0] almost_empty;
    modport slv
    (
        input almost_full,
        input almost_empty
    );
    modport mst
    (
        output almost_full,
        output almost_empty
    );
endinterface
//-------------------------------------------------------
module apb_regs
    #(
    parameter WIDTH = `DW
    )
    (
    output logic s_rs,
    input logic [`DW_fifo - 1:0] data_in,
    output logic [`DW_fifo - 1:0] data,
    
    apb_intf apb_slv,
    dstm m_dstm_1, s_dstm_2,
    fifo_stalvl s_stalvl_1, s_stalvl_2,
    cfg_sta m_cfg_sta_1
    );
    logic [WIDTH - 1:0] RAM [0 : 2** `AW - 1];
    typedef enum logic [2:0] {
        IDLE,
        SETUP,
        ACCESS
    } state;
    state st, nx_st;
    
    
    
    always_ff @(posedge apb_slv.pclk, negedge apb_slv.preset_n) begin
        if (!apb_slv.preset_n) begin
            st  <= IDLE;
        end
        else 
            st  <= nx_st;
//            if (apb_slv.pwrite) begin
//                RAM[apb_slv.paddr] = apb_slv.pwdata ;
//            end 
        end
    always_comb
        begin
            if (apb_slv.pwrite) begin
                case(apb_slv.paddr)
                    'h0: RAM[0] = apb_slv.pwdata ;
                    'h2: RAM[2] = apb_slv.pwdata ;
                    'h3: RAM[3] = apb_slv.pwdata ;
                endcase
        end 
    end
    
    //-----------------------------
always_comb begin
    case(st)    
        IDLE: 
            if (apb_slv.psel)
                nx_st = SETUP;
            else 
                nx_st = st;
        SETUP:
            if (apb_slv.penable)
                nx_st = ACCESS;
            else 
                nx_st = st;
        ACCESS:
            if (apb_slv.pready) begin
                if (!apb_slv.pwrite) begin
                    apb_slv.prdata <= RAM[apb_slv.paddr] ;
                    nx_st = IDLE;
                end
                else nx_st = IDLE;
                end
            else
                nx_st = st;    
    endcase
end

    // always_comb begin
    //     if(!apb_slv.preset_n) 
    // 		apb_slv.pready = 0;
    //     else if (apb_slv.psel & apb_slv.penable) begin
    //         if (apb_slv.pwrite) begin
    //             RAM[apb_slv.paddr] = apb_slv.pwdata ;
    //             apb_slv.pready = 'b1;
    //         end
    //         else 
    //             apb_slv.prdata <= RAM[apb_slv.paddr] ;
    //             apb_slv.pready = 'b1;
    //         end
    //     else 
    //         apb_slv.pready = 'b0;
    //     end
    
    
    //---------------------------------------------------
    //---------------------------------------------------
    //register_block
    always_comb begin
        //soft reset
        if (apb_slv.paddr == 2'b00 & apb_slv.pwdata[0] == 1)
            s_rs = 0;
        else s_rs = 1 ;
        //status
        RAM[1][3:0]    = {s_stalvl_1.almost_empty,s_stalvl_1.almost_full,s_stalvl_1.empty,s_stalvl_1.full};
        //config
        if (apb_slv.paddr == 2'b10 & apb_slv.pwdata[0])
            m_cfg_sta_1.almost_full =  `almost_full_cfg;
        if (apb_slv.paddr == 2'b10 & apb_slv.pwdata[1])
            m_cfg_sta_1.almost_empty =  `almost_empty_cfg;
        //read_write data
            //write data to FIFO
        if (apb_slv.paddr == 2'b11 & apb_slv.pwdata[0] & !s_stalvl_1.almost_full & apb_slv.pready) begin
            m_dstm_1.data = data_in;
            m_dstm_1.valid = 1;
        end
        else   
            m_dstm_1.valid = 0;
            //read data from FIFO
        if(apb_slv.paddr == 2'b11 & apb_slv.pwdata[1] & !s_stalvl_2.almost_empty & apb_slv.pready) begin
            s_dstm_2.ready = 1;
            data = s_dstm_2.data ;         
        end
        else
            s_dstm_2.ready = 0;
        
    end
endmodule
module csv_afifo
    #(
    parameter WIDTH = `DW_fifo,
    parameter ASIZE = `AW_fifo,
    parameter DEPTH = 2**`AW_fifo
    )
    
    (
    dstm.slv        s_dstm_1,
    dstm.mst        m_dstm_2,
    fifo_stalvl.mst m_stalvl_1,
    fifo_stalvl.mst m_stalvl_2,
    cfg_sta.slv     s_cfg_sta_1,
    input logic s_rs,

    input logic i_clk_s, i_rst_n_s, 
    input logic i_clk_m, i_rst_n_m
    );
    logic [ASIZE-1:0]   waddr, raddr;
    logic [ASIZE:0]     wptr, rptr, wq2_rptr, rq2_wptr;
    
    //----------------------------------------------------------------------
    //wprt_full
    logic [ASIZE : 0] wbin, wbin_next;
    logic [ASIZE : 0] wgray_next_1, wgray_next_2;
    logic             wfull_val_1, wfull_val_2;
    
    // Write pointer
    always_ff @(posedge i_clk_s or negedge i_rst_n_s)
    begin
        if (!i_rst_n_s)
        begin 
            wbin <= 0;
            wptr <= 0;
        end
        else if (!s_rs)
        begin
            wbin <= 0;
            wptr <= 0;
        end
        else
        begin
            wbin <= wbin_next;
            wptr <= wgray_next_1;
        end
    end

    always_comb
        begin
            waddr           = wbin[ASIZE - 1 : 0];
            wbin_next       = wbin + (s_dstm_1.valid & ~m_stalvl_1.almost_full);
            wgray_next_1    = (wbin_next >> 1 ) ^ wbin_next;
            wfull_val_1     = (wgray_next_1 == { ~wq2_rptr[ASIZE : ASIZE - 1], wq2_rptr[ASIZE - 2 : 0]});
            wgray_next_2    = ((wbin_next + s_cfg_sta_1.almost_full) >> 1 ) ^ (wbin_next + s_cfg_sta_1.almost_full);  
            wfull_val_2     = (wgray_next_2 == { ~wq2_rptr[ASIZE : ASIZE - 1], wq2_rptr[ASIZE - 2 : 0]});
        end
    always_ff @(posedge i_clk_s or negedge i_rst_n_s)
        begin
            if(!i_rst_n_s)
                begin
                    m_stalvl_1.almost_full   <= 0;
                    m_stalvl_1.full          <= 0;
                end
            else
            if(!s_rs)
                begin
                    m_stalvl_1.almost_full   <= 0;
                    m_stalvl_1.full          <= 0;
                end
            else
                begin
                    m_stalvl_1.full <= wfull_val_1;
                    m_stalvl_1.almost_full     <= wfull_val_2;
                end
                
        end
    //----------------------------------------------------------------------
    
    // sync_r2w
    logic [ASIZE : 0] wq1_rptr;
    always_ff @(posedge i_clk_s or negedge i_rst_n_s)
        if (!i_rst_n_s) {wq2_rptr,wq1_rptr} <= 0;
        else
        if (!s_rs) {wq2_rptr,wq1_rptr} <= 0;
        else
         {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
    //----------------------------------------------------------------------

    //rprt_empty
    logic [ASIZE : 0] rbin, rbin_next;
    logic [ASIZE : 0] rgray_next_1, rgray_next_2;
    logic             rempty_val_1, rempty_val_2;
    

    always_ff @(posedge i_clk_m or negedge i_rst_n_m)
        if (!i_rst_n_m) 
            begin 
                rbin <= 0;
                rptr <= 0;
            end
        else 
        if (!s_rs ) 
            begin 
                rbin <= 0;
                rptr <= 0;
            end
        else 
            begin
                rbin <= rbin_next;
                rptr <= rgray_next_1;
            end


    always_ff @(posedge i_clk_m or negedge i_rst_n_m)
        begin
            if(!i_rst_n_m)
                begin
                    m_stalvl_1.empty           <= 1;
                    m_stalvl_1.almost_empty    <= 0;
                end
            else
            if(!s_rs)
                begin
                    m_stalvl_1.empty           <= 1;
                    m_stalvl_1.almost_empty    <= 0;
                end
            else
                begin
                    m_stalvl_1.empty       <= rempty_val_1;
                    m_stalvl_1.almost_empty <= rempty_val_2;

                end
            end
        
    
    always_comb
        begin
            raddr = rbin[ASIZE-1:0];
            rbin_next       = rbin + (m_dstm_2.ready & ~m_stalvl_1.almost_empty);
            rgray_next_1    = (rbin_next >> 1) ^ rbin_next;
            rempty_val_1    = (rgray_next_1 == rq2_wptr);
            rgray_next_2    = ((rbin_next + s_cfg_sta_1.almost_empty) >> 1 ) ^ (rbin_next + s_cfg_sta_1.almost_empty);
            rempty_val_2    = (rgray_next_2 == rq2_wptr) ;
        end
    //----------------------------------------------------------------------

    // sync_w2r
    logic [ASIZE : 0] rq1_wptr;
    always_ff @(posedge i_clk_m or negedge i_rst_n_m)
        if (!i_rst_n_m) {rq2_wptr,rq1_wptr} <= 0;
        else
        if (!s_rs) {rq2_wptr,rq1_wptr} <= 0;
        else {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
    //----------------------------------------------------------------------	

    //fifomem
    logic    [WIDTH - 1 : 0] MEM [0:DEPTH-1];
    // read data
    assign m_dstm_2.data = MEM[raddr];
    // write data
    always_ff @(posedge i_clk_s)
        if(s_dstm_1.valid && !m_stalvl_1.full)
            MEM[waddr] <= s_dstm_1.data;


    //----------------------------------------------------------------------
    assign m_stalvl_2.full          = m_stalvl_1.full;
    assign m_stalvl_2.empty         = m_stalvl_1.empty;
    assign m_stalvl_2.almost_full   = m_stalvl_1.almost_full;
    assign m_stalvl_2.almost_empty  = m_stalvl_1.almost_empty;
    //----------------------------------------------------------------------
endmodule


module apb_fifo (

    input logic i_clk_s, i_rst_n_s,
    input logic i_clk_m, i_rst_n_m,
    apb_intf    apb,
    dstm    s_dstm_2, m_dstm_2,                 dstm_1,
    fifo_stalvl s_stalvl_2, m_stalvl_2,         stalvl_1,
    cfg_sta                                     cfg_sta_1,
    output logic [`DW_fifo - 1 : 0] data,
    input logic [`DW_fifo - 1 : 0] data_in
    );

    wire s_rs;
    apb_regs apb_regs(
        .apb_slv(apb), .m_dstm_1(dstm_1.mst), .s_dstm_2(s_dstm_2), 
        .s_stalvl_1(stalvl_1.slv), .s_stalvl_2(s_stalvl_2), .m_cfg_sta_1(cfg_sta_1.mst),
        .s_rs(s_rs), .data(data), .data_in(data_in) 
        );
    csv_afifo async_fifo(
        .s_dstm_1(dstm_1.slv), .m_stalvl_1(stalvl_1.mst), .s_cfg_sta_1(cfg_sta_1.slv),
        .m_dstm_2(m_dstm_2), .m_stalvl_2(m_stalvl_2), .s_rs(s_rs),
        .i_clk_s(i_clk_s), .i_clk_m(i_clk_m), .i_rst_n_s(i_rst_n_s),
        .i_rst_n_m(i_rst_n_m)
        );
endmodule

module connect_2_device (

    input logic i_clk_s, i_rst_n_s_1, i_rst_n_s_2,
    input logic i_clk_m, i_rst_n_m_1, i_rst_n_m_2,
    apb_intf    apb_1, apb_2,
    dstm        s_dstm_2, m_dstm_2,             dstm_1, dstm_2,
    fifo_stalvl s_stalvl_2, m_stalvl_2,         stalvl_1, stalvl_2,
    cfg_sta                                     cfg_sta_1, cfg_sta_2,
    output logic [`DW_fifo - 1 : 0] data_1,
    input logic [`DW_fifo - 1 : 0] data_in_1,
    input logic [`DW_fifo - 1 : 0] data_in_2, 
    output logic [`DW_fifo - 1 : 0] data_2
    );
    apb_fifo apb_fifo_1(
        .apb(apb_1), .s_dstm_2(s_dstm_2.slv), .m_dstm_2(m_dstm_2.mst), 
        .m_stalvl_2(m_stalvl_2.mst), .s_stalvl_2(s_stalvl_2.slv), 
        .data(data_1), .data_in(data_in_1), .i_clk_s(i_clk_s), 
        .i_clk_m(i_clk_m), .i_rst_n_s(i_rst_n_s_1), .i_rst_n_m(i_rst_n_m_1),
        .stalvl_1(stalvl_1), .dstm_1(dstm_1), .cfg_sta_1(cfg_sta_1)
    );
    apb_fifo apb_fifo_2(
        .apb(apb_2), .s_dstm_2(m_dstm_2.slv), .m_dstm_2(s_dstm_2.mst), 
        .m_stalvl_2(s_stalvl_2.mst), .s_stalvl_2(m_stalvl_2.slv), 
        .data(data_2), .data_in(data_in_2), .i_clk_s(i_clk_m), 
        .i_clk_m(i_clk_s), .i_rst_n_s(i_rst_n_s_2), .i_rst_n_m(i_rst_n_m_2),
        .stalvl_1(stalvl_2), .dstm_1(dstm_2), .cfg_sta_1(cfg_sta_2)
    );
endmodule


