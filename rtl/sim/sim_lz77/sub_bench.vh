//------------------------------------------------------------------------------
  //
  //  Filename      : sub_bench.v
  //  Description   : sub testbench for lz77 top
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-05-04
  //
//------------------------------------------------------------------------------

//***   DATA_I   ***************************************************************
//---   LZ77_DATA_I   -------------------------------------
  initial begin
    LZ77_DATA_I ;
  end

  task LZ77_DATA_I ;
    // variables
    integer fpt     ;
    integer tmp     ;

    // main body
    begin
      // open file
      fpt = $fopen( `LZ77_I_FILE , "r") ;

      // core loop
      forever begin
        // wait
        @(negedge clk ) ;

        // fifo_flt_rd_dat_i
        if ( dut.fifo_flt_rd_val_o ) begin
          tmp = $fscanf( fpt ,"%x" , fifo_flt_rd_dat_i ) ;
        end
      end
    end
  endtask


//***   DATA_O   ***************************************************************
//---   FILTER_DATA_O   -------------------------------------
  initial begin
    FILTER_DATA_O ;
  end

  task FILTER_DATA_O ;
    // variables
    integer                      fpt         ;
    integer                      tmp         ;
    integer                      cnt_r       ;
    reg                          dut_flg_lit ;
    reg     [`DATA_PXL_WD-1 :0]  dut_dat_lit ;
    reg     [`SIZE_LEN_WD-1 :0]  dut_dat_len ;
    reg     [`SIZE_DST_WD-1 :0]  dut_dat_dis ;
    reg                          sim_flg_lit ;
    reg     [`DATA_PXL_WD-1 :0]  sim_dat_lit ;
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

        if( dut.val_o ) begin
          // flg_lit
          dut_flg_lit = dut.flg_lit_o ;
          tmp         = $fscanf( fpt ,"%x" , sim_flg_lit ) ;

          if ( sim_flg_lit ) begin
            // dat_lit
            dut_dat_lit = dut.dat_lit_o  ;
            tmp         = $fscanf( fpt ,"%x" , sim_dat_lit ) ;
          end
          else begin
            // dat_len/dat_dis
            dut_dat_len = dut.dat_len_o  ;
            dut_dat_dis = dut.dat_dst_o  ;
            tmp         = $fscanf( fpt ,"%x" , sim_dat_len ) ;
            tmp         = $fscanf( fpt ,"%x" , sim_dat_dis ) ;
          end

          // check
          if( sim_flg_lit ) begin
            if ( sim_flg_lit != dut_flg_lit || sim_dat_lit != dut_dat_lit ) begin
              $display ("\n\t LZ77_TOP ERROR: at %08d ns, lz77_data(scanline %02d-%02d) should be %01x-%02x, however is %01x-%02x \n"
                            , $time
                            , cnt_h_r
                            , cnt_r
                            , sim_flg_lit
                            , sim_dat_lit
                            , dut_flg_lit
                            , dut_dat_lit
              ) ;

              // log
              # ( 10 * `CLK_FULL ) ;
              $stop ;
            end
            else begin
              $display ("\t (%02d,%02d) ok",cnt_h_r, cnt_r) ;
              cnt_r = cnt_r + 'd1;
            end
          end
          else begin
            if ( sim_flg_lit != dut_flg_lit || sim_dat_len != dut_dat_len || sim_dat_dis != dut_dat_dis ) begin
              $display ("\n\t LZ77_TOP ERROR: at %08d ns, lz77_data(scanline %02d-%02d) should be %01x-%02x-%02x, however is %01x-%02x-%02x \n"
                            , $time
                            , cnt_h_r
                            , cnt_r
                            , sim_flg_lit
                            , sim_dat_len
                            , sim_dat_dis
                            , dut_flg_lit
                            , dut_dat_len
                            , dut_dat_dis
              ) ;

              // log
              # ( 10 * `CLK_FULL ) ;
              $stop ;
            end
            else begin
              $display ("\t (%02d,%02d) ok",cnt_h_r, cnt_r) ;
              cnt_r = cnt_r + 'd1;
            end
          end
        end
      end
    end
  endtask