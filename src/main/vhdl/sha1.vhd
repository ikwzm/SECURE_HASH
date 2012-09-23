-----------------------------------------------------------------------------------
--!     @file    sha1.vhd
--!     @brief   SHA1 MODULE :
--!     @version 0.0.1
--!     @date    2012/9/21
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
--! @brief   SHA1_STAGE2 :
--!          SHA1の計算.
-----------------------------------------------------------------------------------
entity  SHA1 is
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
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT WORD DATA :
                      out std_logic_vector(159 downto 0);
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      out std_logic
    );
end SHA1;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA1 is
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    in_word   : std_logic_vector(32*WORDS-1 downto 0);
    signal    in_done   : std_logic;
    signal    in_valid  : std_logic;
    signal    in_ready  : std_logic;
    signal    word_data : std_logic_vector(32*WORDS-1 downto 0);
    signal    word_done : std_logic;
    signal    word_valid: std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component SHA1_INPUT
        generic (
            SYMBOL_BITS : integer := 8;
            SYMBOLS     : integer := 4;
            REVERSE     : integer := 1;
            WORDS       : integer := 1
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
            O_DATA      : out std_logic_vector(32*WORDS-1 downto 0);
            O_DONE      : out std_logic;
            O_VAL       : out std_logic;
            O_RDY       : in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component SHA1_STAGE1
        generic (
            WORDS       : integer := 1
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            I_DATA      : in  std_logic_vector(32*WORDS-1 downto 0);
            I_DONE      : in  std_logic;
            I_VAL       : in  std_logic;
            I_RDY       : out std_logic;
            O_DATA      : out std_logic_vector(32*WORDS-1 downto 0);
            O_DONE      : out std_logic;
            O_VAL       : out std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component SHA1_STAGE2
        generic (
            WORDS       : integer := 1
        );
        port (
            CLK         : in  std_logic; 
            RST         : in  std_logic;
            CLR         : in  std_logic;
            I_DATA      : in  std_logic_vector(32*WORDS-1 downto 0);
            I_DONE      : in  std_logic;
            I_VAL       : in  std_logic;
            O_DATA      : out std_logic_vector(159 downto 0);
            O_VAL       : out std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    INPUT: SHA1_INPUT 
        generic map(
            SYMBOL_BITS => SYMBOL_BITS,
            SYMBOLS     => SYMBOLS,
            REVERSE     => REVERSE,
            WORDS       => WORDS
        )
        port map (
            CLK         => CLK         , -- In  :
            RST         => RST         , -- In  :
            CLR         => CLR         , -- In  :
            I_DATA      => I_DATA      , -- In  :
            I_ENA       => I_ENA       , -- In  :
            I_DONE      => I_DONE      , -- In  :
            I_LAST      => I_LAST      , -- In  :
            I_VAL       => I_VAL       , -- In  :
            I_RDY       => I_RDY       , -- Out :
            O_DATA      => in_word     , -- Out :
            O_DONE      => in_done     , -- Out :
            O_VAL       => in_valid    , -- Out :
            O_RDY       => in_ready      -- In  :
        );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    STAGE1: SHA1_STAGE1
        generic map (
            WORDS       => WORDS
        )
        port map (
            CLK         => CLK         , -- In  :
            RST         => RST         , -- In  :
            CLR         => CLR         , -- In  :
            I_DATA      => in_word     , -- In  :
            I_DONE      => in_done     , -- In  :
            I_VAL       => in_valid    , -- In  :
            I_RDY       => in_ready    , -- Out :
            O_DATA      => word_data   , -- Out :
            O_DONE      => word_done   , -- Out :
            O_VAL       => word_valid    -- Out :
        );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    STAGE2: SHA1_STAGE2
        generic map (
            WORDS       => WORDS
        )
        port map (
            CLK         => CLK         , -- In  :
            RST         => RST         , -- In  :
            CLR         => CLR         , -- In  :
            I_DATA      => word_data   , -- In  :
            I_DONE      => word_done   , -- In  :
            I_VAL       => word_valid  , -- In  :
            O_DATA      => O_DATA      , -- Out :
            O_VAL       => O_VAL         -- Out :
        );
end RTL;
