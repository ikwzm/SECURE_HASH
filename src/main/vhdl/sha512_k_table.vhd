-----------------------------------------------------------------------------------
--!     @file    sha512_k_table.vhd
--!     @brief   SHA-512 Calculation K Table
--!              SHA-512 K TABLE
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
--! @brief   SHA512_K_TABLE :
--!          SHA-512用K(t)テーブル.
-----------------------------------------------------------------------------------
entity  SHA512_K_TABLE is
    generic (
        WORDS       : integer := 1
    );
    port (
        CLK         : in  std_logic;
        RST         : in  std_logic;
        T           : in  integer range 0 to 79;
        K           : out std_logic_vector(64*WORDS-1 downto 0)
    );
end SHA512_K_TABLE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA512_K_TABLE is
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS       : integer := 64;
    -------------------------------------------------------------------------------
    -- K[t]の型定義.
    -------------------------------------------------------------------------------
    subtype   WORD_TYPE      is std_logic_vector(WORD_BITS-1 downto 0);
    type      WORD_VECTOR    is array (INTEGER range <>) of WORD_TYPE;
    constant  WORD_NULL       : WORD_TYPE := (others => '0');
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  K_TABLE         : WORD_VECTOR(0 to 79) := (
        0  => To_StdLogicVector(bit_vector'(X"428a2f98d728ae22")),
        1  => To_StdLogicVector(bit_vector'(X"7137449123ef65cd")),
        2  => To_StdLogicVector(bit_vector'(X"b5c0fbcfec4d3b2f")),
        3  => To_StdLogicVector(bit_vector'(X"e9b5dba58189dbbc")),
        4  => To_StdLogicVector(bit_vector'(X"3956c25bf348b538")),
        5  => To_StdLogicVector(bit_vector'(X"59f111f1b605d019")),
        6  => To_StdLogicVector(bit_vector'(X"923f82a4af194f9b")),
        7  => To_StdLogicVector(bit_vector'(X"ab1c5ed5da6d8118")),
        8  => To_StdLogicVector(bit_vector'(X"d807aa98a3030242")),
        9  => To_StdLogicVector(bit_vector'(X"12835b0145706fbe")),
       10  => To_StdLogicVector(bit_vector'(X"243185be4ee4b28c")),
       11  => To_StdLogicVector(bit_vector'(X"550c7dc3d5ffb4e2")),
       12  => To_StdLogicVector(bit_vector'(X"72be5d74f27b896f")),
       13  => To_StdLogicVector(bit_vector'(X"80deb1fe3b1696b1")),
       14  => To_StdLogicVector(bit_vector'(X"9bdc06a725c71235")),
       15  => To_StdLogicVector(bit_vector'(X"c19bf174cf692694")),
       16  => To_StdLogicVector(bit_vector'(X"e49b69c19ef14ad2")),
       17  => To_StdLogicVector(bit_vector'(X"efbe4786384f25e3")),
       18  => To_StdLogicVector(bit_vector'(X"0fc19dc68b8cd5b5")),
       19  => To_StdLogicVector(bit_vector'(X"240ca1cc77ac9c65")),
       20  => To_StdLogicVector(bit_vector'(X"2de92c6f592b0275")),
       21  => To_StdLogicVector(bit_vector'(X"4a7484aa6ea6e483")),
       22  => To_StdLogicVector(bit_vector'(X"5cb0a9dcbd41fbd4")),
       23  => To_StdLogicVector(bit_vector'(X"76f988da831153b5")),
       24  => To_StdLogicVector(bit_vector'(X"983e5152ee66dfab")),
       25  => To_StdLogicVector(bit_vector'(X"a831c66d2db43210")),
       26  => To_StdLogicVector(bit_vector'(X"b00327c898fb213f")),
       27  => To_StdLogicVector(bit_vector'(X"bf597fc7beef0ee4")),
       28  => To_StdLogicVector(bit_vector'(X"c6e00bf33da88fc2")),
       29  => To_StdLogicVector(bit_vector'(X"d5a79147930aa725")),
       30  => To_StdLogicVector(bit_vector'(X"06ca6351e003826f")),
       31  => To_StdLogicVector(bit_vector'(X"142929670a0e6e70")),
       32  => To_StdLogicVector(bit_vector'(X"27b70a8546d22ffc")),
       33  => To_StdLogicVector(bit_vector'(X"2e1b21385c26c926")),
       34  => To_StdLogicVector(bit_vector'(X"4d2c6dfc5ac42aed")),
       35  => To_StdLogicVector(bit_vector'(X"53380d139d95b3df")),
       36  => To_StdLogicVector(bit_vector'(X"650a73548baf63de")),
       37  => To_StdLogicVector(bit_vector'(X"766a0abb3c77b2a8")),
       38  => To_StdLogicVector(bit_vector'(X"81c2c92e47edaee6")),
       39  => To_StdLogicVector(bit_vector'(X"92722c851482353b")),
       40  => To_StdLogicVector(bit_vector'(X"a2bfe8a14cf10364")),
       41  => To_StdLogicVector(bit_vector'(X"a81a664bbc423001")),
       42  => To_StdLogicVector(bit_vector'(X"c24b8b70d0f89791")),
       43  => To_StdLogicVector(bit_vector'(X"c76c51a30654be30")),
       44  => To_StdLogicVector(bit_vector'(X"d192e819d6ef5218")),
       45  => To_StdLogicVector(bit_vector'(X"d69906245565a910")),
       46  => To_StdLogicVector(bit_vector'(X"f40e35855771202a")),
       47  => To_StdLogicVector(bit_vector'(X"106aa07032bbd1b8")),
       48  => To_StdLogicVector(bit_vector'(X"19a4c116b8d2d0c8")),
       49  => To_StdLogicVector(bit_vector'(X"1e376c085141ab53")),
       50  => To_StdLogicVector(bit_vector'(X"2748774cdf8eeb99")),
       51  => To_StdLogicVector(bit_vector'(X"34b0bcb5e19b48a8")),
       52  => To_StdLogicVector(bit_vector'(X"391c0cb3c5c95a63")),
       53  => To_StdLogicVector(bit_vector'(X"4ed8aa4ae3418acb")),
       54  => To_StdLogicVector(bit_vector'(X"5b9cca4f7763e373")),
       55  => To_StdLogicVector(bit_vector'(X"682e6ff3d6b2b8a3")),
       56  => To_StdLogicVector(bit_vector'(X"748f82ee5defb2fc")),
       57  => To_StdLogicVector(bit_vector'(X"78a5636f43172f60")),
       58  => To_StdLogicVector(bit_vector'(X"84c87814a1f0ab72")),
       59  => To_StdLogicVector(bit_vector'(X"8cc702081a6439ec")),
       60  => To_StdLogicVector(bit_vector'(X"90befffa23631e28")),
       61  => To_StdLogicVector(bit_vector'(X"a4506cebde82bde9")),
       62  => To_StdLogicVector(bit_vector'(X"bef9a3f7b2c67915")),
       63  => To_StdLogicVector(bit_vector'(X"c67178f2e372532b")),
       64  => To_StdLogicVector(bit_vector'(X"ca273eceea26619c")),
       65  => To_StdLogicVector(bit_vector'(X"d186b8c721c0c207")),
       66  => To_StdLogicVector(bit_vector'(X"eada7dd6cde0eb1e")),
       67  => To_StdLogicVector(bit_vector'(X"f57d4f7fee6ed178")),
       68  => To_StdLogicVector(bit_vector'(X"06f067aa72176fba")),
       69  => To_StdLogicVector(bit_vector'(X"0a637dc5a2c898a6")),
       70  => To_StdLogicVector(bit_vector'(X"113f9804bef90dae")),
       71  => To_StdLogicVector(bit_vector'(X"1b710b35131c471b")),
       72  => To_StdLogicVector(bit_vector'(X"28db77f523047d84")),
       73  => To_StdLogicVector(bit_vector'(X"32caab7b40c72493")),
       74  => To_StdLogicVector(bit_vector'(X"3c9ebe0a15c9bebc")),
       75  => To_StdLogicVector(bit_vector'(X"431d67c49c100d4c")),
       76  => To_StdLogicVector(bit_vector'(X"4cc5d4becb3e42b6")),
       77  => To_StdLogicVector(bit_vector'(X"597f299cfc657e2a")),
       78  => To_StdLogicVector(bit_vector'(X"5fcb6fab3ad6faec")),
       79  => To_StdLogicVector(bit_vector'(X"6c44198c4a475817"))
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
