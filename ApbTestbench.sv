module apb_master(

// Interface with System tasks
                  addr,
                  data_valid,
                  data,
                  data_dir,
             read_out_data,
             transaction_done,

// APB Interface signals
                  apb_clk,
                  apb_reset,
                  apb_write,
                  apb_selx,
                  apb_en,
                  apb_wdata,
                  apb_rdata,
                  apb_ready,
                  apb_addr,
  				  apb_tranerr
                 );
 
//INPUT/OUTPUT PORT DECLARATION  

// Interface with System tasks
  input     [7:0]       addr;
  input                 data_valid;  
  input     [31:0]      data;
  input                 data_dir;
  output [31:0]      read_out_data;
  output            transaction_done;

// APB Interface signals
  input                 apb_clk;
  input                 apb_reset;
  output                apb_write;
  output                apb_selx;
  output                apb_en;
  output   [31:0]       apb_wdata;
  input    [31:0]       apb_rdata;
  input                 apb_ready;
  output   [7:0]        apb_addr;
  output   				apb_tranerr;
                 

  reg [31:0]      read_out_data;
  reg            transaction_done;
 
  reg                apb_write;
  reg                apb_selx;
  reg                apb_en;
  reg 				 apb_tranerr;
  reg   [31:0]       apb_wdata;
  reg   [7:0]        apb_addr;
  reg   [31:0]		 timeout_cnt;
  initial 
    begin
      timeout_cnt=0;
    end
  reg	[31:0]		 timeout_limit;
  initial 
    begin
      timeout_limit=20;
    end

 
//CONSTANT STATE DECLARATION  
 
  parameter [1:0]IDLE=2'b00;
  parameter [1:0]SETUP=2'b01;
  parameter [1:0]ACCESS=2'b10;
 
// INTERNAL VARIABLES
  reg [2:0] present_state, next_state;
 
//PROCEDURAL BLOCK FOR INITIAL CONDITION  
  always@(posedge apb_clk)
  begin
      if(apb_reset)
        begin
       present_state<=IDLE;
    end
        else
        begin
          present_state<=next_state;
      end
    if( (present_state == ACCESS) && (apb_ready != 1))
    begin
       timeout_cnt <= timeout_cnt+1;    
    end
    else
    begin
       timeout_cnt <= 0;    
    end
  end
 
//PROCEDURAL BLOCK FOR STATE TRANSITION  
  always@(*)
  begin
      case(present_state)
        IDLE:
        begin
       if(apb_reset)
            begin
                next_state=IDLE;
            end
            else if(data_valid == 1)
            begin
                next_state = SETUP;
            end
            else
            begin      
               next_state=IDLE;
            end        
 
           
            apb_selx = 0;
            apb_write = 0;
            apb_en = 0;
            apb_wdata = 0;
          	apb_tranerr = 0;
        end
        SETUP:
        begin
            next_state = ACCESS;
            apb_selx = 1;
            apb_tranerr = 0;
            begin
            apb_addr = addr;
            if(data_dir == 1)
            begin
                apb_wdata = data;
                apb_write = 1;
            end
            else
            begin
               apb_wdata = 0;
               apb_write = 0;
            end
            end
        end
        ACCESS:
        begin
          if((apb_ready!=1) && (timeout_cnt>=timeout_limit))
             begin
               apb_tranerr = 1; 
               next_state = IDLE;
               
             end
            
            else if(apb_ready == 1)
             begin
                next_state = IDLE;
             end
             else
             begin
                next_state = ACCESS;
             end

             apb_selx = 1;
             apb_addr = addr;
             if(data_dir == 1)
             begin
                 apb_wdata = data;
                 apb_write = 1;
             end
             else
             begin
                apb_wdata = 0;
                apb_write = 0;
             end
             apb_en = 1;
           
        end
        default:
        begin
           next_state=IDLE;
        end
      endcase
  end // always @(*)

  always @(posedge apb_clk)
  begin
    if(apb_reset == 1)
      present_state <= IDLE;
    else
      present_state <= next_state;    
  end // always @(apb_clk)
 
  // LOGIC to read the apb_rdata when transaction is complete
  always @(posedge apb_clk)
  begin
    if( (present_state == ACCESS) && (apb_ready == 1) )
    begin
       transaction_done <=1;
       
      if(data_dir == 0)
      begin
        read_out_data <= apb_rdata;
      end
    end
    else
    begin
        transaction_done <= 0;
        read_out_data <= 0;
    end
  end
 
endmodule


module apb_slave(
                 apb_clk,
                 apb_reset,
                 apb_addr,
                 apb_write,
                 apb_en,
                 apb_wdata,
                 apb_rdata,
                 apb_selx,
                 apb_ready,
                 apb_slverr,
  				 wait_cycle
                );
 
 //INPUT/OUTPUT PORT DECLARATION
 
  input apb_clk;
  input apb_reset;
  input [7:0]apb_addr;
  input [31:0]apb_wdata;
  input apb_en;
  output [31:0]apb_rdata;
  output apb_ready;
  output apb_slverr;
  input apb_selx;
  input apb_write;
  input [31:0]wait_cycle;
 
//SIGNAL DECLARATION
   
  reg [31:0]apb_rdata=1'b0;
  reg [1:0]present_state;
  reg [1:0]next_state;
  reg [31:0]mem[31:0];
  reg apb_ready;
  reg apb_slverr;
 
//CONSTANT PARAMETER DECLARATION FOR STATE TRANSITION
 
  parameter [1:0]IDLE=2'b00;
  parameter [1:0]SETUP=2'b01;
  parameter [1:0]ACCESS=2'b10;

// INTERNAL REGISTERS
 
  reg  [31:0] l_cnt;
 
  initial
  begin

      l_cnt = 0;
  end
 
//PROCEDURAL BLOCK FOR SEQUENTIAL LOGIC
 
  always@(posedge apb_clk) begin
    if(apb_reset)
      present_state<=IDLE;
    else
      present_state<=next_state;
   
    if( (present_state == IDLE) && (apb_selx == 1))
    begin
       l_cnt <= l_cnt + 1;    
    end
    else
    begin
       l_cnt <= 0;    
    end
  end

//PROCEDURAL BLOCK FOR COMBINATIONAL LOGIC FOR STATE TRANSITION
 
  always@(*) begin
    case(present_state)      
      IDLE:
      begin
          if( (apb_selx == 1) && (l_cnt >= wait_cycle))
          begin          
              next_state = SETUP;          
          end
          else
          begin
            next_state = IDLE;            
          end
 
          apb_ready  = 0;  
          apb_slverr = 0;    
         
      end
      SETUP:
      begin
         apb_ready = 0;
         apb_slverr = 0;    
         next_state = ACCESS;
         
         if(apb_selx == 0)
         begin
             next_state = IDLE;
         end        
      end      
      ACCESS:
      begin
          if( (apb_selx == 1) && (apb_en == 1))
          begin
              next_state = IDLE;
          end
          else if((apb_selx == 1) && (apb_en == 0))
          begin
            next_state = ACCESS;
          end
          else
          begin
            next_state = IDLE;
          end

          apb_ready = 1;          
          if( (apb_selx == 1) && (apb_en == 1))
          begin
             if(apb_addr > 31)
             begin
                apb_slverr = 1;
             end
             else if(apb_write == 0)
             begin
                 apb_rdata = mem[apb_addr];
             end
             else if(apb_write == 1)
             begin
                 mem[apb_addr] = apb_wdata;
             end
             else
             begin
                apb_slverr = 1;
             end
          end
      end
      default :
      begin
        next_state=IDLE;
      end

    endcase
  end    
endmodule

module apb_testbench;

  reg  core_clk;
  reg  sys_reset;

  reg [7:0]  addr;
  reg [31:0] data;
  reg        data_valid;
  reg        data_dir;
  reg [31:0] wait_cycle;
  wire [31:0] read_out_data;
  wire        transaction_done;
   
   
  wire apb_ready;
  wire apb_selx;
  wire apb_en;
  wire apb_write;
  wire [7:0]apb_addr;
  wire [31:0]apb_rdata;
  wire [31:0]apb_wdata;
 
  // Initial block for generating the clock
  initial
  begin
    core_clk = 0;

    while(1)
    begin
       #5 core_clk = ~core_clk;
    end
  end

  // Initial block for asserting & de-asserting the reset
  initial
  begin
    sys_reset = 1;
    #50
    sys_reset = 0;
  end

   apb_master master(
      // System interface
      .addr(addr),
 .data_valid(data_valid),
      .data (data),
      .data_dir (data_dir),
      .transaction_done(transaction_done),
      .read_out_data(read_out_data),
      // APB interface signals
     .apb_clk(core_clk),
      .apb_reset(sys_reset),
      .apb_write(apb_write),
      .apb_selx(apb_selx),
      .apb_en(apb_en),
      .apb_wdata(apb_wdata),
      .apb_rdata(apb_rdata),
      .apb_ready(apb_ready),
     .apb_addr(apb_addr)
           );
   apb_slave slave(
       .apb_clk(core_clk),
       .apb_reset(sys_reset),
       .apb_addr(apb_addr),
       .apb_write(apb_write),
       .apb_en(apb_en),
       .apb_wdata(apb_wdata),
  .apb_rdata(apb_rdata),
       .apb_selx(apb_selx),
     .apb_ready(apb_ready),
     .wait_cycle(wait_cycle)
    );


  // initial block to end the simulation
  initial
  begin
    #500;
    $finish;
  end
 
   initial
   begin
       $dumpfile("dump.vcd");
       $dumpvars;
   end
 
   // Test the transaction
   initial
   begin  
 `ifdef TEST1_WR_RD
     @(negedge sys_reset);
     data = 10;
     addr = 4;
     data_dir=1;
     data_valid=1;
     @(posedge transaction_done);
     data_valid=0;

     data = 12;
     addr = 5;
     data_dir=1;
     data_valid=1;
     @(posedge transaction_done);
     data_valid=0;

     data = 12;
     addr = 4;
     data_dir=0;
     data_valid=1;
     @(posedge transaction_done);
     data_valid=0;
   
     
     data = 12;
     addr = 5;
     data_dir=0;
     data_valid=1;
     @(posedge transaction_done);
     data_valid=0;
`endif
     
`ifdef TEST2_SLV_ERR_WR
     data = 12;
     addr = 100;
     data_dir=0;
     data_valid=1;
     @(posedge transaction_done);
     data_valid=0;  
`endif

`ifdef TEST3_SLV_ERR_RD
     data = 12;
     addr = 100;
     data_dir=1;
     data_valid=1;
     @(posedge transaction_done);
     data_valid=0;  
`endif
     
`ifdef TEST4_TIMEOUT
     #15
     data = 12;
     addr = 1;
     data_dir=1;
     data_valid=1;
     @(posedge transaction_done);
     data_valid=0;
`endif
     

   end

 
endmodule
