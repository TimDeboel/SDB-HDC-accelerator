vlog -f ../flist/accelerator.f
vsim -voptargs=+acc work.tb_synthesis
do ../do/syn.do
run 17000ns
