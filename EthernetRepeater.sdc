#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -name CLOCK_50  -period 20.000ns [get_ports CLOCK_50]
create_clock -name CLOCK2_50 -period 20.000ns [get_ports CLOCK2_50]
create_clock -name CLOCK3_50 -period 20.000ns [get_ports CLOCK3_50]

# Our input from the Ethernet 25MHz crystal
create_clock -name ENETCLK_25 -period 20.000ns [get_ports ENETCLK_25]

# This is our Ethernet Receive clock, which can vary between
# 2.5, 25 and 125 MHz, and comes in glitch-free from the PHY (in theory)
create_clock -name ENET1_RX_CLK_1000 -period   8.000ns [get_ports ENET1_RX_CLK]
create_clock -name ENET1_RX_CLK_100  -period  40.000ns [get_ports ENET1_RX_CLK] -add
create_clock -name ENET1_RX_CLK_10   -period 400.000ns [get_ports ENET1_RX_CLK] -add

# TODO: Figure out how to make DDR read timing work at 125MHz on ENET1_RX_DATA

# TODO: Figure out how to handle ENET1_GTX_CLK which has three speeds
# and will be fed from a clock multiplexer from a PLL

#**************************************************************
# Create Generated Clock
#**************************************************************

# pll_50_to_all_eth_single_input	pll_50_to_all_eth_single_input_inst (
# 	.inclk0 ( CLOCK_50 ),
# 	.c0 ( clk_eth_125 ), // 125 MHz
# 	.c1 ( clk_eth_25 ), // 25 MHz
# 	.c2 ( clk_eth_2p5 ), // 2.5 MHz

# https://www.intel.com/content/www/us/en/docs/programmable/683283/18-1/node-naming-conventions-in-integrated.html
# https://www.intel.com/content/www/us/en/docs/programmable/683283/18-1/hierarchical-node-naming-conventions.html
# View -> Utility -> Node Finder (Although this doesn't seem to find squat)
# I can't find, for example, clk_eth_125 in EthernetRepeater.sv, but I can find:
# |EthernetRepeater|pll_50_to_all_eth_single_input:pll_50_to_all_eth_single_input_inst|altpll:altpll_component|pll_50_to_all_eth_single_input_altpll:auto_generated|wire_pll1_clk[0]
# Or
# |EthernetRepeater|pll_50_to_all_eth_single_input:pll_50_to_all_eth_single_input_inst|c0	
# But not clk_eth_125, _25, _2p5 in EthernetRepeater.sv


# This is an Altera/Intel/Quartus specific command, not a
# standard SDC command.
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



