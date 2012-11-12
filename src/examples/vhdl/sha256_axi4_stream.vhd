-----------------------------------------------------------------------------------
--!     @file    sha256_axi4_stream.vhd
--!     @brief   SHA-256 AXI4-Stream Wrapper
--!     @version 0.8.0
--!     @date    2012/11/13
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
--! @brief   SHA-256 AXI4-Stream Wrapper
-----------------------------------------------------------------------------------
entity  SHA256_AXI4_STREAM is
    generic (
        I_BYTES     : --! @brief INPUT SYMBOL SIZE :
                      --! 入力データのビット幅をバイト単位でを指定する.
                      integer := 4;
        O_BYTES     : --! @brief OUTPUT SYMBOL SIZE :
                      --! 出力データのビット幅をバイト単位でを指定する.
                      integer := 4;
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
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        ACLK        : --! @brief CLOCK :
                      --! クロック信号
                      in  std_logic; 
        ARESETn     : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA      : --! @brief INPUT DATA :
                      in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_STRB      : --! @brief INPUT DATA STROBE :
                      in  std_logic_vector(  I_BYTES-1 downto 0);
        I_LAST      : --! @brief INPUT DATA LAST :
                      in  std_logic;
        I_VALID     : --! @brief INPUT DATA VALID :
                      in  std_logic;
        I_READY     : --! @brief INPUT DATA READY :
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT DATA DATA :
                      out std_logic_vector(8*O_BYTES-1 downto 0);
        O_STRB      : --! @brief OUTPUT DATA STROBE :
                      out std_logic_vector(  O_BYTES-1 downto 0);
        O_LAST      : --! @brief OUTPUT DATA LAST :
                      out std_logic;
        O_VALID     : --! @brief OUTPUT WORD VALID :
                      out std_logic;
        O_READY     : --! @brief OUTPUT WORD READY :
                      in  std_logic
    );
end SHA256_AXI4_STREAM;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.COMPONENTS.REDUCER;
use     PipeWork.SHA256.SHA256_CORE;
use     PipeWork.SHA256.HASH_BITS;
architecture RTL of SHA256_AXI4_STREAM is
    constant BYTE_BITS : integer   := 8;
    constant WORD_BITS : integer   := 32;
    constant HASH_BYTES: integer   := (HASH_BITS/BYTE_BITS);
    constant O_WIDTH   : integer   := (BYTE_BITS*O_BYTES)/WORD_BITS;
    signal   reset     : std_logic;
    constant clear     : std_logic := '0';
    constant i_done    : std_logic := '0';
    constant o_start   : std_logic := '0';
    constant o_done    : std_logic := '0';
    constant o_flush   : std_logic := '0';
    constant o_offset  : std_logic_vector(O_WIDTH   -1 downto 0) := (others => '0');
    constant d_strobe  : std_logic_vector(HASH_BYTES-1 downto 0) := (others => '1');
    signal   d_hash    : std_logic_vector(HASH_BITS -1 downto 0);
    signal   d_word    : std_logic_vector(HASH_BITS -1 downto 0);
    signal   d_valid   : std_logic;
    signal   d_ready   : std_logic;
begin
    reset <= '1' when (ARESETn = '0') else '0';
    -------------------------------------------------------------------------------
    -- SHA256_CORE
    -------------------------------------------------------------------------------
    CORE: SHA256_CORE
        generic map(                              --
            SYMBOL_BITS => BYTE_BITS            , --
            SYMBOLS     => I_BYTES              , --
            REVERSE     => 1                    , --
            WORDS       => WORDS                , --
            BLOCK_GAP   => BLOCK_GAP              --
        )                                         --
        port map (                                --
            CLK         => ACLK                 , -- In  :
            RST         => reset                , -- In  :
            CLR         => clear                , -- In  :
            I_DATA      => I_DATA               , -- In  :
            I_ENA       => I_STRB               , -- In  :
            I_DONE      => i_done               , -- In  :
            I_LAST      => I_LAST               , -- In  :
            I_VAL       => I_VALID              , -- In  :
            I_RDY       => I_READY              , -- Out :
            O_DATA      => d_hash               , -- Out :
            O_VAL       => d_valid              , -- Out :
            O_RDY       => d_ready                -- In  :
        );
    -------------------------------------------------------------------------------
    -- MSB->LSBに変換.
    -------------------------------------------------------------------------------
    REVS: for i in 0 to HASH_BYTES-1 generate
        d_word(BYTE_BITS*(i+1)-1 downto BYTE_BITS*i) <=
            d_hash(BYTE_BITS*(HASH_BYTES-1-i+1)-1 downto BYTE_BITS*(HASH_BYTES-1-i));
    end generate;
    -------------------------------------------------------------------------------
    -- 入力バッファ.
    -------------------------------------------------------------------------------
    O_BUF: REDUCER 
        generic map (
            WORD_BITS   => WORD_BITS            , -- シンボルのビット数を指定.
            ENBL_BITS   => WORD_BITS/BYTE_BITS  , -- I_ENAはシンボル毎に4ビット.
            I_WIDTH     => HASH_BITS/WORD_BITS  , -- 入力側のシンボル数.
            O_WIDTH     => O_WIDTH              , -- 出力側のシンボル数.
            QUEUE_SIZE  => 0                    ,
            VALID_MIN   => 0                    , -- ibuf_word_validの範囲の最小値.
            VALID_MAX   => 0                    , -- ibuf_word_validの範囲の最大値.
            I_JUSTIFIED => 1                    , -- 入力シンボルはLSB側に詰められている.
            FLUSH_ENABLE=> 0                      -- FLUSHは未使用にする.
        )
        port map (
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK         => ACLK                 , -- In  : クロック.
            RST         => reset                , -- In  : 非同期リセット.
            CLR         => clear                , -- In  : 同期リセット.
        ---------------------------------------------------------------------------
        -- 各種制御信号
        ---------------------------------------------------------------------------
            START       => o_start              , -- In  : 未使用のため'0'に固定.
            OFFSET      => o_offset             , -- In  : 未使用のためALL'0'に固定.
            DONE        => o_done               , -- In  : 未使用のため'0'に固定.
            FLUSH       => o_flush              , -- In  : 未使用のため'0'に固定.
            BUSY        => open                 , -- Out : 未使用のためオープン.
            VALID       => open                 , -- Out : 未使用のためオープン.
        ---------------------------------------------------------------------------
        -- 入力側 I/F
        ---------------------------------------------------------------------------
            I_DATA      => d_word               , -- In  : 入力データ.
            I_ENBL      => d_strobe             , -- In  :
            I_DONE      => d_valid              , -- In  :
            I_FLUSH     => o_flush              , -- In  : 未使用のため'0'に固定.
            I_VAL       => d_valid              , -- In  :
            I_RDY       => d_ready              , -- Out : 
        ---------------------------------------------------------------------------
        -- 出力側 I/F
        ---------------------------------------------------------------------------
            O_DATA      => O_DATA               , -- Out : 出力データ.
            O_ENBL      => O_STRB               , -- Out : 出力データストローブ.
            O_DONE      => O_LAST               , -- Out : 最終データ出力.
            O_FLUSH     => open                 , -- Out : 未使用のためオープン.
            O_VAL       => O_VALID              , -- Out : 出力データ有効信号.
            O_RDY       => O_READY                -- In  : 出力データ応答信号.
        );
end RTL;
