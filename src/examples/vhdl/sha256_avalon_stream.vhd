-----------------------------------------------------------------------------------
--!     @file    sha256_avalon_stream.vhd
--!     @brief   SHA-256 Avalon-Stream Wrapper
--!     @version 0.8.0
--!     @date    2012/10/13
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
entity  SHA256_AVALON_STREAM is
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
                      integer := 0
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLOCK       : --! @brief CLOCK :
                      --! クロック信号
                      in  std_logic; 
        RESET_N     : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブロー.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA      : --! @brief INPUT DATA :
                      in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_SOP       : --! @brief INPUT START OF PACKET :
                      in  std_logic;
        I_EOP       : --! @brief INPUT END OF PACKET :
                      in  std_logic;
        I_EMPTY     : --! @brief INPUT EMPTY SYMBOL NUMBER :
                      in  std_logic_vector(3 downto 0);
        I_VALID     : --! @brief INPUT DATA VALID :
                      in  std_logic;
        I_READY     : --! @brief INPUT DATA READY :
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT DATA DATA :
                      out std_logic_vector(8*O_BYTES-1 downto 0);
        O_SOP       : --! @brief OUTPUT START OF PACKET :
                      out  std_logic;
        O_EOP       : --! @brief OUTPUT DATA LAST :
                      out std_logic;
        O_EMPTY     : --! @brief INPUT EMPTY SYMBOL NUMBER :
                      out std_logic_vector(3 downto 0);
        O_VALID     : --! @brief OUTPUT WORD VALID :
                      out std_logic;
        O_READY     : --! @brief OUTPUT WORD READY :
                      in  std_logic
    );
end SHA256_AVALON_STREAM;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA256_AVALON_STREAM is
    constant HASH_BITS : integer   := 256;
    constant BYTE_BITS : integer   := 8;
    constant WORD_BITS : integer   := 32;
    constant O_WIDTH   : integer   := (BYTE_BITS*O_BYTES)/WORD_BITS;
    signal   reset     : std_logic;
    constant clear     : std_logic := '0';
    constant in_done   : std_logic := '0';
    signal   in_data   : std_logic_vector(BYTE_BITS*I_BYTES-1 downto 0);
    signal   in_strb   : std_logic_vector(          I_BYTES-1 downto 0);
    constant o_start   : std_logic := '0';
    constant o_done    : std_logic := '0';
    constant o_flush   : std_logic := '0';
    constant o_offset  : std_logic_vector(O_WIDTH-1 downto 0) := (others => '0');
    signal   out_valid : std_logic;
    constant d_strobe  : std_logic_vector((HASH_BITS/BYTE_BITS)-1 downto 0) := (others => '1');
    signal   d_word    : std_logic_vector((HASH_BITS          )-1 downto 0);
    signal   d_valid   : std_logic;
    signal   d_ready   : std_logic;
    component SHA256_CORE
        generic (
            SYMBOL_BITS : integer := 8;
            SYMBOLS     : integer := 4;
            REVERSE     : integer := 1;
            WORDS       : integer := 1;
            BLOCK_GAP   : integer := 1
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
            O_DATA      : out std_logic_vector(HASH_BITS-1 downto 0);
            O_VAL       : out std_logic;
            O_RDY       : in  std_logic
        );
    end component;
    component REDUCER
        generic (
            WORD_BITS   : integer := 8;
            ENBL_BITS   : integer := 1;
            I_WIDTH     : integer := 4;
            O_WIDTH     : integer := 4;
            QUEUE_SIZE  : integer := 0;
            VALID_MIN   : integer := 0;
            VALID_MAX   : integer := 0;
            I_JUSTIFIED : integer := 0;
            FLUSH_ENABLE: integer := 1
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            START       : in  std_logic;
            OFFSET      : in  std_logic_vector(O_WIDTH-1 downto 0);
            DONE        : in  std_logic;
            FLUSH       : in  std_logic;
            BUSY        : out std_logic;
            VALID       : out std_logic_vector(VALID_MAX downto VALID_MIN);
            I_DATA      : in  std_logic_vector(I_WIDTH*WORD_BITS-1 downto 0);
            I_ENBL      : in  std_logic_vector(I_WIDTH*ENBL_BITS-1 downto 0);
            I_DONE      : in  std_logic;
            I_FLUSH     : in  std_logic;
            I_VAL       : in  std_logic;
            I_RDY       : out std_logic;
            O_DATA      : out std_logic_vector(O_WIDTH*WORD_BITS-1 downto 0);
            O_ENBL      : out std_logic_vector(O_WIDTH*ENBL_BITS-1 downto 0);
            O_DONE      : out std_logic;
            O_FLUSH     : out std_logic;
            O_VAL       : out std_logic;
            O_RDY       : in  std_logic
        );
    end component;
begin
    reset <= '1' when (RESET_N = '0') else '0';
    IN_GEN: for i in 0 to I_BYTES-1 generate
        in_data(BYTE_BITS*(i+1)-1 downto BYTE_BITS*i) <=
            I_DATA(BYTE_BITS*(I_BYTES-1-i+1)-1 downto BYTE_BITS*(I_BYTES-1-i));
        in_strb(i) <= '1' when (I_EOP = '0') or
                               (unsigned(TO_X01(I_EMPTY)) < (I_BYTES-i)) else '0';
    end generate;
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
            CLK         => CLOCK                , -- In  :
            RST         => reset                , -- In  :
            CLR         => clear                , -- In  :
            I_DATA      => in_data              , -- In  :
            I_ENA       => in_strb              , -- In  :
            I_DONE      => in_done              , -- In  :
            I_LAST      => I_EOP                , -- In  :
            I_VAL       => I_VALID              , -- In  :
            I_RDY       => I_READY              , -- Out :
            O_DATA      => d_word               , -- Out :
            O_VAL       => d_valid              , -- Out :
            O_RDY       => d_ready                -- In  :
        );
    -------------------------------------------------------------------------------
    -- 入力バッファ.
    -------------------------------------------------------------------------------
    O_BUF: REDUCER 
        generic map (
            WORD_BITS   => WORD_BITS            , -- シンボルのビット数を指定.
            ENBL_BITS   => WORD_BITS/BYTE_BITS  , -- I_ENAはシンボル毎に4ビット.
            I_WIDTH     => HASH_BITS/WORD_BITS  , -- 入力側のシンボル数.
            O_WIDTH     => O_WIDTH              , -- 出力側のシンボル数.
            QUEUE_SIZE  => 0                    , -- 
            VALID_MIN   => 0                    , -- ibuf_word_validの範囲の最小値.
            VALID_MAX   => 0                    , -- ibuf_word_validの範囲の最大値.
            I_JUSTIFIED => 1                    , -- 入力シンボルはLSB側に詰められている.
            FLUSH_ENABLE=> 0                      -- FLUSHは未使用にする.
        )
        port map (
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK         => CLOCK                , -- In  : クロック.
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
            O_ENBL      => open                 , -- Out : 出力データストローブ.
            O_DONE      => O_EOP                , -- Out : 最終データ出力.
            O_FLUSH     => open                 , -- Out : 未使用のためオープン.
            O_VAL       => out_valid            , -- Out : 出力データ有効信号.
            O_RDY       => O_READY                -- In  : 出力データ応答信号.
        );
    process(CLOCK, reset) begin
        if (reset = '1') then
            O_SOP <= '1';
        elsif (CLOCK'event and CLOCK = '1') then
            if    (d_valid = '1') then
                O_SOP <= '1';
            elsif (out_valid = '1' and O_READY = '1') then
                O_SOP <= '0';
            end if;
        end if;
    end process;
    O_VALID <= out_valid;
    O_EMPTY <= (others => '0');
end RTL;
