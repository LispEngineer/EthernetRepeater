onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_mii_management_interface/clk
add wave -noupdate /test_mii_management_interface/reset
add wave -noupdate /test_mii_management_interface/mdc
add wave -noupdate /test_mii_management_interface/mdio_i
add wave -noupdate /test_mii_management_interface/mdio_o
add wave -noupdate /test_mii_management_interface/mdio_e
add wave -noupdate /test_mii_management_interface/mii_busy
add wave -noupdate /test_mii_management_interface/mii_success
add wave -noupdate /test_mii_management_interface/mii_activate
add wave -noupdate /test_mii_management_interface/mii_read
add wave -noupdate /test_mii_management_interface/mii_phy_address
add wave -noupdate /test_mii_management_interface/mii_register
add wave -noupdate /test_mii_management_interface/mii_data_in
add wave -noupdate /test_mii_management_interface/mii_data_out
add wave -noupdate -divider DUT
add wave -noupdate /test_mii_management_interface/dut/state
add wave -noupdate /test_mii_management_interface/dut/mdc_step
add wave -noupdate /test_mii_management_interface/dut/state_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {670000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 297
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
WaveRestoreZoom {0 ps} {11310690 ps}
