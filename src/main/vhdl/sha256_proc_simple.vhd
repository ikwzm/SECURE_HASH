-----------------------------------------------------------------------------------
--!     @file    sha256_proc_simple.vhd
--!     @brief   SHA-256 Processing Module :
--!              SHA-256用計算モジュール(シンプル版).
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
library PipeWork;
use     PipeWork.SHA256.WORD_BITS;
use     PipeWork.SHA256.HASH_BITS;
-----------------------------------------------------------------------------------
--! @brief   SHA256_PROC_SIMPLE :
--!          SHA-256用計算モジュール(シンプル版).
-----------------------------------------------------------------------------------
entity  SHA256_PROC_SIMPLE is
    generic (
        WORDS       : --! @brief OUTPUT WORD SIZE :
                      --! 出力側のワード数を指定する(1ワードは32bit).
                      integer := 1;
        PIPELINE    : --! @brief PIPELINE MODE :
                      --! パイプラインモードを指定する.
                      --! * 1: K[t]+W[t]を一度レジスタで叩いてから演算する.
                      --!   少しだけ動作周波数が上がる可能性がある.  
                      --!   スループットは変わらないが、レイテンシーが１クロック遅
                      --!   くなる.
                      integer := 1;
        BLOCK_GAP   : --! @brief BLOCK GAP CYCLE :
                      --! １ブロック(16word)処理する毎に挿入するギャップのサイクル
                      --! 数を指定する.
                      --! サイクル数分だけスループットが落ちるが、動作周波数が上が
                      --! る可能性がある.
                      integer := 0
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK         : --! @brief CLOCK :
                      --! クロック信号
                      in  std_logic; 
        RST         : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
        CLR         : --! @brief SYNCRONOUSE RESET :
                      --! 同期リセット信号.アクティブハイ.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        M_DATA      : --! @brief INPUT MESSAGE DATA :
                      in  std_logic_vector(WORD_BITS*WORDS-1 downto 0);
        M_DONE      : --! @brief INPUT MESSAGE DONE :
                      in  std_logic;
        M_VAL       : --! @brief INPUT MESSAGE VALID :
                      in  std_logic;
        M_RDY       : --! @brief INPUT MESSAGE READY :
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT WORD DATA :
                      out std_logic_vector(HASH_BITS-1 downto 0);
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      out std_logic;
        O_RDY       : --! @brief OUTPUT WORD READY :
                      in  std_logic
    );
end SHA256_PROC_SIMPLE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.SHA256.all;
architecture RTL of SHA256_PROC_SIMPLE is
    -------------------------------------------------------------------------------
    -- カウンタ(NUM)の最大値
    -------------------------------------------------------------------------------
    constant  END_NUM         : integer := ROUNDS + WORDS*BLOCK_GAP;
    subtype   NUM_TYPE       is integer range 0 to END_NUM-1;
    -------------------------------------------------------------------------------
    -- スケジュール用の信号
    -------------------------------------------------------------------------------
    signal    s_num     : NUM_TYPE;
    signal    s_done    : std_logic;
    signal    s_last    : std_logic;
    signal    s_input   : std_logic;
    signal    s_valid   : std_logic;
    signal    s_ready   : std_logic;
    -------------------------------------------------------------------------------
    -- W[t]
    -------------------------------------------------------------------------------
    signal    w_done    : std_logic;
    signal    w_last    : std_logic;
    signal    w_valid   : std_logic;
    signal    w_reg     : WORD_VECTOR(0 to 15   );
    signal    w         : WORD_VECTOR(0 to WORDS);
    -------------------------------------------------------------------------------
    -- W[t]+K[t]
    -------------------------------------------------------------------------------
    signal    p_valid   : std_logic;
    signal    p_done    : std_logic;
    signal    p_last    : std_logic;
    signal    p         : WORD_VECTOR(0 to WORDS-1);
    -------------------------------------------------------------------------------
    -- a,b,c,d,e,f,g,h
    -------------------------------------------------------------------------------
    signal    a         : WORD_VECTOR(0 to WORDS);
    signal    b         : WORD_VECTOR(0 to WORDS);
    signal    c         : WORD_VECTOR(0 to WORDS);
    signal    d         : WORD_VECTOR(0 to WORDS);
    signal    e         : WORD_VECTOR(0 to WORDS);
    signal    f         : WORD_VECTOR(0 to WORDS);
    signal    g         : WORD_VECTOR(0 to WORDS);
    signal    h         : WORD_VECTOR(0 to WORDS);
    signal    a_reg     : WORD_TYPE;
    signal    b_reg     : WORD_TYPE;
    signal    c_reg     : WORD_TYPE;
    signal    d_reg     : WORD_TYPE;
    signal    e_reg     : WORD_TYPE;
    signal    f_reg     : WORD_TYPE;
    signal    g_reg     : WORD_TYPE;
    signal    h_reg     : WORD_TYPE;
    -------------------------------------------------------------------------------
    -- H0,H1,H2,H3,H4,H5,H6,H7
    -------------------------------------------------------------------------------
    signal    h0        : WORD_TYPE;
    signal    h1        : WORD_TYPE;
    signal    h2        : WORD_TYPE;
    signal    h3        : WORD_TYPE;
    signal    h4        : WORD_TYPE;
    signal    h5        : WORD_TYPE;
    signal    h6        : WORD_TYPE;
    signal    h7        : WORD_TYPE;
    -------------------------------------------------------------------------------
    -- K[t]
    -------------------------------------------------------------------------------
    signal    k_num     : integer range 0 to ROUNDS-1;
    signal    k         : WORD_VECTOR(0 to WORDS-1);
    signal    k_data    : std_logic_vector(WORD_BITS*WORDS-1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    o_last    : std_logic;
    signal    o_done    : std_logic;
    signal    o_valid   : std_logic;
begin
    -------------------------------------------------------------------------------
    -- スケジューラ
    -------------------------------------------------------------------------------
    SCHEDULE: SHA_SCHEDULE
        generic map (
            WORD_BITS   => WORD_BITS   , --
            WORDS       => WORDS       , --
            INPUT_NUM   => 16          , --
            CALC_NUM    => ROUNDS      , --
            END_NUM     => END_NUM       -- 
        )
        port map (
            CLK         => CLK         , -- In  :
            RST         => RST         , -- In  :
            CLR         => CLR         , -- In  :
            I_DONE      => M_DONE      , -- In  :
            I_VAL       => M_VAL       , -- In  :
            I_RDY       => M_RDY       , -- Out :
            O_NUM       => s_num       , -- Out :
            O_INPUT     => s_input     , -- Out :
            O_LAST      => s_last      , -- Out :
            O_DONE      => s_done      , -- Out :
            O_VAL       => s_valid     , -- Out :
            O_RDY       => s_ready       -- In  :
        );
    process (CLK, RST) begin
        if         (RST   = '1') then s_ready <= '1';
        elsif (CLK'event and CLK = '1') then
            if    (CLR    = '1') then s_ready <= '1';
            elsif (o_done = '1') then s_ready <= '1';
            elsif (s_done = '1') then s_ready <= '0';
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- W[t]の生成
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable w_work : WORD_VECTOR(0 to 15 + WORDS);
    begin
        if (RST = '1') then
                w_reg   <= (others => WORD_NULL);
                w_valid <= '0';
                w_done  <= '0';
                w_last  <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                w_reg   <= (others => WORD_NULL);
                w_valid <= '0';
                w_done  <= '0';
                w_last  <= '0';
            else
                if (s_valid = '1') then
                    w_work(0 to 15) := w_reg(0 to 15);
                    for i in 0 to WORDS-1 loop
                        if (s_input = '1') then
                            w_work(16+i) := M_DATA(WORD_BITS*(i+1)-1 downto WORD_BITS*i);
                        else
                            w_work(16+i) := std_logic_vector(
                                              unsigned(SigmaB1(w_work(16+i- 2))) +
                                              unsigned(        w_work(16+i- 7) ) +
                                              unsigned(SigmaB0(w_work(16+i-15))) + 
                                              unsigned(        w_work(16+i-16) )
                                            );
                        end if;
                    end loop;
                    w_reg <= w_work(WORDS to WORDS+15);
                end if;
                w_valid <= s_valid;
                w_done  <= s_done;
                w_last  <= s_last;
            end if;
        end if;
    end process;
    W_GEN: for i in 0 to WORDS-1 generate
        w(i) <= w_reg(16-WORDS+i);
    end generate;
    -------------------------------------------------------------------------------
    -- K[t]の生成
    -------------------------------------------------------------------------------
    k_num <= s_num when (END_NUM = ROUNDS or s_num < ROUNDS) else 0;
    K_TBL: SHA256_K_TABLE generic map (WORDS) port map (
            CLK         => CLK, 
            RST         => RST,
            T           => k_num,
            K           => k_data
        );
    K_GEN: for i in 0 to WORDS-1 generate
        k(i) <= k_data(WORD_BITS*(i+1)-1 downto WORD_BITS*i);
    end generate;
    -------------------------------------------------------------------------------
    -- K[t]+W[t]の生成
    -------------------------------------------------------------------------------
    P_TRUE: if (PIPELINE > 0) generate
        process (CLK, RST) begin
            if (RST = '1') then
                    p_valid <= '0';
                    p_done  <= '0';
                    p_last  <= '0';
                    p       <= (others => WORD_NULL);
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    p_valid <= '0';
                    p_done  <= '0';
                    p_last  <= '0';
                    p       <= (others => WORD_NULL);
                else
                    p_valid <= w_valid;
                    p_done  <= w_done;
                    p_last  <= w_last;
                    for i in 0 to WORDS-1 loop
                        p(i) <= std_logic_vector(unsigned(k(i))+unsigned(w(i)));
                    end loop;
                end if;
            end if;
        end process;
    end generate;
    P_FALSE: if (PIPELINE = 0) generate
        p_valid <= w_valid;
        p_done  <= w_done;
        p_last  <= w_last;
        P_GEN: for i in 0 to WORDS-1 generate
            p(i) <= std_logic_vector(unsigned(k(i))+unsigned(w(i)));
        end generate;
    end generate;
    -------------------------------------------------------------------------------
    -- a,b,c,d,e,f,g,h の計算
    -------------------------------------------------------------------------------
    a(0) <= a_reg;
    b(0) <= b_reg;
    c(0) <= c_reg;
    d(0) <= d_reg;
    e(0) <= e_reg;
    f(0) <= f_reg;
    g(0) <= g_reg;
    h(0) <= h_reg;
    CALC: for i in 0 to WORDS-1 generate
        signal t1,t2 : unsigned(WORD_BITS-1 downto 0);
    begin
        t1 <= unsigned(SigmaA1(e(i))) + unsigned(Ch (e(i),f(i),g(i))) +
              unsigned(h(i)) + unsigned(p(i));
        t2 <= unsigned(SigmaA0(a(i))) + unsigned(Maj(a(i),b(i),c(i)));
        a(i+1) <= std_logic_vector(t1+t2);
        b(i+1) <= a(i);
        c(i+1) <= b(i);
        d(i+1) <= c(i);
        e(i+1) <= std_logic_vector(unsigned(d(i))+t1);
        f(i+1) <= e(i);
        g(i+1) <= f(i);
        h(i+1) <= g(i);
    end generate;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable h_next : WORD_VECTOR(0 to 7);
    begin
        if (RST = '1') then
                h0     <= H0_INIT;
                h1     <= H1_INIT;
                h2     <= H2_INIT;
                h3     <= H3_INIT;
                h4     <= H4_INIT;
                h5     <= H5_INIT;
                h6     <= H6_INIT;
                h7     <= H7_INIT;
                a_reg  <= H0_INIT;
                b_reg  <= H1_INIT;
                c_reg  <= H2_INIT;
                d_reg  <= H3_INIT;
                e_reg  <= H4_INIT;
                f_reg  <= H5_INIT;
                g_reg  <= H6_INIT;
                h_reg  <= H7_INIT;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                h0     <= H0_INIT;
                h1     <= H1_INIT;
                h2     <= H2_INIT;
                h3     <= H3_INIT;
                h4     <= H4_INIT;
                h5     <= H5_INIT;
                h6     <= H6_INIT;
                h7     <= H7_INIT;
                a_reg  <= H0_INIT;
                b_reg  <= H1_INIT;
                c_reg  <= H2_INIT;
                d_reg  <= H3_INIT;
                e_reg  <= H4_INIT;
                f_reg  <= H5_INIT;
                g_reg  <= H6_INIT;
                h_reg  <= H7_INIT;
            elsif (o_done  = '1') then
                h0     <= H0_INIT;
                h1     <= H1_INIT;
                h2     <= H2_INIT;
                h3     <= H3_INIT;
                h4     <= H4_INIT;
                h5     <= H5_INIT;
                h6     <= H6_INIT;
                h7     <= H7_INIT;
                a_reg  <= H0_INIT;
                b_reg  <= H1_INIT;
                c_reg  <= H2_INIT;
                d_reg  <= H3_INIT;
                e_reg  <= H4_INIT;
                f_reg  <= H5_INIT;
                g_reg  <= H6_INIT;
                h_reg  <= H7_INIT;
            elsif (p_last = '1' and BLOCK_GAP = 0) then
                h_next(0) := std_logic_vector(unsigned(h0) + unsigned(a(a'high)));
                h_next(1) := std_logic_vector(unsigned(h1) + unsigned(b(b'high)));
                h_next(2) := std_logic_vector(unsigned(h2) + unsigned(c(c'high)));
                h_next(3) := std_logic_vector(unsigned(h3) + unsigned(d(d'high)));
                h_next(4) := std_logic_vector(unsigned(h4) + unsigned(e(e'high)));
                h_next(5) := std_logic_vector(unsigned(h5) + unsigned(f(f'high)));
                h_next(6) := std_logic_vector(unsigned(h6) + unsigned(g(g'high)));
                h_next(7) := std_logic_vector(unsigned(h7) + unsigned(h(h'high)));
                a_reg  <= h_next(0);
                b_reg  <= h_next(1);
                c_reg  <= h_next(2);
                d_reg  <= h_next(3);
                e_reg  <= h_next(4);
                f_reg  <= h_next(5);
                g_reg  <= h_next(6);
                h_reg  <= h_next(7);
                h0     <= h_next(0);
                h1     <= h_next(1);
                h2     <= h_next(2);
                h3     <= h_next(3);
                h4     <= h_next(4);
                h5     <= h_next(5);
                h6     <= h_next(6);
                h7     <= h_next(7);
            elsif (o_last = '1' and BLOCK_GAP > 0) then
                h_next(0) := std_logic_vector(unsigned(h0) + unsigned(a_reg));
                h_next(1) := std_logic_vector(unsigned(h1) + unsigned(b_reg));
                h_next(2) := std_logic_vector(unsigned(h2) + unsigned(c_reg));
                h_next(3) := std_logic_vector(unsigned(h3) + unsigned(d_reg));
                h_next(4) := std_logic_vector(unsigned(h4) + unsigned(e_reg));
                h_next(5) := std_logic_vector(unsigned(h5) + unsigned(f_reg));
                h_next(6) := std_logic_vector(unsigned(h6) + unsigned(g_reg));
                h_next(7) := std_logic_vector(unsigned(h7) + unsigned(h_reg));
                a_reg  <= h_next(0);
                b_reg  <= h_next(1);
                c_reg  <= h_next(2);
                d_reg  <= h_next(3);
                e_reg  <= h_next(4);
                f_reg  <= h_next(5);
                g_reg  <= h_next(6);
                h_reg  <= h_next(7);
                h0     <= h_next(0);
                h1     <= h_next(1);
                h2     <= h_next(2);
                h3     <= h_next(3);
                h4     <= h_next(4);
                h5     <= h_next(5);
                h6     <= h_next(6);
                h7     <= h_next(7);
            elsif (p_valid = '1') then
                a_reg  <= a(a'high);
                b_reg  <= b(b'high);
                c_reg  <= c(c'high);
                d_reg  <= d(d'high);
                e_reg  <= e(e'high);
                f_reg  <= f(f'high);
                g_reg  <= g(g'high);
                h_reg  <= h(h'high);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                o_last  <= '0';
                o_valid <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                o_last  <= '0';
                o_valid <= '0';
            else
                o_last <= p_last;
                if    (o_done = '1') then
                    o_valid <= '0';
                elsif (p_done = '1') then
                    o_valid <= '1';
                end if;
            end if;
        end if;
    end process;
    O_DATA <= h0 & h1 & h2 & h3 & h4 & h5 & h6 & h7;
    O_VAL  <= o_valid;
    o_done <= '1' when (o_valid = '1' and O_RDY = '1') else '0';
end RTL;
