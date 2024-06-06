onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_encode/i_top_system/clk_i
add wave -noupdate /tb_encode/i_top_system/rst_ni
add wave -noupdate /tb_encode/i
add wave -noupdate /tb_encode/k
add wave -noupdate /tb_encode/i_top_system/in_ready
add wave -noupdate /tb_encode/i_top_system/in_valid
add wave -noupdate /tb_encode/i_top_system/item_memory_i/im_input
add wave -noupdate /tb_encode/i_top_system/item_memory_i/im_en
add wave -noupdate /tb_encode/i_top_system/item_memory_i/im_hv_out
add wave -noupdate /tb_encode/i_top_system/item_memory_i/im_man_out
add wave -noupdate /tb_encode/i_top_system/binding_i/im_hv_in
add wave -noupdate /tb_encode/i_top_system/binding_i/cim_hv_in
add wave -noupdate /tb_encode/i_top_system/binding_i/start_op
add wave -noupdate /tb_encode/i_top_system/binding_i/segment_mode
add wave -noupdate /tb_encode/i_top_system/binding_i/xor_binding_mode
add wave -noupdate /tb_encode/i_top_system/binding_i/shift_binding_mode
add wave -noupdate /tb_encode/i_top_system/binding_i/shift_amount
add wave -noupdate /tb_encode/i_top_system/binding_i/out_ready
add wave -noupdate /tb_encode/i_top_system/binding_i/xor_out
add wave -noupdate /tb_encode/i_top_system/binding_i/shift_counter
add wave -noupdate /tb_encode/i_top_system/binding_i/sh_out
add wave -noupdate -radix binary /tb_encode/i_top_system/bundling_i/hv_in
add wave -noupdate /tb_encode/i_top_system/bundling_i/start_op
add wave -noupdate /tb_encode/i_top_system/bundling_i/segment_mode
add wave -noupdate /tb_encode/i_top_system/bundling_i/or_mode
add wave -noupdate /tb_encode/i_top_system/bundling_i/acc1_en
add wave -noupdate /tb_encode/i_top_system/bundling_i/cdt_en
add wave -noupdate /tb_encode/i_top_system/bundling_i/acc2_en
add wave -noupdate /tb_encode/i_top_system/bundling_i/cdt_k_factor
add wave -noupdate /tb_encode/i_top_system/bundling_i/thr1_val
add wave -noupdate /tb_encode/i_top_system/bundling_i/thr2_val
add wave -noupdate /tb_encode/i_top_system/bundling_i/acc_reset
add wave -noupdate /tb_encode/i_top_system/bundling_i/window1_size
add wave -noupdate /tb_encode/i_top_system/bundling_i/hv_bundling_out
add wave -noupdate /tb_encode/i_top_system/bundling_i/out_ready
add wave -noupdate -radix unsigned /tb_encode/i_top_system/bundling_i/or_amount
add wave -noupdate -radix unsigned /tb_encode/i_top_system/bundling_i/or_counter
add wave -noupdate -radix binary /tb_encode/i_top_system/bundling_i/reg1_out
add wave -noupdate /tb_encode/i_top_system/bundling_i/cdt_out
add wave -noupdate -radix binary /tb_encode/i_top_system/hv_temp_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {760257 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 157
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {501100 ps} {1026258 ps}
