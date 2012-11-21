SHA-1,SHA-256,SHA-512 Secure Hash Generator VHDL RTL.
-----------------------------------------------------

###概要###
SHA-1,SHA-256,SHA-512を計算する論理合成可能なVHDLモジュールです.

論理合成可能です。

１クロックで１、２ワード(１ワードはSHA-1およびSHA-256で32bit、SHA-512では64bit)処理できます.

####開発環境####
以下の開発環境で合成出来ることを確認しています.

* Xilinx ISE14.2
* Altera QuartusII 11.1sp2 Web Edition(32bit)

###論理合成###

fpga/xilinx/ise14.2 の下に Xilinx 社FPGA用の各プロジェクトがあります.
fpga/altera/11.2sp2 の下に Altera 社FPGA用の各プロジェクトを生成するスクリプトがあります.


####論理合成の結果####

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
    <td align="right">1151,1590</td>
    <td align="right">145[MHz]</td>
    <td align="right">928[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">1157,1730</td>
    <td align="right">141[MHz]</td>
    <td align="right">890[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">1525,1873</td>
    <td align="right">87[MHz]</td>
    <td align="right">1113[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">1527,1914</td>
    <td align="right">91[MHz]</td>
    <td align="right">1135[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="4">Virtex6</th>
    <th align="right" rowspan="4">-3</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">1138,1609</td>
    <td align="right">204[MHz]</td>
    <td align="right">1306[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">1139,1680</td>
    <td align="right">227[MHz]</td>
    <td align="right">1436[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">1515,1851</td>
    <td align="right">133[MHz]</td>
    <td align="right">1707[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">1517,1897</td>
    <td align="right">136[MHz]</td>
    <td align="right">1711[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="4">CycloneIV</th>
    <th align="right" rowspan="4">Auto</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">1018,1938</td>
    <td align="right">111[MHz]</td>
    <td align="right">711[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">1019,1944</td>
    <td align="right">123[MHz]</td>
    <td align="right">771[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">1190,2469</td>
    <td align="right">77[MHz]</td>
    <td align="right">961[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">1191,2476</td>
    <td align="right">92[MHz]</td>
    <td align="right">1135[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="4">Arria II</th>
    <th align="right" rowspan="4">Auto</th>
    <td align="right" rowspan="2">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">1022,1224</td>
    <td align="right">123[MHz]</td>
    <td align="right">790[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">1023,1231</td>
    <td align="right">152[MHz]</td>
    <td align="right">960[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">1191,1605</td>
    <td align="right">104[MHz]</td>
    <td align="right">1338[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">1191,1608</td>
    <td align="right">104[MHz]</td>
    <td align="right">1307[Mbit/sec]</td>
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
    <th align="right" rowspan="5">Spartan6</th>
    <th align="right" rowspan="5">-3</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">64</td>
    <td align="right">1460,2587</td>
    <td align="right">102[MHz]</td>
    <td align="right">816[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">65</td>
    <td align="right">1442,2597</td>
    <td align="right">128[MHz]</td>
    <td align="right">1010[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">68</td>
    <td align="right">1555,2971</td>
    <td align="right">178[MHz]</td>
    <td align="right">1344[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">32</td>
    <td align="right">1862,3096</td>
    <td align="right">59[MHz]</td>
    <td align="right">941[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">33</td>
    <td align="right">1835,3094</td>
    <td align="right">69[MHz]</td>
    <td align="right">1070[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="5">Virtex6</th>
    <th align="right" rowspan="5">-3</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">64</td>
    <td align="right">1452,2546</td>
    <td align="right">163[MHz]</td>
    <td align="right">1311[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">65</td>
    <td align="right">1425,2583</td>
    <td align="right">200[MHz]</td>
    <td align="right">1575[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">68</td>
    <td align="right">1530,2766</td>
    <td align="right">250[MHz]</td>
    <td align="right">1882[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">32</td>
    <td align="right">1858,3094</td>
    <td align="right">95[MHz]</td>
    <td align="right">1524[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">33</td>
    <td align="right">1831,3078</td>
    <td align="right">114[MHz]</td>
    <td align="right">1763[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="5">CycloneIV</th>
    <th align="right" rowspan="5">Auto</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">64</td>
    <td align="right">1334,3177</td>
    <td align="right">104[MHz]</td>
    <td align="right">832[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">65</td>
    <td align="right">1336,3196</td>
    <td align="right">119[MHz]</td>
    <td align="right">937[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">68</td>
    <td align="right">1441,3360</td>
    <td align="right">127[MHz]</td>
    <td align="right">953[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">32</td>
    <td align="right">1504,3877</td>
    <td align="right">65[MHz]</td>
    <td align="right">1046[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">33</td>
    <td align="right">1506,3897</td>
    <td align="right">69[MHz]</td>
    <td align="right">1070[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="5">Arria II</th>
    <th align="right" rowspan="5">Auto</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">64</td>
    <td align="right">1338,1979</td>
    <td align="right">118[MHz]</td>
    <td align="right">945[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">65</td>
    <td align="right">1340,2001</td>
    <td align="right">121[MHz]</td>
    <td align="right">953[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">68</td>
    <td align="right">1445,2050</td>
    <td align="right">158[MHz]</td>
    <td align="right">1197[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">32</td>
    <td align="right">1507,2569</td>
    <td align="right">88[MHz]</td>
    <td align="right">1416[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">33</td>
    <td align="right">1509,2574</td>
    <td align="right">92[MHz]</td>
    <td align="right">1473[Mbit/sec]</td>
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
    <th align="right" rowspan="5">Spartan6</th>
    <th align="right" rowspan="5">-3</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">2880,8091</td>
    <td align="right">83[MHz]</td>
    <td align="right">1067[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">2842,8133</td>
    <td align="right">109[MHz]</td>
    <td align="right">1374[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">84</td>
    <td align="right">3024,8755</td>
    <td align="right">125[MHz]</td>
    <td align="right">1524[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">3705,10270</td>
    <td align="right">45[MHz]</td>
    <td align="right">1163[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">3648,10361</td>
    <td align="right">59[MHz]</td>
    <td align="right">1469[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="5">Virtex6</th>
    <th align="right" rowspan="5">-3</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">2876,8012</td>
    <td align="right">147[MHz]</td>
    <td align="right">1882[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">2818,8207</td>
    <td align="right">164[MHz]</td>
    <td align="right">2072[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">84</td>
    <td align="right">3023,8538</td>
    <td align="right">200[MHz]</td>
    <td align="right">2438[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">3701,10387</td>
    <td align="right">87[MHz]</td>
    <td align="right">2226[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">3641,10429</td>
    <td align="right">95[MHz]</td>
    <td align="right">2379[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="5">CycloneIV</th>
    <th align="right" rowspan="5">Auto</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">2627,6950</td>
    <td align="right">81[MHz]</td>
    <td align="right">1049[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">2628,6963</td>
    <td align="right">102[MHz]</td>
    <td align="right">1290[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">84</td>
    <td align="right">2829,7326</td>
    <td align="right">114[MHz]</td>
    <td align="right">1385[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">2961,8778</td>
    <td align="right">53[MHz]</td>
    <td align="right">1354[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">2962,8795</td>
    <td align="right">51[MHz]</td>
    <td align="right">1287[Mbit/sec]</td>
  </tr>
  <tr>
    <th align="right" rowspan="5">Arria II</th>
    <th align="right" rowspan="5">Auto</th>
    <td align="right" rowspan="3">1</td>
    <td align="right">0</td>
    <td align="right">80</td>
    <td align="right">2631,4504</td>
    <td align="right">103[MHz]</td>
    <td align="right">1320[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">81</td>
    <td align="right">2632,4597</td>
    <td align="right">114[MHz]</td>
    <td align="right">1444[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">4</td>
    <td align="right">84</td>
    <td align="right">2833,4629</td>
    <td align="right">137[MHz]</td>
    <td align="right">1680[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right" rowspan="2">2</td>
    <td align="right">0</td>
    <td align="right">40</td>
    <td align="right">2964,5729</td>
    <td align="right">73[MHz]</td>
    <td align="right">1879[Mbit/sec]</td>
  </tr>
  <tr>
    <td align="right">1</td>
    <td align="right">41</td>
    <td align="right">2965,5762</td>
    <td align="right">78[MHz]</td>
    <td align="right">1948[Mbit/sec]</td>
  </tr>
</table>


###シミュレーション###

####他に必要なファイル####
シミュレーションをするためには次のファイルが必要です。

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

