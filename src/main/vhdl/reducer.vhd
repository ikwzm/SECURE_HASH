-----------------------------------------------------------------------------------
--!     @file    reducer.vhd
--!     @brief   REDUCER MODULE :
--!              異なるデータ幅のパスを継ぐためのアダプタ
--!     @version 1.0.0
--!     @date    2012/8/11
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
--! @brief   REDUCER :
--!          異なるデータ幅のパスを継ぐためのアダプタ.
--!        * REDUCER とは配管用語で径違い継ぎ手、つまり直径違う配管(パイプ)を接続
--!          するために用いる管継手のことです.
--!        * 論理回路の世界でも、ビット幅の異なるデータパスどうしを継ぐことが多い
--!          のでこのような汎用のアダプタを作って REDUCER という名前をつけました.
--!        * ちょっと汎用的に作りすぎたせいか、多少回路が冗長です.
--!          特にI_WIDTHが大きいとかなり大きな回路になってしまいます.
--!          例えば32bit入力64bit出力の場合、
--!          WORD_BITS=8 、ENBL_BITS=1、I_WIDTH=4、O_WIDTH=8 とするよりも、
--!          WORD_BITS=32、ENBL_BITS=4、I_WIDTH=1、O_WIDTH=2 としたほうが
--!          回路はコンパクトになります.
--!        * O_WIDTH>I_WIDTHの場合、最初のワードデータを出力する際のオフセットを
--!          設定できます. 詳細はOFFSETの項を参照.
-----------------------------------------------------------------------------------
entity  REDUCER is
    generic (
        WORD_BITS   : --! @brief WORD BITS :
                      --! １ワードのデータのビット数を指定する.
                      integer := 8;
        ENBL_BITS   : --! @brief ENABLE BITS :
                      --! ワードデータのうち有効なデータであることを示す信号の
                      --! ビット数を指定する.
                      integer := 1;
        I_WIDTH     : --! @brief INPUT WORD WIDTH :
                      --! 入力側のデータのワード数を指定する.
                      integer := 4;
        O_WIDTH     : --! @brief OUTPUT WORD WIDTH :
                      --! 出力側のデータのワード数を指定する.
                      integer := 4;
        QUEUE_SIZE  : --! @brief QUEUE SIZE :
                      --! キューの大きさをワード数で指定する.
                      --! * 少なくともキューの大きさは、I_WIDTH+O_WIDTH-1以上で
                      --!   なければならない.
                      --! * ただしQUEUE_SIZE=0を指定した場合は、キューの深さは
                      --!   自動的にI_WIDTH+O_WIDTH に設定される.
                      integer := 0;
        VALID_MIN   : --! @brief BUFFER VALID MINIMUM NUMBER :
                      --! VALID信号の配列の最小値を指定する.
                      integer := 0;
        VALID_MAX   : --! @brief BUFFER VALID MAXIMUM NUMBER :
                      --! VALID信号の配列の最大値を指定する.
                      integer := 0;
        I_JUSTIFIED : --! @brief INPUT WORD JUSTIFIED :
                      --! 入力側の有効なデータが常にLOW側に詰められていることを
                      --! 示すフラグ.
                      --! * 常にLOW側に詰められている場合は、シフタが必要なくなる
                      --!   ため回路が簡単になる.
                      integer := 0;
        FLUSH_ENABLE: --! @brief FLUSH ENABLE :
                      --! FLUSH/I_FLUSHによるフラッシュ処理を有効にするかどうかを
                      --! 指定する.
                      --! * FLUSHとDONEとの違いは、DONEは最後のデータの出力時に
                      --!   キューの状態をすべてクリアするのに対して、
                      --!   FLUSHは最後のデータの出力時にENBLだけをクリアしてVALは
                      --!   クリアしない.
                      --!   そのため次の入力データは、最後のデータの次のワード位置
                      --!   から格納される.
                      --! * フラッシュ処理を行わない場合は、0を指定すると回路が若干
                      --!   簡単になる.
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
    -- 各種制御信号
    -------------------------------------------------------------------------------
        START       : --! @brief START :
                      --! 開始信号.
                      --! * この信号はOFFSETを内部に設定してキューを初期化する.
                      --! * 最初にデータ入力と同時にアサートしても構わない.
                      in  std_logic;
        OFFSET      : --! @brief OFFSET :
                      --! 最初のワードの出力位置を指定する.
                      --! * START信号がアサートされた時のみ有効.
                      --! * O_WIDTH>I_WIDTHの場合、最初のワードデータを出力する際の
                      --!   オフセットを設定できる.
                      --! * 例えばWORD_BITS=8、I_WIDTH=1(1バイト入力)、O_WIDTH=4(4バイト出力)の場合、
                      --!   OFFSET="0000"に設定すると、最初に入力したバイトデータは
                      --!   1バイト目から出力される.    
                      --!   OFFSET="0001"に設定すると、最初に入力したバイトデータは
                      --!   2バイト目から出力される.    
                      --!   OFFSET="0011"に設定すると、最初に入力したバイトデータは
                      --!   3バイト目から出力される.    
                      --!   OFFSET="0111"に設定すると、最初に入力したバイトデータは
                      --!   4バイト目から出力される.    
                      in  std_logic_vector(O_WIDTH-1 downto 0);
        DONE        : --! @brief DONE :
                      --! 終了信号.
                      --! * この信号をアサートすることで、キューに残っているデータ
                      --!   を掃き出す.
                      --!   その際、最後のワードと同時にO_DONE信号がアサートされる.
                      --! * FLUSH信号との違いは、FLUSH_ENABLEの項を参照.
                      in  std_logic;
        FLUSH       : --! @brief FLUSH :
                      --! フラッシュ信号.
                      --! * この信号をアサートすることで、キューに残っているデータ
                      --!   を掃き出す.
                      --!   その際、最後のワードと同時にO_FLUSH信号がアサートされる.
                      --! * DONE信号との違いは、FLUSH_ENABLEの項を参照.
                      in  std_logic;
        BUSY        : --! @brief BUSY :
                      --! ビジー信号.
                      --! * 最初にデータが入力されたときにアサートされる.
                      --! * 最後のデータが出力し終えたらネゲートされる.
                      out std_logic;
        VALID       : --! @brief QUEUE VALID FLAG :
                      --! キュー有効信号.
                      --! * 対応するインデックスのキューに有効なワードが入って
                      --!   いるかどうかを示すフラグ.
                      out std_logic_vector(VALID_MAX downto VALID_MIN);
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA      : --! @brief INPUT WORD DATA :
                      --! ワードデータ入力.
                      in  std_logic_vector(I_WIDTH*WORD_BITS-1 downto 0);
        I_ENBL      : --! @brief INPUT WORD ENABLE :
                      --! ワードイネーブル信号入力.
                      in  std_logic_vector(I_WIDTH*ENBL_BITS-1 downto 0);
        I_DONE      : --! @brief INPUT WORD DONE :
                      --! 最終ワード信号入力.
                      --! * 最後の力ワードデータ入であることを示すフラグ.
                      --! * 基本的にはDONE信号と同じ働きをするが、I_DONE信号は
                      --!   最後のワードデータを入力する際に同時にアサートする.
                      --! * I_FLUSH信号との違いはFLUSH_ENABLEの項を参照.
                      in  std_logic;
        I_FLUSH     : --! @brief INPUT WORD FLUSH :
                      --! 最終ワード信号入力.
                      --! * 最後のワードデータ入力であることを示すフラグ.
                      --! * 基本的にはFLUSH信号と同じ働きをするが、I_FLUSH信号は
                      --!   最後のワードデータを入力する際に同時にアサートする.
                      --! * I_DONE信号との違いはFLUSH_ENABLEの項を参照.
                      in  std_logic;
        I_VAL       : --! @brief INPUT WORD VALID :
                      --! 入力ワード有効信号.
                      --! * I_DATA/I_ENBL/I_DONE/I_FLUSHが有効であることを示す.
                      --! * I_VAL='1'and I_RDY='1'でワードデータがキューに取り込まれる.
                      in  std_logic;
        I_RDY       : --! @brief INPUT WORD READY :
                      --! 入力レディ信号.
                      --! * キューが次のワードデータを入力出来ることを示す.
                      --! * I_VAL='1'and I_RDY='1'でワードデータがキューに取り込まれる.
                      out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA      : --! @brief OUTPUT WORD DATA :
                      --! ワードデータ出力.
                      out std_logic_vector(O_WIDTH*WORD_BITS-1 downto 0);
        O_ENBL      : --! @brief OUTPUT WORD ENABLE :
                      --! ワードイネーブル信号出力.
                      out std_logic_vector(O_WIDTH*ENBL_BITS-1 downto 0);
        O_DONE      : --! @brief OUTPUT WORD DONE :
                      --! 最終ワード信号出力.
                      --! * 最後のワードデータ出力であることを示すフラグ.
                      --! * O_FLUSH信号との違いはFLUSH_ENABLEの項を参照.
                      out std_logic;
        O_FLUSH     : --! @brief OUTPUT WORD FLUSH :
                      --! 最終ワード信号出力.
                      --! * 最後のワードデータ出力であることを示すフラグ.
                      --! * O_DONE信号との違いはFLUSH_ENABLEの項を参照.
                      out std_logic;
        O_VAL       : --! @brief OUTPUT WORD VALID :
                      --! 出力ワード有効信号.
                      --! * O_DATA/O_ENBL/O_DONE/O_FLUSHが有効であることを示す.
                      --! * O_VAL='1'and O_RDY='1'でワードデータがキューから取り除かれる.
                      out std_logic;
        O_RDY       : --! @brief OUTPUT WORD READY :
                      --! 出力レディ信号.
                      --! * キューから次のワードを取り除く準備が出来ていることを示す.
                      --! * O_VAL='1'and O_RDY='1'でワードデータがキューから取り除かれる.
                      in  std_logic
    );
end REDUCER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
architecture RTL of REDUCER is
    -------------------------------------------------------------------------------
    --! @brief ワード単位でデータ/データイネーブル信号/ワード有効フラグをまとめておく
    -------------------------------------------------------------------------------
    type      WORD_TYPE    is record
              DATA          : std_logic_vector(WORD_BITS-1 downto 0);
              ENBL          : std_logic_vector(ENBL_BITS-1 downto 0);
              VAL           : boolean;
    end record;
    -------------------------------------------------------------------------------
    --! @brief WORD TYPE の初期化時の値.
    -------------------------------------------------------------------------------
    constant  WORD_NULL     : WORD_TYPE := (DATA => (others => '0'),
                                            ENBL => (others => '0'),
                                            VAL  => FALSE);
    -------------------------------------------------------------------------------
    --! @brief WORD TYPE の配列の定義.
    -------------------------------------------------------------------------------
    type      WORD_VECTOR  is array (INTEGER range <>) of WORD_TYPE;
    -------------------------------------------------------------------------------
    --! @brief キューの最後にワードを追加するプロシージャ.
    -------------------------------------------------------------------------------
    procedure APPEND(
        variable QUEUE : inout WORD_VECTOR;
                 WORDS : in    WORD_VECTOR
    ) is
        alias    vec   :       WORD_VECTOR(0 to WORDS'length-1) is WORDS;
        type     bv    is      array (INTEGER range <>) of boolean;
        variable val   :       bv(QUEUE'low to QUEUE'high);
        variable hit   :       boolean;
    begin
        for i in val'range loop         -- 先に val を作っておいた方が論理合成の結果
            val(i) := QUEUE(i).VAL;     -- が良かった
        end loop;                       --
        for i in val'range loop
            if (val(i) = FALSE) then
                QUEUE(i) := WORD_NULL;
                for pos in vec'range loop
                    if (i-pos-1 < val'low) then
                        hit := TRUE;
                    else
                        hit := val(i-pos-1);
                    end if;
                    if (hit) then
                        QUEUE(i) := vec(pos);
                        exit;
                    end if;
                end loop;
           end if;
        end loop;
    end APPEND;
    -------------------------------------------------------------------------------
    --! @brief キューのサイズを計算する関数.
    -------------------------------------------------------------------------------
    function  QUEUE_DEPTH return integer is begin
        if (QUEUE_SIZE > 0) then
            if (QUEUE_SIZE >= O_WIDTH+I_WIDTH-1) then
                return QUEUE_SIZE;
            else
                assert (QUEUE_SIZE >= I_WIDTH+O_WIDTH-1)
                    report "require QUEUE_SIZE >= I_WIDTH+O_WIDTH-1" severity WARNING;
                return I_WIDTH+O_WIDTH;
            end if;
        else
                return I_WIDTH+O_WIDTH;
        end if;
    end function;
    -------------------------------------------------------------------------------
    --! @brief 現在のキューの状態.
    -------------------------------------------------------------------------------
    signal    curr_queue    : WORD_VECTOR(0 to QUEUE_DEPTH-1);
    -------------------------------------------------------------------------------
    --! @brief 1ワード分のイネーブル信号がオール0であることを示す定数.
    -------------------------------------------------------------------------------
    constant  ENBL_NULL     : std_logic_vector(ENBL_BITS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --! @brief FLUSH 出力フラグ.
    -------------------------------------------------------------------------------
    signal    flush_output  : std_logic;
    -------------------------------------------------------------------------------
    --! @brief FLUSH 保留フラグ.
    -------------------------------------------------------------------------------
    signal    flush_pending : std_logic;
    -------------------------------------------------------------------------------
    --! @brief DONE 出力フラグ.
    -------------------------------------------------------------------------------
    signal    done_output   : std_logic;
    -------------------------------------------------------------------------------
    --! @brief DONE 保留フラグ.
    -------------------------------------------------------------------------------
    signal    done_pending  : std_logic;
    -------------------------------------------------------------------------------
    --! @brief O_VAL信号を内部で使うための信号.
    -------------------------------------------------------------------------------
    signal    o_valid       : std_logic;
    -------------------------------------------------------------------------------
    --! @brief I_RDY信号を内部で使うための信号.
    -------------------------------------------------------------------------------
    signal    i_ready       : std_logic;
    -------------------------------------------------------------------------------
    --! @brief BUSY信号を内部で使うための信号.
    -------------------------------------------------------------------------------
    signal    curr_busy     : std_logic;
begin
    -------------------------------------------------------------------------------
    -- メインプロセス
    -------------------------------------------------------------------------------
    process (CLK, RST) 
        variable    in_word           : WORD_VECTOR(0 to I_WIDTH-1);
        variable    next_queue        : WORD_VECTOR(curr_queue'range);
        variable    next_flush_output : std_logic;
        variable    next_flush_pending: std_logic;
        variable    next_flush_fall   : std_logic;
        variable    next_done_output  : std_logic;
        variable    next_done_pending : std_logic;
        variable    next_done_fall    : std_logic;
        variable    pending_flag      : boolean;
    begin
        if (RST = '1') then
                curr_queue    <= (others => WORD_NULL);
                flush_output  <= '0';
                flush_pending <= '0';
                done_output   <= '0';
                done_pending  <= '0';
                i_ready       <= '0';
                o_valid       <= '0';
                curr_busy     <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_queue    <= (others => WORD_NULL);
                flush_output  <= '0';
                flush_pending <= '0';
                done_output   <= '0';
                done_pending  <= '0';
                i_ready       <= '0';
                o_valid       <= '0';
                curr_busy     <= '0';
            else
                -------------------------------------------------------------------
                -- 次のクロックでのキューの状態を示す変数に現在のキューの状態をセット
                -------------------------------------------------------------------
                next_queue := curr_queue;
                -------------------------------------------------------------------
                -- データ出力時の次のクロックでのキューの状態に更新
                -------------------------------------------------------------------
                if (o_valid = '1' and O_RDY = '1') then
                    if (FLUSH_ENABLE >  0 ) and
                       (flush_output = '1') and
                       (O_WIDTH      >  1 ) and
                       (curr_queue(O_WIDTH-1).VAL = FALSE) then
                        for i in next_queue'range loop
                            if (i < O_WIDTH-1) then
                                next_queue(i).VAL := curr_queue(i).VAL;
                            else
                                next_queue(i).VAL := FALSE;
                            end if;
                            next_queue(i).DATA := (others => '0');
                            next_queue(i).ENBL := (others => '0');
                        end loop;
                    else
                        for i in next_queue'range loop
                            if (i+O_WIDTH > next_queue'high) then
                                next_queue(i) := WORD_NULL;
                            else
                                next_queue(i) := curr_queue(i+O_WIDTH);
                            end if;
                        end loop;
                    end if;
                end if;
                -------------------------------------------------------------------
                -- キュー初期化時の次のクロックでのキューの状態に更新
                -------------------------------------------------------------------
                if (START = '1') then
                    for i in next_queue'range loop
                        if (i < O_WIDTH-1) then
                            next_queue(i).VAL := (OFFSET(i) = '1');
                        else
                            next_queue(i).VAL := FALSE;
                        end if;
                        next_queue(i).DATA := (others => '0');
                        next_queue(i).ENBL := (others => '0');
                    end loop;
                end if;
                -------------------------------------------------------------------
                -- データ入力時の次のクロックでのキューの状態に更新
                -------------------------------------------------------------------
                if (I_VAL = '1' and i_ready = '1') then
                    for i in in_word'range loop
                        in_word(i).DATA :=  I_DATA((i+1)*WORD_BITS-1 downto i*WORD_BITS);
                        in_word(i).ENBL :=  I_ENBL((i+1)*ENBL_BITS-1 downto i*ENBL_BITS);
                        in_word(i).VAL  := (I_ENBL((i+1)*ENBL_BITS-1 downto i*ENBL_BITS) /= ENBL_NULL);
                    end loop;
                    if (I_JUSTIFIED    > 0) or
                       (in_word'length = 1) then
                        APPEND(next_queue, in_word);
                    else
                        for i in in_word'range loop
                            if (in_word(i).VAL) then
                                APPEND(next_queue, in_word(i to in_word'high));
                                exit;
                            end if;
                        end loop;
                    end if;
                end if;
                -------------------------------------------------------------------
                -- 次のクロックでのキューの状態をレジスタに保持
                -------------------------------------------------------------------
                curr_queue <= next_queue;
                -------------------------------------------------------------------
                -- 次のクロックでのキューの状態でO_WIDTHの位置にデータが入って
                -- いるか否かをチェック.
                -------------------------------------------------------------------
                if (next_queue'high >= O_WIDTH) then
                    pending_flag := (next_queue(O_WIDTH).VAL);
                else
                    pending_flag := FALSE;
                end if;
                -------------------------------------------------------------------
                -- FLUSH制御
                -------------------------------------------------------------------
                if    (FLUSH_ENABLE = 0) then
                        next_flush_output  := '0';
                        next_flush_pending := '0';
                        next_flush_fall    := '0';
                elsif (flush_output = '1') then
                    if (o_valid = '1' and O_RDY = '1') then
                        next_flush_output  := '0';
                        next_flush_pending := '0';
                        next_flush_fall    := '1';
                    else
                        next_flush_output  := '1';
                        next_flush_pending := '0';
                        next_flush_fall    := '0';
                    end if;
                 elsif (flush_pending = '1') or
                       (FLUSH         = '1') or
                       (I_VAL = '1' and i_ready = '1' and I_FLUSH = '1') then
                    if (pending_flag) then
                        next_flush_output  := '0';
                        next_flush_pending := '1';
                        next_flush_fall    := '0';
                    else
                        next_flush_output  := '1';
                        next_flush_pending := '0';
                        next_flush_fall    := '0';
                    end if;
                else
                        next_flush_output  := '0';
                        next_flush_pending := '0';
                        next_flush_fall    := '0';
                end if;
                flush_output  <= next_flush_output;
                flush_pending <= next_flush_pending;
                -------------------------------------------------------------------
                -- DONE制御
                -------------------------------------------------------------------
                if    (done_output = '1') then
                    if (o_valid = '1' and O_RDY = '1') then
                        next_done_output   := '0';
                        next_done_pending  := '0';
                        next_done_fall     := '1';
                    else
                        next_done_output   := '1';
                        next_done_pending  := '0';
                        next_done_fall     := '0';
                    end if;
                elsif (done_pending = '1') or
                      (DONE         = '1') or
                      (I_VAL = '1' and i_ready = '1' and I_DONE = '1') then
                    if (pending_flag) then
                        next_done_output   := '0';
                        next_done_pending  := '1';
                        next_done_fall     := '0';
                    else
                        next_done_output   := '1';
                        next_done_pending  := '0';
                        next_done_fall     := '0';
                    end if;
                else
                        next_done_output   := '0';
                        next_done_pending  := '0';
                        next_done_fall     := '0';
                end if;
                done_output   <= next_done_output;
                done_pending  <= next_done_pending;
                -------------------------------------------------------------------
                -- 出力有効信号の生成
                -------------------------------------------------------------------
                if (next_done_output  = '1') or
                   (next_flush_output = '1') or
                   (next_queue(O_WIDTH-1).VAL = TRUE) then
                    o_valid <= '1';
                else
                    o_valid <= '0';
                end if;
                -------------------------------------------------------------------
                -- 入力可能信号の生成
                -------------------------------------------------------------------
                if (next_done_output  = '0' and next_done_pending  = '0') and
                   (next_flush_output = '0' and next_flush_pending = '0') and
                   (next_queue(next_queue'length-I_WIDTH).VAL = FALSE) then
                    i_ready <= '1';
                else
                    i_ready <= '0';
                end if;
                -------------------------------------------------------------------
                -- 現在処理中であることを示すフラグ
                -- 最初に入力があった時点で'1'になり、O_DONEまたはO_FLUSHが出力完了
                -- した時点で'0'になる。
                -------------------------------------------------------------------
                if (curr_busy = '1') then
                    if (next_flush_fall = '1') or
                       (next_done_fall  = '1') then
                        curr_busy <= '0';
                    else
                        curr_busy <= '1';
                    end if;
                else
                    if (I_VAL = '1' and i_ready = '1') then
                        curr_busy <= '1';
                    else
                        curr_busy <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 各種出力信号の生成
    -------------------------------------------------------------------------------
    O_FLUSH <= flush_output when(FLUSH_ENABLE > 0) else '0';
    O_DONE  <= done_output;
    O_VAL   <= o_valid;
    I_RDY   <= i_ready;
    BUSY    <= curr_busy;
    process (curr_queue) begin
        for i in 0 to O_WIDTH-1 loop
            O_DATA((i+1)*WORD_BITS-1 downto i*WORD_BITS) <= curr_queue(i).DATA;
            O_ENBL((i+1)*ENBL_BITS-1 downto i*ENBL_BITS) <= curr_queue(i).ENBL;
        end loop;
        for i in VALID'range loop
            if (curr_queue'low <= i and i <= curr_queue'high) then
                if (curr_queue(i).VAL) then
                    VALID(i) <= '1';
                else
                    VALID(i) <= '0';
                end if;
            else
                    VALID(i) <= '0';
            end if;
        end loop;
    end process;
end RTL;
