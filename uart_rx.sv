module uart_rx # (parameter CLKS_PER_BIT)
					  (input logic clk,
					   input logic serial,
						output logic o_data
						// Signal for recieve all data
						output logic o_dv);
	
	typedef enum logic [2:0] {s_idle,
									  s_start,
									  s_data,
									  s_stop,
									  s_cleanup};
	
	logic [31:0] clock_counter = 32'b0;
	logic [2:0]  bit_index = 3'b0;
	
	// State of reciever
	logic [2:0]  state = 3'b0
	
	logic data = 1'b1;
	logic data_r = 1'b1;
	
	logic [7:0] r_bytes = 8'b0;
	
	assign o_data = r_bytes;
	
	always_ff @ (posedge clk)
		begin
			data_r <= serial;
			date <= data_r;
		end
	
	always_ff @ (posedge clk)
		begin
			case (state)
				s_idle:
					begin
						clock_counter <= 0;
						bit_index <= 0;
						o_dv <= 0;
						
						if (data == 1'b0)
							state <= s_start;
						else 
							state <= s_idle;
					end
				s_start:
					begin
						// Check in the middle of byte
						if (clock_counter == (CLKS_PER_BIT-1)/2)
							begin
								if (data == 1'b0)
									begin
										clock_counter <= 32'b0;
										state <= s_data;
									end
								else
									state <= s_idle
							end
						else
							begin
								CLKS_PER_BIT = CLKS_PER_BIT + 1;
								state <= s_start;
							end
					end
				s_data:
					begin
						if (clock_counter < CLK_PER_BIT - 1)
							begin
								clock_counter <= clock_counter + 1;
								state <= s_data;
							end
						else
							begin
								r_bytes[bit_index] <= data;
								clock_counter <= 0;
								if (bit_index < 7)
									begin
										state <= s_data;
										bit_index <= bit_index + 1;
									end
								else
									begin
										state <= s_stop;
										bit_index <= 3'b0;
									end
							end
					end
				s_stop:
					begin
						// Wait for stop bit to finish
						if (clock_counter < CLKS_PER_BIT-1)
							begin
								clock_counter <= clock_counter + 1;
								state <= s_stop
							end
						else
							begin
								clock_counter <= 0;
								o_dv <= 1;
								state <= s_cleanup;
							end
					end
				s_cleanup:
					begin
						o_dv <= 0;
						state <= s_idle;
					end
				default:
					state <= s_idle;
			endcase							
		end	
endmodule 