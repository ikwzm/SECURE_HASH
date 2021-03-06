-----------------------------------------------------------------------------------
--!     @file    sha1_test_bench.vhd
--!     @brief   SHA-1 TEST BENCH :
--!     @version 0.9.0
--!     @date    2012/11/20
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
--! @brief   SHA-1テストベンチのベースモデル.
-----------------------------------------------------------------------------------
entity  SHA1_TEST_BENCH is
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
end SHA1_TEST_BENCH;
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
library IKWZM_SECURE_HASH;
use     IKWZM_SECURE_HASH.SHA1.SHA1_CORE;
use     IKWZM_SECURE_HASH.SHA1.HASH_BITS;
architecture MODEL of SHA1_TEST_BENCH is
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
    DUT: SHA1_CORE
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
        procedure INPUT_SYMBOL(VEC:SYMBOL_VECTOR;CNT,OFF:integer;LAST,DONE:boolean) is
            variable i_pos : integer;
            variable v_pos : integer;
            variable count : integer;
        begin
            I_VAL  <= '0'             after DELAY;
            I_LAST <= '0'             after DELAY;
            I_DONE <= '0'             after DELAY;
            I_ENA  <= (others => '0') after DELAY;
            I_DATA <= (others => '0') after DELAY;
            i_pos := OFF;
            v_pos := VEC'low;
            count := 0;
            assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO &
                " VEC'length=" & INTEGER_TO_STRING(VEC'length) &
                " CNT="        & INTEGER_TO_STRING(CNT)        &
                " OFF="        & INTEGER_TO_STRING(OFF)        severity NOTE;
            MAIN_LOOP: loop
             -- assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " VPOS="  & INTEGER_TO_STRING(v_pos) severity NOTE;
             -- assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " COUNT=" & INTEGER_TO_STRING(count) severity NOTE;
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
        procedure RUN_TEST(MES:SYMBOL_VECTOR;CNT,OFF:integer;LAST,DONE:boolean;EXP:std_logic_vector) is
            variable  run_time   : integer;
        begin
            TIME_COUNT_RESET <= '1', '0' after 1 ns;
            assert(VERBOSE=0) report MESSAGE_TAG & " " & SCENARIO & " Start" severity NOTE;
            O_RDY <= '1';
            INPUT_SYMBOL(MES, CNT, OFF, LAST, DONE);
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
        procedure RUN_TEST_ONE(MES,EXP:STRING) is
            variable  message    : SYMBOL_VECTOR(0 to MES'length-1);
            variable  exp_digest : std_logic_vector(HASH_BITS-1 downto 0);
            variable  str_len    : integer;
            variable  run_time   : integer;
        begin
            message := STRING_TO_SYMBOL_VECTOR(MES);
            STRING_TO_STD_LOGIC_VECTOR(
                STR     => EXP, 
                VAL     => exp_digest,
                STR_LEN => str_len
            );
            RUN_TEST(message, 1, 0, TRUE, FALSE, exp_digest);
        end procedure;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        procedure RUN_TEST_ALL(CNT:integer;MES,EXP:STRING) is
            variable  message    : SYMBOL_VECTOR(0 to MES'length-1);
            variable  exp_digest : std_logic_vector(HASH_BITS-1 downto 0);
            variable  str_len    : integer;
            variable  run_time   : integer;
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
                RUN_TEST(message, CNT, offset, TRUE, FALSE, exp_digest);
            end loop;
            SCENARIO(3) <= INTEGER_TO_CHAR(3);
            for offset in 0 to SYMBOLS-1 loop
                SCENARIO(5) <= INTEGER_TO_CHAR(offset+1);
                wait for 0 ns;
                RUN_TEST(message, CNT, offset, FALSE, TRUE, exp_digest);
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
        RUN_TEST_ALL(1,
                     string'("abc"),
                     string'("0xA9993E364706816ABA3E25717850C26C9CD0D89D"));
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        SCENARIO <= "2.0.0";
        wait for 0 ns;
        RUN_TEST_ALL(1,
                     string'("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
                     string'("0x84983E441C3BD26EBAAE4AA1F95129E5E54670F1"));
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
        RUN_TEST_ALL(10,
                     string'("0123456701234567012345670123456701234567012345670123456701234567"),
                     string'("0xDEA356A2CDDD90C7A7ECEDC5EBB563934F460452"));
        ---------------------------------------------------------------------------
        -- WORD=4 かつメッセージの長さが48byte の場合に間違った値を生成するのを再現
        ---------------------------------------------------------------------------
        SCENARIO <= "5.0.0";
        wait for 0 ns;
        RUN_TEST_ONE(string'("9xechjlnzwiesrptcUrfp)kgxgughsfucsKnusuojkazva5l"),
                     string'("0x970a78cc84b23d4c4d36e6a13722a65448c6e820"));
        ---------------------------------------------------------------------------
        -- WORD=4 かつメッセージの長さが55byte の場合に間違った値を生成するのを再現
        ---------------------------------------------------------------------------
        SCENARIO <= "5.0.1";
        wait for 0 ns;
        RUN_TEST_ONE(string'("ltjIurwtb#zgnia4smalxiycusvlukdmdapkygdomipuVdu7iablkbf"),
                     string'("0x73f26e481c521d5766972cde8c08ac9b57956bbd"));
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
--! @brief   SHA-1テストベンチ(WORDS=1,SYMBOLS=4,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA1_TEST_BENCH_W1_S4_G0 is
end     SHA1_TEST_BENCH_W1_S4_G0;
architecture MODEL of SHA1_TEST_BENCH_W1_S4_G0 is
    component  SHA1_TEST_BENCH
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
    TB: SHA1_TEST_BENCH generic map(
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
--! @brief   SHA-1テストベンチ(WORDS=1,SYMBOLS=4,BLOCK_GAP=1)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA1_TEST_BENCH_W1_S4_G1 is
end     SHA1_TEST_BENCH_W1_S4_G1;
architecture MODEL of SHA1_TEST_BENCH_W1_S4_G1 is
    component  SHA1_TEST_BENCH
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
    TB: SHA1_TEST_BENCH generic map(
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
--! @brief   SHA-1テストベンチ(WORDS=2,SYMBOLS=8,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA1_TEST_BENCH_W2_S8_G0 is
end     SHA1_TEST_BENCH_W2_S8_G0;
architecture MODEL of SHA1_TEST_BENCH_W2_S8_G0 is
    component  SHA1_TEST_BENCH
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
    TB: SHA1_TEST_BENCH generic map(
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
--! @brief   SHA-1テストベンチ(WORDS=4,SYMBOLS=16,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA1_TEST_BENCH_W4_S16_G0 is
end     SHA1_TEST_BENCH_W4_S16_G0;
architecture MODEL of SHA1_TEST_BENCH_W4_S16_G0 is
    component  SHA1_TEST_BENCH
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
    TB: SHA1_TEST_BENCH generic map(
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
--! @brief   SHA-1テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA1_TEST_BENCH_W1_S8_G0 is
end     SHA1_TEST_BENCH_W1_S8_G0;
architecture MODEL of SHA1_TEST_BENCH_W1_S8_G0 is
    component  SHA1_TEST_BENCH
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
    TB: SHA1_TEST_BENCH generic map(
           SYMBOLS      => 8,
           WORDS        => 1,
           BLOCK_GAP    => 0,
           VERBOSE      => 0,
           AUTO_FINISH  => 1
    ) port map (
           FINISH       => open
    );
end MODEL;
