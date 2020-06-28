transcript on

vlib work

vlog -sv -work work +incdir+../../rtl/hdmi                {../../rtl/hdmi/*.sv  }
vlog -sv -work work +incdir+../../tb/dmt_timing_generate  {../../tb/dmt_timing_generate/*.sv   }

vsim -t 1ps -L work -voptargs="+acc"  dmt_timing_generate_tb

add wave *

log -r /*

view structure
view signals

run -all

