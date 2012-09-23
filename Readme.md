SH1 Digest Generator VHDL RTL.
------------------------------

###概要###
SH1を計算する論理合成可能なVHDLモジュールです.

###シミュレーション###
シミュレーションをするためには次のファイルが必要です。

* PipeWorkのコンポーネント宣言パッケージ components.vhd (<https://github.com/ikwzm/PipeWork.git>)
* 異なるデータ幅のパスを継ぐためのアダプタ reducer.vhd (<https://github.com/ikwzm/PipeWork.git>)

シミュレーションには GHDL (http://ghdl.free.fr/) を使いました。
Makefile を用意したので、make コマンド一発でシミュレーションが走ります。
もしかしたら他のシミュレーションでは走らないかもしれません。その際はご一報ください。


###ライセンス###
二条項BSDライセンス (2-clause BSD license) で公開しています。

