sourceQuesta = source /esat/micas-data/data/design/scripts/questasim_2022.4.rc


no_target:
	echo "give a usefull target"

#removes output to start over clean
clean:
	rm -rf csrc/* linter/* log/* out/* work/* vc_hdrs.h transcript covhtmlreport/ cov_report vish_stacktrace.vstf vsim.wlf

clean_linter:
	rm -rf linter/out/* linter/log/* vc_hdrs.h linter/csrc/*

cl: clean_linter

#just a shorthand
all: compile run
ag: compile_gui run_gui

###########
# compile #
###########
#Compiles the source into an executable simulator (out/simv)
# -sv17compat
# Used in conjunction with the -sv switch to ensure compatibility with the reserved keyword set of IEEE Std1800-2017
# -vopt provides global optimization
# -mfcu to treat multiple compilation files as one compilation unit


compile:
	$(sourceQuesta);\
	vlog -sv17compat -lint -override_timescale=1ns/1ps  -vopt -64 -mfcu -f ../flist/accelerator.f


#######
# run #
#######
#runs the compiled simulator
run:
	$(sourceQuesta);\
	vsim
	#vsim -c WORK.tbench_top -do "run -all" 



