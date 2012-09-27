SHA-1/SHA-256 Digest Generator VHDL RTL.
----------------------------------------

###概要###
SHA-1/SHA-256を計算する論理合成可能なVHDLモジュールです.

論理合成可能です。

１クロックで１、２、４、８ワード(１ワードは32bit)処理できます.

###論理合成###
論理合成を行うためには次のファイルが必要です。

* PipeWorkのコンポーネント宣言パッケージ   components.vhd (<https://github.com/ikwzm/PipeWork.git>)
* 異なるデータ幅のパスを継ぐためのアダプタ reducer.vhd    (<https://github.com/ikwzm/PipeWork.git>)

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
未完成です.

とりあえず簡単なテストはしていますが、完璧ではありません.

###ライセンス###
二条項BSDライセンス (2-clause BSD license) で公開しています。

