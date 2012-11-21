-----------------------------------------------------------------------------------
--!     @file    sha1.vhd
--!     @brief   SHA-1 Package :
--!              SHA-1用各種定義パッケージ.
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
--! @brief SHA-1用各種定義パッケージ.
-----------------------------------------------------------------------------------
package SHA1 is
    -------------------------------------------------------------------------------
    -- ハッシュのビット数
    -------------------------------------------------------------------------------
    constant  HASH_BITS : integer := 160;
    -------------------------------------------------------------------------------
    -- １ワードのビット数
    -------------------------------------------------------------------------------
    constant  WORD_BITS : integer := 32;
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
    constant  H0_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"67452301"));
    constant  H1_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"EFCDAB89"));
    constant  H2_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"98BADCFE"));
    constant  H3_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"10325476"));
    constant  H4_INIT   : WORD_TYPE := To_StdLogicVector(bit_vector'(X"C3D2E1F0"));
    -------------------------------------------------------------------------------
    -- K[t]の値
    -------------------------------------------------------------------------------
    constant  K0        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"5A827999"));
    constant  K1        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"6ED9EBA1"));
    constant  K2        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"8F1BBCDC"));
    constant  K3        : WORD_TYPE := To_StdLogicVector(bit_vector'(X"CA62C1D6"));
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  RotL(X:WORD_TYPE;N:integer) return std_logic_vector;
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
    -- SHA1_COREのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA1_CORE
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
    -- SHA1_PROCのコンポーネント宣言
    -------------------------------------------------------------------------------
    component SHA1_PROC
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
end SHA1;
-----------------------------------------------------------------------------------
--! @brief SHA-1用各種プロシージャの定義.
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
package body SHA1 is
    -------------------------------------------------------------------------------
    -- ローテート演算関数.
    -------------------------------------------------------------------------------
    function  RotL(X:WORD_TYPE;N:integer) return std_logic_vector is
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
end SHA1;
