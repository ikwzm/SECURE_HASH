-----------------------------------------------------------------------------------
--!     @file    sha1_stage1.vhd
--!     @brief   SHA1 STAGE1 MODULE :
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
--! @brief   SHA1_STAGE1 :
--!          SHA1用ワードデータ生成.
-----------------------------------------------------------------------------------
entity  SHA1_STAGE1 is
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
        I_RDY       : --! @brief INPUT WORD DATA READY :
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT WORD DATA :
                      out std_logic_vector(32*WORDS-1 downto 0);
        O_DONE      : --! @brief OUTPUT WORD DONE :
                      out std_logic;
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      out std_logic
    );
end SHA1_STAGE1;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.Components.REDUCER;
architecture RTL of SHA1_STAGE1 is
    -------------------------------------------------------------------------------
    -- １ブロックのビット数
    -------------------------------------------------------------------------------
    constant  BLOCK_BITS      : integer := 512;
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS       : integer := 32;
    -------------------------------------------------------------------------------
    -- データのビット数
    -------------------------------------------------------------------------------
    constant  DATA_BITS       : integer := WORD_BITS*WORDS;
    -------------------------------------------------------------------------------
    -- W[t]の型定義.
    -------------------------------------------------------------------------------
    subtype   WORD_TYPE      is std_logic_vector(WORD_BITS-1 downto 0);
    type      WORD_VECTOR    is array (INTEGER range <>) of WORD_TYPE;
    constant  WORD_NULL       : WORD_TYPE := (others => '0');
    -------------------------------------------------------------------------------
    -- W[t]配列
    -------------------------------------------------------------------------------
    signal    word_regs       : WORD_VECTOR(0 to 15);
    signal    word_work       : WORD_VECTOR(0 to 15 + WORDS);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    state_count     : integer range 0 to 80/WORDS;
    signal    input_state     : boolean;
    signal    calc_state      : boolean;
    signal    last_state      : boolean;
    signal    valid           : std_logic;
    signal    done            : std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  ROTATE(ARG:WORD_TYPE) return WORD_TYPE is
    begin
        return ARG(WORD_TYPE'high-1 downto WORD_TYPE'low ) &
               ARG(WORD_TYPE'high   downto WORD_TYPE'high);
    end function;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    word_work(0 to 15) <= word_regs(0 to 15);
    WGEN: for i in 0 to WORDS-1 generate
        word_work(16+i) <= I_DATA(32*(i+1)-1 downto 32*i) when (input_state) else
                           ROTATE(word_work(16+i-3 ) xor
                                  word_work(16+i-8 ) xor
                                  word_work(16+i-14) xor
                                  word_work(16+i-16));
    end generate;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
            word_regs <= (others => WORD_NULL);
        elsif (CLK'event and CLK = '1') then
            if (valid = '1') then
                word_regs <= word_work(WORDS to WORDS+15);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    valid <= '1' when (input_state and I_VAL = '1') or
                      (calc_state) else '0';
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    I_RDY <= '1' when (input_state) else '0';
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
            state_count <= 0;
        elsif (CLK'event and CLK = '1') then
            if    (last_state) then
                state_count <= 0;
            elsif (valid = '1') then
                state_count <= state_count + 1;
            end if;
        end if;
    end process;
    input_state <= (state_count <  16/WORDS  );
    calc_state  <= (state_count >= 16/WORDS and state_count < 80/WORDS);
    last_state  <= (state_count  = 80/WORDS-1);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
            done   <= '0';
            O_VAL  <= '0';
            O_DONE <= '0';
        elsif (CLK'event and CLK = '1') then
            if    (input_state and I_VAL = '1' and I_DONE = '1') then
                done <= '1';
            elsif (last_state) then
                done <= '0';
            end if;
            if (last_state and done = '1') then
                O_DONE <= '1';
            else
                O_DONE <= '0';
            end if;
            O_VAL <= valid;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    O_DATA_GEN: for i in 0 to WORDS-1 generate
        O_DATA(WORD_BITS*(i+1)-1 downto WORD_BITS*i) <= word_regs(16-WORDS+i);
    end generate;
end RTL;
