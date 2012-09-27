GHDL=ghdl
GHDLFLAGS=--mb-comments
WORK=work

SHA1_TEST_BENCH   = sha1_test_bench_w1_s4  \
                    sha1_test_bench_w1_s8  \
                    sha1_test_bench_w2_s8  \
                    sha1_test_bench_w4_s16 \
                    $(END_LIST)

SHA256_TEST_BENCH = sha256_test_bench_w1_s4  \
                    sha256_test_bench_w1_s8  \
                    sha256_test_bench_w2_s8  \
                    sha256_test_bench_w4_s16 \
                    $(END_LIST)

all: $(SHA1_TEST_BENCH) $(SHA256_TEST_BENCH)

clean:
	rm -f *.o *.cf $(TEST_BENCH)

sha1_test_bench_w1_s4     : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench_w1_s8     : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench_w2_s8     : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench_w4_s16    : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w1_s4   : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w1_s8   : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w2_s8   : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w4_s16  : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench.o         :  ../../src/test/vhdl/sha1_test_bench.vhd Dummy_Plug PipeWork
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha256_test_bench.o       :  ../../src/test/vhdl/sha256_test_bench.vhd Dummy_Plug PipeWork
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

DUT            : sha_pre_proc.o sha_schedule.o sha1_proc.o sha1.o sha256_proc.o sha256_k_table.o sha256.o

sha1.o         :  ../../src/main/vhdl/sha1.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha1_proc.o    :  ../../src/main/vhdl/sha1_proc.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha256.o       :  ../../src/main/vhdl/sha256.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha256_proc.o  :  ../../src/main/vhdl/sha256_proc.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha256_k_table.o:  ../../src/main/vhdl/sha256_k_table.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha_pre_proc.o :  ../../src/main/vhdl/sha_pre_proc.vhd PipeWork
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha_schedule.o :  ../../src/main/vhdl/sha_schedule.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

Dummy_Plug     : util.o

util.o         :  ../../Dummy_Plug/src/main/vhdl/core/util.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=Dummy_Plug $<

PipeWork       : reducer.o components.o

components.o   :  ../../PipeWork/src/main/vhdl/components/components.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

reducer.o      :  ../../PipeWork/src/main/vhdl/components/reducer.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<
