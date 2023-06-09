onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label {main clk} /test_rgmii_rx/clk
add wave -noupdate -label reset /test_rgmii_rx/reset
add wave -noupdate -divider {Memory Write}
add wave -noupdate -label ram_wr_ena /test_rgmii_rx/dut/rgmii_rx_impl_inst/ram_wr_ena
add wave -noupdate -label ram_wr_addr /test_rgmii_rx/dut/rgmii_rx_impl_inst/ram_wr_addr
add wave -noupdate -label ram_wr_data /test_rgmii_rx/dut/rgmii_rx_impl_inst/ram_wr_data
add wave -noupdate -divider {RX Internals}
add wave -noupdate -label state /test_rgmii_rx/dut/rgmii_rx_impl_inst/state
add wave -noupdate -label cur_buf /test_rgmii_rx/dut/rgmii_rx_impl_inst/cur_buf
add wave -noupdate -label byte_pos -radix decimal /test_rgmii_rx/dut/rgmii_rx_impl_inst/byte_pos
add wave -noupdate -label local_count -radix decimal /test_rgmii_rx/dut/rgmii_rx_impl_inst/local_count
add wave -noupdate -label ram_pos /test_rgmii_rx/dut/rgmii_rx_impl_inst/ram_pos
add wave -noupdate -divider FIFO
add wave -noupdate -label empty /test_rgmii_rx/dut/fifo_rd_empty
add wave -noupdate -label full /test_rgmii_rx/dut/fifo_wr_full
add wave -noupdate -label dropped -radix decimal /test_rgmii_rx/dut/rgmii_rx_impl_inst/dropped_packets
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {38621709 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 103
configure wave -valuecolwidth 67
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
WaveRestoreZoom {0 ps} {43575195 ps}
