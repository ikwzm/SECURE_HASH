-----------------------------------------------------------------------------------
--!     @file    sha1_stage2.vhd
--!     @brief   SHA1 STAGE2 MODULE :
--!              SHA1用ワードデータ生成モジュール.
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
--! @brief   SHA1_PROC :
--!          SHA1の計算.
-----------------------------------------------------------------------------------
entity  SHA1_PROC is
    generic (
        NUM         : integer := 1
    );
    port (
        T           : in  integer range 0 to 127;
        W           : in  std_logic_vector(31 downto 0);
        Ai          : in  std_logic_vector(31 downto 0);
        Bi          : in  std_logic_vector(31 downto 0);
        Ci          : in  std_logic_vector(31 downto 0);
        Di          : in  std_logic_vector(31 downto 0);
        Ei          : in  std_logic_vector(31 downto 0);
        Ao          : out std_logic_vector(31 downto 0);
        Bo          : out std_logic_vector(31 downto 0);
        Co          : out std_logic_vector(31 downto 0);
        Do          : out std_logic_vector(31 downto 0);
        Eo          : out std_logic_vector(31 downto 0)
    );
end SHA1_PROC;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of SHA1_PROC is
    signal   a0 : unsigned(31 downto 0);
    signal   a1 : unsigned(31 downto 0);
    signal   a2 : unsigned(31 downto 0);
    signal   a3 : unsigned(31 downto 0);
    signal   a4 : unsigned(31 downto 0);
    constant k0 : unsigned(31 downto 0) := "01011010100000100111100110011001"; -- 0x5A827999
    constant k1 : unsigned(31 downto 0) := "01101110110110011110101110100001"; -- 0x6ED9EBA1
    constant k2 : unsigned(31 downto 0) := "10001111000110111011110011011100"; -- 0x8F1BBCDC
    constant k3 : unsigned(31 downto 0) := "11001010011000101100000111010110"; -- 0xCA62C1D6
    function Func00_19(B,C,D:std_logic_vector) return unsigned is
    begin
        return unsigned((B and C) or (not B and D));
    end function;
    function Func20_39(B,C,D:std_logic_vector) return unsigned is
    begin
        return unsigned(B xor C xor D);
    end function;
    function Func40_59(B,C,D:std_logic_vector) return unsigned is
    begin
        return unsigned((B and C) or (B and D) or (C and D));
    end function;
    function Func60_79(B,C,D:std_logic_vector) return unsigned is
    begin
        return unsigned(B xor C xor D);
    end function;
begin
    a0 <= unsigned(Ai(Ai'high-5 downto Ai'low) & Ai(Ai'high downto Ai'high-5+1));
    a1 <= Func00_19(Bi,Ci,Di) when ( 0 <= T+NUM and T+NUM <= 19) else
          Func20_39(Bi,Ci,Di) when (20 <= T+NUM and T+NUM <= 39) else
          Func40_59(Bi,Ci,Di) when (49 <= T+NUM and T+NUM <= 59) else
          Func60_79(Bi,Ci,Di);
    a2 <= unsigned(Ei);
    a3 <= unsigned(W);
    a4 <= k0 when ( 0 <= T+NUM and T+NUM <= 19) else
          k1 when (20 <= T+NUM and T+NUM <= 39) else
          k2 when (40 <= T+NUM and T+NUM <= 59) else
          k3;
    Ao <= std_logic_vector(a0+a1+a2+a3+a4);
    Bo <= Ai;
    Co <= Ci(Ci'high-30 downto Ci'low) & Ci(Ci'high downto Ci'high-30+1);
    Do <= Ci;
    Eo <= Di;
end RTL;
