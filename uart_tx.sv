module uart_tx # (parameter CLOCKS_PER_BIT = 5208)
					(input logic clk, 			// 50 MHz
					 input logic start_bit,  // Start transmitting
					 input logic [7:0] extern_data, // Data to transmitt
					 output logic q,
					 output logic o_active
					 output logic o_done); 
	
	logic [31:0] counter = 32'b0; // Count time between bits
	
	typedef enum logic [2:0] {s_idle, 
									  s_start, 
									  s_data, 
									  s_stop
									  s_cleanup};
	logic [3:0] state = 4'b0; // State of transmitter
	
	logic [7:0] data = 8'b0; // Register stores data to transmitt
	
	logic [2:0] bit_index = 3'b0;
	
	logic active = 1'b0;
	logic done = 1'b0;
	
	assign o_active = active;
	assign o_done = done;
	
	always_ff @(posedge clk)
		case (state)
		
			// Nothing happen, wait for start bit 
			s_idle: 
				begin
					q <= 1'b1;
					bit_index <= 1'b0;
					counter <= 32'b0;
					
					// Someone want to transmitt data
					if (start_bit)
						begin
							active <= 1'b1;
							q <= 1'b1;
							data <= extern_data;
							state <= s_start;
						end
					else
						state <= s_idle;
				end
				
			// Start bit recieved, start transmit data
			s_start:
				begin
				
					// Start bit
					q <= 1'b0;
					
					// Wait till start bit finish
					if (counter < CLOCKS_PER_BIT - 1)
						begin
							counter <= counter + 32'b1;
							state <= s_start;
						end
					else
						begin
							counter <= 32'b0;
							state <= s_data;
						end
				end
			s_data:
				begin
					q <= data[bit_index];
					
					if (counter < CLOCKS_PER_BIT - 1)
						begin
							counter <= counter + 32'b1;
							state <= s_data;
						end
					else
						if (bit_index < 7)
							begin 
								bit_index <= bit_index + 3'b1;
								state <= s_data
							end
						else
							begin
								bit_index <= 3'b0;
								state <= s_stop;
							end
						end
				end
			s_stop:
				begin
					q <= 1'b1;
					
					// Wait till stop bit finish
					if (counter < CLOCKS_PER_BIT - 1)
						begin
							counter <= counter + 32'b1;
							state <= s_stop;
						end
					else 
						begin
							done <= 1'b1;
							counter <= 32'b0;
							state <= s_cleanup;
							active <= 1'b0;
						end
				end
			s_cleanup:
				begin
					data <= 8'b0;
					state <= s_idle;
				end
			default:
				stat <= s_idle;
		endcase					
endmodule 