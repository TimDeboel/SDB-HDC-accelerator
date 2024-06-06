vlog -f ../flist/accelerator.f
vsim -voptargs=+acc work.tb_encode
do ../do/am.do
run 17000ns
