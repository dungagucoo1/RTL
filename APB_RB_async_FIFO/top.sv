`define PERIOD 8
`define period_read_fifo 12
module top (
    );
    apb_intf    apb_1(), apb_2();
    dstm        s_dstm_2(), m_dstm_2()         , dstm_1(), dstm_2();
    fifo_stalvl s_stalvl_2(), m_stalvl_2()     , stalvl_1(), stalvl_2();
    cfg_sta                                      cfg_sta_1(), cfg_sta_2();
    //----------FIFO----------
    logic i_rst_n_s_1, i_rst_n_s_2;
    logic i_clk_m, i_rst_n_m_1, i_rst_n_m_2 ;
    //----------end-----------
    //------------------------
    //----------APB-----------
    logic [m_dstm_2.WIDTH - 1 : 0] data_1, data_in_1;
    logic [s_dstm_2.WIDTH - 1 : 0] data_in_2, data_2;
    //----------end-----------
    connect_2_device connect_2_device(
        .apb_1(apb_1), .apb_2(apb_2), 
        .data_1(data_1), .data_2(data_2), .data_in_1(data_in_1),
        .data_in_2(data_in_2), .i_clk_s(apb_1.pclk), .i_clk_m(i_clk_m),
        .i_rst_n_s_1(i_rst_n_s_1), .i_rst_n_m_1(i_rst_n_m_1), .i_rst_n_s_2(i_rst_n_s_2), 
        .i_rst_n_m_2(i_rst_n_m_2), .s_dstm_2(s_dstm_2), .m_dstm_2(m_dstm_2),
        .m_stalvl_2(m_stalvl_2), .s_stalvl_2(s_stalvl_2), .dstm_1(dstm_1),
        .dstm_2(dstm_2), .stalvl_1(stalvl_1), .stalvl_2(stalvl_2),
        .cfg_sta_1(cfg_sta_1), .cfg_sta_2(cfg_sta_2)
        );

        // apb_regs apb_regs(
        //     .apb_slv(apb_1), .m_dstm_1(dstm_1.mst), .s_dstm_2(s_dstm_2), 
        //     .s_stalvl_1(stalvl_1.slv),.s_stalvl_2(s_stalvl_2),.m_cfg_sta_1(cfg_sta_1.mst),
        //     .s_rs(s_rs), .data(data_1), .data_in(data_in_1) 
        //     );
        // csv_afifo async_fifo(
        //     .s_dstm_1(dstm_1.slv), .m_stalvl_1(stalvl_1.mst), .s_cfg_sta_1(cfg_sta_1.slv),
        //     .m_dstm_2(m_dstm_2), .m_stalvl_2(m_stalvl_2), .s_rs(s_rs),
        //     .i_clk_s(apb_1.pclk), .i_clk_m(i_clk_m), .i_rst_n_s(i_rst_n_s_1),
        //     .i_rst_n_m(i_rst_n_m_1)
        //     );
            // apb_fifo apb_fifo_1(
            //     .apb(apb_1), .s_dstm_2(s_dstm_2), .m_dstm_2(m_dstm_2), 
            //     .m_stalvl_2(m_stalvl_2), .s_stalvl_2(s_stalvl_2), .s_rs(s_rs), 
            //     .data(data_1), .data_in(data_in_1), .i_clk_s(apb_1.pclk), 
            //     .i_clk_m(i_clk_m), .i_rst_n_s(i_rst_n_s_1), .i_rst_n_m(i_rst_n_m_1),
            //     .stalvl_1(stalvl_1), .dstm_1(dstm_1), .cfg_sta_1(cfg_sta_1)
            // );
    //----------------------------------------------
    //----------------------------------------------
    initial begin
        reset_1();
        start_1();
        run_apb_1();
        run_fifo_1(18, 12);
        run_fifo_1(18, 18);
        // write_fifo_1(18);
        // read_fifo_2(18);
        // write_fifo_1(18);
        // read_fifo_2(18);
        $finish;
    end
    initial begin
        reset_2();
        start_2();
        run_apb_2();
        run_fifo_2(18, 10);
        run_fifo_2(5, 10);
    end
    
    //----------------------------------------------
    //----------------------------------------------
    //task w_num_clock
    task w_num_clock(integer w_c);
        begin
            for (int i = 0; i < w_c; i++) begin
                @(posedge apb_1.pclk);
            end
        end
    endtask
    task r_num_clock(integer r_c);
        begin
            for (int i = 0; i < r_c; i++) begin
                @(posedge i_clk_m);
            end
        end
    endtask
    //------------------------task reset------------------------
    task reset_1;
        i_clk_m = 0;
        apb_1.pclk = 0;
        i_rst_n_s_1 = 0;
        i_rst_n_m_1 = 0;
        apb_1.preset_n = 0;
        apb_1.paddr = 0;
        apb_1.pwrite = 1'b0;
        apb_1.psel = 1'b0;
        apb_1.penable = 1'b0;
        apb_1.pwdata = 0;
        w_num_clock(1);     
    endtask
    task reset_2;
        // i_clk_m = 0;
        apb_2.pclk = 0;
        i_rst_n_s_2 = 0;
        i_rst_n_m_2 = 0;
        apb_2.preset_n = 0;
        apb_2.paddr = 0;
        apb_2.pwrite = 1'b0;
        apb_2.psel = 1'b0;
        apb_2.penable = 1'b0;
        apb_2.pwdata = 0;
        w_num_clock(1);     
    endtask


    //------------------------task start------------------------
    task start_1;
        w_num_clock(4);
        data_in_1 = 10;    
        i_rst_n_s_1 = 1;
        i_rst_n_m_1 = 1;
        w_num_clock(1);
        apb_1.preset_n = 1;
    endtask
    task start_2;
        w_num_clock(4);
        data_in_2 = 10;    
        i_rst_n_s_2 = 1;
        i_rst_n_m_2 = 1;
        w_num_clock(1);
        apb_2.preset_n = 1;
    endtask
    //------------------------task read_apb------------------------
    task read_apb_1(input [apb_1.AW - 1 : 0] addr, output [apb_1.DW - 1 : 0]data_out, input [1:0]n);
        begin
            w_num_clock(1);       
            apb_1.paddr = addr ;
            apb_1.psel = 1'b1;
            apb_1.pwrite = 1'b0;
			w_num_clock(1);
			apb_1.penable  = 1'b1;
			if (n > 0) begin
				apb_1.pready = 1'b0;
				w_num_clock(n);
			end
			apb_1.pready = 1'b1;
			w_num_clock(1);
            apb_1.pready = 1'b0;
			apb_1.psel = 1'b0;
			apb_1.penable = 1'b0;
			data_out = apb_1.prdata;
        end
    endtask
    task read_apb_2(input [apb_2.AW - 1 : 0] addr, output [apb_2.DW - 1 : 0]data_out, input [1:0]n);
        begin
            r_num_clock(1);       
            apb_2.paddr = addr ;
            apb_2.psel = 1'b1;
            apb_2.pwrite = 1'b0;
			r_num_clock(1);
			apb_2.penable  = 1'b1;
			if (n > 0) begin
				apb_2.pready = 1'b0;
				r_num_clock(n);
			end
			apb_2.pready = 1'b1;
			r_num_clock(1);
            apb_2.pready = 1'b0;
			apb_2.psel = 1'b0;
			apb_2.penable = 1'b0;
			data_out = apb_2.prdata;
        end
    endtask
    //------------------------task write_apb------------------------
    task write_apb_1(input [apb_1.AW - 1 : 0] addr, input [apb_1.DW - 1 : 0]data, input [1:0]n);
        w_num_clock(1);       
        apb_1.paddr = addr ;
        apb_1.pwrite = 1'b1;
        apb_1.psel = 1'b1;
        apb_1.pwdata  = data;
        $display("Time:%d; 	Addr: %h; 	Data: %h",$realtime(),addr,data);
        w_num_clock(1);
        apb_1.penable  = 1'b1;
            if (n > 0) begin
                apb_1.pready = 1'b0;
                w_num_clock(n);
            end
        apb_1.pready = 1'b1;
        w_num_clock(1);    
        apb_1.pready = 1'b0;
        apb_1.psel = 1'b0;
        apb_1.penable = 1'b0;
    endtask

    task write_apb_2(input [apb_2.AW - 1 : 0] addr, input [apb_2.DW - 1 : 0]data, input [1:0]n);
        r_num_clock(1);       
        apb_2.paddr = addr ;
        apb_2.pwrite = 1'b1;
        apb_2.psel = 1'b1;
        apb_2.pwdata  = data;
        r_num_clock(1);
        apb_2.penable  = 1'b1;
            if (n > 0) begin
                apb_2.pready = 1'b0;
                r_num_clock(n);
            end
        apb_2.pready = 1'b1;
        r_num_clock(1);    
        apb_2.pready = 1'b0;
        apb_2.psel = 1'b0;
        apb_2.penable = 1'b0;
    endtask
    //------------------------task write_fifo------------------------
    task write_fifo_1(integer w);
        begin
            for (int i = 0; i < w; i++) begin
                write_apb_1(3,1,0);
                data_in_1++;
            end
        end
    endtask
    task write_fifo_2(integer w);
        begin
            for (int i = 0; i < w; i++) begin
                write_apb_2(3,1,0);
                data_in_2++;
            end
        end
    endtask
    //------------------------task read_fifo------------------------
    task read_fifo_1(integer r);
        begin 
            w_num_clock(3);    
            for (int i = 0; i < r; i++) begin
                write_apb_1(3,2,0);
            end
        end
    endtask
    task read_fifo_2(integer r);
        begin 
            r_num_clock(3);    
            for (int i = 0; i < r; i++) begin
                write_apb_2(3,2,0);
            end
        end
    endtask
    //------------------------task run_fifo------------------------
    task run_fifo_1(integer n, m);
        begin
            write_fifo_1(n);
            read_fifo_1(m);
        end
    endtask 
    task run_fifo_2(integer n, m);
        begin
            write_fifo_2(n);
            read_fifo_2(m);
        end
    endtask 
    //------------------------task run_apb------------------------
    task run_apb_1;
        write_apb_1(0,0,0);
        // read_apb(0,apb.prdata,0);
        // $display("Time:%d; 	Addr: %h; 	Data: %h",$realtime(),apb.paddr,apb.prdata);
        write_apb_1(0,1,0);
        w_num_clock(3);    
        write_apb_1(0,0,0);
        write_apb_1(2,1,0);
        write_apb_1(2,2,0);
    endtask
    task run_apb_2;
        write_apb_2(0,0,0);
        write_apb_2(2,1,0);
        write_apb_2(2,2,0);
    endtask
	always #(`period_read_fifo/2) i_clk_m = ~i_clk_m;
	always #(`PERIOD / 2) apb_1.pclk = ~apb_1.pclk;
	always #(`period_read_fifo/2) apb_2.pclk = ~apb_2.pclk;

endmodule