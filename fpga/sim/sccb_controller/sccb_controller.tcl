transcript on

vlib work

vlog -sv -work work +incdir+../../rtl/ov5640       {../../rtl/ov5640/*.sv  }
vlog -sv -work work +incdir+../../tb/sccb_controller        {../../tb/sccb_controller/*.sv   }

vsim -t 1ps -L work -voptargs="+acc"  sccb_controller_tb

add wave *

log -r /*

view structure
view signals

run -all

