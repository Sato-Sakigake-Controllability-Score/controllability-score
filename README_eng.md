# Controllability Score Computation Program
<!-- 2026/03/18 Umezu -->

<table>
	<thead>
		<tr>
			<th style="text-align:center">English</th>
			<th style="text-align:center"><a href="README.md">日本語</a></th>
		</tr>
	</thead>
</table>

## 1. Introduction

This project is a MATLAB library for computing controllability scores.
It mainly takes a system matrix $`A`$ and a terminal time $`T`$ as inputs and outputs controllability scores (VCS, AECS).
In addition, target controllability scores
(target VCS, target AECS) can be computed by `vcs`, `aecs`, and `bothcs` with the `TargetNodes` option.

### Operating Environment
- MATLAB version: R2024a or later
- Required toolbox: Control System Toolbox
- Development environment: Python >= 3.7, < 4.0, MISS_HIT 0.9.44

For development and Pull Request procedures, see [CONTRIBUTING.md](CONTRIBUTING.md).

### Areas for Improvement
- `gramian.infLyapScale_`
  - The computation of the Gramian for the eigenvalue part on the imaginary axis is approximate and may become unstable when Jordan blocks exist.
  - At present, the method for improving the algorithm is unknown.
---

## 2. Overview of the Overall Structure

This project has the following directory structure.

``` 
project/
├─ vcs.m                    % Main API
├─ aecs.m                   % Main API
├─ bothcs.m                 % Main API
│
├─ @CSProblem/              % Problem setting
├─ @CSResult/               % Results
├─ @CSOptions/              % Options
│
├─ @WList                   % Class for W processing
├─ @ProjectedGradientSolver % Optimization solver
├─ @WOptions                % Options for W computation
├─ @PGSolverOptions         % Options for optimization
│
├─ +gramian/                % Gramian computation
├─ +csutil/                 % Common processing
│
├─ examples/                % Usage examples
├─ README_eng.md            % This document (English)
├─ README.md                % Documentation (Japanese)
└─ LICENSE                  % License
```
The roles of the main components are as follows.

- `vcs.m`: Main function that computes VCS
- `aecs.m`: Main function that computes AECS
- `bothcs.m`: Main function that computes both VCS and AECS
- `@CSProblem`: Class representing the problem setting
- `@CSResult`: Class that stores computation results

---

## 3. Main Elements
| Name                    | Type     | Role                  |
| ----------------------- | -------- | --------------------- |
| vcs, aecs, bothcs       | Function | Metric computation    |
| CSProblem               | Class    | Problem setting       |
| CSOptions               | Class    | Option management     |
| CSResult                | Class    | Result storage        |
| gramian.computeGramian | Function | Gramian computation   |


## 4. Description of Each Module

### 4.1 Top-Level Functions (`vcs.m`, `aecs.m`, `bothcs.m`)

#### 4.1.1 API for Ordinary Controllability Scores

These functions are the basic functions for computing VCS and AECS. \
`vcs.m` outputs VCS (optionally together with information about the computation process). \
`aecs.m` outputs AECS (optionally together with information about the computation process). \
`bothcs.m` outputs both. \
Since $`W_1,\ldots,W_n`$ is computed all at once at the beginning of the algorithm and VCS and AECS are computed based on it, calling `bothcs.m` is more efficient than calling `vcs.m` and `aecs.m` sequentially. \
(This is especially noticeable when the computation cost of $`W_1,\ldots,W_n`$ is large.) \
After generating a `CSProblem` object, VCS and AECS are computed by `CSProblem.solveVcs` and `CSProblem.solveAecs`.

- Input:
  -  `A` : system matrix
      - Type: double
      - Constraint: square matrix
---
- Optional inputs (passed as Name=Value):
  -  `T` : terminal time
      - Type: double
      - Constraint: $`T>0`$ 
      - Default: $`T=\infty`$ 
      - It can also be passed as the second argument
      (`vcs(A, t)` or `vcs(A, T=t)`)
  - `CSOptions`: options for $`W`$ computation and optimization
    - Type: CSOptions scalar
    - Overwritten if the following optional inputs are provided
  ---
  - `Method`: computation method
    - Type: string or char vector
    - Constraint: "lyap" or "integral"
    - Default: "lyap"
  - `Steps`: number of grid points (for numerical integration)
    - Type: double
    - Constraint: integer, $` \geq0 `$ 
    - Default: $`0 `$ 
  - `UseScaling`: whether to use scaling
    - Type: logical or double
    - Constraint: $`0`$  or  $`1`$  (if double)
    - Default: true
  - `EigTol`: threshold (for eigenvalue computation)
    - Type: double
    - Constraint: $` \geq0 `$ 
    - Default: $` 10^{-12} `$ 
  - `WOptions`: options for $`W`$ computation
    - Type: WOptions
    - Overwritten if Method, Steps, UseScaling, or EigTol is provided
  ---
  - `StepSize`: optimization step size
    - Type: double
    - Constraint: $` >0 `$ 
    - Default: $` 0.1 `$ 
  - `StepSizeInf`: lower bound of optimization step size
    - Type: double
    - Constraint: $` >0 `$ 
    - Default: $` 10^{-12} `$ 
  - `MaxIter`: maximum number of iterations (optimization)
    - Type: double
    - Constraint: integer, $` >0 `$ 
    - Default: 1000
  - `Tol`: threshold (for convergence judgment)
    - Type: double
    - Constraint: $` >0 `$ 
    - Default: $` 10^{-8} `$ 
  - `Rho`: parameter for backtracking
    - Type: double
    - Constraint: $` >0 `$ , $` <1 `$ 
    - Default: $` 0.5 `$ 
  - `Sigma`: parameter for the Armijo condition
    - Type: double
    - Constraint: $` >0 `$ , $` <1 `$ 
    - Default: $` 10^{-4} `$ 
  - `Verbose`: whether to display progress
    - Type: logical
    - Default: false
  - `StoreTrace`: whether to store intermediate results
    - Type: logical
    - Default: false
  - `SolverOptions`: options for optimization
    - Type: PGSolverOptions
    - Overwritten if StepSize, StepSizeInf, MaxIter, Tol, Rho, Sigma, Verbose, StoreTrace, or SolverOptions is provided
---
---
- Output:
  -  `p` : VCS, AECS
      - Type: double vector
      - Same size as $`A`$
---
- Optional output:
  - `info`: optimization result
    - Type: CSResult
---
---
- Usage examples:
  - `vcs(A)` ( $`T=\infty`$ )
  - `p = vcs(A)` ( $`T=\infty`$ )
  - `p = vcs(A, t)`
  - `p = vcs(A, T=t)`
  - `[p, info] = vcs(A, T=t, Method="integral", Steps=50)`
  - `[pV, pA] = bothcs(A)`
  - `[pV, pA, infoV, infoA] = bothcs(A)`

#### 4.1.2 API for Target Controllability Scores

target VCS / target AECS are computed by giving the `TargetNodes` option to `vcs`, `aecs`, and `bothcs`. \
Give `TargetNodes` an index vector of target nodes.
That is, if $`C`$ is the selection matrix that extracts the components of `TargetNodes`, each $`W_i(T)`$ is computed as
the single-input Gramian to the corresponding target nodes projected onto the target part:
```math
W_i(T) = C \tilde W_{i}(T) C^\top
```

- Additional optional input:
  - `TargetNodes`: indices of target nodes
    - Type: double vector
    - Constraint: integer, 1-indexed (if duplicates exist, the implementation uniquifies them while preserving their order of appearance)
---
- Output:
  - `p`: target VCS, target AECS
    - Type: double vector
    - Length is `numel(unique(TargetNodes, "stable"))`
---
- Usage examples:
  - `p = vcs(A, T=2.0, TargetNodes=[1 3 5])`
  - `p = aecs(A, T=2.0, TargetNodes=[1 3 5], Method="integral", Steps=80)`
  - `[pV, pA] = bothcs(A, T=2.0, TargetNodes=[1 3 5])`
  - `[pV, pA, infoV, infoA] = bothcs(A, T=2.0, TargetNodes=[1 3 5])`


### 4.2 Class (`CSProblem`)

This class represents the problem setting. \
When it receives inputs, it computes $`W_1,\ldots,W_n`$ by `gramian.computeGramian(A, T, wopts[, TargetNodes])`. \
VCS and AECS can be computed by `CSProblem.solveVcs` and `CSProblem.solveAecs`.

- Properties:
  - `WList`: container for $`W_1,\ldots,W_n`$ and computation of $`f(W(p))`$
    - Type: WList
  - `Dimension`: dimension of the problem ( $`=n`$ )
    - Type: double
  - `InitialGuess`: initial solution
    - Type: double vector
---
#### 4.2.1 Constructor `obj = CSProblem(A, varargin)`
- Input:
  -  `A` : system matrix
      - Type: double matrix
      - Constraint: square matrix
---
- Optional inputs (passed as Name=Value):
  -  `T` : terminal time
      - Type: double
      - Constraint: $`T>0`$ 
      - Default: $`T=\infty`$ 
      - Passed as the second argument or as Name=Value
      (`vcs(A, t)` or `vcs(A, T=t)`)
  - `WOptions`: options for $`W`$ computation
    - Type: WOptions
    - Default: WOptions()
  - `TargetNodes`: indices of target nodes
    - Type: double vector
    - Constraint: integer, 1-indexed (if duplicates exist, the implementation uniquifies them while preserving their order of appearance)
    - Default: empty (compute full-state CS)
    - If nonempty, target controllability scores are computed
  - `InitialGuess`: initial solution
    - Type: double vector
    - Constraint: size $`n`$ (when `TargetNodes` is specified, the dimension of the target nodes ( $`=m`$ ))
    - Default: $` \frac{1}{n}\boldsymbol{1} `$ (when `TargetNodes` is specified, normalized by $`m`$)
    - The given initial solution is projected onto the $`n`$ ( $`m`$ )-dimensional standard simplex.
    - If the initial solution is not feasible (if $`W(p)`$ is singular), that value is returned by `CSProblem.solveVcs` or `CSProblem.solveAecs`, and ExitFlag=-2.
---
- Notes:
  - Since `gramian.computeGramian` is executed inside the constructor to compute $`W_1,\ldots,W_n`$, it can become a bottleneck in computation time for large-scale problems.
---
---
- Usage examples:
  - `prob = CSProblem(A)` ( $`T=\infty`$ )
  - `prob = CSProblem(A, T=t, InitialGuess=p)`
  - `prob = CSProblem(A, T=t, TargetNodes=[1 3 5])`
---
#### 4.2.2 Main Methods `CSProblem.solveVcs`, `CSProblem.solveAecs`
- Optional input (passed as Value):
  - `solopts`: solver options
    - Type: PGSolverOptions
    - Default: PGSolverOptions()
---
---
- Output:
  - `p` : VCS, AECS
    - Type: double vector
    - Same size as $`A`$
---
- Optional output:
  - `info`: optimization result
    - Type: CSResult
---
---
- Usage examples:
  - `prob.solveVcs`
  - `p = prob.solveVcs`
  - `[p, info] = prob.solveVcs(solopts)`
---
#### 4.2.3 Function Value Evaluation Methods `CSProblem.fVcs`, `CSProblem.gradVcs`, `CSProblem.fAecs`, `CSProblem.gradAecs`
- These are called when optimization is executed by a `ProjectedGradientSolver` object.
- They are computed by calling `WList.evalVcs` and `WList.evalAecs`.
---
### 4.3 Class (`CSOptions`)
This class manages all options required for computation. \
Its main properties include WOptions and SolverOptions. \
The properties of WOptions and SolverOptions can also be modified directly. (See 4.3.1 and 4.3.2.)

- Main properties:
  - `WOptions`: options for $`W`$ computation
    - Type: WOptions
    - Overwritten if Method, Steps, UseScaling, or EigTol is assigned
  - `SolverOptions`: options for optimization
    - Type: PGSolverOptions
    - Overwritten if StepSize, StepSizeInf, MaxIter, Tol, Rho, Sigma, Verbose, StoreTrace, or SolverOptions is assigned
- Dependent properties:
  - Properties of WOptions and SolverOptions
    - Have getters and setters
---
#### 4.3.1 Constructor `obj = CSOptions(varargin)`
- Optional inputs (passed as Name=Value):
  - `Method`, `Steps`, `UseScaling`, `EigTol`: same as the top-level functions
  - `WOptions`: same as the top-level functions
    - Overwritten if Method, Steps, UseScaling, or EigTol is provided
  ---
  - `StepSize`, `StepSizeInf`, `MaxIter`, `Tol`, `Rho`, `Sigma`, `Verbose`, `StoreTrace`: same as the top-level functions
  - `SolverOptions`: same as the top-level functions
    - Overwritten if StepSize, StepSizeInf, MaxIter, Tol, Rho, Sigma, Verbose, StoreTrace, or SolverOptions is provided
---
---
- Usage example:
  - `csopts = CSOptions(UseScaling = false, WOptions = wopts)`
    - `wopts` is assigned to `csopts.WOptions`, but `csopts.WOptions.UseScaling` is set to `false`. (It does not depend on `wopts.UseScaling`.)
---
#### 4.3.2 Getters and Setters
- In addition to `WOptions` and `SolverOptions`, getters and setters for their properties are also implemented, so they can be overwritten directly.
- Usage example:
  - `csopts.UseScaling = false` (`csopts.WOptions.UseScaling = false` and the same operation)

### 4.4 Class (`WOptions`)
This class manages the options required for computing $`W`$. \
When actually computing $`W_1,\ldots,W_n`$, it calls `gramian.computeGramian`. \
After computing $`W_1,\ldots,W_n`$, they are stored in a `WList` object, and the necessary computations are performed by its methods.

- Properties:
  - `Method`: computation method
    - Type: string or char vector
    - Constraint: "lyap" or "integral"
    - Default: "lyap"
  - `Steps`: number of grid points (for numerical integration)
    - Type: double
    - Constraint: integer, $`\geq 0`$ 
    - Default: $`0`$ 
  - `UseScaling`: whether to use scaling
    - Type: logical or double
    - Constraint: $`0`$  or  $`1`$  (if double)
    - Default: true
  - `EigTol`: threshold (for eigenvalue computation)
    - Type: double
    - Constraint: $`\geq 0`$ 
    - Default: $`10^{-12}`$ 
---
- Property dependencies:
  - `Method` and `Steps`
    - When Method="lyap", calling WOptions.Steps returns $`0`$. (The original numerical value is retained internally.)
    - An error occurs if `gramian.computeGramian` is executed with Method="integral" and Steps=0.
  - `UseScaling` and `EigTol`
    - When UseScaling=false, calling WOptions.EigTol returns $`0`$. (The original numerical value is retained internally.)

### 4.5 Class (`PGSolverOptions`)
This class manages the options required for executing optimization. \
When actually performing optimization, it calls `ProjectedGradientSolver.solve`. \
The computation result is stored in `CSResult`.
- Properties:
  - `StepSize`: optimization step size
    - Type: double
    - Constraint: $`>0`$ 
    - Default: $`0.1`$ 
  - `StepSizeInf`: lower bound of optimization step size
    - Type: double
    - Constraint: $`>0`$ 
    - Default: $`10^{-12}`$ 
  - `MaxIter`: maximum number of iterations (optimization)
    - Type: double
    - Constraint: integer, $`>0`$ 
    - Default: 1000
  - `Tol`: threshold (for convergence judgment)
    - Type: double
    - Constraint: $`>0`$ 
    - Default: $`10^{-8}`$ 
  - `Rho`: parameter for backtracking
    - Type: double
    - Constraint: $`>0`$ , $`<1`$ 
    - Default: $`0.5`$ 
  - `Sigma`: parameter for the Armijo condition
    - Type: double
    - Constraint: $`>0`$ , $`<1`$ 
    - Default: $`10^{-4}`$ 
  - `Verbose`: whether to display progress
    - Type: logical
    - Default: false
  - `StoreTrace`: whether to store intermediate results
    - Type: logical
    - Default: false

### 4.6 Class (`CSResult`)
This class stores the computation results of optimization. \
When actually performing optimization, it calls `ProjectedGradientSolver.solve`. 
- Properties:
  - `ObjectiveValue`: objective function value at termination
    - Type: double
  - `Gradient`: gradient at termination (because this is a projected gradient method, it does not become $`\boldsymbol{0}`$)
    - Type: double vector
  - `GradNorm`: norm of the gradient at termination (because this is a projected gradient method, it does not become $`0`$)
    - Type: double
  - `StepNorm`: norm of the update width at termination (used for the convergence judgment condition)
    - Type: double
  - `Iterations`: number of iterations
    - Type: double
  - `FuncCount`: number of objective function evaluations
    - Type: double
  - `Converged`: whether convergence occurred
    - Type: logical
  - `ExitFlag`: reason for termination
    - Type: double
    - Constraint: integer
      - 1: converged (update width $`<`$ threshold)
      - 0: maximum number of updates reached
      - -1: terminated because the Armijo condition was not satisfied
      - -2: terminated because the initial point was not in the feasible region ( $`W(p)`$ did not become positive definite)
      - -3: terminated because the point accepted by the Armijo condition was outside the feasible region (exceptional)
  - `ExitMessage`: termination message
    - Type: string
  - `Algorithm`: algorithm used
    - Type: string
    - "ProjectedGradient (Armijo, projection arc)" (currently unnecessary; to be changed when extended)
  - `SolverOptions`: options used
    - Type: PGSolverOptions
  - `ProblemInfo`: information about the problem (currently unnecessary; to be changed when extended)
    - Type: struct
  - `Trace`: stores information about progress
    - Type: struct
    - Stores intermediate numerical information when StoreTrace=true
      - `Iteration`
      - `Fval`
      - `StepNorm`
      - `Alpha`
      - `FuncCount`

### 4.7 Class (`ProjectedGradientSolver`)
This class is for the optimization solver. \
By providing an objective function and an initial point and calling the `solve` method, the projected gradient method is executed.
- Properties:
  - `StepSize`: optimization step size
    - Type: double
    - Constraint: $`>0`$ 
    - Default: $`0.1`$ 
  - `StepSizeInf`: lower bound of optimization step size
    - Type: double
    - Constraint: $`>0`$ 
    - Default: $`10^{-12}`$ 
  - `MaxIter`: maximum number of iterations (optimization)
    - Type: double
    - Constraint: integer, $`>0`$ 
    - Default: 1000
  - `Tol`: threshold (for convergence judgment)
    - Type: double
    - Constraint: $`>0`$ 
    - Default: $`10^{-8}`$ 
  - `Rho`: parameter for backtracking
    - Type: double
    - Constraint: $`>0`$ , $`<1`$ 
    - Default: $`0.5`$ 
  - `Sigma`: parameter for the Armijo condition
    - Type: double
    - Constraint: $`>0`$ , $`<1`$ 
    - Default: $`10^{-4}`$ 
  - `Verbose`: whether to display progress
    - Type: logical
    - Default: false
  - `StoreTrace`: whether to store intermediate results
    - Type: logical
    - Default: false
#### 4.7.1 Main Method `ProjectedGradientSolver.solve`
- Input:
  - `fun`: objective function
    - Type: function handle
  - `p0`: initial solution
    - Type: double vector
---
---
- Output:
  - `p`: optimal solution
    - Type: double vector
  - `info`: computation result
    - Type: CSResult
---

### 4.8 Class (`WList`)
This class stores the array of $`W_1,\ldots,W_n`$ and performs related computations. \
When scaling is performed, it stores the scaled controllability Gramian. \
By giving a point $`p`$ and calling the `evalVcs` and `evalAecs` methods, the objective function and its gradient can be evaluated.
- Properties:
  - `W` : array of controllability Gramians
    - Type: cell vector
    - It is a cell array consisting of $`n`$ elements, and each element is also a cell array.
    - When $`W_1,\ldots,W_n`$ has a block diagonal matrix structure, the corresponding element of `W` stores each diagonal block.
    - The main constraints are as follows.
    - `W` must have $`n`$ elements.
    - `W{1}`, ..., `W{n}` must have the same size.
    - The elements of `W{1}`, ..., `W{n}` at the same positions must be real square matrices with the same size.
    - The constraints satisfied by each element are verified by executing `validateWList_`.
  -  `Q` : coordinate transformation matrix
      - Type: double matrix or []
      - When scaling is performed, this represents a matrix such that $`Q^{-1}AQ`$ becomes a block diagonal matrix.
      - If `CSOptions.WOptions.UseScaling` is `false`, or if $`A`$ does not need to be block-diagonalized, it stores `[]`.
  -  `Sa` : constant matrix used for AECS function evaluation
      - Type: cell vector
      - `Sa` represents $`D^{-1}Q^{-1}Q^{-\top}D^{-\top}`$.
        However, what is needed for objective function evaluation is only the block diagonal part with the same block diagonal structure as $`W(p)`$.
        Therefore, `Sa` has the block diagonal elements as each cell element. The specific definitions of $`D, Q`$ are explained near the end of this section.
      - If `CSOptions.WOptions.UseScaling` is `false`, or if $`A`$ does not need to be block-diagonalized, it stores a cell array consisting of `[]`.
      - Constraints related to size and so on are verified by executing `validateWList_`.
  - `vcsBlocks`, `aecsBlocks`: arrays representing the block positions used for objective function evaluation
    - Type: double vector
    - Since VCS uses all blocks and AECS uses only the upper-left block, this is explicitly indicated. (Currently it is unnecessary to store this as a property; to be changed when extended.)
  - `blockSizes`: size of each block diagonal matrix
    - Type: double vector
  - `n`: dimension of the problem
    - Type: double
  - `nb`: number of block diagonal elements
    - Type: double
    - In this example, it represents $`\ell`$.
  - `WOptions`: options used for $`W`$ computation
    - Type: WOptions

For example, when there is a block structure

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
    & \ddots & \\
    & & W_{n,\ell}
\end{pmatrix}
```

`W{1}{k}` is a double array representing $`W_{1,k}`$.

For example, when there is a block structure
```math
W(p)=
\begin{pmatrix}
W_1(p) & & \\
& \ddots & \\
& & W_\ell(p)
\end{pmatrix},
S_{\mathrm{a}}=
\begin{pmatrix}
S_{\mathrm{a}, 1, 1} & \cdots & S_{\mathrm{a}, 1, n} \\
\vdots & \ddots & \vdots \\
S_{\mathrm{a}, n, 1} & \cdots & S_{\mathrm{a}, n, n}
\end{pmatrix}
```

`Sa{k}` is a double array representing $`S_{\mathrm{a}, k, k}`$.

Also, let $`\widetilde{W}(p)`$ be the ordinary controllability Gramian and $`W(p)`$ be the scaled controllability Gramian, and suppose that

```math
\widetilde{W}(p)=QDW(p)D^\top Q^\top
```

is satisfied. Then the objective function of AECS is expressed as

```math
\begin{align*}
g(p)&=\mathrm{tr}\left(\widetilde{W}(p)^{-1}\right) \\
&=\mathrm{tr}\left(Q^{-\top}D^{-\top}W(p)^{-1}D^{-1}Q^{-1}\right) \\
&=\mathrm{tr}\left(W(p)^{-1}D^{-1}Q^{-1}Q^{-\top}D^{-\top}\right)
\end{align*}
```

#### 4.8.1 Main Method `WList.evalVcs`
- Input:
  - `p` : point at which to evaluate the objective function
    - Type: double vector
---
- Output:
  - `f` : objective function value of VCS $`f_{\mathrm{VCS}}(p)`$ 
    - Type: double scalar
---
- Optional output:
  - `g` : gradient of the VCS objective function $`\nabla f_{\mathrm{VCS}}(p)`$ 
    - Type: double vector
---
---
- Usage examples:
  - `f = wlist.evalVcs(p)`
  - `[f, g] = wlist.solveVcs(p)`
---
- Algorithm:
  - Performs eigenvalue decomposition of $`W(p)`$ and determines whether a matrix is symmetric positive definite and computes $`\log\det W(p)`$.
---

#### 4.8.2 Main Method `WList.evalAecs`
- Input:
  - `p` : point at which to evaluate the objective function
    - Type: double vector
---
- Output:
  - `f` : objective function value of AECS $`f_{\mathrm{AECS}}(p)`$ 
    - Type: double scalar
---
- Optional output:
  -  `g` : gradient of the AECS objective function $`\nabla f_{\mathrm{AECS}}(p)`$ 
    - Type: double vector
---
---
- Usage examples:
  - `f = wlist.evalAecs(p)`
  - `[f, g] = wlist.solveAecs(p)`
---
- Algorithm:
  - Performs eigenvalue decomposition of $`W(p)`$ and determines whether a matrix is symmetric positive definite and computes $`\mathrm{tr}\left(W(p)^{-1}\right)`$.
---

### 4.9 Namespace (`+gramian`)
Implements computation of the controllability Gramian.
#### 4.9.1 Main Function `gramian.computeGramian`
- Input:
  - `A` : system matrix
    - Type: double matrix
    - Constraint: square matrix
  - `T` : terminal time
    - Type: double
    - Constraint: $`T>0`$ 
  - `wopts`: options for $`W`$ computation
    - Type: WOptions
  - `targetNodes`: indices of target nodes (optional)
    - Type: double vector
    - Constraint: integer, 1-indexed (if duplicates exist, they are uniquified while preserving their order of appearance)
---
- Output:
  - `wlist`: WList object that stores the controllability Gramian for the problem
    - Type: WList scalar
---
- Algorithm:
  - When `targetNodes` is empty, depending on the values of `T`, `wopts.UseScaling`, and `wopts.Method`, calls one of `gramian.infLyapScale_`, `gramian.infLyapNoscale_`, `gramian.finLyapScale_`, `gramian.finLyapNoscale_`, `gramian.finIntegralScale_`, or `gramian.finIntegralNoscale_` and computes a WList object.
  - When `targetNodes` is nonempty, depending on `wopts.Method`, calls either `gramian.finTargetLyap_` or `gramian.finTargetIntegral_`. Since the case $`T=\infty`$ has not yet been formulated theoretically, it results in an error.

#### 4.9.2 Main Function `gramian.blockDiagonalization_`
Finds the block diagonalization of the given matrix $`A`$ and its transformation matrix.
 ```math 
  Q^{-1}AQ=
  \begin{pmatrix}
    A_- \\
    & A_0 \\
    & & A_+
  \end{pmatrix}
 ```
It block-diagonalizes as above.
- Input:
  - `A` : system matrix
    - Type: double matrix
    - Constraint: square matrix
  - `wopts`: options for $`W`$ computation
    - Type: WOptions
- Notes:
  - In eigenvalue separation, wopts.EigTol is used as the threshold.
  - Eigenvalues whose absolute value is less than wopts.EigTol are judged to be eigenvalues on the imaginary axis.

#### 4.9.3 Other Main Functions
##### `gramian.infLyapScale_`
For $`T=\infty`$, computes using the Lyapunov equations

```math
\begin{gather*}
A_-W_{i,-}+W_{i,-}A_-+q_{i,-}q_{i,-}^\top=0 \\
(A_0-\varepsilon I)W_{i,0}+W_{i,0}(A_0-\varepsilon I)^\top+q_{i,0}q_{i,0}^\top=0 \\
(-A_+)W_{i,+}+W_{i,+}(-A_+)+q_{i,+}q_{i,+}^\top=0 \\
\end{gather*}
```

(with scaling, $`\varepsilon=10^{-8}`$ ) \
**The computation method for $`W_{i,0}`$ is temporarily set and is not exact; it may become unstable (requires improvement).**


##### `gramian.infLyapNoscale_`
For $`T=\infty`$, computes using the Lyapunov equation

```math
AW_i+W_iA+e_ie_i^\top=0
```

(without scaling)

##### `gramian.finLyapScale_`
For $`T<\infty`$, computes using the Lyapunov equation and van Loan (1978). (with scaling)

##### `gramian.finLyapNoscale_`
For $`T<\infty`$, computes using the Lyapunov equation

```math
AW_i+W_iA=e^{AT}e_ie_i^\top e^{A^\top T}-e_ie_i^\top
```

(without scaling)

##### `gramian.finIntegralScale_`
For $`T<\infty`$, computes using numerical integration. (with scaling)

##### `gramian.finIntegralNoscale_`
For $`T<\infty`$, computes using numerical integration. (without scaling)

---

### 4.10 Namespace (`+csutil`)
Implements processing that does not depend on classes.
- Main functions
  - projectOntoSimplex
    - Euclidean projection onto the standard simplex
  - isposdef
    - Determines positive definiteness symmetry of a matrix
---

## 5. Processing Flow
The basic processing flow in this project is as follows.

1. The user calls `vcs(...)`. \
Based on the inputs, a `WOptions` object and a `PGSolverOptions` object are generated.
2. A `CSProblem` object is generated based on the inputs and the `WOptions` object. \
At that time, $`W_1,\ldots,W_n`$ is computed by `gramian.computeGramian(A, T, wopts)` for full-state scores, or by `gramian.computeGramian(A, T, wopts, targetNodes)` for target controllability scores.
3. The `PGSolverOptions` object is passed to the `CSProblem` object, and the `solveVcs` method is executed.
4. A `ProjectedGradientSolver` object is generated, the `PGSolverOptions` object is passed to it, and the `solve` method is executed. \
At that time, the projected gradient method based on the Armijo condition is executed.
5. The computation result is stored in `CSResult` and returned.


## 6. Usage Examples
Basic usage examples are shown below.

```matlab
    vcs(A) % T=\infty, displayed in the command window
    p = vcs(A) % T=\infty
    p = vcs(A, t) % Argument specification for T by Value
    p = vcs(A, T=t) % Argument specification for T by Name=Value
    [p, info] = vcs(A, T=t, Method="integral", Steps=50) % Compute the controllability Gramian by numerical integration; info stores information about the computation result
    [pV, pA] = bothcs(A) % Compute both VCS and AECS, avoiding duplicate Gramian computation
    [pV, pA, infoV, infoA] = bothcs(A) % Store information about the computation results for both VCS and AECS
    pT = vcs(A, T=2.0, TargetNodes=[1 3 5]) % target VCS
    pTA = aecs(A, T=2.0, TargetNodes=[1 3 5], Method="integral", Steps=80) % target AECS
    [pTV, pTA] = bothcs(A, T=2.0, TargetNodes=[1 3 5]) % Compute target VCS/AECS simultaneously
```

## Citation

If you use this source code in a paper, please cite the following references.

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

@article{sato2025target,
  title={Target Controllability Scores for Actuation-Constrained Network Intervention}, 
  author={Kazuhiro Sato},
  journal={arXiv preprint arXiv:2510.13354},
  year={2025}
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
