-----------------------------------------------------------------------------------
--!     @file    sha256.vhd
--!     @brief   SHA-256 Package :
--!              SHA-256用各種定義パッケージ.
--!     @version 0.0.0
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
--! @brief SHA-256用各種定義パッケージ.
-----------------------------------------------------------------------------------
package SHA256 is
    -------------------------------------------------------------------------------
    -- ハッシュのビット数
    -------------------------------------------------------------------------------
    constant  HASH_BITS : integer := 256;
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS : integer := 32;
    -------------------------------------------------------------------------------
    -- ラウンド数
    -------------------------------------------------------------------------------
    constant  ROUNDS    : integer := 64;
    -------------------------------------------------------------------------------
    -- ワードの型宣言
    -------------------------------------------------------------------------------
    subtype   WORD_TYPE      is std_logic_vector(WORD_BITS-1 downto 0);
    type      WORD_VECTOR    is array (INTEGER range <>) of WORD_TYPE;
    constant  WORD_NULL : WORD_TYPE := (others => '0');
    -------------------------------------------------------------------------------
    -- ハッシュレジスタの初期値
    -------------------------------------------------------------------------------
    constant  H0_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"6A09E667"));
    constant  H1_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"BB67AE85"));
    constant  H2_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"3C6EF372"));
    constant  H3_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"A54FF53A"));
    constant  H4_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"510E527F"));
    constant  H5_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"9B05688C"));
    constant  H6_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"1F83D9AB"));
    constant  H7_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"5BE0CD19"));
    -------------------------------------------------------------------------------
    -- K-Tableの初期値
    -------------------------------------------------------------------------------
    constant  K_TABLE         : WORD_VECTOR(0 to ROUNDS-1) := (
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
    --! @brief   SHA-256 計算コアモジュール.
    -------------------------------------------------------------------------------
    component SHA256_CORE 
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
    component SHA256_K_TABLE is
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
    -- SHA_SCHEDULEのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA_SCHEDULE
        generic (
            WORD_BITS   : integer := WORD_BITS;
            WORDS       : integer := 1;
            INPUT_NUM   : integer := 16;
            CALC_NUM    : integer := ROUNDS;
            END_NUM     : integer := ROUNDS
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
    -- SHA256_PROC_SIMPLEのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA256_PROC_SIMPLE
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
    -- SHA256_PROC_PIPELINEのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA256_PROC_PIPELINE
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
end SHA256;
-----------------------------------------------------------------------------------
--! @brief SHA-256用各種プロシージャの定義.
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
package body SHA256 is
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
        return RotR(X, 2) xor RotR(X,13) xor RotR(X,22);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function SigmaA1(X:WORD_TYPE) return std_logic_vector is
    begin
        return RotR(X, 6) xor RotR(X,11) xor RotR(X,25);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function SigmaB0(X:WORD_TYPE) return std_logic_vector is
    begin
        return RotR(X,7) xor RotR(X,18) xor SftR(X,3);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function SigmaB1(X:WORD_TYPE) return std_logic_vector is
    begin
        return RotR(X,17) xor RotR(X,19) xor SftR(X,10);
    end function;
end SHA256;

