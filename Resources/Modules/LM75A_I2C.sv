module LM75A_I2C (
    input  logic clk,                  // 50 Mhz
    output logic i2c_scl,              // I2C Clock
    inout  wire  i2c_sda,              // I2C Data (bidirectional)
    output logic sensor_found,         // Debug
    output logic [7:0] temp_data       // Output temperature (standard C)
);

    // I2C clock gen - 50MHz -> 100KHz...50Mhz/x = 100K
    // We need individual timing steps to actually manage the data though.
    // Using 4 steps gives us 400KHz sampling time. i.e every 125 ticks

    localparam LM75A_W = 8'b1001000_0; // LM75A ID + Write(0)
    localparam LM75A_R = 8'b1001000_1; // LM75A ID + Read(1)


    logic [7:0] clk_count = 0;
    logic tick; // Running at 400Hz

    always_ff @(posedge clk) begin
        if (clk_count >= 124) begin
            clk_count <= 0;
            tick <= 1;
        end else begin
            clk_count <= clk_count + 1;
            tick <= 0;
        end
    end

    typedef enum logic [5:0] {
        IDLE,
        START,
        ADDR_W,     // Send Address + Write
        ACK_1,      // Wait for sensor to ack
        PTR_REG,    // Send Register 0;
        ACK_2,      
        RESTART,    // Send START again
        ADDR_R,     // Send Address + Read
        ACK_3,
        READ_MSB,   // Read the temperature integer
        ACK_4,      // We send Ack
        READ_LSB,   // Read .5 part (we ignore this for now)
        NACK_5,     // We send Nack (stop reading)
        STOP
    } state_t;

    state_t state  = IDLE;

    // I2C Signals
    logic sda_out = 1;
    logic sda_link = 0;     // 1 = Drive output,    0 = Read Input (High Z)
    logic scl_enable = 0;   // 0 = SCL High (IDLE), 1 = SCL Toggling

    // Data Management
    logic [2:0] bit_idx = 0;
    logic [7:0] saved_data = 0;
    logic [7:0] addr = LM75A_W; 

    // Tristate Buffer
    assign i2c_sda = (sda_link) ? sda_out : 1'bz;

    // SCL logic: if enabled, toggle at 100KHz. If disabled, float high
    assign i2c_scl = (scl_enable) ? ~clk_count[7] : 1'b1;

    // --- MAIN FSM ---
    // We update state every "tick" (400kHz) to create the sequence
    // This is a "Bit Banging" style state machine
    
    // Timing Helper: We use a sub-step counter (0-3) for each bit
    // Step 0: Change Data
    // Step 1: Float SCL High
    // Step 2: Read Data
    // Step 3: Pull SCL Low

    logic [1:0] sub_step = 0;
    

    always_ff @(posedge clk) begin
        if (tick) begin
            case (state)

                IDLE: begin
                    sda_link <= 1; sda_out <= 1; scl_enable <= 0;
                    if (sub_step == 3) begin
                        state <= START;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                START: begin
                    // Create start condition: SDA goes low while SCL high
                    scl_enable <= 1; // Start clocking
                    sda_link <= 1;
                    if (sub_step == 0) sda_out <= 1;
                    if (sub_step == 1) sda_out <= 0; // Drop SDA

                    if (sub_step == 3) begin
                        state <= ADDR_W;
                        bit_idx <= 7;
                        sub_step <= 0;
                        addr <= LM75A_W;
                    end else sub_step <= sub_step + 1;
                end

                ADDR_W: begin
                    sda_link <= 1;
                    if (sub_step == 0) sda_out <= addr[bit_idx];

                    if (sub_step == 3) begin
                        if (bit_idx == 0) state <= ACK_1;
                        else bit_idx <= bit_idx - 1;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                ACK_1: begin
                    sda_link <= 0; // Let go of bus, let slave Ack

                    if (sub_step == 2) begin
                        if (i2c_sda == 0) begin
                            sensor_found <= 1; // Success
                        end else begin
                            sensor_found <= 0; // Failure
                        end
                    end

                    if (sub_step == 3) begin
                        state <= PTR_REG;
                        bit_idx <= 7;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                PTR_REG: begin
                    sda_link <= 1;
                    if (sub_step == 0) sda_out <= 0; // Send 00000000

                    if (sub_step == 3) begin
                        if (bit_idx == 0) state <= ACK_2;
                        else bit_idx <= bit_idx - 1;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                ACK_2: begin
                    sda_link <= 0;
                    if (sub_step == 3) begin
                        state <= RESTART;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                RESTART: begin
                    // Repeated Start
                    sda_link <= 1;
                    if (sub_step == 0) sda_out <= 1;
                    if (sub_step == 1) sda_out <= 0; // Drop SDA

                    if (sub_step == 3) begin
                        state <= ADDR_R;
                        bit_idx <= 7;
                        addr <= LM75A_R;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                ADDR_R: begin
                    sda_link <= 1;
                    if (sub_step == 0) sda_out <= addr[bit_idx];

                    if (sub_step == 3) begin
                        if (bit_idx == 0) state <= ACK_3;
                        else bit_idx <= bit_idx - 1;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                ACK_3: begin
                    sda_link <= 0;
                    if (sub_step == 3) begin
                        state <= READ_MSB;
                        bit_idx <= 7;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                READ_MSB: begin
                    sda_link <= 0;  // Listen
                    // Read in the middle of pulse
                    if (sub_step == 2) saved_data[bit_idx] <= i2c_sda;

                    if (sub_step == 3) begin
                        if (bit_idx == 0) state <= ACK_4;
                        else bit_idx <= bit_idx - 1;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                ACK_4: begin
                    sda_link <= 1; sda_out <= 0;        // Master ACK (we want more data)
                    if (sub_step == 3) begin
                        state <= READ_LSB; // We just skip/dummy read LSB for now
                        bit_idx <= 7;
                        sub_step <= 0;
                        temp_data <= saved_data; // Update output
                    end else sub_step <= sub_step + 1;
                end

                READ_LSB: begin
                    sda_link <= 0;
                    if (sub_step == 3) begin
                        if (bit_idx == 0) state <= NACK_5;
                        else bit_idx <= bit_idx - 1;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                NACK_5: begin
                    sda_link <= 1; sda_out <= 1;    // master NACK (DONE Reading)
                    if (sub_step == 3) begin
                        state <= STOP;
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end

                STOP: begin
                    // Stop: SDA goes low->high while SCL high
                    if (sub_step == 0) sda_out <= 0;
                    if (sub_step == 1) scl_enable <= 0;  // SCL stops high
                    if (sub_step == 2) sda_out <= 1;    // SDA rises

                    if (sub_step == 3) begin
                        state <= IDLE;
                        // Wait for a long time before reading again (e.g 500ms)
                        // For simplicity, we loop immediately for now.
                        sub_step <= 0;
                    end else sub_step <= sub_step + 1;
                end
            endcase
        end
    end
endmodule


