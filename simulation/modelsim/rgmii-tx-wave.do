onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_rgmii_tx/clk
add wave -noupdate /test_rgmii_tx/reset
add wave -noupdate /test_rgmii_tx/busy
add wave -noupdate /test_rgmii_tx/tx_data
add wave -noupdate /test_rgmii_tx/tx_data_h
add wave -noupdate /test_rgmii_tx/tx_data_l
add wave -noupdate /test_rgmii_tx/tx_ctl
add wave -noupdate /test_rgmii_tx/tx_ctl_h
add wave -noupdate /test_rgmii_tx/tx_ctl_l
add wave -noupdate /test_rgmii_tx/gtx_clk
add wave -noupdate /test_rgmii_tx/fifo_wr_full
add wave -noupdate /test_rgmii_tx/fifo_wr_req
add wave -noupdate /test_rgmii_tx/fifo_wr_data
add wave -noupdate -divider {RGMII TX Internals}
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/txn_ddr
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/state
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/count
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/nibble
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/current_data
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/saved_fifo
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/cur_buf_num
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/cur_buf_len
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/last_data_byte
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/crc_out
add wave -noupdate /test_rgmii_tx/crc_final
add wave -noupdate -divider {RAM/FIFO Reader}
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/rd_pos
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/ram_rd_ena
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/ram_rd_addr
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/ram_rd_data
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/fifo_rd_empty
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/fifo_rd_req
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/fifo_rd_data
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/first_read
add wave -noupdate /test_rgmii_tx/dut/rgmii_tx_inst/ram_read_sdr_sending
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {748447 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 145
configure wave -valuecolwidth 95
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
WaveRestoreZoom {0 ps} {990515 ps}
