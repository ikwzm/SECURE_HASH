-----------------------------------------------------------------------------------
--!     @file    sha1_proc.vhd
--!     @brief   SHA-1 Processing Module :
--!              SHA-1用計算モジュール.
--!     @version 0.2.0
--!     @date    2012/9/26
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
--! @brief   SHA1_PROC :
--!          SHA-1用計算モジュール.
-----------------------------------------------------------------------------------
entity  SHA1_PROC is
    generic (
        WORDS       : --! @brief OUTPUT WORD SIZE :
                      --! 出力側のワード数を指定する(1ワードは32bit).
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
                      in  std_logic_vector(32*WORDS-1 downto 0);
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
                      out std_logic_vector(159 downto 0);
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      out std_logic
    );
end SHA1_PROC;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA1_PROC is
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS       : integer := 32;
    -------------------------------------------------------------------------------
    -- ワードの型宣言
    -------------------------------------------------------------------------------
    subtype   WORD_TYPE      is std_logic_vector(WORD_BITS-1 downto 0);
    type      WORD_VECTOR    is array (INTEGER range <>) of WORD_TYPE;
    constant  WORD_NULL       : WORD_TYPE := (others => '0');
    -------------------------------------------------------------------------------
    -- スケジュール用の信号
    -------------------------------------------------------------------------------
    signal    s_num     : integer range 0 to 79;
    signal    s_done    : std_logic;
    signal    s_last    : std_logic;
    signal    s_input   : std_logic;
    signal    s_valid   : std_logic;
    -------------------------------------------------------------------------------
    -- W[t]
    -------------------------------------------------------------------------------
    signal    w_num     : integer range 0 to 79;
    signal    w_done    : std_logic;
    signal    w_valid   : std_logic;
    signal    w_reg     : WORD_VECTOR(0 to 15   );
    signal    w         : WORD_VECTOR(0 to WORDS);
    -------------------------------------------------------------------------------
    -- a,b,c,d,e
    -------------------------------------------------------------------------------
    signal    a         : WORD_VECTOR(0 to WORDS);
    signal    b         : WORD_VECTOR(0 to WORDS);
    signal    c         : WORD_VECTOR(0 to WORDS);
    signal    d         : WORD_VECTOR(0 to WORDS);
    signal    e         : WORD_VECTOR(0 to WORDS);
    signal    a_reg     : WORD_TYPE;
    signal    b_reg     : WORD_TYPE;
    signal    c_reg     : WORD_TYPE;
    signal    d_reg     : WORD_TYPE;
    signal    e_reg     : WORD_TYPE;
    -------------------------------------------------------------------------------
    -- H0,H1,H2,H3,H4
    -------------------------------------------------------------------------------
    signal    h0        : WORD_TYPE;
    signal    h1        : WORD_TYPE;
    signal    h2        : WORD_TYPE;
    signal    h3        : WORD_TYPE;
    signal    h4        : WORD_TYPE;
    signal    k         : WORD_VECTOR(0 to WORDS);
    constant  H0_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"67452301"));
    constant  H1_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"EFCDAB89"));
    constant  H2_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"98BADCFE"));
    constant  H3_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"10325476"));
    constant  H4_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"C3D2E1F0"));
    -------------------------------------------------------------------------------
    -- K[t]
    -------------------------------------------------------------------------------
    constant  K0        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"5A827999"));
    constant  K1        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"6ED9EBA1"));
    constant  K2        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"8F1BBCDC"));
    constant  K3        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"CA62C1D6"));
    -------------------------------------------------------------------------------
    -- ローテート演算関数.
    -------------------------------------------------------------------------------
    function  RotL(X:WORD_TYPE;N:integer) return WORD_TYPE is
    begin
        return X(WORD_TYPE'high-N downto WORD_TYPE'low     ) &
               X(WORD_TYPE'high   downto WORD_TYPE'high-N+1);
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
    component SHA_SCHEDULE
        generic (
            WORD_BITS   : integer := 32;
            WORDS       : integer := 1;
            INPUT_NUM   : integer := 16;
            CALC_NUM    : integer := 80;
            END_OF_NUM  : integer := 80
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
            O_NUM       : out integer range 0 to END_OF_NUM-1;
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
            CALC_NUM    => 80          , --
            END_OF_NUM  => 80            -- 
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
                w_num   <=  0 ;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                w_reg   <= (others => WORD_NULL);
                w_valid <= '0';
                w_done  <= '0';
                w_num   <=  0 ;
            else
                if (s_valid = '1') then
                    w_work(0 to 15) := w_reg(0 to 15);
                    for i in 0 to WORDS-1 loop
                        if (s_input = '1') then
                            w_work(16+i) := M_DATA(WORD_BITS*(i+1)-1 downto WORD_BITS*i);
                        else
                            w_work(16+i) := RotL(w_work(16+i-3 ) xor
                                                 w_work(16+i-8 ) xor
                                                 w_work(16+i-14) xor
                                                 w_work(16+i-16), 1);
                        end if;
                    end loop;
                    w_reg <= w_work(WORDS to WORDS+15);
                end if;
                w_valid <= s_valid;
                w_done  <= s_done;
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
    K_GEN: for i in 0 to WORDS-1 generate
        k(i) <= K0 when ( 0 <= w_num + i and w_num + i < 20) else
                K1 when (20 <= w_num + i and w_num + i < 40) else
                K2 when (40 <= w_num + i and w_num + i < 60) else
                K3;
    end generate;
    -------------------------------------------------------------------------------
    -- a,b,c,d,e の計算
    -------------------------------------------------------------------------------
    a(0) <= a_reg;
    b(0) <= b_reg;
    c(0) <= c_reg;
    d(0) <= d_reg;
    e(0) <= e_reg;
    CALC: for i in 0 to WORDS-1 generate
        signal   a0 : unsigned(31 downto 0);
        signal   a1 : unsigned(31 downto 0);
        signal   a2 : unsigned(31 downto 0);
        signal   a3 : unsigned(31 downto 0);
        signal   a4 : unsigned(31 downto 0);
    begin 
        a0 <= unsigned(RotL(a(i),5));
        a1 <= unsigned(Ch    (b(i),c(i),d(i))) when ( 0 <= w_num+i and w_num+i < 20) else
              unsigned(Parity(b(i),c(i),d(i))) when (20 <= w_num+i and w_num+i < 40) else
              unsigned(Maj   (b(i),c(i),d(i))) when (40 <= w_num+i and w_num+i < 60) else
              unsigned(Parity(b(i),c(i),d(i)));
        a2 <= unsigned(e(i));
        a3 <= unsigned(w(i));
        a4 <= unsigned(k(i));
        a(i+1) <= std_logic_vector(a0+a1+a2+a3+a4);
        b(i+1) <= a(i);
        c(i+1) <= RotL(B(i),30);
        d(i+1) <= c(i);
        e(i+1) <= d(i);
    end generate;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable h0_next : WORD_TYPE;
        variable h1_next : WORD_TYPE;
        variable h2_next : WORD_TYPE;
        variable h3_next : WORD_TYPE;
        variable h4_next : WORD_TYPE;
    begin
        if (RST = '1') then
                h0     <= H0_INIT;
                h1     <= H1_INIT;
                h2     <= H2_INIT;
                h3     <= H3_INIT;
                h4     <= H4_INIT;
                a_reg  <= H0_INIT;
                b_reg  <= H1_INIT;
                c_reg  <= H2_INIT;
                d_reg  <= H3_INIT;
                e_reg  <= H4_INIT;
                O_DATA <= (others => '0');
                O_VAL  <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                h0     <= H0_INIT;
                h1     <= H1_INIT;
                h2     <= H2_INIT;
                h3     <= H3_INIT;
                h4     <= H4_INIT;
                a_reg  <= H0_INIT;
                b_reg  <= H1_INIT;
                c_reg  <= H2_INIT;
                d_reg  <= H3_INIT;
                e_reg  <= H4_INIT;
                O_DATA <= (others => '0');
                O_VAL  <= '0';
            elsif (w_valid = '1') then
                h0_next := std_logic_vector(unsigned(h0) + unsigned(a(WORDS)));
                h1_next := std_logic_vector(unsigned(h1) + unsigned(b(WORDS)));
                h2_next := std_logic_vector(unsigned(h2) + unsigned(c(WORDS)));
                h3_next := std_logic_vector(unsigned(h3) + unsigned(d(WORDS)));
                h4_next := std_logic_vector(unsigned(h4) + unsigned(e(WORDS)));
                if (w_done = '1') then
                    h0     <= H0_INIT;
                    h1     <= H1_INIT;
                    h2     <= H2_INIT;
                    h3     <= H3_INIT;
                    h4     <= H4_INIT;
                    a_reg  <= H0_INIT;
                    b_reg  <= H1_INIT;
                    c_reg  <= H2_INIT;
                    d_reg  <= H3_INIT;
                    e_reg  <= H4_INIT;
                    O_DATA <= h0_next & h1_next & h2_next & h3_next & h4_next;
                    O_VAL  <= '1';
                else
                    O_VAL  <= '0';
                    if (w_num < 80-WORDS) then
                        a_reg <= a(a'high);
                        b_reg <= b(b'high);
                        c_reg <= c(c'high);
                        d_reg <= d(d'high);
                        e_reg <= e(e'high);
                    else
                        a_reg <= h0_next;
                        b_reg <= h1_next;
                        c_reg <= h2_next;
                        d_reg <= h3_next;
                        e_reg <= h4_next;
                        h0    <= h0_next;
                        h1    <= h1_next;
                        h2    <= h2_next;
                        h3    <= h3_next;
                        h4    <= h4_next;
                    end if;
                end if;
            else
                    O_VAL  <= '0';
            end if;
        end if;
    end process;
end RTL;
