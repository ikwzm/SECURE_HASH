GHDL=ghdl
GHDLFLAGS=--mb-comments
WORK=work
TOP=../../..

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
                    sha512_test_bench_w1_s8_g4  \
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

sha512_test_bench_w1_s8_g4  : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w2_s8_g0  : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha512_test_bench_w4_s16_g0 : sha512_test_bench.o DUT
	 $(GHDL) -e $(GHDLFLAGS) $@
	-$(GHDL) -r $(GHDLRUNFLAGS) $@

sha1_test_bench.o         :  $(TOP)/src/test/vhdl/sha1_test_bench.vhd   Dummy_Plug DUT
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha256_test_bench.o       :  $(TOP)/src/test/vhdl/sha256_test_bench.vhd Dummy_Plug DUT
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

sha512_test_bench.o       :  $(TOP)/src/test/vhdl/sha512_test_bench.vhd Dummy_Plug DUT 
	$(GHDL) -a $(GHDLFLAGS) --work=work $<

DUT            : sha_pre_proc.o sha_schedule.o reducer.o \
                 sha1.o   sha1_core.o   sha1_proc.o      \
                 sha256.o sha256_core.o sha256_k_table.o sha256_proc_simple.o sha256_proc_pipeline.o \
                 sha512.o sha512_core.o sha512_k_table.o sha512_proc_simple.o sha512_proc_pipeline.o \
                 $(END_LIST)

sha1.o                  :  $(TOP)/src/main/vhdl/sha1.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha1_core.o             :  $(TOP)/src/main/vhdl/sha1_core.vhd            sha1.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha1_proc.o             :  $(TOP)/src/main/vhdl/sha1_proc.vhd            sha1.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha256.o                :  $(TOP)/src/main/vhdl/sha256.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha256_core.o           :  $(TOP)/src/main/vhdl/sha256_core.vhd          sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha256_proc_simple.o    :  $(TOP)/src/main/vhdl/sha256_proc_simple.vhd   sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha256_proc_pipeline.o  :  $(TOP)/src/main/vhdl/sha256_proc_pipeline.vhd sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha256_k_table.o        :  $(TOP)/src/main/vhdl/sha256_k_table.vhd       sha256.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha512.o                :  $(TOP)/src/main/vhdl/sha512.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha512_core.o           :  $(TOP)/src/main/vhdl/sha512_core.vhd          sha512.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha512_proc_simple.o    :  $(TOP)/src/main/vhdl/sha512_proc_simple.vhd   sha512.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha512_proc_pipeline.o  :  $(TOP)/src/main/vhdl/sha512_proc_pipeline.vhd sha512.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha512_k_table.o        :  $(TOP)/src/main/vhdl/sha512_k_table.vhd       sha512.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha_pre_proc.o          :  $(TOP)/src/main/vhdl/sha_pre_proc.vhd         reducer.o
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

sha_schedule.o          :  $(TOP)/src/main/vhdl/sha_schedule.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

reducer.o               :  $(TOP)/src/main/vhdl/reducer.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=IKWZM_SECURE_HASH $<

Dummy_Plug     : util.o

util.o         :  $(TOP)/Dummy_Plug/src/main/vhdl/core/util.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=Dummy_Plug $<

