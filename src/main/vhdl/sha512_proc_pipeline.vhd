-----------------------------------------------------------------------------------
--!     @file    sha512_proc_pipeline.vhd
--!     @brief   SHA-512 Processing Module :
--!              SHA-512用計算モジュール(パイプライン版).
--!     @version 0.7.1
--!     @date    2012/10/12
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
use     PipeWork.SHA512.WORD_BITS;
use     PipeWork.SHA512.HASH_BITS;
-----------------------------------------------------------------------------------
--! @brief   SHA512_PROC_PIPELINE :
--!          SHA-512用計算モジュール(パイプライン版).
-----------------------------------------------------------------------------------
entity  SHA512_PROC_PIPELINE is
    generic (
        WORDS       : --! @brief OUTPUT WORD SIZE :
                      --! 出力側のワード数を指定する(1ワードは64bit).
                      integer := 1
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
end SHA512_PROC_PIPELINE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.SHA512.all;
architecture RTL of SHA512_PROC_PIPELINE is
    -------------------------------------------------------------------------------
    -- カウンタ(NUM)の最大値
    -------------------------------------------------------------------------------
    constant  END_NUM         : integer := ROUNDS + 4;
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
    signal    s_hole    : std_logic;
    signal    wait_done : std_logic;
    signal    wait_hole : std_logic;
    -------------------------------------------------------------------------------
    -- W[t]
    -------------------------------------------------------------------------------
    signal    w_done    : std_logic;
    signal    w_last    : std_logic;
    signal    w_first   : std_logic;
    signal    w_valid   : std_logic;
    signal    w_hole    : std_logic;
    signal    w_resume  : std_logic;
    signal    w_reg     : WORD_VECTOR(0 to 15);
    signal    w         : WORD_TYPE;
    -------------------------------------------------------------------------------
    -- a,b,c,d,e,f,g,h
    -------------------------------------------------------------------------------
    signal    a         : WORD_TYPE;
    signal    b         : WORD_TYPE;
    signal    c         : WORD_TYPE;
    signal    d         : WORD_TYPE;
    signal    e         : WORD_TYPE;
    signal    f         : WORD_TYPE;
    signal    g         : WORD_TYPE;
    signal    h         : WORD_TYPE;
    signal    t2        : WORD_TYPE;
    signal    t3        : WORD_TYPE;
    signal    t4        : WORD_TYPE;
    signal    t5        : WORD_TYPE;
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
    signal    k         : WORD_TYPE;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    p_first   : std_logic_vector(0 to 2);
    signal    p_last    : std_logic_vector(0 to 2);
    signal    p_valid   : std_logic_vector(0 to 3);
    signal    p_hole    : std_logic_vector(0 to 2);
    signal    p_resume  : std_logic_vector(0 to 1);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    o_last    : std_logic;
    signal    o_done    : std_logic;
    signal    o_valid   : std_logic;
    signal    o_hole    : std_logic;
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
        if         (RST   = '1') then wait_done <= '0';
        elsif (CLK'event and CLK = '1') then
            if    (CLR    = '1') then wait_done <= '0';
            elsif (o_done = '1') then wait_done <= '0';
            elsif (s_done = '1') then wait_done <= '1';
            end if;
        end if;
    end process;
    process (CLK, RST) begin
        if         (RST   = '1') then wait_hole <= '0';
        elsif (CLK'event and CLK = '1') then
            if    (CLR    = '1') then wait_hole <= '0';
            elsif (o_hole = '1') then wait_hole <= '0';
            elsif (s_hole = '1') then wait_hole <= '1';
            end if;
        end if;
    end process;
    s_hole  <= '1' when (s_valid   = '0' and w_valid   = '1' and w_last = '0') else '0';
    s_ready <= '1' when (wait_done = '0' and wait_hole = '0') else '0';
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
                w_first <= '0';
                w_resume<= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                w_reg   <= (others => WORD_NULL);
                w_valid <= '0';
                w_done  <= '0';
                w_last  <= '0';
                w_first <= '0';
                w_resume<= '0';
            else
                if (s_valid = '1' and s_ready = '1') then
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
                if (s_valid = '1' and s_ready = '1') then
                    w_valid <= '1';
                else
                    w_valid <= '0';
                end if;
                w_done  <= s_done;
                w_last  <= s_last;
                w_hole  <= s_hole;
                if (s_valid = '1' and s_ready = '1' and s_num = 0) then
                    w_first <= '1';
                else
                    w_first <= '0';
                end if;
                if (w_valid = '0' and s_valid = '1' and s_ready = '1' and s_num /= 0) then
                    w_resume <= '1';
                else
                    w_resume <= '0';
                end if;
            end if;
        end if;
    end process;
    w <= w_reg(15);
    -------------------------------------------------------------------------------
    -- K[t]の生成
    -------------------------------------------------------------------------------
    k_num <= s_num when (END_NUM = ROUNDS or s_num < ROUNDS) else 0;
    K_TBL: SHA512_K_TABLE generic map (1) port map (
            CLK         => CLK, 
            RST         => RST,
            T           => k_num,
            K           => k
        );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable h_next : WORD_VECTOR(0 to 7);
        variable sigma0 : WORD_TYPE;
        variable sigma1 : WORD_TYPE;
        variable ch0    : WORD_TYPE;
        variable ma0    : WORD_TYPE;
        variable t6     : WORD_TYPE;
    begin
        if (RST = '1') then
                p_valid  <= (others => '0');
                p_last   <= (others => '0');
                p_first  <= (others => '0');
                p_hole   <= (others => '0');
                p_resume <= (others => '0');
                h0       <= H0_INIT;
                h1       <= H1_INIT;
                h2       <= H2_INIT;
                h3       <= H3_INIT;
                h4       <= H4_INIT;
                h5       <= H5_INIT;
                h6       <= H6_INIT;
                h7       <= H7_INIT;
                a        <= H0_INIT;
                b        <= H1_INIT;
                c        <= H2_INIT;
                d        <= H3_INIT;
                e        <= H4_INIT;
                f        <= H5_INIT;
                g        <= H6_INIT;
                h        <= H7_INIT;
                t2       <= WORD_NULL;
                t3       <= WORD_NULL;
                t4       <= WORD_NULL;
                t5       <= WORD_NULL;
        elsif (CLK'event and CLK = '1') then
            if (CLR    = '1') or
               (o_done = '1') then
                p_valid  <= (others => '0');
                p_last   <= (others => '0');
                p_first  <= (others => '0');
                p_hole   <= (others => '0');
                p_resume <= (others => '0');
                h0       <= H0_INIT;
                h1       <= H1_INIT;
                h2       <= H2_INIT;
                h3       <= H3_INIT;
                h4       <= H4_INIT;
                h5       <= H5_INIT;
                h6       <= H6_INIT;
                h7       <= H7_INIT;
                a        <= H0_INIT;
                b        <= H1_INIT;
                c        <= H2_INIT;
                d        <= H3_INIT;
                e        <= H4_INIT;
                f        <= H5_INIT;
                g        <= H6_INIT;
                h        <= H7_INIT;
                t2       <= WORD_NULL;
                t3       <= WORD_NULL;
                t4       <= WORD_NULL;
                t5       <= WORD_NULL;
            elsif (o_last = '1') then
                p_valid  <= (others => '0');
                p_last   <= (others => '0');
                p_first  <= (others => '0');
                p_hole   <= (others => '0');
                p_resume <= (others => '0');
                h_next(0) := std_logic_vector(unsigned(h0) + unsigned(a));
                h_next(1) := std_logic_vector(unsigned(h1) + unsigned(b));
                h_next(2) := std_logic_vector(unsigned(h2) + unsigned(c));
                h_next(3) := std_logic_vector(unsigned(h3) + unsigned(d));
                h_next(4) := std_logic_vector(unsigned(h4) + unsigned(e));
                h_next(5) := std_logic_vector(unsigned(h5) + unsigned(f));
                h_next(6) := std_logic_vector(unsigned(h6) + unsigned(g));
                h_next(7) := std_logic_vector(unsigned(h7) + unsigned(h));
                h0       <= h_next(0);
                h1       <= h_next(1);
                h2       <= h_next(2);
                h3       <= h_next(3);
                h4       <= h_next(4);
                h5       <= h_next(5);
                h6       <= h_next(6);
                h7       <= h_next(7);
                a        <= h_next(0);
                b        <= h_next(1);
                c        <= h_next(2);
                d        <= h_next(3);
                e        <= h_next(4);
                f        <= h_next(5);
                g        <= h_next(6);
                h        <= h_next(7);
                t2       <= WORD_NULL;
                t3       <= WORD_NULL;
                t4       <= WORD_NULL;
                t5       <= WORD_NULL;
            else
                p_valid (0) <= w_valid ; p_valid (1 to p_valid 'high) <= p_valid (0 to p_valid 'high-1);
                p_last  (0) <= w_last  ; p_last  (1 to p_last  'high) <= p_last  (0 to p_last  'high-1);
                p_first (0) <= w_first ; p_first (1 to p_first 'high) <= p_first (0 to p_first 'high-1);
                p_hole  (0) <= w_hole  ; p_hole  (1 to p_hole  'high) <= p_hole  (0 to p_hole  'high-1);
                p_resume(0) <= w_resume; p_resume(1 to p_resume'high) <= p_resume(0 to p_resume'high-1);
                if (w_valid = '1') then
                    if    (w_first     = '1') then
                        h <= h7;
                    elsif (p_first(0)  = '1') then
                        h <= h6;
                    elsif (w_resume    = '1') then
                        h <= h;
                    elsif (p_resume(0) = '1') then
                        h <= g;
                    else
                        h <= f;
                    end if;
                else
                    if (p_valid(1) = '1') then
                        h <= g;
                    end if;
                end if;
                if (w_valid = '1') then
                    if    (w_first     = '1') then
                        d <= h3;
                    elsif (p_first(0)  = '1') then
                        d <= h2;
                    elsif (p_first(1)  = '1') then
                        d <= h1;
                    elsif (w_resume    = '1') then
                        d <= d;
                    elsif (p_resume(0) = '1') then
                        d <= c;
                    elsif (p_resume(1) = '1') then
                        d <= b;
                    else
                        d <= a;
                    end if;
                else
                    if (p_valid(2) = '1') then
                        d <= c;
                    end if;
                end if;
                if (w_valid = '1') then
                    t5 <= std_logic_vector(unsigned(w) + unsigned(k));
                end if;
                if (p_valid(0) = '1') then
                    t6 := std_logic_vector(unsigned(t5) + unsigned(h));
                    t3 <= t6;
                    t4 <= std_logic_vector(unsigned(t6) + unsigned(d));
                end if;
                if (p_valid(1) = '1') then
                    sigma1 := SigmaA1(e);
                    ch0    := Ch (e,f,g);
                    t2 <= std_logic_vector(unsigned(ch0) + (unsigned(sigma1) + unsigned(t3)));
                    e  <= std_logic_vector(unsigned(ch0) + (unsigned(sigma1) + unsigned(t4)));
                    f  <= e;
                    g  <= f;
                end if;
                if (p_valid(2) = '1') then
                    sigma0 := SigmaA0(a);
                    ma0    := Maj(a,b,c);
                    a  <= std_logic_vector(unsigned(ma0) + (unsigned(sigma0) + unsigned(t2)));
                    b  <= a;
                    c  <= b;
                end if;
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
                o_last  <= p_last(2);
                if    (o_done = '1') then
                    o_valid <= '0';
                elsif (w_done = '1') then
                    o_valid <= '1';
                end if;
            end if;
        end if;
    end process;
    O_DATA <= h0 & h1 & h2 & h3 & h4 & h5 & h6 & h7;
    O_VAL  <= o_valid;
    o_done <= '1' when (o_valid = '1' and O_RDY = '1') else '0';
    o_hole <= '1' when (p_hole(2) = '1') else '0';
end RTL;
