onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_rgmii_tx/clk
add wave -noupdate /test_rgmii_tx/reset
add wave -noupdate /test_rgmii_tx/activate
add wave -noupdate /test_rgmii_tx/busy
add wave -noupdate /test_rgmii_tx/tx_data
add wave -noupdate /test_rgmii_tx/tx_data_h
add wave -noupdate /test_rgmii_tx/tx_data_l
add wave -noupdate /test_rgmii_tx/tx_ctl
add wave -noupdate /test_rgmii_tx/tx_ctl_h
add wave -noupdate /test_rgmii_tx/tx_ctl_l
add wave -noupdate /test_rgmii_tx/gtx_clk
add wave -noupdate -divider {RGMII TX Internals}
add wave -noupdate /test_rgmii_tx/dut/state
add wave -noupdate /test_rgmii_tx/dut/nibble
add wave -noupdate /test_rgmii_tx/dut/count
add wave -noupdate /test_rgmii_tx/dut/tx_en
add wave -noupdate /test_rgmii_tx/dut/tx_err
add wave -noupdate /test_rgmii_tx/dut/txn_ddr
add wave -noupdate /test_rgmii_tx/dut/syncd_activate
add wave -noupdate /test_rgmii_tx/dut/syncd_ddr_tx
add wave -noupdate /test_rgmii_tx/dut/real_activate
add wave -noupdate /test_rgmii_tx/dut/real_ddr_tx
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6998765 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 236
configure wave -valuecolwidth 51
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
WaveRestoreZoom {0 ps} {13201732 ps}
