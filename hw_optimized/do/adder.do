onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_adder/i_adder/clk_i
add wave -noupdate /tb_adder/i_adder/rst_ni
add wave -noupdate -radix unsigned /tb_adder/i_adder/a_data_i
add wave -noupdate -radix unsigned /tb_adder/i_adder/b_data_i
add wave -noupdate -radix unsigned /tb_adder/i_adder/c_data_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {243 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ns} {552 ns}
