module Thermometer_Top (
    input  logic clk,
    output logic i2c_scl,
    inout  wire i2c_sda,
    output logic led_1,
    output logic led_4,
    output logic [7:0] seg,
    output logic [3:0] dig
);

    logic [7:0] temperature;
    assign led_4 = 0;

    LM75A_I2C t_sensor (
        .clk(clk),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda),
        .sensor_found(led_1),
        .temp_data(temperature)
    );

    // Display the hex value of temperature
    Display_Driver disp (
        .clk(clk),
        .in0(temperature[3:0]),
        .in1(temperature[7:4]),
        .in2(4'd0), .in3(4'd0),
        .dig_sel(dig), .seg_out(seg)
    );

endmodule