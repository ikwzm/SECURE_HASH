-----------------------------------------------------------------------------------
--!     @file    sha256_schedule.vhd
--!     @brief   SHA-256 Prepare the Message Schedule Module.
--!              SHA-256用スケジュールモジュール.
--!     @version 0.1.0
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
--! @brief   SHA256_SCHEDULE :
--!          SHA-256用ワードデータ(W[t])生成&スケジュールモジュール.
-----------------------------------------------------------------------------------
entity  SHA256_SCHEDULE is
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
        O_DATA      : --! @brief OUTPUT MESSAGE DATA :
                      out std_logic_vector(32*WORDS-1 downto 0);
        O_DONE      : --! @brief OUTPUT MESSAGE DONE :
                      out std_logic;
        O_VAL       : --! @brief OUTPUT MESSAGE VALID :
                      out std_logic;
        O_NUM       : --! @brief OUTPUT MESSAGE NUMBER :
                      out integer range 0 to 63;
        K_NUM       : --! @brief OUTPUT MESSAGE NUMBER :
                      out integer range 0 to 63
    );
end SHA256_SCHEDULE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA256_SCHEDULE is
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS       : integer := 32;
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
    -- 各種内部信号.
    -------------------------------------------------------------------------------
    signal    state_count     : integer range 0 to 63;
    signal    input_state     : boolean;
    signal    calc_state      : boolean;
    signal    last_state      : boolean;
    signal    valid           : std_logic;
    signal    done            : std_logic;
    -------------------------------------------------------------------------------
    -- ローテート演算関数.
    -------------------------------------------------------------------------------
    function  ROR(X:WORD_TYPE;N:integer) return WORD_TYPE is
    begin
        return X(WORD_TYPE'low+N-1 downto WORD_TYPE'low  ) &
               X(WORD_TYPE'high    downto WORD_TYPE'low+N)
    end function;
    -------------------------------------------------------------------------------
    -- シフト演算関数.
    -------------------------------------------------------------------------------
    function  SHR(X:WORD_TYPE;N:integer) return WORD_TYPE is
    begin
        return  (WORD_TYPE'low+N-1 downto WORD_TYPE'low => '0') & 
               X(WORD_TYPE'high    downto WORD_TYPE'low+N);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function W(W2,W7,W15,W16:WORD_TYPE) return WORD_TYPE is
    begin
        return std_logic_vector(
            unsigned(ROR(W2,17) xor ROR(W2 ,19) xor SHR(W2,10)) +
            unsigned(W7) +
            unsigned(ROR(W15,7) xor ROR(W15,18) xor SHR(W15,3)) +
            unsigned(W16)
        );
    end function;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    word_work(0 to 15) <= word_regs(0 to 15);
    WGEN: for i in 0 to WORDS-1 generate
        word_work(16+i) <= I_DATA(WORD_BITS*(i+1)-1 downto WORD_BITS*i) when (input_state) else
                           W(W2  => word_work(16+i- 2),
                             W7  => word_work(16+i- 7),
                             W15 => word_work(16+i-15),
                             W16 => word_work(16+i-16));
    end generate;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                word_regs <= (others => WORD_NULL);
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                word_regs <= (others => WORD_NULL);
            elsif (valid = '1') then
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
            if    (CLR = '1' or last_state) then
                state_count <= 0;
            elsif (valid = '1') then
                state_count <= state_count + WORDS;
            end if;
        end if;
    end process;
    input_state <= (state_count <  16 );
    calc_state  <= (state_count >= 16 and state_count < 64);
    last_state  <= (state_count  = 64-WORDS);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                done   <= '0';
                O_VAL  <= '0';
                O_DONE <= '0';
                O_NUM  <=  0 ;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                done   <= '0';
                O_VAL  <= '0';
                O_DONE <= '0';
                O_NUM  <=  0 ;
            else
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
                O_NUM <= state_count;
            end if;
        end if;
    end process;
    K_NUM <= state_count;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    O_DATA_GEN: for i in 0 to WORDS-1 generate
        O_DATA(WORD_BITS*(i+1)-1 downto WORD_BITS*i) <= word_regs(16-WORDS+i);
    end generate;
end RTL;
