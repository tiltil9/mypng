//------------------------------------------------------------------------------
  //
  //  Filename      : sub_bench.v
  //  Description   : sub testbench for png top
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-04-23
  //
//------------------------------------------------------------------------------

//***   DATA_I   ***************************************************************
//---   PNG_DATA_I   -------------------------------------
  event png_data_i_event ;

  initial begin
    PNG_DATA_I ;
  end

  task PNG_DATA_I ;
    // variables
    integer fpt     ;
    integer tmp     ;
    integer cnt_w_r ;

    // main body
    begin
      // open file
      fpt = $fopen( `PNG_I_FILE , "r") ;

      // core loop
      forever begin
        // wait
        @( png_data_i_event ) ;

        // active
          // val_i
          val_i = 1'd1;
          
          // dat_i
          for( cnt_w_r = 'd0 ; cnt_w_r < `SIZE_W ; cnt_w_r = cnt_w_r + 'd1 ) begin
            tmp = $fscanf( fpt , "%x" , dat_i );
            @(negedge clk ) ;
          end

          // val_i
          val_i = 'd0;
      end
    end
  endtask


//***   DATA_O   ***************************************************************
//---   CHKO_TOP_O   -------------------------------------
  initial begin
    CHKO_TOP_O;
  end

  task CHKO_TOP_O;
    // variables
    integer                       fpt     ;
    integer                       tmp     ;
    reg     [`DATA_PXL_WD -1: 0]  dut_dat ;
    reg     [`DATA_PXL_WD -1: 0]  sim_dat ;

    // main body
    begin
      // log
      #(10 * `CLK_FULL);
      $display( "\t\t function check to png is on!");

      // open file
      fpt = $fopen(`PNG_O_FILE, "r");

      // core
      forever begin
        // wait
        @(negedge clk);

        if(dut.val_o) begin // !!! val_o could be valid during several successively cycles
          dut_dat = dut.dat_o;
          tmp     = $fscanf(fpt, "%x", sim_dat);

          // check
          if(dut_dat != sim_dat) begin
            $display ("\n\t BS ERROR: at %10d ns, png should be %08x, however is %08x \n"
                          , $time
                          , sim_dat
                          , dut_dat
            );

            // log
            # (10 * `CLK_FULL);
            $stop;
          end
        end
      end
    end
  endtask

//---   FILTER_DATA_O   -------------------------------------
initial begin
  FILTER_DATA_O ;
end

task FILTER_DATA_O ;
  // variables
  integer                      fpt     ;
  integer                      tmp     ;
  reg     [`DATA_PXL_WD-1 :0]  dut_dat ;
  reg     [`DATA_PXL_WD-1 :0]  sim_dat ;
  reg     [`SIZE_W_WD-1   :0]  cnt_r   ;

  // main body
  begin
    // log
    #( 10 * `CLK_FULL );
    $display( "\t\t function check to filter is on!" ) ;

    // open file
    fpt = $fopen( `FILTER_O_FILE , "r") ;

    // initial
    cnt_r = 'd0;

    // core loop
    forever begin
      // wait
      @(negedge clk ) ;

      if( dut.filter_fifo_flt_wr_val_o ) begin
        dut_dat = dut.filter_fifo_flt_wr_dat_o          ;
        tmp     = $fscanf( fpt ,"%x" , sim_dat ) ;

        // check
        if( dut_dat != sim_dat ) begin
          $display ("\n\t FILTER_TOP ERROR: at %08d ns, filter_data(scanline %04d-%04d) should be %08x, however is %08x \n"
                        , $time
                        , cnt_h_r
                        , cnt_r
                        , sim_dat
                        , dut_dat
          ) ;

        // log
        # ( 10 * `CLK_FULL ) ;
        $stop ;
        end
        else begin
          cnt_r = (cnt_r + 'd1) % (`SIZE_W + 'd1);
        end
      end
    end
  end
endtask

//---   LZ77_DATA_O   -------------------------------------
  initial begin
    LZ77_DATA_O ;
  end

  task LZ77_DATA_O ;
    // variables
    integer                      fpt         ;
    integer                      tmp         ;
    integer                      cnt_r       ;
    reg                          dut_flg_lit ;
    reg     [`DATA_PXL_WD-1 :0]  dut_dat_lit ;
    reg                          dut_flg_lst ;
    reg     [`SIZE_LEN_WD-1 :0]  dut_dat_len ;
    reg     [`SIZE_DST_WD-1 :0]  dut_dat_dis ;
    reg                          sim_flg_lit ;
    reg     [`DATA_PXL_WD-1 :0]  sim_dat_lit ;
    reg                          sim_flg_lst ;
    reg     [`SIZE_LEN_WD-1 :0]  sim_dat_len ;
    reg     [`SIZE_DST_WD-1 :0]  sim_dat_dis ;

    // main body
    begin
      // log
      #( 10 * `CLK_FULL );
      $display( "\t\t function check to lz77 is on!" ) ;

      // open file
      fpt = $fopen( `LZ77_O_FILE , "r") ;

      // initial
      cnt_r = 'd0;

      // core loop
      forever begin
        // wait
        @(negedge clk ) ;

        if( dut.lz77_val_o ) begin
          // flg_lst
          dut_flg_lst = dut.lz77_flg_lst_o ;
          tmp         = $fscanf( fpt ,"%x" , sim_flg_lst ) ;

          // flg_lit
          dut_flg_lit = dut.lz77_flg_lit_o ;
          tmp         = $fscanf( fpt ,"%x" , sim_flg_lit ) ;

          if ( sim_flg_lit ) begin
            // dat_lit
            dut_dat_lit = dut.lz77_dat_lit_o  ;
            tmp         = $fscanf( fpt ,"%x" , sim_dat_lit ) ;
          end
          else begin
            // dat_len/dat_dis
            dut_dat_len = dut.lz77_dat_len_o  ;
            dut_dat_dis = dut.lz77_dat_dst_o  ;
            tmp         = $fscanf( fpt ,"%x" , sim_dat_len ) ;
            tmp         = $fscanf( fpt ,"%x" , sim_dat_dis ) ;
          end

          // check
          if( sim_flg_lit ) begin
            if ( sim_flg_lit != dut_flg_lit || sim_flg_lst !=  dut_flg_lst || sim_dat_lit != dut_dat_lit ) begin
              $display ("\n\t LZ77_TOP ERROR: at %08d ns, lz77_data(scanline %02d-%02d) should be %01x-%02x-%02x, however is %01x-%02x-%02x \n"
                            , $time
                            , cnt_h_r
                            , cnt_r
                            , sim_flg_lst
                            , sim_flg_lit
                            , sim_dat_lit
                            , dut_flg_lst
                            , dut_flg_lit
                            , dut_dat_lit
              ) ;

              // log
              # ( 10 * `CLK_FULL ) ;
              $stop ;
            end
            else begin
              // $display ("\t (%02d,%02d) ok",cnt_h_r, cnt_r) ;
              cnt_r = cnt_r + 'd1;
            end
          end
          else begin
            if ( sim_flg_lit != dut_flg_lit ||  sim_flg_lst !=  dut_flg_lst || sim_dat_len != dut_dat_len || sim_dat_dis != dut_dat_dis ) begin
              $display ("\n\t LZ77_TOP ERROR: at %08d ns, lz77_data(scanline %02d-%02d) should be %01x-%02x-%02x-%02x, however is %01x-%02x-%02x-%02x \n"
                            , $time
                            , cnt_h_r
                            , cnt_r
                            , sim_flg_lst
                            , sim_flg_lit
                            , sim_dat_len
                            , sim_dat_dis
                            , dut_flg_lst
                            , dut_flg_lit
                            , dut_dat_len
                            , dut_dat_dis
              ) ;

              // log
              # ( 10 * `CLK_FULL ) ;
              $stop ;
            end
            else begin
              // $display ("\t (%02d,%02d) ok",cnt_h_r, cnt_r) ;
              cnt_r = cnt_r + 'd1;
            end
          end
        end
      end
    end
  endtask