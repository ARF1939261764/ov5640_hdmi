transcript on

vlib work

vlog -sv -work work +incdir+../../rtl/sdram       {../../rtl/bus/avl_bus_type.sv  }
vlog -sv -work work +incdir+../../rtl/sdram       {../../rtl/sdram/*.sv  }
vlog -sv -work work +incdir+../../rtl/sdram       {../../rtl/bus/*.sv  }
vlog -sv -work work +incdir+../../rtl/sdram       {../../rtl/fifo/*.sv  }
vlog -sv -work work +incdir+../../tb/sdram        {../../tb/sdram/*.sv   }
vlog -sv -work work +incdir+../../tb/sdram        {../../tb/common/*.sv   }
vlog -sv -work work +incdir+../../tb/sdram        {../../tb/common/*.v   }

vsim -t 1ps -L work -voptargs="+acc"  sdram_controller_tb

add wave *

log -r /*

view structure
view signals

run -all

