//------------------------------------------------------------------------------
  //
  //  Filename      : sub_bench.v
  //  Description   : sub testbench for filter top
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-04-23
  //
//------------------------------------------------------------------------------

//***   DATA_I   ***************************************************************
//---   FILTER_DATA_I   -------------------------------------
  event filter_data_i_event ;

  initial begin
    FILTER_DATA_I ;
  end

  task FILTER_DATA_I ;
    // variables
    integer fpt     ;
    integer tmp     ;
    integer cnt_w_r ;

    // main body
    begin
      // open file
      fpt = $fopen( `FILTER_I_FILE , "r") ;

      // core loop
      forever begin
        // wait
        @( filter_data_i_event ) ;

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

        if( dut.fifo_flt_wr_val_o ) begin
          dut_dat = dut.fifo_flt_wr_dat_o          ;
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