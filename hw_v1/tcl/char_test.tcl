vlog -f ../flist/accelerator.f
vsim -voptargs=+acc work.tb_encode
do ../do/char_test.do
run 500ns
