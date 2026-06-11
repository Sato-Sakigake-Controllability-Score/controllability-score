# 可制御性スコア計算プログラム
<!-- 2026/03/18 梅津 -->
## 1. はじめに

本プロジェクトは，可制御性スコアの計算を目的としたMATLABライブラリである．
主にシステム行列 $ A $ と終端時刻 $ T $ を受け取り，可制御性スコア(VCS, AECS)を出力する．

### 動作環境
- MATLAB バージョン：R2024a以上
- 必要なツールボックス：Control System Toolbox
- 開発用環境：Python >= 3.7, < 4.0，MISS_HIT 0.9.44

開発や Pull Request の手順は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください．

### 要改善部分
- `gramian.infLyapScale_`
  - 虚軸上の固有値部分のグラミアンの計算が近似であり，ジョルダンブロックがある場合に不安定になる可能性がある．
  - 今のところアルゴリズムの改善方法は不明
---

## 2. 全体構成の概要

本プロジェクトは以下のディレクトリ構成を持つ．

``` 
project/
├─ vcs.m                    % メインAPI
├─ aecs.m                   % メインAPI
├─ bothcs.m                 % メインAPI
│
├─ @CSProblem/              % 問題設定
├─ @CSResult/               % 結果
├─ @CSOptions/              % オプション
│
├─ @WList                   % W処理用クラス
├─ @ProjectedGradientSolver % 最適化ソルバ
├─ @WOptions                % W計算用オプション
├─ @PGSolverOptions         % 最適化用オプション
│
├─ +gramian/                % Gramian計算
├─ +csutil/                 % 共通処理
│
├─ examples/                % 使用例
├─ README.md                % 本ドキュメント
└─ LICENSE                  % ライセンス
```
主な構成要素の役割は以下のとおりである．

- `vcs.m`：VCSの計算を行うメイン関数
- `aecs.m`：AECSの計算を行うメイン関数
- `bothcs.m`：VCSの計算とAECSの計算を両方行うメイン関数
- `@CSProlbem`：問題設定を表すクラス
- `@CSResult`：計算結果を保持するクラス

---

## 3. 主要な要素
| 名称                     | 種類  | 役割         |
| ----------------------- | ----- | ---------- |
| vcs, aecs, bothcs       | 関数  | 指標の計算  |
| CSProblem               | クラス | 問題設定       |
| CSOptions               | クラス | オプション管理    |
| CSResult                | クラス | 結果の保持      |
| gramian.computeGramian | 関数  | Gramian 計算 |


## 4. 各モジュールの説明

### 4.1 トップレベル関数（`vcs.m`, `aecs.m`, `bothcs.m`）

本関数はVCS，AECSを計算するための基本関数である． \
`vcs.m`はVCSを（オプションで計算過程の情報とともに）出力する． \
`aecs.m`はAECSを（オプションで計算過程の情報とともに）出力する． \
`bothcs.m`は両方を出力する． \
アルゴリズムの最初に  $`W_1,\ldots,W_n`$  を一度に計算し，それをもとにVCSとAECSを計算するため，`vcs.m`，`aecs.m`を順に呼び出すよりも`bothcs.m`を呼び出す方が効率的である． \
（特に， $`W_1,\ldots,W_n`$ の計算コストが大きい場合に顕著になる．） \
`CSProblem`オブジェクトを生成したのち，`CSProblem.solveVcs`, `CSProblem.solveAecs`によってVCS，AECSを計算する．

- 入力：
  -  $`A`$ ：システム行列
    - 型　：double matrix
    - 制約：正方行列
---
- オプション入力 (Name=Valueで渡す)：
  -  $`T`$ ：終端時刻
    - 型　：double scalar
    - 制約： $`T>0`$ 
    - 既定： $`T=\infty`$ 
    - 第2引数で渡すこともできる
    （vcs(A, t) or vcs(A, T=t)）
  - CSOptions： $`W`$ 計算および最適化用オプション
    - 型　：CSOptions scalar
    - 以下のオプション入力があれば上書きされる
  ---
  - Method：計算方法
    - 型　：string scalar or char vector
    - 制約："lyap" or "integral"
    - 既定："lyap"
  - Steps：分点数（数値積分用）
    - 型　：double scalar
    - 制約：整数， $` \geq0 `$ 
    - 既定： $`0 `$ 
  - UseScaling：スケーリング有無
    - 型　：logical scalar or double scalar
    - 制約： $`0`$  or  $`1`$  (if double)
    - 既定：true
  - EigTol：しきい値（固有値計算用）
    - 型　：double scalar
    - 制約： $` \geq0 `$ 
    - 既定： $` 10^{-12} `$ 
  - WOptions： $`W`$ 計算用オプション
    - 型　：WOptions scalar
    - Method, Steps, UseScaling, EigTolの入力があれば上書きされる
  ---
  - StepSize：最適化ステップサイズ
    - 型　：double scalar
    - 制約： $` >0 `$ 
    - 既定： $` 0.1 `$ 
  - StepSizeInf：最適化ステップサイズ下限
    - 型　：double scalar
    - 制約： $` >0 `$ 
    - 既定： $` 10^{-12} `$ 
  - MaxIter：最大反復回数（最適化）
    - 型　：double scalar
    - 制約：整数， $` >0 `$ 
    - 既定：1000
  - Tol：しきい値（収束判定用）
    - 型　：double scalar
    - 制約： $` >0 `$ 
    - 既定： $` 10^{-8} `$ 
  - Rho：バックトラッキング用パラメータ
    - 型　：double scalar
    - 制約： $` >0 `$ ， $` <1 `$ 
    - 既定： $` 0.5 `$ 
  - Sigma：アルミホ条件用パラメータ
    - 型　：double scalar
    - 制約： $` >0 `$ ， $` <1 `$ 
    - 既定： $` 10^{-4} `$ 
  - Verbose：途中経過表示有無
    - 型　：logical scalar
    - 既定：false
  - StoreTrace：途中結果格納有無
    - 型　：logical scalar
    - 既定：false
  - SolverOptions：最適化用オプション
    - 型　：PGSolverOptions scalar
    - StepSize, StepSizeInf, MaxIter, Tol, Rho, Sigma, Verbose, StoreTrace, SolverOptionsの入力があれば上書きされる
---
---
- 出力：
  -  $`p`$ ：VCS，AECS
    - 型　：double vector
    -  $`A`$ と同じサイズ
---
- オプション出力：
  - info：最適化結果
    - 型　：CSResult scalar
---
---
- 使用例：
  - `vcs(A)` ( $`T=\infty`$ )
  - `p = vcs(A)` ( $`T=\infty`$ )
  - `p = vcs(A, t)`
  - `p = vcs(A, T=t)`
  - `[p, info] = vcs(A, T=t, Method="integral", Steps=50)`
  - `[pV, pA] = bothcs(A)`
  - `[pV, pA, infoV, infoA] = bothcs(A)`


### 4.2 クラス（`CSProblem`）

本クラスは問題設定を表す． \
入力を受け取ると，`gramian.computeGramian`によって $`W_1,\ldots,W_n`$ を計算する． \
`CSProblem.solveVcs`,`CSProblem.solveAecs`によってVCS，AECSを計算することができる．

- プロパティ：
  - WList： $`W_1,\ldots,W_n`$ のコンテナ，および $`f(W(p))`$ の計算
    - 型　：WList scalar
  - Dimension：問題の次元（ $`=n`$ ）
    - 型　：double scalar
  - InitialGuess：初期解
    - 型　：double vector
---
#### 4.2.1 コンストラクタ `obj = CSProblem(A, varargin)`
- 入力：
  -  $`A`$ ：システム行列
    - 型　：double matrix
    - 制約：正方行列
---
- オプション入力 (Name=Valueで渡す)：
  -  $`T`$ ：終端時刻
    - 型　：double scalar
    - 制約： $`T>0`$ 
    - 既定： $`T=\infty`$ 
    - 第2引数 or Name=Valueで渡す
    （vcs(A, t) or vcs(A, T=t)）
  - WOptions： $`W`$ 計算用オプション
    - 型　：WOptions scalar
    - 既定：WOptions()
  - InitialGuess：初期解
    - 型　：double vector
    - 制約：サイズ $`n`$ 
    - 既定： $` \frac{1}{n}\bm{1} `$ 
    - 与えられた初期解は $`n`$ 次元標準単体へ射影される．
    - 初期解が実行可能でなければ（ $`W(p)`$ が特異なら）`CSProblem.solveVcs`,`CSProblem.solveAecs`によってその値が返され，ExitFlag=-2となる．
---
- 注意：
  - コンストラクタ内部で`gramian.computeGramian`を実行し， $`W_1,\ldots,W_n`$ を計算するため，大規模問題の場合は計算時間のボトルネックになる．
---
---
- 使用例：
  - `prob = CSProblem(A)` ( $`T=\infty`$ )
  - `prob = CSProblem(A, T=t, InitialGuess=p)`
---
#### 4.2.2 主なメソッド `CSProblem.solveVcs`,`CSProblem.solveAecs`
- オプション入力 (Valueで渡す)：
  - solopts：システム行列
    - 型　：PGSolverOptions scalar
    - 既定：PGSolverOptions()
---
---
- 出力：
  -  $`p`$ ：VCS，AECS
    - 型　：double vector
    -  $`A`$ と同じサイズ
---
- オプション出力：
  - info：最適化結果
    - 型　：CSResult scalar
---
---
- 使用例：
  - `prob.solveVcs`
  - `p = prob.solveVcs`
  - `[p, info] = prob.solveVcs(solopts)`
---
#### 4.2.3 関数値評価メソッド `CSProblem.fVcs`,`CSProblem.gradVcs`,`CSProblem.fAecs`,`CSProblem.gradAecs`
- `ProjectedGradientSolver`オブジェクトによって最適化が実行されるときに呼び出される．
- `WList.evalVcs`, `WList.evalAecs`を呼び出すことによって計算される．
---
### 4.3 クラス（`CSOptions`）
本クラスは計算に必要なオプションをすべて管理する． \
主なプロパティとして，WOptionsとSolverOptionsを持つ． \
WOptions，SolverOptionsのプロパティを直接変更することもできる．（4.3.1，4.3.2参照）

- 主なプロパティ：
  - WOptions： $`W`$ 計算用オプション
    - 型　：WOptions scalar
    - Method, Steps, UseScaling, EigTolへの代入があれば上書きされる
  - SolverOptions：最適化用オプション
    - 型　：PGSolverOptions scalar
    - StepSize, StepSizeInf, MaxIter, Tol, Rho, Sigma, Verbose, StoreTrace, SolverOptionsへの代入があれば上書きされる
- 依存プロパティ：
  - WOptionsとSolverOptionsのプロパティ
    - ゲッタとセッタを持つ
---
#### 4.3.1 コンストラクタ `obj = CSOptions(varargin)`
- オプション入力 (Name=Valueで渡す)：
  - Method, Steps, UseScaling, EigTol：トップレベル関数と同じ
  - WOptions：トップレベル関数と同じ
    - Method, Steps, UseScaling, EigTolの入力があれば上書きされる
  ---
  - StepSize, StepSizeInf, MaxIter, Tol, Rho, Sigma, Verbose, StoreTrace：トップレベル関数と同じ
  - SolverOptions：トップレベル関数と同じ
    - StepSize, StepSizeInf, MaxIter, Tol, Rho, Sigma, Verbose, StoreTrace, SolverOptionsの入力があれば上書きされる
---
---
- 使用例：
  - `csopts = CSOptions(UseScaling = false, WOptions = wopts)`
    - `csopts.WOptions`に`wopts`が代入されるが，`csopts.WOptions.UseScaling`は`false`に設定される．（`wopts.UseScaling`にはよらない．）
---
#### 4.3.2 ゲッタとセッタ
- `WOptions`, `SolverOptions`の他，これらのプロパティのゲッタとセッタも実装されており，直接上書きできる．
- 使用例：
  - `csopts.UseScaling = false`　(`csopts.WOptions.UseScaling = false`と同じ操作)

### 4.4 クラス（`WOptions`）
本クラスは $`W`$ の計算に必要なオプションを管理する． \
実際に $`W_1,\ldots,W_n`$ を計算する際には`gramian.computeGramian`を呼ぶ． \
また， $`W_1,\ldots,W_n`$ を計算した後は`WList`オブジェクトに格納し，そのメソッドによって必要な計算を行う．

- プロパティ：
  - Method：計算方法
    - 型　：string scalar or char vector
    - 制約："lyap" or "integral"
    - 既定："lyap"
  - Steps：分点数（数値積分用）
    - 型　：double scalar
    - 制約：整数， $`\geq 0`$ 
    - 既定： $`0`$ 
  - UseScaling：スケーリング有無
    - 型　：logical scalar or double scalar
    - 制約： $`0`$  or  $`1`$  (if double)
    - 既定：true
  - EigTol：しきい値（固有値計算用）
    - 型　：double scalar
    - 制約： $`\geq 0`$ 
    - 既定： $`10^{-12}`$ 
---
- プロパティの依存関係：
  - MethodとSteps
    - Method="lyap"のときは，WOptions.Stepsを呼び出すと $`0`$ が返される．（内部的にはもとの数値を保持．）
    - Method="integral"かつSteps=0でgramian.computeGramianを実行しようとするとエラー
  - UseScalingとEigTol
    - UseScaling=falseのときは，WOptions.EigTolを呼び出すと $`0`$ が返される．（内部的にはもとの数値を保持．）

### 4.5 クラス（`PGSolverOptions`）
本クラスは最適化実行に必要なオプションを管理する． \
実際に最適化を行う際には`ProjectedGradientSolver.solve`を呼ぶ． \
計算結果は`CSResult`に格納される．
- プロパティ：
  - StepSize：最適化ステップサイズ
    - 型　：double scalar
    - 制約： $`>0`$ 
    - 既定： $`0.1`$ 
  - StepSizeInf：最適化ステップサイズ下限
    - 型　：double scalar
    - 制約： $`>0`$ 
    - 既定： $`10^{-12}`$ 
  - MaxIter：最大反復回数（最適化）
    - 型　：double scalar
    - 制約：整数， $`>0`$ 
    - 既定：1000
  - Tol：しきい値（収束判定用）
    - 型　：double scalar
    - 制約： $`>0`$ 
    - 既定： $`10^{-8}`$ 
  - Rho：バックトラッキング用パラメータ
    - 型　：double scalar
    - 制約： $`>0`$ ， $`<1`$ 
    - 既定： $`0.5`$ 
  - Sigma：アルミホ条件用パラメータ
    - 型　：double scalar
    - 制約： $`>0`$ ， $`<1`$ 
    - 既定： $`10^{-4}`$ 
  - Verbose：途中経過表示有無
    - 型　：logical scalar
    - 既定：false
  - StoreTrace：途中結果格納有無
    - 型　：logical scalar
    - 既定：false

### 4.6 クラス（`CSResult`）
本クラスは最適化の計算結果を格納する． \
実際に最適化を行う際には`ProjectedGradientSolver.solve`を呼ぶ． 
- プロパティ：
  - ObjectiveValue：終了時の目的関数値
    - 型　：double scalar
  - Gradient：終了時の勾配（射影勾配法であるため， $`\bm{0}`$ にはならない）
    - 型　：double vector
  - GradNorm：終了時の勾配のノルム（射影勾配法であるため， $`0`$ にはならない）
    - 型　：double scalar
  - StepNorm：終了時の更新幅のノルム（収束判定条件に用いられる）
    - 型　：double scalar
  - Iterations：反復回数
    - 型　：double scalar
  - FuncCount：目的関数の評価回数
    - 型　：double scalar
  - Converged：収束有無
    - 型　：logical scalar
  - ExitFlag：終了理由
    - 型　：double scalar
    - 制約：整数
      - 1：収束（更新幅 $`<`$ しきい値）
      - 0：最大更新回数到達
      - -1：Armijo条件が満たされず終了
      - -2：初期点が実行可能領域になく（ $`W(p)`$ が正定値にならず）終了
      - -3：Armijo条件で採用された点が実行領域外にあり終了（例外的）
  - ExitMessage：終了メッセージ
    - 型　：string scalar
  - Algorithm：使用されたアルゴリズム
    - 型　：string scalar
    - "ProjectedGradient (Armijo, projection arc)"（現状不要，拡張時に変更）
  - SolverOptions：使用されたオプション
    - 型　：PGSolverOptions scalar
  - ProblemInfo：問題の情報（現状不要，拡張時に変更）
    - 型　：struct
  - Trace：途中経過の情報を格納
    - 型　：struct
    - StoreTrace=trueの場合に途中の数値情報を格納
      - Iteration
      - Fval
      - StepNorm
      - Alpha
      - FuncCount

### 4.7 クラス（`ProjectedGradientSolver`）
本クラスは最適化ソルバ用のクラスである． \
目的関数と初期点を与えて`solve`メソッドを呼び出すことで，射影勾配法を実行する．
- プロパティ：
  - StepSize：最適化ステップサイズ
    - 型　：double scalar
    - 制約： $`>0`$ 
    - 既定： $`0.1`$ 
  - StepSizeInf：最適化ステップサイズ下限
    - 型　：double scalar
    - 制約： $`>0`$ 
    - 既定： $`10^{-12}`$ 
  - MaxIter：最大反復回数（最適化）
    - 型　：double scalar
    - 制約：整数， $`>0`$ 
    - 既定：1000
  - Tol：しきい値（収束判定用）
    - 型　：double scalar
    - 制約： $`>0`$ 
    - 既定： $`10^{-8}`$ 
  - Rho：バックトラッキング用パラメータ
    - 型　：double scalar
    - 制約： $`>0`$ ， $`<1`$ 
    - 既定： $`0.5`$ 
  - Sigma：アルミホ条件用パラメータ
    - 型　：double scalar
    - 制約： $`>0`$ ， $`<1`$ 
    - 既定： $`10^{-4}`$ 
  - Verbose：途中経過表示有無
    - 型　：logical scalar
    - 既定：false
  - StoreTrace：途中結果格納有無
    - 型　：logical scalar
    - 既定：false
#### 4.7.1 主なメソッド `ProjectedGradientSolver.solve`
- 入力：
  - fun：目的関数
    - 型　：function handle
  - p0：初期解
    - 型　：double vector
---
---
- 出力：
  - p：最適解
    - 型　：double vector
  - info：計算結果
    - 型　：CSResult
---

### 4.8 クラス（`WList`）
本クラスは $`W_1,\ldots,W_n`$ の配列の保持と関連する計算を行う． \
スケーリングを行う場合には，スケーリングされた可制御性グラミアンを保持する． \
点 $`p`$ を与えて`evalVcs`、`evalAecs`メソッドを呼び出すことで，目的関数とその勾配を評価することができる．
- プロパティ：
  -  $`W`$ ：可制御性グラミアンの配列
    - 型　：cell vector
    -  $`n`$ 個の要素からなるcell配列であり，各要素もcell配列となっている．
     $`W_1,\ldots,W_n`$ がブロック対角行列の構造を持つときに，対応する`W`の要素は各対角ブロックを保持する．
    - 主な制約は以下の通りである．
    - `W`の要素は $`n`$ 個であること
    - `W{1}`，．．．，`W{n}`は同じサイズであること．
    - `W{1}`，．．．，`W{n}`のそれぞれの同じ位置の要素は，同じサイズを持つ実正方行列であること．
    - 各要素の満たす制約は`validateWList_`を実行することで検証する．
  -  $`Q`$ ：座標変換行列
    - 型　：double matrix or []
    - スケーリングを行う際に， $`Q^{-1}AQ`$ がブロック対角行列になるような行列を表す．
    - `CSOptions.WOptions.UseScaling`が`false`の場合，あるいは $`A`$ をブロック対角化する必要がない場合は`[]`を保持する．
  -  $`S_\mathrm{a}`$ ：AECSの関数評価に利用する定数行列
    - 型　：cell vector
    -  $`\widetilde{W}(p)`$ を通常の可制御性グラミアン， $`W(p)`$ をスケーリングされた可制御性グラミアンとし，
       ```math
        \widetilde{W}(p)=QDW(p)D^\top Q^\top
       ```
      を満たすとき，AECSの目的関数は
       ```math
       \begin{align*}
        g(p)&=\operatorname{tr}\left(\widetilde{W}(p)^{-1}\right) \\
        &=\operatorname{tr}\left(Q^{-\top}D^{-\top}W(p)^{-1}D^{-1}Q^{-1}\right) \\
        &=\operatorname{tr}\left(W(p)^{-1}D^{-1}Q^{-1}Q^{-\top}D^{-\top}\right)
      \end{align*}
      ```
      と表される．
      `Sa`は $`D^{-1}Q^{-1}Q^{-\top}D^{-\top}`$ を表す．
      ただし，目的関数評価に必要なのは $`W(p)`$ のもつブロック対角構造と同じブロック対角部分のみである．
      そこで，`Sa`はブロック対角要素を各cell要素として持つ．
    - `CSOptions.WOptions.UseScaling`が`false`の場合，あるいは $`A`$ をブロック対角化する必要がない場合は`[]`からなるcell配列を保持する．
    - サイズ等に関する制約は`validateWList_`を実行することで検証する．
  - vcsBlocks, aecsBlocks：目的関数評価に使用するブロック位置を表す配列
    - 型　：double vector
    - VCSは全ブロックを使用，AECSは左上ブロックのみを使用するため，そのことを明示する．（現状はプロパティとして保持することは不要，拡張時に変更）
  - blockSizes：各ブロック対角行列のサイズ
    - 型　：double vector
  - n：問題の次元
    - 型　：double scalar
  - nb：ブロック対角要素の数
    - 型　：double scalar
    - ここでの例では， $`\ell`$ を表す．
  - WOptions：使用した $`W`$ 計算用オプション
    - 型　：WOptions scalar

例えば,

```math
W_1=
\begin{pmatrix}
    W_{1,1} & & \\
    & \ddots & \\
    & & W_{1,\ell}
\end{pmatrix}
, \ldots, W_n=
\begin{pmatrix}
    W_{n,1} & & \\
    & \ddots \\
    & & W_{n,\ell}
\end{pmatrix}
```

というブロック構造を持つとき，`W{1}{k}`は $`W_{1,k}`$ を表すdouble配列である．

例えば，
```math
W(p)=
\begin{pmatrix}
W_1(p) \\
& \ddots \\
& & W_\ell(p)
\end{pmatrix},
S_{\mathrm{a}}=
\begin{pmatrix}
S_{\mathrm{a}, 1, 1} & \cdots & S_{\mathrm{a}, 1, n} \\
\vdots & \ddots & \vdots \\
S_{\mathrm{a}, n, 1} & \cdots & S_{\mathrm{a}, n, n}
\end{pmatrix}
```

というブロック構造を持つときに，`Sa{k}`は $`S_{\mathrm{a}, k, k}`$ を表すdouble配列である．

#### 4.8.1 主なメソッド `WList.evalVcs`
- 入力：
  -  $`p`$ ：目的関数評価を行う点
    - 型　：double vector
---
- 出力：
  -  $`f`$ ：VCSの目的関数値 $`f_{\mathrm{VCS}}(p)`$ 
    - 型　：double scalar
---
- オプション出力：
  -  $`g`$ ：VCSの目的関数の勾配 $`\nabla f_{\mathrm{VCS}}(p)`$ 
    - 型　：double vector
---
---
- 使用例：
  - `f = wlist.evalVcs(p)`
  - `[f, g] = wlist.solveVcs(p)`
---
- アルゴリズム：
  -  $`W(p)`$ の固有値分解を行い，正定値性の判定と $`\log\det W(p)`$ の計算を行う．
---

#### 4.8.2 主なメソッド `WList.evalAecs`
- 入力：
  -  $`p`$ ：目的関数評価を行う点
    - 型　：double vector
---
- 出力：
  -  $`f`$ ：AECSの目的関数値 $`f_{\mathrm{AECS}}(p)`$ 
    - 型　：double scalar
---
- オプション出力：
  -  $`g`$ ：AECSの目的関数の勾配 $`\nabla f_{\mathrm{AECS}}(p)`$ 
    - 型　：double vector
---
---
- 使用例：
  - `f = wlist.evalAecs(p)`
  - `[f, g] = wlist.solveAecs(p)`
---
- アルゴリズム：
  -  $`W(p)`$ の固有値分解を行い，正定値性の判定と $`\operatorname{tr}\left(W(p)^{-1}\right)`$ の計算を行う．
---

### 4.9 名前空間（`+gramian`）
可制御性グラミアンの計算を実装．
#### 4.9.1 主な関数 `gramian.computeGramian`
- 入力：
  -  $`A`$ ：システム行列
    - 型　：double matrix
    - 制約：正方行列
  -  $`T`$ ：終端時刻
    - 型　：double scalar
    - 制約： $`T>0`$ 
  - wopts： $`W`$ 計算用オプション
    - 型　：WOptions scalar
---
- 出力：
  - wlist：問題に対する可制御性グラミアンを格納したWListオブジェクト
    - 型　：WList scalar
---
- アルゴリズム：
  - `T`，`wopts.UseScaling`，`wopts.Method`の値に応じて，`gramian.infLyapScale_`，`gramian.infLyapNoscale_`，`gramian.finLyapScale_`，`gramian.finLyapNoscale_`，`gramian.finIntegralScale_`，`gramian.finIntegralNoscale_`のいずれかを呼び出し，WListオブジェクトを計算する．

#### 4.9.2 主な関数 `gramian.blockDiagonalization_`
与えられた行列 $`A`$ のブロック対角化とその変換行列を求める．
 ```math 
  Q^{-1}AQ=
  \begin{pmatrix}
    A_- \\
    & A_0 \\
    & & A_+
  \end{pmatrix}
 ```
とブロック対角化する．
- 入力：
  -  $`A`$ ：システム行列
    - 型　：double matrix
    - 制約：正方行列
  - wopts： $`W`$ 計算用オプション
    - 型　：WOptions scalar
- 注意：
  - 固有値の分離においてwopts.EigTolを閾値として用いる．
  - 絶対値がwopts.EigTol未満の固有値は，虚軸上の固有値として判定する．

#### 4.9.3 他の主な関数
- `gramian.infLyapScale_`
  -  $`T=\infty`$ において，Lyapunov方程式
     ```math
     \begin{gather*}
      A_-W_{i,-}+W_{i,-}A_-+q_{i,-}q_{i,-}^\top=0 \\
      (A_0-\varepsilon I)W_{i,0}+W_{i,0}(A_0-\varepsilon)^\top+q_{i,0}q_{i,0}^\top=0 \\
      (-A_+)W_{i,+}+W_{i,+}(-A_+)+q_{i,+}q_{i,+}^\top=0 \\
    \end{gather*}
    ```
    を用いて計算する．（スケーリングあり， $`\varepsilon=10^{-8}`$ ） \
    **W_{i,0}の計算方法は一時的に設定しているものであり，厳密ではなく不安定になる可能性がある（要改善）**
- `gramian.infLyapNoscale_`
  -  $`T=\infty`$ において，Lyapunov方程式
     ```math
      AW_i+W_iA+e_ie_i^\top=0
     ```
    を用いて計算する．（スケーリングなし）
- `gramian.finLyapScale_`
  -  $`T<\infty`$ において，Lyapunov方程式とvan Loan (1978)を用いて計算する．（スケーリングあり）
- `gramian.finLyapNoscale_`
  -  $`T<\infty`$ において，Lyapunov方程式
     ```math
      AW_i+W_iA=e^{AT}e_ie_i^\top e^{A^\top T}-e_ie_i^\top
     ```
    を用いて計算する．（スケーリングなし）
- `gramian.finIntegralScale_`
  -  $`T<\infty`$ において，数値積分を用いて計算する．（スケーリングあり）
- `gramian.finIntegralNoscale_`
  -  $`T<\infty`$ において，数値積分を用いて計算する．（スケーリングなし）
---

### 4.10 名前空間（`+csutil`）
クラスに依存しない処理を実装．
- 主な関数
  - projectOntoSimplex
    - 標準単体上へのユークリッド射影
  - isposdef
    - 行列の正定値対象性を判定
---

## 5. 処理の流れ
本プロジェクトにおける基本的な処理の流れは以下のとおりである．

1. ユーザーが`vcs(...)`を呼び出す． \
入力をもとに`WOptions`オブジェクトと`PGSolverOptions`オブジェクトが生成される．
2. 入力と`WOptions`オブジェクトをもとに`CSProblem`オブジェクトを生成する． \
その際に，`gramian.computeGramian`によって $`W_1,\ldots,W_n`$ を計算する．
3. `CSProblem`オブジェクトに`PGSolverOptions`オブジェクトを渡し，`solveVcs`メソッドを実行する．
4. `ProjectedGradientSolver`オブジェクトが生成され，`PGSolverOptions`オブジェクトを渡し，`solve`メソッドが実行される． \
その際に，アルミホ条件に基づいた射影勾配法が実行される．
5. 計算結果を`CSResult`に格納して返す．


## 6. 使用例
以下に基本的な使用例を示す．

```matlab
    vcs(A) % T=\infty，コマンドウィンドウに表示
    p = vcs(A) % T=\infty
    p = vcs(A, t) % ValueでのTの引数指定
    p = vcs(A, T=t) % Name=ValueでのTの引数指定
    [p, info] = vcs(A, T=t, Method="integral", Steps=50) % 可制御性グラミアンを数値積分で計算，infoは計算結果の情報を格納
    [pV, pA] = bothcs(A) % VCS, AECSの両方を計算，グラミアンの重複計算を回避
    [pV, pA, infoV, infoA] = bothcs(A) % VCS, AECS両方の計算結果の情報を格納
```


## 7. ターゲット可制御性スコアへの拡張に向けて
目的関数は，通常の可制御性スコアとほとんど同じであるため，WListは概ね修正不要と思われる．
`gramian.computeGramian`を修正し，ターゲット可制御性スコア用の可制御性グラミアン等を計算した上でWListへ渡せば問題ないと思われる．
無限時間区間への拡張ができるかは不明である．

## Citation

このソースコードを論文内で利用した場合は，以下の文献を引用してください．

```bibtex
@article{sato2024controllability,
  title={Controllability scores for selecting control nodes of large-scale network systems},
  author={Sato, Kazuhiro and Terasaki, Shun},
  journal={IEEE Transactions on Automatic Control},
  volume={69},
  number={7},
  pages={4673--4680},
  year={2024},
  publisher={IEEE}
}

@article{sato2025uniqueness,
  title={Uniqueness analysis of controllability scores and their application to brain networks},
  author={Sato, Kazuhiro and Kawamura, Ryohei},
  journal={IEEE Transactions on Control of Network Systems},
  volume={12},
  number={4},
  pages={2568--2580},
  year={2025},
  publisher={IEEE}
}

@article{umezu2026infinite,
  title={Infinite-horizon controllability scores for linear time-invariant systems},
  author={Umezu, Kota and Sato, Kazuhiro},
  journal={arXiv preprint arXiv:2601.10260},
  year={2026}
}
```

## License

This software is released under the MIT License. See `LICENSE` for details.

## Contributors

This software has been developed by members of the Sato Group.

Project lead:

- Kazuhiro Sato

Main contributors:

- Kota Umezu
- Ritsuki Yamada

## Contact

For questions or bug reports, please open an issue on GitHub or contact:

Kazuhiro Sato  
kazuhiro[at]mist.i.u-tokyo.ac.jp
