onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_memcopy/clk
add wave -noupdate /test_memcopy/reset
add wave -noupdate -divider {Source RAM}
add wave -noupdate /test_memcopy/src_rd_en
add wave -noupdate /test_memcopy/src_rd_addr
add wave -noupdate /test_memcopy/src_rd_data
add wave -noupdate -divider {Destination RAM}
add wave -noupdate /test_memcopy/dst_wr_en
add wave -noupdate /test_memcopy/dst_wr_addr
add wave -noupdate /test_memcopy/dst_wr_data
add wave -noupdate -divider {DUT Inputs}
add wave -noupdate /test_memcopy/busy
add wave -noupdate /test_memcopy/activate
add wave -noupdate /test_memcopy/dst_addr
add wave -noupdate /test_memcopy/src_addr
add wave -noupdate /test_memcopy/src_len
add wave -noupdate -divider {DUT memcopy}
add wave -noupdate /test_memcopy/dut/s_dst_addr
add wave -noupdate /test_memcopy/dut/s_src_addr
add wave -noupdate /test_memcopy/dut/s_src_len
add wave -noupdate /test_memcopy/dut/state
add wave -noupdate /test_memcopy/dut/copying_delay
add wave -noupdate -divider {memcopy reader}
add wave -noupdate /test_memcopy/dut/write_ready
add wave -noupdate /test_memcopy/dut/reader_was_idle
add wave -noupdate /test_memcopy/dut/read_delay
add wave -noupdate /test_memcopy/dut/cur_src_addr
add wave -noupdate -divider {memcopy writer}
add wave -noupdate /test_memcopy/dut/copying_done
add wave -noupdate /test_memcopy/dut/writer_was_idle
add wave -noupdate /test_memcopy/dut/cur_dst_addr
add wave -noupdate /test_memcopy/dut/last_dst_addr
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {15117 ps} {375740 ps}
