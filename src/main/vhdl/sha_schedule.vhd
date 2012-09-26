-----------------------------------------------------------------------------------
--!     @file    sha_schedule.vhd
--!     @brief   SHA-1/2 Prepare the Message Schedule Module.
--!              SHA-1/2 用スケジュールモジュール.
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
--! @brief   SHA_SCHEDULE :
--!          SHA-1/2用スケジュールモジュール.
-----------------------------------------------------------------------------------
entity  SHA_SCHEDULE is
    generic (
        WORD_BITS   : --! @brief SHA-1/2 WORD BITS :
                      --! １ワードのビット数を指定する.
                      --! * SHA-1/SHA-256の場合は32を設定する.
                      --! * SHA-512の場合は64を設定する.
                      integer := 32;
        WORDS       : --! @brief SHA-1/2 WORD SIZE :
                      --! １クロックで処理するワード数を指定する.
                      integer := 1;
        INPUT_NUM   : --! @brief INPUT END NUMBER :
                      integer := 16;
        CALC_NUM    : --! @brief CALC END NUMBER :
                      --! SHA-1では80, SHA-2では64
                      integer := 80;
        END_OF_NUM  : --! @brief END OF NUMBER :
                      --! 最後のスケジューリング番号を指定する.
                      --! SHA-1では80, SHA-2では64
                      integer := 80
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
        I_DONE      : --! @brief INPUT MESSAGE DONE  :
                      in  std_logic;
        I_VAL       : --! @brief INPUT MESSAGE VALID :
                      in  std_logic;
        I_RDY       : --! @brief INPUT MESSAGE READY :
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_INPUT     : --! @brief INPUT MESSAGE PHASE :
                     out std_logic;
        O_LAST      : --! @brief LAST WORD OF MESSAGE :
                      out std_logic;
        O_DONE      : --! @brief MESSAGE DONE :
                      out std_logic;
        O_VAL       : --! @brief OUTPUT MESSAGE VALID :
                      out std_logic;
        O_NUM       : --! @brief OUTPUT MESSAGE NUMBER :
                      out integer range 0 to END_OF_NUM-1
    );
end SHA_SCHEDULE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA_SCHEDULE is
    -------------------------------------------------------------------------------
    -- 各種内部信号.
    -------------------------------------------------------------------------------
    signal    state_count     : integer range 0 to END_OF_NUM-1;
    signal    input_state     : boolean;
    signal    calc_state      : boolean;
    signal    last_state      : boolean;
    signal    valid           : std_logic;
    signal    done            : std_logic;
begin
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
    input_state <= (state_count <  INPUT_NUM);
    calc_state  <= (state_count >= INPUT_NUM and state_count < CALC_NUM);
    last_state  <= (state_count  = END_OF_NUM-WORDS);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                done   <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                done   <= '0';
            elsif (input_state and I_VAL = '1' and I_DONE = '1') then
                done <= '1';
            elsif (last_state) then
                done <= '0';
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    O_VAL   <= valid;
    O_NUM   <= state_count;
    O_INPUT <= '1' when (input_state) else '0';
    O_LAST  <= '1' when (state_count = CALC_NUM-WORDS) else '0';
    O_DONE  <= '1' when (last_state and done = '1') else '0';
end RTL;
