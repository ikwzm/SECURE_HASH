-----------------------------------------------------------------------------------
--!     @file    sha_pre_proc.vhd
--!     @brief   SHA1/2 PRE-PROCESSING MODULE :
--!              SHA1/2用プリプロセッシングモジュール.
--!     @version 0.0.2
--!     @date    2012/9/23
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
--! @brief   SHA_PRE_PROC :
--!          SHA1用入力モジュール.
--!          ブロック単位でのパディング、入力ビット数の付加等の処理を行う.
-----------------------------------------------------------------------------------
entity  SHA_PRE_PROC is
    generic (
        WORD_BITS   : --! @brief SHA-1/2 WORD BITS :
                      --! １ワードのビット数を指定する.
                      --! * SHA-1/SHA-256の場合は32を設定する.
                      --! * SHA-512の場合は64を設定する.
                      integer := 32;
        WORDS       : --! @brief SHA-1/2 WORD SIZE :
                      --! １クロックで処理するワード数を指定する.
                      integer := 1;
        SYMBOL_BITS : --! @brief INPUT SYMBOL BITS :
                      --! 入力データの１シンボルのビット数を指定する.
                      integer := 8;
        SYMBOLS     : --! @brief INPUT SYMBOL SIZE :
                      --! 入力データのシンボル数を指定する.
                      integer := 4;
        REVERSE     : --! @brief INPUT SYMBOL REVERSE :
                      --! 入力データのシンボルのビット並びを逆にするかどうかを指定する.
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
                      out std_logic_vector(WORD_BITS*WORDS-1 downto 0);
        O_DONE      : --! @brief OUTPUT WORD DONE :
                      out std_logic;
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      out std_logic;
        O_RDY       : --! @brief OUTPUT WORD READY :
                      in  std_logic
    );
end SHA_PRE_PROC;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.Components.REDUCER;
architecture RTL of SHA_PRE_PROC is
    -------------------------------------------------------------------------------
    -- １ブロックのビット数
    -------------------------------------------------------------------------------
    constant  BLOCK_BITS      : integer := 16*WORD_BITS;
    -------------------------------------------------------------------------------
    -- 出力側ワードデータのビット数
    -------------------------------------------------------------------------------
    constant  OUT_BITS        : integer := WORD_BITS*WORDS;
    -------------------------------------------------------------------------------
    -- 出力側ワードデータのシンボルの数(出力側データの総ビット数をシンボルのビット数で割った値)
    -------------------------------------------------------------------------------
    constant  OUT_SYMBOLS     : integer := OUT_BITS/SYMBOL_BITS;
    -------------------------------------------------------------------------------
    -- IBUFの入力側の信号達
    -------------------------------------------------------------------------------
    signal    in_symbol       : std_logic_vector(SYMBOL_BITS*SYMBOLS-1 downto 0);
    signal    in_ready        : std_logic;
    constant  in_flush        : std_logic := '0';
    -------------------------------------------------------------------------------
    -- IBUFの制御信号達
    -------------------------------------------------------------------------------
    constant  ibuf_start      : std_logic := '0';
    constant  ibuf_flush      : std_logic := '0';
    constant  ibuf_offset     : std_logic_vector(OUT_SYMBOLS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    -- IBUFの出力側の信号達
    -------------------------------------------------------------------------------
    signal    ibuf_word_data  : std_logic_vector(OUT_BITS   -1 downto 0);
    signal    ibuf_word_valid : std_logic_vector(OUT_SYMBOLS-1 downto 0);
    signal    ibuf_done       : std_logic;
    signal    ibuf_valid      : std_logic;
    signal    ibuf_ready      : std_logic;
    -------------------------------------------------------------------------------
    -- 入力したシンボルの総ビット数をカウントするカウンタ.
    -------------------------------------------------------------------------------
    signal    symbol_size     : std_logic_vector(2*WORD_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- ステートマシンの型宣言.
    -------------------------------------------------------------------------------
    type      STATE_TYPE    is (  INPUT_STATE  ,
                                  PADDING_STATE,
                                  LAST_STATE
                               );
    -------------------------------------------------------------------------------
    -- 各種内部状態信号.
    -------------------------------------------------------------------------------
    signal    curr_state      : STATE_TYPE;
    signal    next_state      : STATE_TYPE;
    signal    curr_delimiter  : std_logic_vector(0 downto 0);
    signal    next_delimiter  : std_logic_vector(0 downto 0);
    constant  MAX_OUT_SIZE    : integer := BLOCK_BITS/(OUT_BITS)-1;
    signal    remain_out_size : integer range 0 to MAX_OUT_SIZE;
    -------------------------------------------------------------------------------
    -- OBUFへの入力信号
    -------------------------------------------------------------------------------
    signal    out_word_data   : std_logic_vector(OUT_BITS-1 downto 0);
    signal    out_done        : std_logic;
    signal    out_valid       : std_logic;
    signal    out_ready       : std_logic;
    constant  out_flush       : std_logic := '0';
    constant  out_word_valid  : std_logic_vector(WORDS-1 downto 0) := (others => '1');
    -------------------------------------------------------------------------------
    -- OBUFの制御信号達
    -------------------------------------------------------------------------------
    constant  obuf_start      : std_logic := '0';
    constant  obuf_done       : std_logic := '0';
    constant  obuf_flush      : std_logic := '0';
    constant  obuf_offset     : std_logic_vector(WORDS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --! @brief ビットを逆順にする関数.
    -------------------------------------------------------------------------------
    function  REVERSE_BIT(ARG:std_logic_vector) return std_logic_vector is
        alias    i_vec : std_logic_vector(0     to ARG'length-1) is ARG;
        variable o_vec : std_logic_vector(ARG'length-1 downto 0);
    begin
        for i in o_vec'range loop
            o_vec(i) := i_vec(i);
        end loop;
        return o_vec;
    end function;
begin
    -------------------------------------------------------------------------------
    -- リバースの場合はシンボル内でビットの並びを逆順にする.
    -------------------------------------------------------------------------------
    SYM_REVERSE : if (REVERSE > 0) generate
        N_GEN: for i in 0 to SYMBOLS-1 generate
            in_symbol(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i) <=
                REVERSE_BIT(I_DATA(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i));
        end generate;
    end generate;
    -------------------------------------------------------------------------------
    -- ストレートの場合はシンボル内でビットの並びはそのまま.
    -------------------------------------------------------------------------------
    SYM_STRAIGHT: if (REVERSE = 0) generate
        in_symbol <= I_DATA;
    end generate;
    -------------------------------------------------------------------------------
    -- 入力バッファ.
    -------------------------------------------------------------------------------
    I_BUF: REDUCER 
        generic map (
            WORD_BITS   => SYMBOL_BITS          , -- シンボルのビット数を指定.
            ENBL_BITS   => 1                    , -- I_ENAはシンボル毎に1ビット.
            I_WIDTH     => SYMBOLS              , -- 入力側のシンボル数.
            O_WIDTH     => OUT_SYMBOLS          , -- 出力側のシンボル数.
            QUEUE_SIZE  => 0                    , -- キューのサイズはI_BUFにおまかせ.
            VALID_MIN   => ibuf_word_valid'low  , -- ibuf_word_validの範囲の最小値.
            VALID_MAX   => ibuf_word_valid'high , -- ibuf_word_validの範囲の最大値.
            I_JUSTIFIED => 0                    , -- 入力シンボルはLSB側に詰められているわけではない.
            FLUSH_ENABLE=> 0                      -- FLUSHは未使用にする.
        )
        port map (
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK         => CLK                  , -- In  : クロック.
            RST         => RST                  , -- In  : 非同期リセット.
            CLR         => CLR                  , -- In  : 同期リセット.
        ---------------------------------------------------------------------------
        -- 各種制御信号
        ---------------------------------------------------------------------------
            START       => ibuf_start           , -- In  : 未使用のため'0'に固定.
            OFFSET      => ibuf_offset          , -- In  : 未使用のためALL'0'に固定.
            DONE        => I_DONE               , -- In  : 
            FLUSH       => ibuf_flush           , -- In  : 未使用のため'0'に固定.
            BUSY        => open                 , -- Out : 未使用のためオープン.
            VALID       => ibuf_word_valid      , -- Out :
        ---------------------------------------------------------------------------
        -- 入力側 I/F
        ---------------------------------------------------------------------------
            I_DATA      => in_symbol            , -- In  : 入力データ.
            I_ENBL      => I_ENA                , -- In  :
            I_DONE      => I_LAST               , -- In  :
            I_FLUSH     => in_flush             , -- In  : 未使用のため'0'に固定.
            I_VAL       => I_VAL                , -- In  :
            I_RDY       => in_ready             , -- Out : 
        ---------------------------------------------------------------------------
        -- 出力側 I/F
        ---------------------------------------------------------------------------
            O_DATA      => ibuf_word_data       , -- Out : ワードデータ出力.
            O_ENBL      => open                 , -- Out : 未使用のためオープン.
            O_DONE      => ibuf_done            , -- Out :
            O_FLUSH     => open                 , -- Out : 未使用のためオープン.
            O_VAL       => ibuf_valid           , -- Out : ワードデータ有効信号.
            O_RDY       => ibuf_ready             -- In  : ワードデータ応答信号.
        );
    I_RDY <= in_ready when (curr_state = INPUT_STATE) else '0';
    -------------------------------------------------------------------------------
    -- 入力したシンボルの総ビット数をカウントするカウンタ.
    -------------------------------------------------------------------------------
    process (CLK, RST)
        subtype  SYMBOL_SIZE_TYPE  is integer range 0 to SYMBOLS*SYMBOL_BITS;
        subtype  SYMBOL_COUNT_TYPE is integer range 0 to SYMBOLS;
        function COUNT_BIT_1(ARG:std_logic_vector) return SYMBOL_COUNT_TYPE is
            alias    ENA : std_logic_vector(ARG'length-1 downto 0) is ARG;
        begin
            if    (ENA'length = 1) then
                if (ENA(0) = '1') then
                    return 1;
                else
                    return 0;
                end if;
            else
                return COUNT_BIT_1(ENA(ENA'high         downto (ENA'high+1)/2))
                     + COUNT_BIT_1(ENA((ENA'high+1)/2-1 downto ENA'low       ));
            end if;
        end function;
        variable in_size : SYMBOL_SIZE_TYPE;
    begin
        if    (RST = '1') then
                symbol_size <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if    (CLR = '1') or
                  (out_valid = '1' and out_ready = '1' and out_done = '1') then
                symbol_size <= (others => '0');
            elsif (I_VAL = '1' and in_ready = '1' and curr_state = INPUT_STATE) then
                in_size := COUNT_BIT_1(I_ENA) * SYMBOL_BITS;
                symbol_size <= std_logic_vector(unsigned(symbol_size) + in_size);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (curr_state,  remain_out_size, curr_delimiter, symbol_size, 
             ibuf_word_valid, ibuf_word_data, ibuf_valid, ibuf_done)
        variable prev_valid       : boolean;
        variable padding_done     : boolean;
        variable out_sym_size     : boolean;
        variable out_data         : std_logic_vector(OUT_BITS-1 downto 0);
        variable in_data          : std_logic_vector(OUT_BITS-1 downto 0);
        constant DELIMITER_SYMBOL : std_logic_vector(SYMBOL_BITS-1 downto 0) := (0 downto 0 => '1', others => '0');
        constant PADDING_SYMBOL   : std_logic_vector(SYMBOL_BITS-1 downto 0) := (others => '0');
    begin
        ---------------------------------------------------------------------------
        -- in_data      : INPUT_STATE時に出力するワードデータ.
        -- prev_valid   : ワードデータがすべて有効であることを示す.
        -- padding_done : パディング済みであることを示すフラグ.
        ---------------------------------------------------------------------------
        if (ibuf_done = '1') then
            prev_valid   := TRUE;
            padding_done := FALSE;
            out_sym_size := FALSE;
            for i in ibuf_word_valid'low to ibuf_word_valid'high loop
                if (WORDS > 2 and padding_done and ibuf_word_valid(i) = '0' and
                    ibuf_word_valid'high - i >= symbol_size'length/SYMBOL_BITS) then
                    out_sym_size := TRUE;
                end if;
                if (ibuf_word_valid(i) = '1') then
                    in_data(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i) :=
                        ibuf_word_data(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i);
                    prev_valid   := TRUE;
                    padding_done := FALSE;
                elsif (prev_valid and SYMBOL_BITS > 1) then
                    in_data(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i) := DELIMITER_SYMBOL;
                    prev_valid   := FALSE;
                    padding_done := TRUE;
                elsif (prev_valid and SYMBOL_BITS = 1) then
                    in_data(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i) := DELIMITER_SYMBOL;
                    prev_valid   := FALSE;
                    padding_done := FALSE;
                else
                    in_data(SYMBOL_BITS*(i+1)-1 downto SYMBOL_BITS*i) := PADDING_SYMBOL;
                    prev_valid   := FALSE;
                    padding_done := TRUE;
                end if;
            end loop;
        else
            in_data      := ibuf_word_data;
            prev_valid   := TRUE;
            padding_done := FALSE;
            out_sym_size := FALSE;
        end if;
        ---------------------------------------------------------------------------
        -- next_delimiter :
        ---------------------------------------------------------------------------
        if (curr_state = INPUT_STATE and i_done = '1' and prev_valid and SYMBOL_BITS > 0) then
            next_delimiter <= "1";
        else
            next_delimiter <= "0";
        end if;
        ---------------------------------------------------------------------------
        -- 出力側のワード数が１ワードの場合.
        ---------------------------------------------------------------------------
        if    (WORDS = 1) then
            case curr_state is
                when INPUT_STATE =>
                    out_data  := in_data;
                    out_done  <= '0';
                    out_valid <= ibuf_valid;
                    if (ibuf_done = '1') then
                        if (remain_out_size = 2 and padding_done) then
                            next_state <= LAST_STATE;
                        else
                            next_state <= PADDING_STATE;
                        end if;
                    else
                            next_state <= INPUT_STATE;
                    end if;
                when PADDING_STATE =>
                    out_data  := (out_data'high    downto 1 => '0') & curr_delimiter;
                    out_done  <= '0';
                    out_valid <= '1';
                    if (remain_out_size = 2) then
                        next_state <= LAST_STATE;
                    else
                        next_state <= PADDING_STATE;
                    end if;
                when LAST_STATE =>
                    if (remain_out_size = 1) then
                        out_data   := REVERSE_BIT(symbol_size(WORD_BITS*2-1 downto WORD_BITS));
                        out_done   <= '0';
                        out_valid  <= '1';
                        next_state <= LAST_STATE;
                    else
                        out_data   := REVERSE_BIT(symbol_size(WORD_BITS  -1 downto 0));
                        out_done   <= '1';
                        out_valid  <= '1';
                        next_state <= INPUT_STATE;
                    end if;
                when others =>
                    out_data   := ibuf_word_data;
                    out_done   <= '0';
                    out_valid  <= ibuf_valid;
                    next_state <= INPUT_STATE;
            end case;
        ---------------------------------------------------------------------------
        -- 出力側のワード数が２ワードの場合.
        ---------------------------------------------------------------------------
        elsif (WORDS = 2) then
            case curr_state is
                when INPUT_STATE =>
                    out_data  := in_data;
                    out_done  <= '0';
                    out_valid <= ibuf_valid;
                    if (i_done = '1') then
                        if (remain_out_size = 1 and padding_done) then
                            next_state <= LAST_STATE;
                        else
                            next_state <= PADDING_STATE;
                        end if;
                    else
                            next_state <= INPUT_STATE;
                    end if;
                when PADDING_STATE =>
                    out_data  := (out_data'high    downto 1 => '0') & curr_delimiter;
                    out_done  <= '0';
                    out_valid <= '1';
                    if (remain_out_size = 1) then
                        next_state <= LAST_STATE;
                    else
                        next_state <= PADDING_STATE;
                    end if;
                when LAST_STATE =>
                    out_data   := REVERSE_BIT(symbol_size(WORD_BITS*2-1 downto 0));
                    out_done   <= '1';
                    out_valid  <= '1';
                    next_state <= INPUT_STATE;
                when others =>
                    out_data   := ibuf_word_data;
                    out_done   <= '0';
                    out_valid  <= ibuf_valid;
                    next_state <= INPUT_STATE;
            end case;
        ---------------------------------------------------------------------------
        -- 出力側のワード数が３ワード以上場合.
        ---------------------------------------------------------------------------
        elsif (WORDS > 2) then
            case curr_state is
                when INPUT_STATE =>
                    if (ibuf_done = '1') then
                        if    (remain_out_size = 0 and out_sym_size) then
                            out_data   := REVERSE_BIT(symbol_size) & 
                                          in_data(out_data'high-symbol_size'length downto 0);
                            out_done   <= '1';
                            out_valid  <= ibuf_valid;
                            next_state <= INPUT_STATE;
                        elsif (remain_out_size = 1 and padding_done) then
                            out_data   := in_data;
                            out_done   <= '0';
                            out_valid  <= ibuf_valid;
                            next_state <= LAST_STATE;
                        else
                            out_data   := in_data;
                            out_done   <= '0';
                            out_valid  <= ibuf_valid;
                            next_state <= PADDING_STATE;
                        end if;
                    else
                            out_data   := in_data;
                            out_done   <= '0';
                            out_valid  <= ibuf_valid;
                            next_state <= INPUT_STATE;
                    end if;
                when PADDING_STATE =>
                    out_data  := (out_data'high     downto 1 => '0') & curr_delimiter;
                    out_done  <= '0';
                    out_valid <= '1';
                    if (remain_out_size = 1) then
                        next_state <= LAST_STATE;
                    else
                        next_state <= PADDING_STATE;
                    end if;
                when LAST_STATE =>
                    out_data   := REVERSE_BIT(symbol_size) & 
                                  (out_data'high-symbol_size'length downto 1 => '0') & curr_delimiter;
                    out_done   <= '1';
                    out_valid  <= '1';
                    next_state <= INPUT_STATE;
                when others =>
                    out_data   := ibuf_word_data;
                    out_done   <= '0';
                    out_valid  <= ibuf_valid;
                    next_state <= INPUT_STATE;
            end case;
        ---------------------------------------------------------------------------
        -- 出力側のワード数が０ワードの場合(あり得ないが一応).
        ---------------------------------------------------------------------------
        else
            out_data   := ibuf_word_data;
            out_done   <= '0';
            out_valid  <= ibuf_valid;
            next_state <= INPUT_STATE;
        end if;
        ---------------------------------------------------------------------------
        -- ワード毎にビットをひっくり返す.
        ---------------------------------------------------------------------------
        for i in 0 to WORDS-1 loop
            out_word_data(WORD_BITS*(i+1)-1 downto WORD_BITS*i) <=
                REVERSE_BIT(out_data(WORD_BITS*(i+1)-1 downto WORD_BITS*i));
        end loop;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    ibuf_ready <= '1' when (curr_state = INPUT_STATE and out_ready = '1') else '0';
    -------------------------------------------------------------------------------
    -- curr_state      : 現在の状態.
    -- curr_delimiter  : 現在のデリミタ出力フラグ.
    -- remain_out_size : 出力した数をカウントするカウンタ.
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if    (RST = '1') then
                curr_state      <= INPUT_STATE;
                curr_delimiter  <= "0";
                remain_out_size <= MAX_OUT_SIZE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state      <= INPUT_STATE;
                curr_delimiter  <= "0";
                remain_out_size <= MAX_OUT_SIZE;
            elsif (out_valid = '1' and out_ready = '1') then
                curr_state      <= next_state;
                curr_delimiter  <= next_delimiter;
                if (out_done = '1' or remain_out_size = 0) then
                    remain_out_size <= MAX_OUT_SIZE;
                else
                    remain_out_size <= remain_out_size - 1;
                end if;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 出力バッファ
    -------------------------------------------------------------------------------
    O_BUF: REDUCER 
        generic map (
            WORD_BITS   => WORD_BITS            , -- ワードのビット数を指定.
            ENBL_BITS   => 1                    , -- 
            I_WIDTH     => WORDS                , -- 入力側のワード数.
            O_WIDTH     => WORDS                , -- 出力側のワード数.
            QUEUE_SIZE  => 0                    , -- キューのサイズはO_BUFにおまかせ.
            VALID_MIN   => 0                    , -- VALIDは未使用だけどとりあえず.
            VALID_MAX   => 0                    , -- VALIDは未使用だけどとりあえず.
            I_JUSTIFIED => 1                    , -- 入力ワードはLSB側に詰められている.
            FLUSH_ENABLE=> 0                      -- FLUSHは未使用にする.
        )
        port map (
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK         => CLK                  , -- In  : クロック.
            RST         => RST                  , -- In  : 非同期リセット.
            CLR         => CLR                  , -- In  : 同期リセット.
        ---------------------------------------------------------------------------
        -- 各種制御信号
        ---------------------------------------------------------------------------
            START       => obuf_start           , -- In  : 未使用のため'0'に固定.
            OFFSET      => obuf_offset          , -- In  : 未使用のためALL'0'に固定.
            DONE        => obuf_done            , -- In  : 未使用のため'0'に固定.
            FLUSH       => obuf_flush           , -- In  : 未使用のため'0'に固定.
            BUSY        => open                 , -- Out : 未使用のためオープン.
            VALID       => open                 , -- Out : 未使用のためオープン.
        ---------------------------------------------------------------------------
        -- 入力側 I/F
        ---------------------------------------------------------------------------
            I_DATA      => out_word_data        , -- In  : 入力データ.
            I_ENBL      => out_word_valid       , -- In  : ALL'1'にしとく.
            I_DONE      => out_done             , -- In  :
            I_FLUSH     => out_flush            , -- In  : 未使用のため'0'に固定.
            I_VAL       => out_valid            , -- In  :
            I_RDY       => out_ready            , -- Out : 
        ---------------------------------------------------------------------------
        -- 出力側 I/F
        ---------------------------------------------------------------------------
            O_DATA      => O_DATA               , -- Out : ワードデータ出力.
            O_ENBL      => open                 , -- Out : 未使用のためオープン.
            O_DONE      => O_DONE               , -- Out :
            O_FLUSH     => open                 , -- Out : 未使用のためオープン.
            O_VAL       => O_VAL                , -- Out : 出力データ有効信号.
            O_RDY       => O_RDY                  -- In  : 出力データ許可信号.
        );
end RTL;
