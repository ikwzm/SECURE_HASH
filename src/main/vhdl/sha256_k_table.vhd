-----------------------------------------------------------------------------------
--!     @file    sha256_k_table.vhd
--!     @brief   SHA-256 Calculation K Table
--!              SHA-256 K TABLE
--!     @version 0.2.0
--!     @date    2012/9/28
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
        T           : in  integer range 0 to 63;
        K           : out std_logic_vector(32*WORDS-1 downto 0)
    );
end SHA256_K_TABLE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA256_K_TABLE is
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS       : integer := 32;
    -------------------------------------------------------------------------------
    -- K[t]の型定義.
    -------------------------------------------------------------------------------
    subtype   WORD_TYPE      is std_logic_vector(WORD_BITS-1 downto 0);
    type      WORD_VECTOR    is array (INTEGER range <>) of WORD_TYPE;
    constant  WORD_NULL       : WORD_TYPE := (others => '0');
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  K_TABLE         : WORD_VECTOR(0 to 63) := (
        0  => To_StdLogicVector(bit_vector'(X"428a2f98")),
        1  => To_StdLogicVector(bit_vector'(X"71374491")),
        2  => To_StdLogicVector(bit_vector'(X"b5c0fbcf")),
        3  => To_StdLogicVector(bit_vector'(X"e9b5dba5")),
        4  => To_StdLogicVector(bit_vector'(X"3956c25b")),
        5  => To_StdLogicVector(bit_vector'(X"59f111f1")),
        6  => To_StdLogicVector(bit_vector'(X"923f82a4")),
        7  => To_StdLogicVector(bit_vector'(X"ab1c5ed5")),
        8  => To_StdLogicVector(bit_vector'(X"d807aa98")),
        9  => To_StdLogicVector(bit_vector'(X"12835b01")),
       10  => To_StdLogicVector(bit_vector'(X"243185be")),
       11  => To_StdLogicVector(bit_vector'(X"550c7dc3")),
       12  => To_StdLogicVector(bit_vector'(X"72be5d74")),
       13  => To_StdLogicVector(bit_vector'(X"80deb1fe")),
       14  => To_StdLogicVector(bit_vector'(X"9bdc06a7")),
       15  => To_StdLogicVector(bit_vector'(X"c19bf174")),
       16  => To_StdLogicVector(bit_vector'(X"e49b69c1")),
       17  => To_StdLogicVector(bit_vector'(X"efbe4786")),
       18  => To_StdLogicVector(bit_vector'(X"0fc19dc6")),
       19  => To_StdLogicVector(bit_vector'(X"240ca1cc")),
       20  => To_StdLogicVector(bit_vector'(X"2de92c6f")),
       21  => To_StdLogicVector(bit_vector'(X"4a7484aa")),
       22  => To_StdLogicVector(bit_vector'(X"5cb0a9dc")),
       23  => To_StdLogicVector(bit_vector'(X"76f988da")),
       24  => To_StdLogicVector(bit_vector'(X"983e5152")),
       25  => To_StdLogicVector(bit_vector'(X"a831c66d")),
       26  => To_StdLogicVector(bit_vector'(X"b00327c8")),
       27  => To_StdLogicVector(bit_vector'(X"bf597fc7")),
       28  => To_StdLogicVector(bit_vector'(X"c6e00bf3")),
       29  => To_StdLogicVector(bit_vector'(X"d5a79147")),
       30  => To_StdLogicVector(bit_vector'(X"06ca6351")),
       31  => To_StdLogicVector(bit_vector'(X"14292967")),
       32  => To_StdLogicVector(bit_vector'(X"27b70a85")),
       33  => To_StdLogicVector(bit_vector'(X"2e1b2138")),
       34  => To_StdLogicVector(bit_vector'(X"4d2c6dfc")),
       35  => To_StdLogicVector(bit_vector'(X"53380d13")),
       36  => To_StdLogicVector(bit_vector'(X"650a7354")),
       37  => To_StdLogicVector(bit_vector'(X"766a0abb")),
       38  => To_StdLogicVector(bit_vector'(X"81c2c92e")),
       39  => To_StdLogicVector(bit_vector'(X"92722c85")),
       40  => To_StdLogicVector(bit_vector'(X"a2bfe8a1")),
       41  => To_StdLogicVector(bit_vector'(X"a81a664b")),
       42  => To_StdLogicVector(bit_vector'(X"c24b8b70")),
       43  => To_StdLogicVector(bit_vector'(X"c76c51a3")),
       44  => To_StdLogicVector(bit_vector'(X"d192e819")),
       45  => To_StdLogicVector(bit_vector'(X"d6990624")),
       46  => To_StdLogicVector(bit_vector'(X"f40e3585")),
       47  => To_StdLogicVector(bit_vector'(X"106aa070")),
       48  => To_StdLogicVector(bit_vector'(X"19a4c116")),
       49  => To_StdLogicVector(bit_vector'(X"1e376c08")),
       50  => To_StdLogicVector(bit_vector'(X"2748774c")),
       51  => To_StdLogicVector(bit_vector'(X"34b0bcb5")),
       52  => To_StdLogicVector(bit_vector'(X"391c0cb3")),
       53  => To_StdLogicVector(bit_vector'(X"4ed8aa4a")),
       54  => To_StdLogicVector(bit_vector'(X"5b9cca4f")),
       55  => To_StdLogicVector(bit_vector'(X"682e6ff3")),
       56  => To_StdLogicVector(bit_vector'(X"748f82ee")),
       57  => To_StdLogicVector(bit_vector'(X"78a5636f")),
       58  => To_StdLogicVector(bit_vector'(X"84c87814")),
       59  => To_StdLogicVector(bit_vector'(X"8cc70208")),
       60  => To_StdLogicVector(bit_vector'(X"90befffa")),
       61  => To_StdLogicVector(bit_vector'(X"a4506ceb")),
       62  => To_StdLogicVector(bit_vector'(X"bef9a3f7")),
       63  => To_StdLogicVector(bit_vector'(X"c67178f2"))
    );
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
