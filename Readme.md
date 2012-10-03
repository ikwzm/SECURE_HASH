SHA-1,SHA-256,SHA-512 Digest Generator VHDL RTL.
------------------------------------------------

###概要###
SHA-1,SHA-256,SHA-512を計算する論理合成可能なVHDLモジュールです.

論理合成可能です。

１クロックで１、２、４、８ワード(１ワードは32bit)処理できます.

###論理合成###
論理合成を行うためには次のファイルが必要です。

* PipeWorkのコンポーネント宣言パッケージ   components.vhd (<https://github.com/ikwzm/PipeWork.git>)
* 異なるデータ幅のパスを継ぐためのアダプタ reducer.vhd    (<https://github.com/ikwzm/PipeWork.git>)


<table border="1">
  <tr>
    <th colspan="9">SHA-1 WORD=32bit BLOCK=512bit</th>
  </tr>
  <tr>
    <th>Device</th>
    <th>Speed</th>
    <th>WORDS</th>
    <th>BLOCK_GAP</th>
    <th>Cycle/Block</th>
    <th>Slice[Regs,LUTs]</th>
    <th>Fmax</th>
    <th>Throughput</th>
  </tr>
  <tr>
    <th align="right" rowspan="4">Spartan6</th>
    <th align="right" rowspan="4">-3</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">1164,1449</td>
    <td align="right">122[MHz]</td>
    <td align="right">780[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">1170,1532</td>
    <td align="right">128[MHz]</td>
    <td align="right">810[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">1323,1790</td>
    <td align="right">84[MHz]</td>
    <td align="right">1076[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">1325,1823</td>
    <td align="right">89[MHz]</td>
    <td align="right">1115[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="4">Virtex6</th>
    <th align="right" rowspan="4">-2</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">1125,1399</td>
    <td align="right">150[MHz]</td>
    <td align="right">970[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">1126,1449</td>
    <td align="right">158[MHz]</td>
    <td align="right">1003[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">1317,1785</td>
    <td align="right">101[MHz]</td>
    <td align="right">1293[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">1317,1820</td>
    <td align="right">105[MHz]</td>
    <td align="right">1315[Mbit/sec]</td>
  </tr>
  <tr>
    <th colspan="9">SHA-256 WORD=32bit BLOCK=512bit</th>
  </tr>
  <tr>
    <th>Device</th>
    <th>Speed</th>
    <th>WORDS</th>
    <th>BLOCK_GAP</th>
    <th>Cycle/Block</th>
    <th>Slice[Regs,LUTs]</th>
    <th>Fmax</th>
    <th>Throughput</th>
  </tr>
  <tr>
    <th align="right" rowspan="4">Spartan6</th>
    <th align="right" rowspan="4">-3</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">64</td>
    <td align="right">1437,1880</td>
    <td align="right">102[MHz]</td>
    <td align="right">816[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">65</td>
    <td align="right">1412,1922</td>
    <td align="right">115[MHz]</td>
    <td align="right">906[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">32</td>
    <td align="right">1684,2471</td>
    <td align="right">61[MHz]</td>
    <td align="right">970[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">33</td>
    <td align="right">1657,2483</td>
    <td align="right">69[MHz]</td>
    <td align="right">1070[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="4">Virtex6</th>
    <th align="right" rowspan="4">-2</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">64</td>
    <td align="right">1431,1942</td>
    <td align="right">105[MHz]</td>
    <td align="right">842[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">65</td>
    <td align="right">1404,1943</td>
    <td align="right">135[MHz]</td>
    <td align="right">1064[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">32</td>
    <td align="right">1680,2527</td>
    <td align="right">87[MHz]</td>
    <td align="right">1113[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">33</td>
    <td align="right">1653,2539</td>
    <td align="right">101[MHz]</td>
    <td align="right">1261[Mbit/sec]</td>
  </tr>
  <tr>
    <th colspan="9">SHA-512 WORD=64bit BLOCK=1024bit</th>
  </tr>
  <tr>
    <th>Device</th>
    <th>Speed</th>
    <th>WORDS</th>
    <th>BLOCK_GAP</th>
    <th>Cycle/Block</th>
    <th>Slice[Regs,LUTs]</th>
    <th>Fmax</th>
    <th>Throughput</th>
  </tr>
  <tr>
    <th align="right" rowspan="4">Spartan6</th>
    <th align="right" rowspan="4">-3</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">2785,3758</td>
    <td align="right">95[MHz]</td>
    <td align="right">1219[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">2728,3802</td>
    <td align="right">102[MHz]</td>
    <td align="right">1290[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">3293,4903</td>
    <td align="right">53[MHz]</td>
    <td align="right">1362[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">3233,4978</td>
    <td align="right">62[MHz]</td>
    <td align="right">1542[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="4">Virtex6</th>
    <th align="right" rowspan="4">-2</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">2780,3750</td>
    <td align="right">100[MHz]</td>
    <td align="right">1280[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">2720,3765</td>
    <td align="right">125[MHz]</td>
    <td align="right">1580[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">3289,4895</td>
    <td align="right">77[MHz]</td>
    <td align="right">1969[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">3229,4985</td>
    <td align="right">83[MHz]</td>
    <td align="right">2081[Mbit/sec]</td>
  </tr>
</table>


###シミュレーション###

####他に必要なファイル####
シミュレーションをするためには次のファイルが必要です。

* PipeWorkのコンポーネント宣言パッケージ   components.vhd (<https://github.com/ikwzm/PipeWork.git>)
* 異なるデータ幅のパスを継ぐためのアダプタ reducer.vhd    (<https://github.com/ikwzm/PipeWork.git>)
* 文字列操作用の各種ユーティリティ         util.vhd       (<https://github.com/ikwzm/Dummy_Plug.git>)

####GHDLによるシミュレーション####
シミュレーションには GHDL (http://ghdl.free.fr/) を使いました.

ディレクトリ sim/ghdl に移動して make コマンドでシミュレーションが走ります.

もしかしたら他のシミュレーションでは走らないかもしれません。その際はご一報ください.

####Isimによるシミュレーション####
Xilinx社のIsimでシミュレーションすることができます.

ISE Design Suite 14.2 で動作を確認しています.

ディレクトリ sim/isim にXilinx社のプロジェクトファイルがあります.

###注意###
とりあえず簡単なテストはしていますが、完璧ではありません.

###ライセンス###
二条項BSDライセンス (2-clause BSD license) で公開しています。

