//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

//***   INIT   ****************************************************************
//---   INIT_BS_I   -------------------------------------
  event init_bs_i_event;

  initial begin
    INIT_BS_I;
  end

  task INIT_BS_I;
    // variables
    integer fpt;
    integer tmp;

    // main body
    begin
      // open file
      fpt = $fopen(`BS_I_FILE, "r");

      // core
      forever begin
        // wait
        @(init_bs_i_event);

        // active
        // lst
        tmp = $fscanf(fpt, "%x", lst_i);
        // flg lit
        tmp = $fscanf(fpt, "%x", flg_lit_i);
        // dat
        if (flg_lit_i == 'd1) begin
          // lit dat
          tmp = $fscanf(fpt, "%x", lit_dat_i); 
        end
        else begin
          // len dat
          tmp = $fscanf(fpt, "%x", len_dat_i); 
          // dis dat
          tmp = $fscanf(fpt, "%x", dis_dat_i); 
        end

        // adler32
        if (lst_i == 'd1) begin
          adler32_done_i = 'd1; // can set this to zero later or not in sim
          tmp = $fscanf(fpt, "%x", adler32_dat_i); 
        end

        // set last
        if (lst_i == 'd1) begin
          lst_flg_r = 'd1;
        end
      end
    end
  endtask

//***   CHKO   ****************************************************************
//---   CHKO_BS_O   -------------------------------------
  initial begin
    CHKO_BS_O;
  end

  task CHKO_BS_O;
    // variables
    integer                  fpt     ;
    integer                  tmp     ;
    reg     [DATA_WD -1: 0]  dut_dat ;
    reg     [DATA_WD -1: 0]  sim_dat ;

    // main body
    begin
      // log
      #(10 * `CLK_FULL);
      $display( "\t\t function check to bs is on!");

      // open file
      fpt = $fopen(`BS_O_FILE, "r");

      // core
      forever begin
        // wait
        @(negedge clk);

        if(dut.val_o) begin // !!! val_o could be valid during several successively cycles
          dut_dat = dut.dat_o;
          tmp     = $fscanf(fpt, "%x", sim_dat);

          // check
          if(dut_dat != sim_dat) begin
            $display ("\n\t BS ERROR: at %10d ns, bs(data count %10d) should be %08x, however is %08x \n"
                          , $time
                          , cnt_dat_r
                          , sim_dat
                          , dut_dat
            );

            // log
            # (10 * `CLK_FULL);
            $finish;
          end
        end
      end
    end
  endtask