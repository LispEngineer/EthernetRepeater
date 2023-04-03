onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label clk /test_lcd_module/clk
add wave -noupdate -label reset /test_lcd_module/reset
add wave -noupdate -divider {LCD PHY}
add wave -noupdate -label {lcd_en ("clk")} /test_lcd_module/lcd_en
add wave -noupdate -label lcd_rs /test_lcd_module/lcd_rs
add wave -noupdate -label lcd_rw /test_lcd_module/lcd_rw
add wave -noupdate -label lcd_data_o /test_lcd_module/lcd_data_o
add wave -noupdate -label lcd_data_i /test_lcd_module/lcd_data_i
add wave -noupdate -label {lcd_data OUTPUT ENABLE} /test_lcd_module/lcd_data_e
add wave -noupdate -divider {LCD Module Internals}
add wave -noupdate /test_lcd_module/dut/state
add wave -noupdate /test_lcd_module/dut/count
add wave -noupdate /test_lcd_module/dut/post_delay_state
add wave -noupdate /test_lcd_module/dut/r_is_data
add wave -noupdate /test_lcd_module/dut/r_data_inst
add wave -noupdate /test_lcd_module/dut/r_delay
add wave -noupdate -divider {LCD Module Inputs}
add wave -noupdate /test_lcd_module/activate
add wave -noupdate /test_lcd_module/busy
add wave -noupdate /test_lcd_module/is_data
add wave -noupdate /test_lcd_module/data_inst
add wave -noupdate /test_lcd_module/delay
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1090000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 208
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {3475712 ps}
