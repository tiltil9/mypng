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
//---   INIT_ADLER32_I   ----------------------------------
  event init_adler32_i_event;

  initial begin
    INIT_ADLER32_I;
  end

  task INIT_ADLER32_I;
    // variables
    integer fpt;
    integer tmp;

    // main body
    begin
      // open file
      fpt = $fopen( `ADLER32_I_FILE, "r");

      // core
      forever begin
        // wait
        @(init_adler32_i_event);

        // active
        // lst
        tmp = $fscanf(fpt, "%x", lst_i);
        // num
        tmp = $fscanf(fpt, "%x", num_i);
        // dat
        tmp = $fscanf(fpt, "%x", dat_i);

        // set last
        if (lst_i == 'd1) begin
          lst_flg_r = 'd1;
        end
      end
    end
  endtask

//***   CHKO   ****************************************************************
//---   CHKO_ADLER32_O   ----------------------------------
  initial begin
    CHKO_ADLER32_O;
  end

  task CHKO_ADLER32_O;
    // variables
    integer                  fpt     ;
    integer                  tmp     ;
    reg     [DATA_WD -1: 0]  dut_dat ;
    reg     [DATA_WD -1: 0]  sim_dat ;

    // main body
    begin
      // log
      #(10 * `CLK_FULL);
      $display( "\t\t function check to adler32 is on!");

      // open file
      fpt = $fopen(`ADLER32_O_FILE, "r");

      // core
      forever begin
        // wait
        @(negedge clk);

        if(dut.val_o) begin
          dut_dat = dut.dat_o;
          tmp     = $fscanf(fpt, "%x", sim_dat);

          // check
          if(dut_dat != sim_dat) begin
            $display ("\n\t ADLER32 ERROR: at %10d ns, adler(data count %10d) should be %08x, however is %08x \n"
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