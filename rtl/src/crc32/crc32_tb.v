module tb;

reg                   clk    ;
reg                   rstn   ;
reg                   start_i;
reg                   val_i  ;
reg  [8       -1 :0]  dat_i  ; // temp
reg                   lst_i  ;
wire                  done_o ;
wire                  val_o  ;
wire [32      -1 :0]  dat_o  ;

crc32 dut(.clk    (clk    ),
          .rstn   (rstn   ),
          .start_i(start_i),
          .val_i  (val_i  ),
          .dat_i  (dat_i  ),
          .lst_i  (lst_i  ),
          .done_o (done_o ),
          .val_o  (val_o  ),
          .dat_o  (dat_o  ) );

initial begin
    clk = 1'b0;
    forever 
	begin
		#10 clk = ~clk;
	end
end

initial
begin
    val_i = 1'b0;
    rstn = 1'b0;
	repeat(1) @(posedge clk);
	rstn = 1'b1;
    #1;
	repeat(1) @(posedge clk);
    dat_i = 8'h4;
    val_i = 1'b1;
    #1 ;
	repeat(1) @(posedge clk);
    val_i = 1'b0; // 5d0cc968
    #1;
	repeat(1) @(posedge clk);
    dat_i = 8'h9;
    val_i = 1'b1;
    #1 ;
	repeat(1) @(posedge clk);
    val_i = 1'b0; // 675ab5db

end


endmodule