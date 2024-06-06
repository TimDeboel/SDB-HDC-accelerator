vlog -f ../flist/adder.f
vsim -voptargs=+acc work.tb_adder
do ../do/adder.do
run 500ns
