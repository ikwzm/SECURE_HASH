-----------------------------------------------------------------------------------
--!     @file    sha512.vhd
--!     @brief   SHA-512 Package :
--!              SHA-512用各種定義パッケージ.
--!     @version 0.9.0
--!     @date    2012/11/20
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
--! @brief SHA-512用各種定義パッケージ.
-----------------------------------------------------------------------------------
package SHA512 is
    -------------------------------------------------------------------------------
    -- ハッシュのビット数
    -------------------------------------------------------------------------------
    constant  HASH_BITS : integer := 512;
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
    -- K-Tableの初期値
    -------------------------------------------------------------------------------
    constant  K_TABLE         : WORD_VECTOR(0 to ROUNDS-1) := (
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
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Ch(B,C,D:WORD_TYPE) return std_logic_vector;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Parity(B,C,D:WORD_TYPE) return std_logic_vector;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Maj(B,C,D:WORD_TYPE) return std_logic_vector;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  SigmaA0(X:WORD_TYPE) return std_logic_vector;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  SigmaA1(X:WORD_TYPE) return std_logic_vector;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  SigmaB0(X:WORD_TYPE) return std_logic_vector;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  SigmaB1(X:WORD_TYPE) return std_logic_vector;
    -------------------------------------------------------------------------------
    --! @brief   SHA-512 計算コアモジュール.
    -------------------------------------------------------------------------------
    component SHA512_CORE 
        generic (
            SYMBOL_BITS : --! @brief INPUT SYMBOL BITS :
                          --! 入力データの１シンボルのビット数を指定する.
                          integer := 8;
            SYMBOLS     : --! @brief INPUT SYMBOL SIZE :
                          --! 入力データのシンボル数を指定する.
                          integer := 4;
            REVERSE     : --! @brief INPUT SYMBOL REVERSE :
                          --! 入力データのシンボルのビット並びを逆にするかどうかを指定する.
                          integer := 1;
            WORDS       : --! @brief WORD SIZE :
                          --! 一度に処理するワード数を指定する.
                          integer := 1;
            BLOCK_GAP   : --! @brief BLOCK GAP CYCLE :
                          --! １ブロック(16word)処理する毎に挿入するギャップのサイクル
                          --! 数を指定する.
                          --! サイクル数分だけスループットが落ちるが、動作周波数が上が
                          --! る可能性がある.
                          integer := 1
        );
        port (
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK         : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
            RST         : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
            CLR         : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
        ---------------------------------------------------------------------------
        -- 入力側 I/F
        ---------------------------------------------------------------------------
            I_DATA      : --! @brief INPUT SYMBOL DATA :
                          in  std_logic_vector(SYMBOL_BITS*SYMBOLS-1 downto 0);
            I_ENA       : --! @brief INPUT SYMBOL DATA ENABLE :
                          in  std_logic_vector(            SYMBOLS-1 downto 0);
            I_DONE      : --! @brief INPUT SYMBOL DATA DONE :
                          in  std_logic;
            I_LAST      : --! @brief INPUT SYMBOL DATA LAST :
                          in  std_logic;
            I_VAL       : --! @brief INPUT SYMBOL DATA VALID :
                          in  std_logic;
            I_RDY       : --! @brief INPUT SYMBOL DATA READY :
                          out std_logic;
        ---------------------------------------------------------------------------
        -- 出力側 I/F
        ---------------------------------------------------------------------------
            O_DATA      : --! @brief OUTPUT WORD DATA :
                          out std_logic_vector(HASH_BITS-1 downto 0);
            O_VAL       : --! @brief OUTPUT WORD VALID :
                          out std_logic;
            O_RDY       : --! @brief OUTPUT WORD READY :
                          in  std_logic
        );
    end component;
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
            O_VAL       : out std_logic;
            O_RDY       : in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- SHA_PRE_PROCのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA_PRE_PROC
        generic (
            WORD_BITS   : integer := 32;
            WORDS       : integer := 1;
            SYMBOL_BITS : integer := 8;
            SYMBOLS     : integer := 4;
            REVERSE     : integer := 1
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            I_DATA      : in  std_logic_vector(SYMBOL_BITS*SYMBOLS-1 downto 0);
            I_ENA       : in  std_logic_vector(            SYMBOLS-1 downto 0);
            I_DONE      : in  std_logic;
            I_LAST      : in  std_logic;
            I_VAL       : in  std_logic;
            I_RDY       : out std_logic;
            M_DATA      : out std_logic_vector(WORD_BITS*WORDS-1 downto 0);
            M_DONE      : out std_logic;
            M_VAL       : out std_logic;
            M_RDY       : in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- SHA512_PROC_SIMPLEのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA512_PROC_SIMPLE
        generic (
            WORDS       : integer := 1;
            PIPELINE    : integer := 1;
            BLOCK_GAP   : integer := 0
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            M_DATA      : in  std_logic_vector(WORD_BITS*WORDS-1 downto 0);
            M_DONE      : in  std_logic;
            M_VAL       : in  std_logic;
            M_RDY       : out std_logic;
            O_DATA      : out std_logic_vector(HASH_BITS-1 downto 0);
            O_VAL       : out std_logic;
            O_RDY       : in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- SHA512_PROC_PIPELINEのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA512_PROC_PIPELINE
        generic (
            WORDS       : integer := 1
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            M_DATA      : in  std_logic_vector(WORD_BITS*WORDS-1 downto 0);
            M_DONE      : in  std_logic;
            M_VAL       : in  std_logic;
            M_RDY       : out std_logic;
            O_DATA      : out std_logic_vector(HASH_BITS-1 downto 0);
            O_VAL       : out std_logic;
            O_RDY       : in  std_logic
        );
    end component;
end SHA512;
-----------------------------------------------------------------------------------
--! @brief SHA-512用各種プロシージャの定義.
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
package body SHA512 is
    -------------------------------------------------------------------------------
    -- ローテート演算関数.
    -------------------------------------------------------------------------------
    function  RotR(X:WORD_TYPE;N:integer) return WORD_TYPE is
    begin
        return WORD_TYPE'(X(WORD_TYPE'low+N-1 downto WORD_TYPE'low  ) &
                          X(WORD_TYPE'high    downto WORD_TYPE'low+N));
    end function;
    -------------------------------------------------------------------------------
    -- シフト演算関数.
    -------------------------------------------------------------------------------
    function  SftR(X:WORD_TYPE;N:integer) return WORD_TYPE is
    begin
        return WORD_TYPE'( (WORD_TYPE'low+N-1 downto WORD_TYPE'low => '0') & 
                          X(WORD_TYPE'high    downto WORD_TYPE'low+N));
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
end SHA512;
