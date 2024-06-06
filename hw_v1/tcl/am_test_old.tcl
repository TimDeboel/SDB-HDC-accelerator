vlog -f ../flist/accelerator.f
vsim -voptargs=+acc work.tb_encode
do ../do/encode.do
run 17000ns
