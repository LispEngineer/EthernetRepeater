onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label clk /test_tx_clock_manager/clk
add wave -noupdate -label reset /test_tx_clock_manager/reset
add wave -noupdate -label clk_125 /test_tx_clock_manager/clk_125
add wave -noupdate -label clk_25 /test_tx_clock_manager/clk_25
add wave -noupdate -label clk_2p5 /test_tx_clock_manager/clk_2p5
add wave -noupdate -label rx_speed_10 /test_tx_clock_manager/rx_speed_10
add wave -noupdate -label rx_speed_100 /test_tx_clock_manager/rx_speed_100
add wave -noupdate -label rx_speed_1000 /test_tx_clock_manager/rx_speed_1000
add wave -noupdate -label rx_link_up /test_tx_clock_manager/rx_link_up
add wave -noupdate -label tx_speed_10 /test_tx_clock_manager/tx_speed_10
add wave -noupdate -label tx_speed_100 /test_tx_clock_manager/tx_speed_100
add wave -noupdate -label tx_speed_1000 /test_tx_clock_manager/tx_speed_1000
add wave -noupdate -label clk_tx /test_tx_clock_manager/clk_tx
add wave -noupdate -label reset_tx /test_tx_clock_manager/reset_tx
add wave -noupdate -label tx_link_up /test_tx_clock_manager/tx_link_up
add wave -noupdate /test_tx_clock_manager/tx_changing
add wave -noupdate -divider {Manager Internals}
add wave -noupdate /test_tx_clock_manager/dut/valid_rx_speed_10
add wave -noupdate /test_tx_clock_manager/dut/final_rx_speed_10
add wave -noupdate /test_tx_clock_manager/dut/current_clk_tx_10
add wave -noupdate -divider 100
add wave -noupdate /test_tx_clock_manager/dut/valid_rx_speed_100
add wave -noupdate /test_tx_clock_manager/dut/final_rx_speed_100
add wave -noupdate /test_tx_clock_manager/dut/current_clk_tx_100
add wave -noupdate -divider 1000
add wave -noupdate /test_tx_clock_manager/dut/valid_rx_speed_1000
add wave -noupdate /test_tx_clock_manager/dut/final_rx_speed_1000
add wave -noupdate /test_tx_clock_manager/dut/current_clk_tx_1000
add wave -noupdate -divider Link
add wave -noupdate /test_tx_clock_manager/dut/valid_rx_link_up
add wave -noupdate /test_tx_clock_manager/dut/final_rx_link_up
add wave -noupdate /test_tx_clock_manager/dut/current_link_up
add wave -noupdate -divider <NULL>
add wave -noupdate /test_tx_clock_manager/dut/speed_is_one_hot
add wave -noupdate /test_tx_clock_manager/dut/entirely_valid
add wave -noupdate /test_tx_clock_manager/dut/change_detected
add wave -noupdate /test_tx_clock_manager/dut/state
add wave -noupdate /test_tx_clock_manager/dut/counter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4274176 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 161
configure wave -valuecolwidth 71
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ps} {33985545 ps}
