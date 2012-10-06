-----------------------------------------------------------------------------------
--!     @file    sha256_k_table.vhd
--!     @brief   SHA-256 Calculation K Table
--!              SHA-256 K TABLE
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
use     PipeWork.SHA256.ROUNDS;
-----------------------------------------------------------------------------------
--! @brief   SHA256_K_TABLE :
--!          SHA-256用K(t)テーブル.
-----------------------------------------------------------------------------------
entity  SHA256_K_TABLE is
    generic (
        WORDS       : integer := 1
    );
    port (
        CLK         : in  std_logic;
        RST         : in  std_logic;
        T           : in  integer range 0 to ROUNDS-1;
        K           : out std_logic_vector(WORD_BITS*WORDS-1 downto 0)
    );
end SHA256_K_TABLE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.SHA256.WORD_BITS;
use     PipeWork.SHA256.ROUNDS;
use     PipeWork.SHA256.K_TABLE;
architecture RTL of SHA256_K_TABLE is
begin
    process (CLK, RST) begin
        if (RST = '1') then
            K <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            for i in 0 to WORDS-1 loop
                K(WORD_BITS*(i+1)-1 downto WORD_BITS*i) <= K_TABLE(WORDS*(T/WORDS)+i);
            end loop;
        end if;
    end process;
end RTL;
