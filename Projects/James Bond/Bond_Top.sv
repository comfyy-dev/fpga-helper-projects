module Bond_Top (
    input logic clk,
    output logic buzzer,
    output logic [3:0] led
);

    // --- 1. DEFINING THE NOTES (Ticks for 50MHz Clock) ---
    // Calculated as: 50,000,000 / Freq / 2
    localparam E4  = 75843;  // 329.6 Hz
    localparam F4  = 71586;  // 349.2 Hz
    localparam Fs4 = 67568;  // 369.9 Hz (F Sharp)
    localparam G4  = 63776;  // 392.0 Hz
    localparam Ds4 = 80353;  // 311.1 Hz (D Sharp)
    localparam D4  = 85131;  // 293.7 Hz
    localparam REST = 0;

    // --- 2. TEMPO GENERATOR ---
    // We change notes every 0.25 seconds (fast tempo)
    logic [23:0] tempo_cnt = 0;
    logic beat_tick;

    always_ff @(posedge clk) begin
        // 12,500,000 ticks = 0.25 seconds
        if (tempo_cnt >= 12_500_000) begin
            tempo_cnt <= 0;
            beat_tick <= 1;
        end else begin
            tempo_cnt <= tempo_cnt + 1;
            beat_tick <= 0;
        end
    end

    // --- 3. THE SEQUENCER (The Conductor) ---
    logic [5:0] note_index = 0; // Song position
    logic [19:0] current_period;

    always_ff @(posedge clk) begin
        if (beat_tick) begin
            // Loop the song when it reaches index 31
            if (note_index == 31) note_index <= 0;
            else note_index <= note_index + 1;
        end
    end

    // --- 4. THE SHEET MUSIC (ROM) ---
    always_comb begin : Sheet_Music
        case (note_index)
            // THE VAMP (The Chromatic Tension)
            // Each line is 0.25s. Repeated notes make longer sounds.
            6'd0:  current_period = E4;
            6'd1:  current_period = E4;
            6'd2:  current_period = E4; // E for 0.75s
            6'd3:  current_period = E4; 
            
            6'd4:  current_period = F4;
            6'd5:  current_period = F4;
            6'd6:  current_period = F4; // F for 0.75s
            6'd7:  current_period = F4;

            6'd8:  current_period = Fs4;
            6'd9:  current_period = Fs4;
            6'd10: current_period = Fs4; // F# for 0.75s
            6'd11: current_period = Fs4;

            6'd12: current_period = F4;
            6'd13: current_period = F4;
            6'd14: current_period = F4; // Back to F
            6'd15: current_period = F4;

            // THE MELODY (Dum... Dum... Dum-Dum)
            6'd16: current_period = E4;  // E
            6'd17: current_period = E4;
            6'd18: current_period = E4;
            6'd19: current_period = REST; // Short pause
            
            6'd20: current_period = G4;   // G!
            6'd21: current_period = G4;
            6'd22: current_period = G4;
            6'd23: current_period = REST;
            
            6'd24: current_period = Ds4;  // D#!
            6'd25: current_period = Ds4;
            6'd26: current_period = Ds4;
            6'd27: current_period = REST;

            6'd28: current_period = D4;   // D...
            6'd29: current_period = D4;
            6'd30: current_period = D4;
            6'd31: current_period = REST;
            
            default: current_period = REST;
        endcase
    end
    
    // --- 5. INSTANTIATE INSTRUMENT ---
    Tone_Generator my_buzzer (
        .clk(clk),
        .tone_period(current_period),
        .buzzer_out(buzzer)
    );

    assign led = ~note_index[3:0];

endmodule