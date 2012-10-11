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
    <td align="right">1547,3080</td>
    <td align="right">188[MHz]</td>
    <td align="right">1418[Mbit/sec]</td>
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
    <td align="right">1537,2914</td>
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
    <td align="right">3093,8934</td>
    <td align="right">123[MHz]</td>
    <td align="right">1505[Mbit/sec]</td>
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
    <td align="right">3092,8705</td>
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

