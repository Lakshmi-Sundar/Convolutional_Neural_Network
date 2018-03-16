//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// DUT

module MyDesign (

            //---------------------------------------------------------------------------
            // Control
            //
            output reg                  dut__xxx__finish   ,
            input  wire                 xxx__dut__go       ,  

            //---------------------------------------------------------------------------
            // b-vector memory 
            //
            output reg  [ 9:0]          dut__bvm__address  ,
            output reg                  dut__bvm__enable   ,
            output reg                  dut__bvm__write    ,
            output reg  [15:0]          dut__bvm__data     ,  // write data
            input  wire [15:0]          bvm__dut__data     ,  // read data
            
            //---------------------------------------------------------------------------
            // Input data memory 
            //
            output reg  [ 8:0]          dut__dim__address  ,
            output reg                  dut__dim__enable   ,
            output reg                  dut__dim__write    ,
            output reg  [15:0]          dut__dim__data     ,  // write data
            input  wire [15:0]          dim__dut__data     ,  // read data


            //---------------------------------------------------------------------------
            // Output data memory 
            //
            output reg  [ 2:0]          dut__dom__address  ,
            output reg  [15:0]          dut__dom__data     ,  // write data
            output reg                  dut__dom__enable   ,
            output reg                  dut__dom__write    ,


            //-------------------------------
            // General
            //
            input  wire                 clk             ,
            input  wire                 reset

            );

			
   //internal signals
   
   
	reg  [15:0]          inputdata;
	reg  [15:0]          bvmdata;
	reg                  save_B_in_ff;
	reg  [3:0]           B_reg_address;
	reg                  clk_count;
	reg                  zcounter;
	reg  [15:0]          Z_file;
 	wire                 firstnine;
	reg                  flag_finish;


	
   wire       dom_write;
   wire       save_B_in_ff_1;
   wire [3:0] B_reg_address_1;
   wire [8:0] A_address;
   wire [9:0] B_address;
   wire [1:0] quad_select;
   reg  [1:0] quad_select_ff;
   reg  [1:0] quad_select_ff_2;
   wire [15:0] dataOut;
   reg  [31:0] Z_output;
   wire [31:0] Z_output0, Z_output1, Z_output2, Z_output3;
   wire [15:0] trunc_Z;
   wire        clkcount;
   wire        zcounter_wire;
   wire [31:0] mac_c;
   wire [31:0] mac_final;  
   reg  [3:0]  enable;
   reg  [31:0] final_output[8:0];
   reg  [3:0]  B_reg_address_delay;
   wire [15:0] finaloutput_trunc;
   wire        flag_finish_wire;
   
   

   assign finaloutput_trunc = ( mac_final[31] ) ? 0 : mac_final[31:16];
   assign trunc_Z = (Z_output[31]) ? 0 : Z_output[31:16];
   assign mac_c   = final_output[B_reg_address_delay];
   
   always@(posedge clk) begin

  dut__bvm__address                  <= B_address;
  dut__dim__address                  <= A_address;
  dut__bvm__enable                   <= 1;
  dut__dim__enable                   <= 1;  
  dut__dom__enable                   <= 1;
  dut__bvm__write                    <= 0;
  dut__dim__write                    <= 0; 
  dut__dom__write                    <= dom_write;

  
  inputdata                          <= dim__dut__data;
  bvmdata                            <= bvm__dut__data;

  dut__dom__address                  <= B_reg_address[2:0];
  dut__dom__data                     <= finaloutput_trunc;
  
  save_B_in_ff                       <= save_B_in_ff_1;
  B_reg_address                      <= B_reg_address_1;
  clk_count                          <= clkcount;
  zcounter                           <= zcounter_wire;
  final_output[B_reg_address_delay]  <= ( firstnine ) ? 32'h0 : (!save_B_in_ff_1 ? mac_final : final_output[B_reg_address_delay]);
  B_reg_address_delay                <= B_reg_address;
  Z_file                             <= reset ? 0 : ( clkcount ) ? trunc_Z : Z_file;
  quad_select_ff                     <= quad_select;
  quad_select_ff_2                   <= quad_select_ff;
  
 if (reset) begin
    dut__xxx__finish                         <= 1;
    final_output[0]                          <= 0;
    final_output[1]                          <= 0;
    final_output[2]                          <= 0;
    final_output[3]                          <= 0;
    final_output[4]                          <= 0;
    final_output[5]                          <= 0;
    final_output[6]                          <= 0;
    final_output[7]                          <= 0;
    final_output[8]                          <= 0;
 end
 else if ( xxx__dut__go ) begin
    dut__xxx__finish                         <= 0; 
end
 else
    dut__xxx__finish                         <=  ( flag_finish_wire ) ? 1 : dut__xxx__finish;
  
  
  end


always@(*) begin
	case(quad_select_ff_2)
		0: begin Z_output = Z_output0; enable = 4'b0001; end
		1: begin Z_output = Z_output1; enable = 4'b0010; end
		2: begin Z_output = Z_output2; enable = 4'b0100; end
		3: begin Z_output = Z_output3; enable = 4'b1000; end
	endcase
end  
  
  //---------------------------------------------------------------------------
  //
  
  
  DW02_mac #(.A_width(16), .B_width(16)) mac(.A(Z_file), .B(bvmdata), .C(mac_c), .MAC(mac_final), .TC(1'b1));
  
  
  controller U0(.clock(clk), .reset(dut__xxx__finish), .A_address(A_address), .B_address(B_address), .quad_select(quad_select), .save_B_in_ff(save_B_in_ff_1), 
                                        .B_reg_address(B_reg_address_1), .count_clk(clkcount), .Zcounter0(zcounter_wire), .first_nine(firstnine), .finish_flag(flag_finish_wire), .dom_write(dom_write) );
  registerfile U1(.clock(clk), .reset(dut__xxx__finish), .address(B_reg_address), .dataIn(bvmdata), .write(save_B_in_ff), .dataOut(dataOut));
  
  // THE 4 QUADS
  quadrant U20( .clock(clk), .clear(clk_count), .enable(enable[0]), .dataA(inputdata), .dataB(dataOut), .data_out(Z_output0));
  quadrant U21( .clock(clk), .clear(clk_count), .enable(enable[1]), .dataA(inputdata), .dataB(dataOut), .data_out(Z_output1));
  quadrant U22( .clock(clk), .clear(clk_count), .enable(enable[2]), .dataA(inputdata), .dataB(dataOut), .data_out(Z_output2));
  quadrant U23( .clock(clk), .clear(clk_count), .enable(enable[3]), .dataA(inputdata), .dataB(dataOut), .data_out(Z_output3));
  
  
 
  //
  //`include "v564.vh"
  // 
  //---------------------------------------------------------------------------

endmodule



module registerfile ( input wire clock, input wire reset, input wire [3:0]address, input wire [15:0] dataIn, input wire write, output reg [15:0]dataOut );


reg [15:0] 	 register0, register1, register2, register3, register4, register5, register6, register7, register8;



   always @(posedge clock) begin
   
   if (reset) begin
		register0 <= 0;
		register1 <= 0;
		register2 <= 0;
		register3 <= 0;
		register4 <= 0;
		register5 <= 0;
		register6 <= 0;
		register7 <= 0;
		register8 <= 0;

	end
   
      if (write) begin
			case (address) 
			  0: register0 <= dataIn;
			  1: register1 <= dataIn;
			  2: register2 <= dataIn;
			  3: register3 <= dataIn;
			  4: register4 <= dataIn;
			  5: register5 <= dataIn;
			  6: register6 <= dataIn;
			  7: register7 <= dataIn;
			  8: register8 <= dataIn;
	
			endcase
			
		end
	end
	
   
   always@(*) begin
   
		if(!write) begin
			case (address)
			  0: dataOut = register0;
			  1: dataOut = register1;
			  2: dataOut = register2;
			  3: dataOut = register3;
			  4: dataOut = register4;
			  5: dataOut = register5;
			  6: dataOut = register6;
			  7: dataOut = register7;
			  8: dataOut = register8;
			endcase
			end
		else
			dataOut = dataIn;
	end
		
		
endmodule

// synopsys translate_off
`include "/afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW02_mac.v"
// synopsys translate_on

module quadrant ( input wire clock, input wire clear, input wire enable, input wire [15:0]dataA,  input wire [15:0]dataB, output wire [31:0] data_out );

wire [31:0] Accum_Z;
reg  [31:0] data_Outz;
wire [31:0] data_out_int;

assign Accum_Z  = clear ? 0 : data_Outz;
assign data_out = enable ? data_out_int : 0; 

always@(posedge clock)
	data_Outz <= data_out;


DW02_mac #(.A_width(16), .B_width(16)) mac(.A(dataA), .B(dataB), .C(Accum_Z), .MAC(data_out_int), .TC(1'b1));

endmodule

module controller ( input wire clock, input wire reset, output wire [8:0] A_address, output wire [9:0] B_address, output reg first_nine,
						output wire [1:0]quad_select, output reg Zcounter0, output reg count_clk, output reg save_B_in_ff, output reg [3:0]B_reg_address, output reg finish_flag, output reg dom_write );

reg  [3:0] x;   	 
reg  [3:0] y;   
reg  [5:0] count0;
reg  [5:0] countm;
reg  [3:0] countm_flip;
reg        skipper;

//reg        first_nine;



// Internal signals
reg       dom_write_unreg;
reg [3:0] next_state;
reg       add_count0;
reg [3:0] gen_x, gen_y, add_x, add_y;
reg [3:0] current_horiz_state;
wire[3:0] current_horiz_state_next;
wire      skipper_next;
//wire      count_clk;
//wire      save_B_in_ff;


// Next state decoder
always @(posedge clock)  begin
  if (reset) begin
	count0                   <= 0;
	current_horiz_state      <= 0;
	countm                   <= 0;
	skipper                  <= 0;
	
  end else begin
	count0                   <= count0 + ( (!skipper_next) & add_count0 );
	countm                   <= ( add_count0 ) ? count0 : countm;
	current_horiz_state      <= current_horiz_state_next;
	skipper                  <= skipper_next;
	
  end
end

always @(posedge clock)  begin
   save_B_in_ff             <= ( count0[3:0] == 0 ) ? 1 : 0;
   B_reg_address            <= current_horiz_state;
   count_clk                <= ~(|current_horiz_state);
   Zcounter0                <= add_count0;
   first_nine               <= ( save_B_in_ff & count0[5:4] == 0 );
   finish_flag              <= count0 == 6'h3F && ((!skipper_next) & add_count0);
   dom_write_unreg          <= &count0 & skipper & current_horiz_state != 8;
   dom_write                <= dom_write_unreg;
end


always@(*) begin
	x                        <= gen_x + add_x;
	y                        <= gen_y + add_y;
end

assign skipper_next             = ( count0[3:0] == 15 && add_count0 ) ? ( !skipper ) : skipper;
assign A_address                = {x,y};
assign B_address                = ( count0[3:0] == 0 )         ? ({count0[5:4],current_horiz_state}) : ({current_horiz_state,countm[5:4],countm_flip}+10'h40);


assign current_horiz_state_next = ( current_horiz_state == 8 ) ? 0 : current_horiz_state + 1;

assign quad_select              = count0[3:2];


always@(*) begin
	case( countm[3:0] )
		4'd0: countm_flip  = 0;
		4'd1: countm_flip  = 1;
		4'd2: countm_flip  = 4;
		4'd3: countm_flip  = 5;
		4'd4: countm_flip  = 2;
		4'd5: countm_flip  = 3;
		4'd6: countm_flip  = 6;
		4'd7: countm_flip  = 7;
		4'd8: countm_flip  = 8;
		4'd9: countm_flip  = 9;
		4'd10: countm_flip = 12;
		4'd11: countm_flip = 13;
		4'd12: countm_flip = 10;
		4'd13: countm_flip = 11;
		4'd14: countm_flip = 14;
		4'd15: countm_flip = 15;
	endcase
end
		
// gen_x logic
always@(*) begin
	case( count0[3:0] )
		4'b00_00 : begin gen_x = 0; gen_y = 0; end 
		4'b00_01 : begin gen_x = 0; gen_y = 3; end
		4'b00_10 : begin gen_x = 3; gen_y = 0; end
		4'b00_11 : begin gen_x = 3; gen_y = 3; end
		
		4'b01_00 : begin gen_x = 0; gen_y = 6; end
		4'b01_01 : begin gen_x = 0; gen_y = 9; end
		4'b01_10 : begin gen_x = 3; gen_y = 6; end
		4'b01_11 : begin gen_x = 3; gen_y = 9; end
		
		4'b10_00 : begin gen_x = 6; gen_y = 0; end
		4'b10_01 : begin gen_x = 6; gen_y = 3; end
		4'b10_10 : begin gen_x = 9; gen_y = 0; end
		4'b10_11 : begin gen_x = 9; gen_y = 3; end
		
		4'b11_00 : begin gen_x = 6; gen_y = 6; end
		4'b11_01 : begin gen_x = 6; gen_y = 9; end
		4'b11_10 : begin gen_x = 9; gen_y = 6; end
		4'b11_11 : begin gen_x = 9; gen_y = 9; end
	endcase
end 

always@(*) begin
	case( current_horiz_state )
		0      : begin add_x = 0; add_y = 0; add_count0 = 0;  end
		1      : begin add_x = 0; add_y = 1; add_count0 = 0;  end
		2      : begin add_x = 0; add_y = 2; add_count0 = 0;  end
		
		3      : begin add_x = 1; add_y = 0; add_count0 = 0;  end
		4      : begin add_x = 1; add_y = 1; add_count0 = 0;  end
		5      : begin add_x = 1; add_y = 2; add_count0 = 0;  end
		
		6      : begin add_x = 2; add_y = 0; add_count0 = 0;  end
		7      : begin add_x = 2; add_y = 1; add_count0 = 0;  end
		8      : begin add_x = 2; add_y = 2; add_count0 = 1;  end
		
		default: begin add_x = 0; add_y = 0; add_count0 = 0;  end
	endcase
end
 
endmodule
