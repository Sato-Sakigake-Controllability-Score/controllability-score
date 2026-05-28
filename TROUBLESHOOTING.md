# Troubleshooting

このドキュメントは，controllability-score を使うときや開発するときに起こりやすい問題と対処をまとめたものです．

## MATLAB から関数が見つからない

### 症状

```matlab
関数または変数 'bothcs' が認識されません。
```

または `vcs`, `aecs`, `CSOptions` などが見つからない．

### 対処

MATLAB のカレントディレクトリをリポジトリのルートにするか，ルートディレクトリを MATLAB パスに追加してください．

```matlab
addpath("/path/to/controllability-score")
```

サンプルを動かす場合も，`examples/` ではなくリポジトリのルートをパスに追加した状態で実行します．

```matlab
addpath("/path/to/controllability-score")
run("examples/ex01_minimal_bothcs.m")
```

## `lyap` が見つからない

### 症状

```matlab
Unrecognized function or variable 'lyap'.
```

または Control System Toolbox に関するエラーが出る．

### 対処

本プロジェクトでは Gramian 計算に `lyap` を使うため，Control System Toolbox が必要です．MATLAB 上で次を確認してください．

```matlab
ver
which lyap
```

`lyap` が見つからない場合は，Control System Toolbox をインストールした MATLAB 環境で実行してください．

## 入力行列 `A` の検証で止まる

### 症状

`A` に関して，正方行列，実数行列，double 行列であることを求めるエラーが出る．

```matlab
次を使用中のエラー: vcs
1 番目の入力引数 Aは正方行列にする必要があります。
```

### 対処

`A` は `double` 型の実正方行列である必要があります．隣接行列やラプラシアンから作る場合も，最後にサイズと型を確認してください．

```matlab
size(A)
class(A)
isreal(A)

A = double(A);
```

`A` に `NaN` や `Inf` が含まれる場合も，計算結果が不安定になります．

## `T=inf` と `Method="integral"` を同時に指定している

### 症状

```matlab
T=inf does not allow WOptions.Method="integral".
```

### 原因

無限時間ホライズン `T=inf` では，数値積分法 `Method="integral"` は使えません．

### 対処

無限時間で計算する場合は，既定の `Method="lyap"` を使ってください．

```matlab
[pV, pA] = bothcs(A);
```

数値積分を使いたい場合は，有限の `T` と `Steps >= 1` を指定します．

```matlab
T = 2.0;
[pV, pA] = bothcs(A, T, Method="integral", Steps=80);
```

## `Steps must be >= 1` と出る

### 症状

```matlab
Steps must be >= 1 when Method is "integral".
```

### 対処

`Method="integral"` を使う場合は，`Steps` に 1 以上の整数を指定してください．

```matlab
p = vcs(A, T=2.0, Method="integral", Steps=50);
```

`Method="lyap"` のときは，`Steps` は使われません．



## `A is unstable` と出る

### 症状

```matlab
computeGramian:A is unstable.
```

または target 版で次のようなエラーが出る．

```matlab
computeTargetGramian:A is unstable.
```

### 原因

`UseScaling=false` の無限時間計算では，安定な `A` が必要です．

### 対処

まず既定の `UseScaling=true` を使ってください．

```matlab
p = vcs(A);
```

それでも数値的に不安定な場合は，有限時間ホライズンを指定します．

```matlab
p = vcs(A, T=2.0);
pTarget = vcs(A, T=2.0, TargetNodes=[1 3 5]);
```

ネットワークの隣接行列をそのまま使っている場合は，自己ループを引くなどして安定化したシステム行列を作る方法もあります．

```matlab
selfLoopWeight = 2.0;
A = adjacency - selfLoopWeight * eye(size(adjacency, 1));
```



## solver が収束しない，または `Converged` が false になる

### 症状

`info.Converged` が `false` になる，または `info.ExitMessage` が収束失敗を示す．

### 対処

まず solver 情報を受け取って，終了理由と反復回数を確認してください．

```matlab
[p, info] = vcs(A, T=2.0, Verbose=true, StoreTrace=true);

info.Converged
info.ExitMessage
info.Iterations
```

反復回数が足りない場合は，`MaxIter` を増やします．収束判定が厳しすぎる場合は，`Tol` を少し大きくします．

```matlab
p = vcs(A, T=2.0, MaxIter=3000, Tol=1e-7);
```

ステップサイズが大きすぎる，または小さすぎる場合は，`StepSize` や `StepSizeInf` も調整してください．

```matlab
p = vcs(A, T=2.0, StepSize=0.05, StepSizeInf=1e-14);
```

# 未検証事項
## 数値積分の結果が `Steps` によって大きく変わる

### 症状

`Method="integral"` を使ったとき，`Steps` を変えると VCS や AECS の値が大きく変わる．または，同じ `Steps` のまま `T` を大きくすると結果が不安定になる．

### 原因

数値積分では，有限時間区間 `[0,T]` を `Steps` で分割して Gramian を近似します．実装では Simpson 則を用いており，刻み幅はおおよそ次の値になります．

```matlab
dt = T / Steps;
```

そのため，`T` に対して `Steps` が少ないと時間刻み `dt` が粗くなり，$e^{At}$ の変化を十分に追えず，正確な Gramian にならない可能性があります．特に，`A` の固有値の絶対値が大きい場合，時間変化が速いため多めの `Steps` が必要になります．

なお，内部では Simpson 則のために `Steps` が奇数の場合は 1 つ増やして偶数として扱います．

### 対処

`Method="integral"` を使う場合は，`T` を大きくしたら `Steps` も増やしてください．例えば，まず `Steps` を倍々に増やして結果が安定するか確認します．

```matlab
T = 10.0;

[pV50,  pA50]  = bothcs(A, T, Method="integral", Steps=50);
[pV100, pA100] = bothcs(A, T, Method="integral", Steps=100);
[pV200, pA200] = bothcs(A, T, Method="integral", Steps=200);

norm(pV200 - pV100)
norm(pA200 - pA100)
```

有限時間で `Method="lyap"` が使える場合は，数値積分の刻み幅に依存しない `Method="lyap"` との比較も有効です．

```matlab
[pVL, pAL] = bothcs(A, T, Method="lyap");
[pVI, pAI] = bothcs(A, T, Method="integral", Steps=200);

norm(pVI - pVL)
norm(pAI - pAL)
```

精度確認をしたい場合は，少なくとも「`Steps` を増やしても結果がほとんど変わらない」ことを確認してから使ってください．

## `UseScaling=true` で固有値や Schur 分解まわりのエラーが出る

### 症状

`SchurFails`，固有値の分類，ブロック対角化，または行列分解に関するエラーが出る．

### 原因

`UseScaling=true` では，固有値に基づく座標変換を使います．重複固有値や虚軸近くの固有値がある場合，数値的に不安定になることがあります．

### 対処

有限時間計算であれば，まず `UseScaling=false` を試してください．

```matlab
[pV, pA] = bothcs(A, T=2.0, UseScaling=false);
```

無限時間で `UseScaling=false` を使う場合は，`A` が安定である必要があります．安定性の確認には固有値を見ます．

```matlab
eig(A)
max(real(eig(A)))
```

`max(real(eig(A))) >= 0` の場合は，有限時間 `T` を指定するか，システム行列の作り方を見直してください．



## `make format` や `make format-check` が失敗する

### 症状

`miss_hit_core` が見つからない，または formatter が失敗する．

### 対処

開発用依存関係をインストールしてください．

```sh
python3 -m pip install -r requirements-dev.txt
```

その後，次を実行します．

```sh
make format
make format-check
```

文字コードや改行に関するエラーが出る場合は，`miss_hit.cfg` と `Makefile` の `--input-encoding utf-8` の指定を確認してください．

## サンプルスクリプトで figure や GUI が表示されない

### 症状

`examples/ex04_visualize_scores.m` などで figure が表示されない，または GUI 関連のエラーが出る．

### 対処

GUI を使うサンプルでは，MATLAB の GUI 表示環境が必要です．リモート環境やヘッドレス環境で実行している場合は，GUI を使わないサンプルから確認してください．

```matlab
run("examples/ex01_minimal_bothcs.m")
run("examples/ex02_finite_horizon.m")
run("examples/ex03_edge_weight_sweep.m")
```

## まず確認する最小例

原因を切り分けたいときは，次の最小例が動くか確認してください．

```matlab
addpath("/path/to/controllability-score")

A = diag([-1.0, -2.0, -3.0]);
[pV, pA, infoV, infoA] = bothcs(A);

disp(pV)
disp(pA)
disp(infoV.ExitMessage)
disp(infoA.ExitMessage)
```

この例が動く場合，MATLAB パス，Control System Toolbox，基本 API は利用できています．次に，実際に使っている `A`，`T`，`Method`，`UseScaling`，`TargetNodes` の指定を一つずつ最小例へ近づけながら確認してください．
