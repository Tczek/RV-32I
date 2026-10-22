# Definicja głównego zegara
create_clock -name clk -period 16.000 [get_ports {clk}]

# Parametry zegara
set_clock_uncertainty 0.250 [get_clocks {clk}]
set_clock_transition 0.150 [get_clocks {clk}]

# Reset jest asynchroniczny i nie powinien być analizowany jako ścieżka synchroniczna.
set_false_path -from [get_ports {rst}]

# Pobranie portów wejściowych z wykluczeniem zegara
set all_inputs_no_clk [get_ports * -filter {direction == in && name != "clk"}]

# Ograniczenia opóźnień
set_input_delay -clock clk -max 3.000 $all_inputs_no_clk
set_input_delay -clock clk -min 0.500 $all_inputs_no_clk

set_output_delay -clock clk -max 3.000 [all_outputs]
set_output_delay -clock clk -min 0.500 [all_outputs]

# Modelowanie komórek wejścia i wyjścia
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $all_inputs_no_clk
set_load -pin_load 0.035 [all_outputs]

# Ograniczenia globalne
set_max_fanout 12 [current_design]
set_max_transition 0.750 [current_design]
