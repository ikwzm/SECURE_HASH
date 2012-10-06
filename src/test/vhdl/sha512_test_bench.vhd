-----------------------------------------------------------------------------------
--!     @file    sha512_test_bench.vhd
--!     @brief   SHA-512 TEST BENCH :
--!     @version 0.7.0
--!     @date    2012/10/6
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2012 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチのベースモデル.
-----------------------------------------------------------------------------------
entity  SHA512_TEST_BENCH is
    generic (
        SYMBOLS     : integer := 4;
        WORDS       : integer := 1;
        BLOCK_GAP   : integer := 1;
        VERBOSE     : integer := 1;
        AUTO_FINISH : integer := 1
    );
    port (
        FINISH      : out std_logic
    );
end SHA512_TEST_BENCH;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.UTIL.INTEGER_TO_STRING;
use     DUMMY_PLUG.UTIL.HEX_TO_STRING;
use     DUMMY_PLUG.UTIL.STRING_TO_STD_LOGIC_VECTOR;
library PipeWork;
use     PipeWork.SHA512.SHA512_CORE;
use     PipeWork.SHA512.HASH_BITS;
architecture MODEL of SHA512_TEST_BENCH is
    constant  SYMBOL_BITS   : integer := 8;
    constant  REVERSE       : integer := 1;
    signal    SCENARIO      : STRING(1 to 5);
    constant  PERIOD        : time    := 10 ns;
    constant  DELAY         : time    :=  2 ns;
    signal    CLK           : std_logic;
    signal    RST           : std_logic;
    signal    CLR           : std_logic;
    signal    I_DATA        : std_logic_vector(SYMBOL_BITS*SYMBOLS-1 downto 0);
    signal    I_ENA         : std_logic_vector(            SYMBOLS-1 downto 0);
    signal    I_DONE        : std_logic;
    signal    I_LAST        : std_logic;
    signal    I_VAL         : std_logic;
    signal    I_RDY         : std_logic;
    signal    O_DATA        : std_logic_vector(HASH_BITS-1 downto 0);
    signal    O_VAL         : std_logic;
    signal    O_RDY         : std_logic;
    subtype   SYMBOL_TYPE      is std_logic_vector(SYMBOL_BITS-1 downto 0);
    type      SYMBOL_VECTOR    is array (INTEGER range <>) of SYMBOL_TYPE;
    constant  SYMBOL_NULL      : SYMBOL_TYPE := (others => '0');
    constant  INTEGER_TO_CHAR  : STRING(1 to 16) := "0123456789ABCDEF";
    signal    TIME_COUNT_RESET : std_logic;
    signal    TIME_COUNTER     : integer;
    function  MESSAGE_TAG return STRING is
    begin
        return "(SYMBOL_BITS="  & INTEGER_TO_STRING(SYMBOL_BITS ) &
               ",SYMBOLS="      & INTEGER_TO_STRING(SYMBOLS     ) &
               ",WORDS="        & INTEGER_TO_STRING(WORDS       ) &
               ",BLOCK_GAP="    & INTEGER_TO_STRING(BLOCK_GAP   ) &
               "):";
    end function;
    function  STRING_TO_SYMBOL_VECTOR(STR:STRING) return SYMBOL_VECTOR is
        alias    arg : STRING(1 to STR'length) is STR;
        variable ret : SYMBOL_VECTOR(0 to STR'length-1);
    begin
        for i in ret'range loop
            ret(i) := std_logic_vector(to_unsigned(CHARACTER'POS(arg(i+1)),8));
        end loop;
        return ret;
    end function;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process begin
        CLK <= '1'; wait for PERIOD/2;
        CLK <= '0'; wait for PERIOD/2;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT: SHA512_CORE
        generic map (
            SYMBOL_BITS => SYMBOL_BITS ,
            SYMBOLS     => SYMBOLS     ,
            REVERSE     => REVERSE     ,
            WORDS       => WORDS       ,
            BLOCK_GAP   => BLOCK_GAP   
        )
        port map (
            CLK         => CLK         , -- In :
            RST         => RST         , -- In :
            CLR         => CLR         , -- In :
            I_DATA      => I_DATA      , -- In :
            I_ENA       => I_ENA       , -- In :
            I_DONE      => I_DONE      , -- In :
            I_LAST      => I_LAST      , -- In :
            I_VAL       => I_VAL       , -- In :
            I_RDY       => I_RDY       , -- Out:
            O_DATA      => O_DATA      , -- Out:
            O_VAL       => O_VAL       , -- Out:
            O_RDY       => O_RDY         -- In :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, TIME_COUNT_RESET) begin
        if (TIME_COUNT_RESET = '1') then
            TIME_COUNTER <= 0;
        elsif (CLK'event and CLK = '1') then
            TIME_COUNTER <= TIME_COUNTER + 1;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        procedure WAIT_CLK(CNT:integer) is
        begin
            if (CNT > 0) then
                for i in 1 to CNT loop 
                    wait until (CLK'event and CLK = '1'); 
                end loop;
            end if;
            wait for DELAY;
        end WAIT_CLK;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        type      CYCLE_VECTOR is array (INTEGER range <>) of INTEGER;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        procedure INPUT_SYMBOL(VEC:SYMBOL_VECTOR;WC:CYCLE_VECTOR;CNT,OFF:integer;LAST,DONE:boolean) is
            variable i_pos : integer;
            variable v_pos : integer;
            variable w_pos : integer;
            variable count : integer;
        begin
            I_VAL  <= '0'             after DELAY;
            I_LAST <= '0'             after DELAY;
            I_DONE <= '0'             after DELAY;
            I_ENA  <= (others => '0') after DELAY;
            I_DATA <= (others => '0') after DELAY;
            i_pos := OFF;
            v_pos := VEC'low;
            w_pos := WC'low;
            count := 0;
            assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO &
                " VEC'length=" & INTEGER_TO_STRING(VEC'length) &
                " CNT="        & INTEGER_TO_STRING(CNT)        &
                " OFF="        & INTEGER_TO_STRING(OFF)        severity NOTE;
            MAIN_LOOP: loop
            -- assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO &
            --     " VPOS="  & INTEGER_TO_STRING(v_pos) severity NOTE;
            -- assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO &
            --     " COUNT=" & INTEGER_TO_STRING(count) severity NOTE;
                if (WC(w_pos) > 0) then
                    for i in 1 to WC(w_pos) loop
                        wait until (CLK'event and CLK = '1');
                    end loop;
                end if;
                if (w_pos >= WC'high) then
                    w_pos := WC'low;
                else
                    w_pos := w_pos + 1;
                end if;
                for i in I_ENA'low to I_ENA'high loop
                    if (i >= i_pos and v_pos <= VEC'high) then
                        I_ENA(i) <= '1' after DELAY;
                        I_DATA(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i) <= VEC(v_pos)  after DELAY;
                        v_pos := v_pos + 1;
                    else
                        I_ENA(i) <= '0' after DELAY;
                        I_DATA(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i) <= SYMBOL_NULL after DELAY;
                    end if;
                end loop;
                i_pos := 0;
                I_VAL <= '1' after DELAY;
                if (v_pos > VEC'high) then
                    count := count + 1;
                    v_pos := VEC'low;
                    if (LAST and count >= CNT) then
                        I_LAST <= '1' after DELAY;
                    else
                        I_LAST <= '0' after DELAY;
                    end if;
                end if;
                wait until (CLK'event and CLK = '1' and I_RDY = '1');
                I_VAL  <= '0' after DELAY;
                I_LAST <= '0' after DELAY;
                exit when (count >= CNT);
            end loop;
            if (DONE) then
                wait until (CLK'event and CLK = '1' and I_RDY = '1');
                I_DONE <= '1' after DELAY;
                wait until (CLK'event and CLK = '1');
            end if;
            I_VAL  <= '0'             after DELAY;
            I_LAST <= '0'             after DELAY;
            I_DONE <= '0'             after DELAY;
            I_ENA  <= (others => '0') after DELAY;
            I_DATA <= (others => '0') after DELAY;
        end procedure;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        procedure RUN_TEST(MES:SYMBOL_VECTOR;WC:CYCLE_VECTOR;CNT,OFF:integer;LAST,DONE:boolean;EXP:std_logic_vector) is
            variable  run_time   : integer;
        begin 
            TIME_COUNT_RESET <= '1', '0' after 1 ns;
            assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " Start" severity NOTE;
            O_RDY <= '1';
            INPUT_SYMBOL(MES, WC, CNT, OFF, LAST, DONE);
            assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " Wait"  severity NOTE;
            wait until (CLK'event and CLK = '1' and O_VAL = '1');
            O_RDY <= '0';
            assert (O_DATA = EXP)
                report MESSAGE_TAG & "Mismatch " & SCENARIO &
                       " O_DATA="   & HEX_TO_STRING(O_DATA) &
                       ",EXP_DATA=" & HEX_TO_STRING(EXP) severity Error;
            run_time := TIME_COUNTER;
            assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " Done" &
                "(RunClock=" & INTEGER_TO_STRING(run_time) & ")" severity NOTE;
        end procedure;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        procedure RUN_TEST_OFFSET(CNT:integer;MES,EXP:STRING) is
            variable  message    : SYMBOL_VECTOR(0 to MES'length-1);
            variable  exp_digest : std_logic_vector(HASH_BITS-1 downto 0);
            variable  str_len    : integer;
            variable  run_time   : integer;
            variable  wait_cycle : CYCLE_VECTOR(0 to 15) := (others => 0);
        begin
            message := STRING_TO_SYMBOL_VECTOR(MES);
            STRING_TO_STD_LOGIC_VECTOR(
                STR     => EXP, 
                VAL     => exp_digest,
                STR_LEN => str_len
            );
            SCENARIO(3) <= INTEGER_TO_CHAR(2);
            for offset in 0 to SYMBOLS-1 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(offset+1);
                wait for 0 ns;
                RUN_TEST(message, wait_cycle, CNT, offset, TRUE, FALSE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(3);
            for offset in 0 to SYMBOLS-1 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(offset+1);
                wait for 0 ns;
                RUN_TEST(message, wait_cycle, CNT, offset, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(4);
        end procedure;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        procedure RUN_TEST_TIMING(CNT:integer;MES,EXP:STRING) is
            variable  message    : SYMBOL_VECTOR(0 to MES'length-1);
            variable  exp_digest : std_logic_vector(HASH_BITS-1 downto 0);
            variable  str_len    : integer;
            variable  run_time   : integer;
            variable  wait_cycle : CYCLE_VECTOR(0 to 15) := (others => 0);
        begin
            message := STRING_TO_SYMBOL_VECTOR(MES);
            STRING_TO_STD_LOGIC_VECTOR(
                STR     => EXP, 
                VAL     => exp_digest,
                STR_LEN => str_len
            );
            SCENARIO(3) <= INTEGER_TO_CHAR(2);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (0 => 0, others => wc);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(3);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (2 => wc, others => 0);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(4);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (3 => wc, others => 0);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(5);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (4 => wc, others => 0);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(6);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (0 => 20, others => wc);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(7);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (0 => 20, 2 => wc, others => 0);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(8);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (0 => 20, 3 => wc, others => 0);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(9);
            for wc in 1 to 4 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(wc);
                wait for 0 ns;
                wait_cycle := (0 => 20, 4 => wc, others => 0);
                RUN_TEST(message, wait_cycle, CNT, 0, FALSE, TRUE, exp_digest);
            end loop;
        end procedure;
    begin
        ---------------------------------------------------------------------------
        -- シミュレーションの開始、まずはリセットから。
        ---------------------------------------------------------------------------
        assert(false) report MESSAGE_TAG & "Starting Run..." severity NOTE;
                       SCENARIO <= "START";
                       RST      <= '1';
                       CLR      <= '1';
                       I_VAL    <= '0';
                       I_LAST   <= '0';
                       I_DONE   <= '0';
                       I_DATA   <= (others => '0');
                       I_ENA    <= (others => '0');
                       O_RDY    <= '0';
        WAIT_CLK( 4);  RST      <= '0';
                       CLR      <= '0';
        WAIT_CLK( 4);
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        SCENARIO <= "1.0.0";
        wait for 0 ns;
        RUN_TEST_OFFSET(
            1,
            string'("abc"),
            string'("0xddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f")
        );
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        SCENARIO <= "2.0.0";
        wait for 0 ns;
        RUN_TEST_OFFSET(
            1,
            string'("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"),
            string'("0x8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909")
        );
        ---------------------------------------------------------------------------
        -- ちょっとシミュレーションでは時間がかかりすぎるので現在は削除
        ---------------------------------------------------------------------------
        -- SCENARIO <= "3.0.0";
        -- wait for 0 ns;
        -- assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " Start" severity NOTE;
        -- RUN_TEST_ALL(1000000,
        --              string'("a"),
        --              string'("0x34AA973CD4C4DAA4F61EEB2BDBAD27316534016F"));
        -- assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " Done." severity NOTE;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        SCENARIO <= "4.0.0";
        wait for 0 ns;
        RUN_TEST_TIMING(
            10,
            string'("0123456701234567012345670123456701234567012345670123456701234567"),
            string'("0x89d05ba632c699c31231ded4ffc127d5a894dad412c0e024db872d1abd2ba8141a0f85072a9be1e2aa04cf33c765cb510813a39cd5a84c4acaa64d3f3fb7bae9")
        );
        ---------------------------------------------------------------------------
        -- シミュレーション終了
        ---------------------------------------------------------------------------
        WAIT_CLK(10); 
        SCENARIO <= "DONE.";
        WAIT_CLK(10); 
        if (AUTO_FINISH = 0) then
            assert(false) report MESSAGE_TAG & " Run complete..." severity NOTE;
            FINISH <= 'Z';
        else
            FINISH <= 'Z';
            assert(false) report MESSAGE_TAG & " Run complete..." severity FAILURE;
        end if;
        wait;
    end process;
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=1,SYMBOLS=4,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W1_S4_G0 is
end     SHA512_TEST_BENCH_W1_S4_G0;
architecture MODEL of SHA512_TEST_BENCH_W1_S4_G0 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 4,
           WORDS        => 1,
           BLOCK_GAP    => 0,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=1,SYMBOLS=4,BLOCK_GAP=1)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W1_S4_G1 is
end     SHA512_TEST_BENCH_W1_S4_G1;
architecture MODEL of SHA512_TEST_BENCH_W1_S4_G1 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 4,
           WORDS        => 1,
           BLOCK_GAP    => 1,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W1_S8_G0 is
end     SHA512_TEST_BENCH_W1_S8_G0;
architecture MODEL of SHA512_TEST_BENCH_W1_S8_G0 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 8,
           WORDS        => 1,
           BLOCK_GAP    => 0,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=1)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W1_S8_G1 is
end     SHA512_TEST_BENCH_W1_S8_G1;
architecture MODEL of SHA512_TEST_BENCH_W1_S8_G1 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 8,
           WORDS        => 1,
           BLOCK_GAP    => 1,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=4)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W1_S8_G4 is
end     SHA512_TEST_BENCH_W1_S8_G4;
architecture MODEL of SHA512_TEST_BENCH_W1_S8_G4 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 8,
           WORDS        => 1,
           BLOCK_GAP    => 4,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=2,SYMBOLS=8,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W2_S8_G0 is
end     SHA512_TEST_BENCH_W2_S8_G0;
architecture MODEL of SHA512_TEST_BENCH_W2_S8_G0 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 8,
           WORDS        => 2,
           BLOCK_GAP    => 0,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=4,SYMBOLS=16,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W4_S16_G0 is
end     SHA512_TEST_BENCH_W4_S16_G0;
architecture MODEL of SHA512_TEST_BENCH_W4_S16_G0 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 16,
           WORDS        => 4,
           BLOCK_GAP    => 0,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-512テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_TEST_BENCH_W1_S8_G0 is
end     SHA512_TEST_BENCH_W1_S8_G0;
architecture MODEL of SHA512_TEST_BENCH_W1_S8_G0 is
    component  SHA512_TEST_BENCH
        generic (
            SYMBOLS     : integer;
            WORDS       : integer;
            BLOCK_GAP   : integer;
            VERBOSE     : integer;
            AUTO_FINISH : integer
        );
        port (
            FINISH      : out std_logic
        );
    end component;
begin
    TB: SHA512_TEST_BENCH generic map(
           SYMBOLS      => 8,
           WORDS        => 1,
           BLOCK_GAP    => 0,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
