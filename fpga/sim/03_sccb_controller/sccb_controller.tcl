transcript on

vlib work

vlog -sv -work work +incdir+../../01_rtl/03_sccb_controller       {../../01_rtl/03_sccb_controller/*.sv  }
vlog -sv -work work +incdir+../../02_tb/03_sccb_controller        {../../02_tb/03_sccb_controller/*.sv   }

vsim -t 1ps -L work -voptargs="+acc"  sccb_controller_tb

add wave *

log -r /*

view structure
view signals

run -all

