GHDL=ghdl
GHDLFLAGS=--mb-comments
WORK=work

SHA1_TEST_BENCH   = sha1_test_bench_w1_s4_g0    \
                    sha1_test_bench_w1_s4_g1    \
                    sha1_test_bench_w1_s8_g0    \
                    sha1_test_bench_w2_s8_g0    \
                    sha1_test_bench_w4_s16_g0   \
                    $(END_LIST)

SHA256_TEST_BENCH = sha256_test_bench_w1_s4_g0  \
                    sha256_test_bench_w1_s4_g1  \
                    sha256_test_bench_w1_s4_g4  \
                    sha256_test_bench_w1_s8_g0  \
                    sha256_test_bench_w2_s8_g0  \
                    sha256_test_bench_w4_s16_g0 \
                    $(END_LIST)

SHA512_TEST_BENCH = sha512_test_bench_w1_s4_g0  \
                    sha512_test_bench_w1_s4_g1  \
                    sha512_test_bench_w1_s8_g0  \
                    sha512_test_bench_w1_s8_g1  \
                    sha512_test_bench_w2_s8_g0  \
                    sha512_test_bench_w4_s16_g0 \
                    $(END_LIST)

all    : $(SHA1_TEST_BENCH) $(SHA256_TEST_BENCH) $(SHA512_TEST_BENCH)

sha1_test   : $(SHA1_TEST_BENCH)

sha256_test : $(SHA256_TEST_BENCH)

sha512_test : $(SHA512_TEST_BENCH)

clean:
	rm -f *.o *.cf $(SHA1_TEST_BENCH) $(SHA256_TEST_BENCH) $(SHA512_TEST_BENCH)

sha1_test_bench_w1_s4_g0    : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench_w1_s4_g1    : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench_w1_s8_g0    : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench_w2_s8_g0    : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench_w4_s16_g0   : sha1_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w1_s4_g0  : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w1_s4_g1  : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w1_s4_g4  : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w1_s8_g0  : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w2_s8_g0  : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha256_test_bench_w4_s16_g0 : sha256_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w1_s4_g0  : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w1_s4_g1  : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w1_s8_g0  : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w1_s8_g1  : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w2_s8_g0  : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w4_s16_g0 : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench.o         :  ../../src/test/vhdl/sha1_test_bench.vhd   Dummy_Plug PipeWork DUT
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha256_test_bench.o       :  ../../src/test/vhdl/sha256_test_bench.vhd Dummy_Plug PipeWork DUT
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha512_test_bench.o       :  ../../src/test/vhdl/sha512_test_bench.vhd Dummy_Plug PipeWork DUT 
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

DUT            : sha_pre_proc.o sha_schedule.o sha1_proc.o sha1.o \
                 sha256.o sha256_core.o sha256_k_table.o sha256_proc_simple.o sha256_proc_pipeline.o \
                 sha512_k_table.o sha512_proc.o sha512.o \
                 $(END_LIST)

sha1.o         :  ../../src/main/vhdl/sha1.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha1_proc.o    :  ../../src/main/vhdl/sha1_proc.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha256.o                :  ../../src/main/vhdl/sha256.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha256_core.o           :  ../../src/main/vhdl/sha256_core.vhd          sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha256_proc_simple.o    :  ../../src/main/vhdl/sha256_proc_simple.vhd   sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha256_proc_pipeline.o  :  ../../src/main/vhdl/sha256_proc_pipeline.vhd sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha256_k_table.o:  ../../src/main/vhdl/sha256_k_table.vhd               sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha512.o       :  ../../src/main/vhdl/sha512.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha512_proc.o  :  ../../src/main/vhdl/sha512_proc.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha512_k_table.o:  ../../src/main/vhdl/sha512_k_table.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha_pre_proc.o :  ../../src/main/vhdl/sha_pre_proc.vhd PipeWork
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

sha_schedule.o :  ../../src/main/vhdl/sha_schedule.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

Dummy_Plug     : util.o

util.o         :  ../../Dummy_Plug/src/main/vhdl/core/util.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=Dummy_Plug $<

PipeWork       : reducer.o components.o

components.o   :  ../../PipeWork/src/main/vhdl/components/components.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<

reducer.o      :  ../../PipeWork/src/main/vhdl/components/reducer.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=PipeWork $<
