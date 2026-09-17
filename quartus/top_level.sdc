create_clock -period 20 -name CLOCK CLOCK
create_clock -name CLOCK_50 -period 20 [get_ports {CLOCK_50}]
