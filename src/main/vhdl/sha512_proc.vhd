-----------------------------------------------------------------------------------
--!     @file    sha512_proc.vhd
--!     @brief   SHA-512 Processing Module :
--!              SHA-512用計算モジュール.
--!     @version 0.5.0
--!     @date    2012/9/30
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
--! @brief   SHA512_PROC :
--!          SHA-512用計算モジュール.
-----------------------------------------------------------------------------------
entity  SHA512_PROC is
    generic (
        WORDS       : --! @brief OUTPUT WORD SIZE :
                      --! 出力側のワード数を指定する(1ワードは64bit).
                      integer := 1;
        PIPELINE    : --! @brief PIPELINE MODE :
                      --! パイプラインモードを指定する.
                      --! * 1: K[t]+W[t]を一度レジスタで叩いてから演算する.
                      --!   少しだけ動作周波数が上がる可能性がある.  
                      --!   スループットは変わらないが、レイテンシーが１クロック遅
                      --!   くなる.
                      integer := 1;
        TURN_AR     : --! @brief TURN AROUND CYCLE :
                      --! １ブロック(16word)処理する毎に挿入するターンアラウンド
                      --! サイクル数を指定する.
                      --! サイクル数分だけスループットが落ちるが、動作周波数が上がる
                      --! 可能性がある.
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
                      in  std_logic_vector(64*WORDS-1 downto 0);
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
                      out std_logic_vector(511 downto 0);
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      out std_logic
    );
end SHA512_PROC;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA512_PROC is
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS : integer := 64;
    -------------------------------------------------------------------------------
    -- ラウンド数
    -------------------------------------------------------------------------------
    constant  ROUNDS    : integer := 80;
    -------------------------------------------------------------------------------
    -- ワードの型宣言
    -------------------------------------------------------------------------------
    subtype   WORD_TYPE      is std_logic_vector(WORD_BITS-1 downto 0);
    type      WORD_VECTOR    is array (INTEGER range <>) of WORD_TYPE;
    constant  WORD_NULL : WORD_TYPE := (others => '0');
    -------------------------------------------------------------------------------
    -- カウンタ(NUM)の最大値
    -------------------------------------------------------------------------------
    constant  END_NUM         : integer := ROUNDS + WORDS*TURN_AR;
    subtype   NUM_TYPE       is integer range 0 to END_NUM-1;
    -------------------------------------------------------------------------------
    -- ハッシュレジスタの初期値
    -------------------------------------------------------------------------------
    constant  H0_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"6a09e667f3bcc908"));
    constant  H1_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"bb67ae8584caa73b"));
    constant  H2_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"3c6ef372fe94f82b"));
    constant  H3_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"a54ff53a5f1d36f1"));
    constant  H4_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"510e527fade682d1"));
    constant  H5_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"9b05688c2b3e6c1f"));
    constant  H6_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"1f83d9abfb41bd6b"));
    constant  H7_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"5be0cd19137e2179"));
    -------------------------------------------------------------------------------
    -- K-Table のコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA512_K_TABLE is
        generic (
            WORDS       : integer := 1
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            T           : in  integer range 0 to ROUNDS-1;
            K           : out std_logic_vector(WORD_BITS*WORDS-1 downto 0)
        );
    end component;
    -------------------------------------------------------------------------------
    -- スケジュール用の信号
    -------------------------------------------------------------------------------
    signal    s_num     : NUM_TYPE;
    signal    s_done    : std_logic;
    signal    s_last    : std_logic;
    signal    s_input   : std_logic;
    signal    s_valid   : std_logic;
    -------------------------------------------------------------------------------
    -- W[t]
    -------------------------------------------------------------------------------
    signal    w_num     : NUM_TYPE;
    signal    w_done    : std_logic;
    signal    w_last    : std_logic;
    signal    w_valid   : std_logic;
    signal    w_reg     : WORD_VECTOR(0 to 15   );
    signal    w         : WORD_VECTOR(0 to WORDS);
    -------------------------------------------------------------------------------
    -- W[t]+K[t]
    -------------------------------------------------------------------------------
    signal    p_num     : NUM_TYPE;
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
    signal    o_done    : std_logic;
    signal    o_last    : std_logic;
    -------------------------------------------------------------------------------
    -- ローテート演算関数.
    -------------------------------------------------------------------------------
    function  RotR(X:WORD_TYPE;N:integer) return WORD_TYPE is
    begin
        return X(WORD_TYPE'low+N-1 downto WORD_TYPE'low  ) &
               X(WORD_TYPE'high    downto WORD_TYPE'low+N);
    end function;
    -------------------------------------------------------------------------------
    -- シフト演算関数.
    -------------------------------------------------------------------------------
    function  SftR(X:WORD_TYPE;N:integer) return WORD_TYPE is
    begin
        return  (WORD_TYPE'low+N-1 downto WORD_TYPE'low => '0') & 
               X(WORD_TYPE'high    downto WORD_TYPE'low+N);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function Ch(B,C,D:WORD_TYPE) return std_logic_vector is
    begin
        return (B and C) or ((not B) and D);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function Parity(B,C,D:WORD_TYPE) return std_logic_vector is
    begin
        return B xor C xor D;
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function Maj(B,C,D:WORD_TYPE) return std_logic_vector is
    begin
        return (B and C) or (B and D) or (C and D);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function SigmaA0(X:WORD_TYPE) return std_logic_vector is
    begin
        return RotR(X,28) xor RotR(X,34) xor RotR(X,39);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function SigmaA1(X:WORD_TYPE) return std_logic_vector is
    begin
        return RotR(X,14) xor RotR(X,18) xor RotR(X,41);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function SigmaB0(X:WORD_TYPE) return std_logic_vector is
    begin
        return RotR(X, 1) xor RotR(X, 8) xor SftR(X, 7);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function SigmaB1(X:WORD_TYPE) return std_logic_vector is
    begin
        return RotR(X,19) xor RotR(X,61) xor SftR(X, 6);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component SHA_SCHEDULE
        generic (
            WORD_BITS   : integer := 32;
            WORDS       : integer := 1;
            INPUT_NUM   : integer := 16;
            CALC_NUM    : integer := 80;
            END_NUM     : integer := 80
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            I_DONE      : in  std_logic;
            I_VAL       : in  std_logic;
            I_RDY       : out std_logic;
            O_INPUT     : out std_logic;
            O_LAST      : out std_logic;
            O_DONE      : out std_logic;
            O_NUM       : out integer range 0 to END_NUM-1;
            O_VAL       : out std_logic
        );
    end component;
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
            O_VAL       => s_valid       -- Out :
        );
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
                w_num   <=  0 ;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                w_reg   <= (others => WORD_NULL);
                w_valid <= '0';
                w_done  <= '0';
                w_last  <= '0';
                w_num   <=  0 ;
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
                w_num   <= s_num;
            end if;
        end if;
    end process;
    W_GEN: for i in 0 to WORDS-1 generate
        w(i) <= w_reg(16-WORDS+i);
    end generate;
    -------------------------------------------------------------------------------
    -- K[t]の生成
    -------------------------------------------------------------------------------
    k_num <= s_num when (s_num < ROUNDS) else 0;
    K_TBL: SHA512_K_TABLE generic map (WORDS) port map (
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
                    p_num   <=  0 ;
                    p_valid <= '0';
                    p_done  <= '0';
                    p_last  <= '0';
                    p       <= (others => WORD_NULL);
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    p_num   <=  0 ;
                    p_valid <= '0';
                    p_done  <= '0';
                    p_last  <= '0';
                    p       <= (others => WORD_NULL);
                else
                    p_num   <= w_num;
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
        p_num   <= w_num;
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
                O_DATA <= (others => '0');
                O_VAL  <= '0';
                o_done <= '0';
                o_last <= '0';
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
                O_DATA <= (others => '0');
                O_VAL  <= '0';
                o_done <= '0';
                o_last <= '0';
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
                O_DATA <= h0 & h1 & h2 & h3 & h4 & h5 & h6 & h7;
                O_VAL  <= '1';
                o_done <= '0';
                o_last <= '0';
            elsif (p_last = '1' and TURN_AR = 0) then
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
                O_VAL  <= '0';
                o_done <= p_done;
                o_last <= p_last;
            elsif (o_last = '1' and TURN_AR > 0) then
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
                O_VAL  <= '0';
                o_done <= p_done;
                o_last <= p_last;
            elsif (p_valid = '1') then
                a_reg  <= a(a'high);
                b_reg  <= b(b'high);
                c_reg  <= c(c'high);
                d_reg  <= d(d'high);
                e_reg  <= e(e'high);
                f_reg  <= f(f'high);
                g_reg  <= g(g'high);
                h_reg  <= h(h'high);
                O_VAL  <= '0';
                o_done <= p_done;
                o_last <= p_last;
            else
                O_VAL  <= '0';
                o_done <= p_done;
                o_last <= p_last;
            end if;
        end if;
    end process;
end RTL;
