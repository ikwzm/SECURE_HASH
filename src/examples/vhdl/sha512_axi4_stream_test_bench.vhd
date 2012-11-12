-----------------------------------------------------------------------------------
--!     @file    sha512_axi4_stream_test_bench.vhd
--!     @brief   SHA-512 AXI4-Stream Wrapper
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
--! @brief   SHA-1テストベンチのベースモデル.
-----------------------------------------------------------------------------------
entity  SHA512_AXI4_STREAM_TEST_BENCH is
    generic (
        SCENARIO_FILE   : STRING;
        SYMBOLS         : integer := 4;
        WORDS           : integer := 1;
        BLOCK_GAP       : integer := 1;
        VERBOSE         : integer := 1;
        AUTO_FINISH     : integer := 1
    );
    port (
        FINISH      : out std_logic
    );
end SHA512_AXI4_STREAM_TEST_BENCH;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.UTIL.INTEGER_TO_STRING;
use     DUMMY_PLUG.SYNC.all;
use     DUMMY_PLUG.CORE.MARCHAL;
use     DUMMY_PLUG.CORE.REPORT_STATUS_TYPE;
use     DUMMY_PLUG.CORE.REPORT_STATUS_VECTOR;
use     DUMMY_PLUG.CORE.MARGE_REPORT_STATUS;
use     DUMMY_PLUG.AXI4_TYPES.all;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_SLAVE_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_SIGNAL_PRINTER;
library PipeWork;
use     PipeWork.SHA512.SHA512_CORE;
use     PipeWork.SHA512.HASH_BITS;
architecture MODEL of SHA512_AXI4_STREAM_TEST_BENCH is
    -------------------------------------------------------------------------------
    -- 各種定数
    -------------------------------------------------------------------------------
    constant  SYMBOL_BITS   : integer := 8;
    constant  REVERSE       : integer := 1;
    constant  PERIOD        : time    := 10 ns;
    constant  DELAY         : time    :=  2 ns;
    constant  SYNC_WIDTH    : integer :=  2;
    constant  GPO_WIDTH     : integer :=  8;
    constant  GPI_WIDTH     : integer :=  2*GPO_WIDTH;
    constant  I_WIDTH       : AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                 ID    =>  4,
                                 DATA  =>  8*SYMBOLS,
                                 USER  =>  4,
                                 DEST  =>  4);
    constant  O_WIDTH       : AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                 ID    =>  4,
                                 DATA  =>  8*SYMBOLS,
                                 USER  =>  4,
                                 DEST  =>  4);
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal    ACLK          : std_logic;
    signal    ARESETn       : std_logic;
    signal    RESET         : std_logic;
    -------------------------------------------------------------------------------
    -- AXI4-Stream Input シグナル.
    -------------------------------------------------------------------------------
    signal    I_LAST        : std_logic;
    signal    I_DATA        : std_logic_vector(I_WIDTH.DATA  -1 downto 0);
    signal    I_STRB        : std_logic_vector(I_WIDTH.DATA/8-1 downto 0);
    signal    I_KEEP        : std_logic_vector(I_WIDTH.DATA/8-1 downto 0);
    signal    I_USER        : std_logic_vector(I_WIDTH.USER  -1 downto 0);
    signal    I_DEST        : std_logic_vector(I_WIDTH.DEST  -1 downto 0);
    signal    I_ID          : std_logic_vector(I_WIDTH.ID    -1 downto 0);
    signal    I_VALID       : std_logic;
    signal    I_READY       : std_logic;
    -------------------------------------------------------------------------------
    -- AXI4-Stream Output シグナル.
    -------------------------------------------------------------------------------
    signal    O_LAST        : std_logic;
    signal    O_DATA        : std_logic_vector(O_WIDTH.DATA  -1 downto 0);
    signal    O_STRB        : std_logic_vector(O_WIDTH.DATA/8-1 downto 0);
    signal    O_KEEP        : std_logic_vector(O_WIDTH.DATA/8-1 downto 0);
    signal    O_USER        : std_logic_vector(O_WIDTH.USER  -1 downto 0);
    signal    O_DEST        : std_logic_vector(O_WIDTH.DEST  -1 downto 0);
    signal    O_ID          : std_logic_vector(O_WIDTH.ID    -1 downto 0);
    signal    O_VALID       : std_logic;
    signal    O_READY       : std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal    SYNC          : SYNC_SIG_VECTOR (SYNC_WIDTH   -1 downto 0);
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal    I_GPI         : std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    I_GPO         : std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal    O_GPI         : std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    O_GPO         : std_logic_vector(GPO_WIDTH    -1 downto 0);
    -------------------------------------------------------------------------------
    -- 各種状態出力.
    -------------------------------------------------------------------------------
    signal    N_REPORT      : REPORT_STATUS_TYPE;
    signal    I_REPORT      : REPORT_STATUS_TYPE;
    signal    O_REPORT      : REPORT_STATUS_TYPE;
    signal    N_FINISH      : std_logic;
    signal    I_FINISH      : std_logic;
    signal    O_FINISH      : std_logic;
    -------------------------------------------------------------------------------
    -- NAMEの生成
    -------------------------------------------------------------------------------
    function  NAME return STRING is
    begin
        return "SHA512_AXI4_STREAM_TEST_BENCH"       &
               "_W" & INTEGER_TO_STRING(WORDS    ) &
               "_S" & INTEGER_TO_STRING(SYMBOLS  ) &
               "_G" & INTEGER_TO_STRING(BLOCK_GAP);
    end function;
    -------------------------------------------------------------------------------
    -- DUT のコンポーネント宣言.
    -------------------------------------------------------------------------------
    component SHA512_AXI4_STREAM
        generic (
            I_BYTES     : integer := 4;
            O_BYTES     : integer := 4;
            WORDS       : integer := 1;
            BLOCK_GAP   : integer := 1
        );
        port (
            ACLK        : in  std_logic; 
            ARESETn     : in  std_logic;
            I_DATA      : in  std_logic_vector(8*I_BYTES-1 downto 0);
            I_STRB      : in  std_logic_vector(  I_BYTES-1 downto 0);
            I_LAST      : in  std_logic;
            I_VALID     : in  std_logic;
            I_READY     : out std_logic;
            O_DATA      : out std_logic_vector(8*O_BYTES-1 downto 0);
            O_STRB      : out std_logic_vector(  O_BYTES-1 downto 0);
            O_LAST      : out std_logic;
            O_VALID     : out std_logic;
            O_READY     : in  std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    N: MARCHAL
        generic map(
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "N"             ,
            SYNC_PLUG_NUM   => 1               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            FINISH_ABORT    => FALSE
        )
        port map(
            CLK             => ACLK            , -- In  :
            RESET           => RESET           , -- In  :
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
            REPORT_STATUS   => N_REPORT        , -- Out :
            FINISH          => N_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- AXI4_STREAM_MASTER_PLAYER
    ------------------------------------------------------------------------------
    I: AXI4_STREAM_MASTER_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "I"             ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => I_WIDTH         ,
            SYNC_PLUG_NUM   => 2               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            TLAST           => I_LAST          , -- I/O : 
            TDATA           => I_DATA          , -- I/O : 
            TSTRB           => I_STRB          , -- I/O : 
            TKEEP           => I_KEEP          , -- I/O : 
            TUSER           => I_USER          , -- I/O : 
            TDEST           => I_DEST          , -- I/O : 
            TID             => I_ID            , -- I/O : 
            TVALID          => I_VALID         , -- I/O : 
            TREADY          => I_READY         , -- In  :    
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => I_GPI           , -- In  :
            GPO             => I_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => I_REPORT        , -- Out :
            FINISH          => I_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- AXI4_STREAM_SLAVE_PLAYER
    ------------------------------------------------------------------------------
    O: AXI4_STREAM_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "O"             ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => O_WIDTH         ,
            SYNC_PLUG_NUM   => 3               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            TLAST           => O_LAST          , -- In  :    
            TDATA           => O_DATA          , -- In  :    
            TSTRB           => O_STRB          , -- In  :    
            TKEEP           => O_KEEP          , -- In  :    
            TUSER           => O_USER          , -- In  :    
            TDEST           => O_DEST          , -- In  :    
            TID             => O_ID            , -- In  :    
            TVALID          => O_VALID         , -- In  :    
            TREADY          => O_READY         , -- I/O : 
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => O_GPI           , -- In  :
            GPO             => O_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => O_REPORT        , -- Out :
            FINISH          => O_FINISH          -- Out :
    );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT: SHA512_AXI4_STREAM
        generic map(
            I_BYTES         => SYMBOLS         ,
            O_BYTES         => SYMBOLS         ,
            WORDS           => WORDS           ,
            BLOCK_GAP       => BLOCK_GAP
        )
        port map (
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
            I_DATA          => I_DATA          , -- In  :
            I_STRB          => I_STRB          , -- In  :
            I_LAST          => I_LAST          , -- In  :
            I_VALID         => I_VALID         , -- In  :
            I_READY         => I_READY         , -- Out :
            O_DATA          => O_DATA          , -- Out :
            O_STRB          => O_STRB          , -- Out :
            O_LAST          => O_LAST          , -- Out :
            O_VALID         => O_VALID         , -- Out :
            O_READY         => O_READY           -- In  :
        );
    O_KEEP <= (others => '1');
    O_USER <= (others => '0');
    O_DEST <= (others => '0');
    O_ID   <= (others => '0');
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process begin
        ACLK <= '1';
        wait for PERIOD / 2;
        ACLK <= '0';
        wait for PERIOD / 2;
    end process;
    ARESETn <= '1' when (RESET = '0') else '0';
    I_GPI   <= O_GPO & I_GPO;
    O_GPI   <= O_GPO & I_GPO;
    process
        variable L   : LINE;
        constant T   : STRING(1 to 7) := "  ***  ";
        variable rep : REPORT_STATUS_TYPE;
        variable rv  : REPORT_STATUS_VECTOR(1 to 2);
    begin
        wait until (N_FINISH'event and N_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                          WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ INPUT  ]");                                    WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,I_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,I_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,I_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ OUTPUT ]");                                    WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,O_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,O_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,O_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        assert FALSE report "Simulation complete." severity FAILURE;
        wait;
    end process;
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-1テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G0 is
end     SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G0;
architecture MODEL of SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G0 is
    component  SHA512_AXI4_STREAM_TEST_BENCH
        generic (
            SCENARIO_FILE   : STRING ;
            SYMBOLS         : integer;
            WORDS           : integer;
            BLOCK_GAP       : integer;
            VERBOSE         : integer;
            AUTO_FINISH     : integer
        );
        port (
            FINISH          : out std_logic
        );
    end component;
begin
    TB: SHA512_AXI4_STREAM_TEST_BENCH generic map(
           SCENARIO_FILE    => "sha512_test.snr",
           SYMBOLS          => 8,
           WORDS            => 1,
           BLOCK_GAP        => 0,
           VERBOSE          => 0,
           AUTO_FINISH      => 1
    ) port map (
           FINISH           => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-1テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=1)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G1 is
end     SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G1;
architecture MODEL of SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G1 is
    component  SHA512_AXI4_STREAM_TEST_BENCH
        generic (
            SCENARIO_FILE   : STRING ;
            SYMBOLS         : integer;
            WORDS           : integer;
            BLOCK_GAP       : integer;
            VERBOSE         : integer;
            AUTO_FINISH     : integer
        );
        port (
            FINISH          : out std_logic
        );
    end component;
begin
    TB: SHA512_AXI4_STREAM_TEST_BENCH generic map(
           SCENARIO_FILE    => "sha512_test.snr",
           SYMBOLS          => 8,
           WORDS            => 1,
           BLOCK_GAP        => 1,
           VERBOSE          => 0,
           AUTO_FINISH      => 1
    ) port map (
           FINISH           => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-1テストベンチ(WORDS=1,SYMBOLS=8,BLOCK_GAP=4)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G4 is
end     SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G4;
architecture MODEL of SHA512_AXI4_STREAM_TEST_BENCH_W1_S8_G4 is
    component  SHA512_AXI4_STREAM_TEST_BENCH
        generic (
            SCENARIO_FILE   : STRING ;
            SYMBOLS         : integer;
            WORDS           : integer;
            BLOCK_GAP       : integer;
            VERBOSE         : integer;
            AUTO_FINISH     : integer
        );
        port (
            FINISH          : out std_logic
        );
    end component;
begin
    TB: SHA512_AXI4_STREAM_TEST_BENCH generic map(
           SCENARIO_FILE    => "sha512_test.snr",
           SYMBOLS          => 8,
           WORDS            => 1,
           BLOCK_GAP        => 4,
           VERBOSE          => 0,
           AUTO_FINISH      => 1
    ) port map (
           FINISH           => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-1テストベンチ(WORDS=2,SYMBOLS=16,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_AXI4_STREAM_TEST_BENCH_W2_S16_G0 is
end     SHA512_AXI4_STREAM_TEST_BENCH_W2_S16_G0;
architecture MODEL of SHA512_AXI4_STREAM_TEST_BENCH_W2_S16_G0 is
    component  SHA512_AXI4_STREAM_TEST_BENCH
        generic (
            SCENARIO_FILE   : STRING ;
            SYMBOLS         : integer;
            WORDS           : integer;
            BLOCK_GAP       : integer;
            VERBOSE         : integer;
            AUTO_FINISH     : integer
        );
        port (
            FINISH          : out std_logic
        );
    end component;
begin
    TB: SHA512_AXI4_STREAM_TEST_BENCH generic map(
           SCENARIO_FILE    => "sha512_test.snr",
           SYMBOLS          => 16,
           WORDS            => 2,
           BLOCK_GAP        => 0,
           VERBOSE          => 0,
           AUTO_FINISH      => 1
    ) port map (
           FINISH           => open
    );
end MODEL;
-----------------------------------------------------------------------------------
--! @brief   SHA-1テストベンチ(WORDS=4,SYMBOLS=32,BLOCK_GAP=0)
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  SHA512_AXI4_STREAM_TEST_BENCH_W4_S32_G0 is
end     SHA512_AXI4_STREAM_TEST_BENCH_W4_S32_G0;
architecture MODEL of SHA512_AXI4_STREAM_TEST_BENCH_W4_S32_G0 is
    component  SHA512_AXI4_STREAM_TEST_BENCH
        generic (
            SCENARIO_FILE   : STRING ;
            SYMBOLS         : integer;
            WORDS           : integer;
            BLOCK_GAP       : integer;
            VERBOSE         : integer;
            AUTO_FINISH     : integer
        );
        port (
            FINISH          : out std_logic
        );
    end component;
begin
    TB: SHA512_AXI4_STREAM_TEST_BENCH generic map(
           SCENARIO_FILE    => "sha512_test.snr",
           SYMBOLS          => 32,
           WORDS            => 4,
           BLOCK_GAP        => 0,
           VERBOSE          => 0,
           AUTO_FINISH      => 1
    ) port map (
           FINISH           => open
    );
end MODEL;
