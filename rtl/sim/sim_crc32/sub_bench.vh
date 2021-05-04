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
//---   INIT_CRC32_I   ----------------------------------
  event init_crc32_i_event;

  initial begin
    INIT_CRC32_I;
  end

  task INIT_CRC32_I;
    // variables
    integer fpt;
    integer tmp;

    // main body
    begin
      // open file
      fpt = $fopen(`CRC32_I_FILE, "r");

      // core
      forever begin
        // wait
        @(init_crc32_i_event);

        // active
        if (cnt_dat_r == 'd0) begin
          // w_i
          tmp = $fscanf(fpt, "%x", w_i);
          // h_i
          tmp = $fscanf(fpt, "%x", h_i);
        end
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
//---   CHKO_CRC32_O   ----------------------------------
  initial begin
    CHKO_CRC32_O;
  end

  task CHKO_CRC32_O;
    // variables
    integer                  fpt     ;
    integer                  tmp     ;
    reg     [DATA_WD -1: 0]  dut_dat ;
    reg     [DATA_WD -1: 0]  sim_dat ;

    // main body
    begin
      // log
      #(10 * `CLK_FULL);
      $display( "\t\t function check to crc32 is on!");

      // open file
      fpt = $fopen(`CRC32_O_FILE, "r");

      // core
      forever begin
        // wait
        @(negedge clk);

        if(dut.val_o) begin
          dut_dat = dut.dat_o;
          tmp     = $fscanf(fpt, "%x", sim_dat);

          // check
          if(dut_dat != sim_dat) begin
            $display ("\n\t CRC32 ERROR: at %10d ns, crc32(data count %10d)  should be %08x, however is %08x \n"
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