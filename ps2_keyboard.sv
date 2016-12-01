module ps2_keyboard(input reset, input ps2_clk, input ps2_data, output key_downw, output key_upw, output [7:0] key);

`define KEYUP_ESCAPE 8'hF0

typedef enum reg [1:0]
{
	state_idle,
	state_reading_data,
	state_reading_parity_bit,
	state_reading_stop_bit
} test_state_t;

typedef struct
{
	reg [7:0] key;
	reg [2:0] ptr;
	
	reg is_key_up;
	
	test_state_t state;
} test_info_t;

// Set the default value of our structure to zero.
test_info_t testinfo = '{0,0,0,state_idle};

assign key = testinfo.key;

reg key_down;
reg key_up;

assign key_upw = key_up;
assign key_downw = key_down;

always @(negedge ps2_clk or posedge reset)
begin
	if(reset) begin
		testinfo = '{0,0,0,state_idle};
	end
	else begin
		// Switch on our current state.
		case( testinfo.state )
		
			state_idle:
			begin
				// Start if we see ps2_data go low...
				if(!ps2_data)
				begin
					testinfo.state <= state_reading_data;
					//testinfo.is_key_up <= 0;
					testinfo.ptr <= 0;
					
					key_up <= 0;
					key_down <= 0;
				end
			end
			
			state_reading_data:
			begin
				testinfo.key[testinfo.ptr] <= ps2_data;
				
				// Once data byte is done, go to reading parity bit.
				if(testinfo.ptr >= 7) begin
					testinfo.state <= state_reading_parity_bit;
					testinfo.ptr <= 0;
				end
				else
					testinfo.ptr <= testinfo.ptr + 1;
			end
			
			state_reading_parity_bit:
			begin
				testinfo.state <= state_reading_stop_bit;
				
				// Check parity here. If bad, raise a "bad data" output line high.
				
				if( testinfo.is_key_up )
				begin
					key_up <= 1;
					testinfo.is_key_up <= 0;
				end
				else if( testinfo.key == `KEYUP_ESCAPE)
				begin
					testinfo.is_key_up <= 1;
				end
				else begin
					key_down <= 1;
					testinfo.is_key_up <= 0;
				end
			end
			
			state_reading_stop_bit:
			begin
				key_up <= 0;
				key_down <= 0;
				
				testinfo.state <= state_idle;
			end
			
			default:
				testinfo = '{0,0,0,state_idle};
		endcase
	end
end



endmodule
