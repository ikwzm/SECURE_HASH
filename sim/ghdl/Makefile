GHDL=ghdl
GHDLFLAGS=--mb-comments
WORK=work

TEST_BENCH = test_bench_1 \
             $(END_LIST)

all: $(TEST_BENCH)

clean:
	rm -f *.o *.cf $(TEST_BENCH)

test_bench_1: test_bench_1.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

test_bench_1.o   :  ../../src/test/vhdl/test_bench_1.vhd Dummy_Plug PipeWork
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

DUT            : sha1_proc.o sha_pre_proc.o sha1_proc.o sha1_schedule.o sha1_calc.o sha1.o

sha1.o         :  ../../src/main/vhdl/sha1.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha_pre_proc.o :  ../../src/main/vhdl/sha_pre_proc.vhd PipeWork
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha1_proc.o    :  ../../src/main/vhdl/sha1_proc.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha1_schedule.o:  ../../src/main/vhdl/sha1_schedule.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha1_calc.o    :  ../../src/main/vhdl/sha1_calc.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

Dummy_Plug     : util.o

util.o         :  ../../Dummy_Plug/src/main/vhdl/core/util.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=Dummy_Plug $<

PipeWork       : reducer.o components.o

components.o   :  ../../PipeWork/src/main/vhdl/components/components.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

reducer.o      :  ../../PipeWork/src/main/vhdl/components/reducer.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<
