-----------------------------------------------------------------------------------
--!     @file    sha1_stage2.vhd
--!     @brief   SHA1 STAGE2 MODULE :
--!              SHA1用ワードデータ生成モジュール.
--!     @version 0.0.1
--!     @date    2012/9/21
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
--! @brief   SHA1_STAGE2 :
--!          SHA1の計算.
-----------------------------------------------------------------------------------
entity  SHA1_STAGE2 is
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
        I_DATA      : --! @brief INPUT WORD DATA :
                      in  std_logic_vector(32*WORDS-1 downto 0);
        I_DONE      : --! @brief INPUT WORD DATA DONE :
                      in  std_logic;
        I_VAL       : --! @brief INPUT WORD DATA VALID :
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT WORD DATA :
                      out std_logic_vector(159 downto 0);
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      out std_logic
    );
end SHA1_STAGE2;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA1_STAGE2 is
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS       : integer := 32;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    subtype   WORD_TYPE      is std_logic_vector(WORD_BITS-1 downto 0);
    type      WORD_VECTOR    is array (INTEGER range <>) of WORD_TYPE;
    constant  WORD_NULL       : WORD_TYPE := (others => '0');
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    index     : integer range 0 to 127;
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
    signal    h0        : WORD_TYPE;
    signal    h1        : WORD_TYPE;
    signal    h2        : WORD_TYPE;
    signal    h3        : WORD_TYPE;
    signal    h4        : WORD_TYPE;
    constant  H0_INIT   : WORD_TYPE := "01100111010001010010001100000001"; -- 0x67452301
    constant  H1_INIT   : WORD_TYPE := "11101111110011011010101110001001"; -- 0xEFCDAB89
    constant  H2_INIT   : WORD_TYPE := "10011000101110101101110011111110"; -- 0x98BADCFE
    constant  H3_INIT   : WORD_TYPE := "00010000001100100101010001110110"; -- 0x10325476
    constant  H4_INIT   : WORD_TYPE := "11000011110100101110000111110000"; -- 0xC3D2E1F0
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component SHA1_PROC is
        generic (
            NUM         : integer := 1
        );
        port (
            T           : in  integer range 0 to 127;
            W           : in  std_logic_vector(31 downto 0);
            Ai          : in  std_logic_vector(31 downto 0);
            Bi          : in  std_logic_vector(31 downto 0);
            Ci          : in  std_logic_vector(31 downto 0);
            Di          : in  std_logic_vector(31 downto 0);
            Ei          : in  std_logic_vector(31 downto 0);
            Ao          : out std_logic_vector(31 downto 0);
            Bo          : out std_logic_vector(31 downto 0);
            Co          : out std_logic_vector(31 downto 0);
            Do          : out std_logic_vector(31 downto 0);
            Eo          : out std_logic_vector(31 downto 0)
        );
    end component;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    a(0) <= a_reg;
    b(0) <= b_reg;
    c(0) <= c_reg;
    d(0) <= d_reg;
    e(0) <= e_reg;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    PROC: for i in 0 to WORDS-1 generate
        U: SHA1_PROC generic map(i) port map(
            T  => index,                           -- In  :
            W  => I_DATA(32*(i+1)-1 downto 32*i),  -- In  :
            Ai => a(i),                            -- In  :
            Bi => b(i),                            -- In  :
            Ci => c(i),                            -- In  :
            Di => d(i),                            -- In  :
            Ei => e(i),                            -- In  :
            Ao => a(i+1),                          -- Out :
            Bo => b(i+1),                          -- Out :
            Co => c(i+1),                          -- Out :
            Do => d(i+1),                          -- Out :
            Eo => e(i+1)                           -- Out :
        );
    end generate;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable h0_next : std_logic_vector(31 downto 0);
        variable h1_next : std_logic_vector(31 downto 0);
        variable h2_next : std_logic_vector(31 downto 0);
        variable h3_next : std_logic_vector(31 downto 0);
        variable h4_next : std_logic_vector(31 downto 0);
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
            index  <= 0;
            O_DATA <= (others => '0');
            O_VAL  <= '0';
        elsif (CLK'event and CLK = '1') then
            if (I_VAL = '1') then
                h0_next := std_logic_vector(unsigned(h0) + unsigned(a(a'high)));
                h1_next := std_logic_vector(unsigned(h1) + unsigned(b(b'high)));
                h2_next := std_logic_vector(unsigned(h2) + unsigned(c(c'high)));
                h3_next := std_logic_vector(unsigned(h3) + unsigned(d(d'high)));
                h4_next := std_logic_vector(unsigned(h4) + unsigned(e(e'high)));
                if (I_DONE = '1') then
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
                    index  <= 0;
                else
                    O_VAL  <= '0';
                    if (index < 80-WORDS) then
                        index <= index + WORDS;
                        a_reg <= a(a'high);
                        b_reg <= b(b'high);
                        c_reg <= c(c'high);
                        d_reg <= d(d'high);
                        e_reg <= e(e'high);
                    else
                        index <= 0;
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
