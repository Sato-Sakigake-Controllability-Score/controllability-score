# 使用例

このディレクトリには，controllability score を計算するための MATLAB 使用例を配置する．

各 example ファイルは，リポジトリのルートディレクトリからそのまま実行できる MATLAB スクリプトとして実装している．

## 基本例

- `ex01_minimal_bothcs.m`: `bothcs` によって VCS と AECS を同時に計算する例. `vcs`，`aecs`，`bothcs` の使い分けを比較や, `infoV` と `infoA` に格納される計算結果の確認も含む
- `ex02_finite_horizon.m`: 有限時間ホライズン `T` を指定する例
- `ex03_options_lyap_integral.m`: Gramian の計算方法を比較する例

## 実験例

- `ex04_edge_weight_sweep.m`: 1本のエッジ重みを変化させ，スコアの変化を可視化する例
- `ex05_visualize_scores.m`: GUI で作成した隣接行列に自己ループを加え，VCS と AECS の重みを出力・プロットする例

## 注意

MATLAB が本プロジェクトの関数を見つけられるように，使用例はリポジトリのルートディレクトリから実行する．
