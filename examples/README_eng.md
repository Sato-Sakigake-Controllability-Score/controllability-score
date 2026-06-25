# Usage Examples

<table>
    <thead>
        <tr>
            <th style="text-align:center">English</th>
            <th style="text-align:center"><a href="README.md">Japanese</a></th>
        </tr>
    </thead>
</table>

This README is a guide for checking, step by step, how to use controllability score with MATLAB code.

The files from `ex01_*.m` to `ex05_*.m` are provided as reference scripts that can execute the usage described here in an organized form.

## Obtaining the Repository

First, move to any working directory in the terminal and clone the repository from GitHub.

```sh
git clone https://github.com/Sato-Sakigake-Controllability-Score/controllability-score.git
cd controllability-score
```

Below, this `controllability-score` directory is referred to as the root directory of the repository.

## Prerequisites

- MATLAB R2024a or later
- Control System Toolbox
- For code that uses `figure` or a GUI, a MATLAB GUI display environment is required

When running sample scripts, move to the root directory of the repository in MATLAB, add the root to the path as follows, and then call the script.

```matlab
addpath(pwd)  % Add the root directory of the repository to the path
run("examples/ex01_minimal_bothcs.m")
```

## 1. Prepare a System Matrix

The basic API takes a system matrix `A` and returns weights for each node.

```matlab
% Example of a simple diagonal matrix
A = diag([-1.0, -2.0, 0.5, 1.2]);
```

In general, it is sufficient for `A` to be a square matrix whose rows and columns correspond to nodes, and the following variations are possible.

- Use the adjacency matrix $A$ of a network directly as the system matrix
- For stabilization, add diagonal components (corresponding to self-loops) and use a form such as $A - cI$
- Compute the Laplacian $L = D - A$ and use $-L$ as the system matrix

```matlab
adjacency = [ ...
    0.0, 0.8, 0.0; ...
    0.0, 0.0, 0.4; ...
    0.2, 0.0, 0.0];

% Example with self-loops added
selfLoopWeight = 2.0;
A1 = adjacency - selfLoopWeight * eye(size(adjacency, 1));

% Example using the Laplacian
degree = sum(adjacency, 2);
L = diag(degree) - adjacency;
A2 = -L;
```

## 2. Display an Adjacency Matrix as a Directed Graph

If it is difficult to see the network structure from the shape of the adjacency matrix alone, you can use MATLAB's `digraph` and `plot` to check it as a directed graph.
For example, use the following.

```matlab
n = size(adjacency, 1);

figure;
G = digraph(adjacency);
plot(G, ...
     NodeLabel=compose("%d", 1:n), ...
     EdgeLabel=G.Edges.Weight);
axis equal off;
title("Directed adjacency graph");
```

This visualization and a minimal example of `bothcs` are collected in [`ex05_minimal_graph_bothcs.m`][ex05].

## 3. Compute VCS and AECS Simultaneously

When using both VCS and AECS, the basic approach is to use `bothcs`.

```matlab
[pV, pA] = bothcs(A);
```

`pV` and `pA` are weight vectors for each node.

```matlab
disp("VCS weights:");
disp(pV);

disp("AECS weights:");
disp(pA);
```

If only VCS or only AECS is needed, the individual functions can also be used.

```matlab
pV = vcs(A);
pA = aecs(A);
```

However, `bothcs(A)` computes $W_1,\ldots,W_n$ all at once at the beginning of the algorithm and then computes VCS and AECS based on them. Therefore, when using both, calling `bothcs(A)` is more efficient than calling `vcs(A)` and `aecs(A)` sequentially.

## 4. Check Solver Information

If you want to check not only the computed weights but also the state of optimization, you can receive additional outputs.

```matlab
[pV, pA, infoV, infoA] = bothcs(A);
```

For example, `infoV` is a `CSResult` object and has properties such as the following.
```matlab
infoV = 
    ObjectiveValue: 8.5001  % Objective function value
    Gradient: [4×1 double] 
    GradNorm: 8 
    StepNorm: 0
    Iterations: 1   % Number of iterations
    FuncCount: 3
    Converged: 1
    ExitFlag: 1
    ExitMessage: "Step norm below Tol."
    Algorithm: "ProjectedGradient (Armijo, projection arc)"
    SolverOptions: [1×1 ProjectedGradientSolver]
    ProblemInfo: [1×1 struct]
    Trace: []
```

For details of each property, see the "4.6 Class (`CSResult`)" section of [README_eng.md][repo-readme].

The same kind of `info` can also be received from individual functions.

```matlab
[pV, infoV] = vcs(A);
[pA, infoA] = aecs(A);
```

## 5. Specify a Finite Time Horizon

By default, `T = inf` is used, but if you want to compute finite-time scores, specify the terminal time as the second argument or with `T=...`.

```matlab
T = 2.0;
[pV, pA] = bothcs(A, T);
```

The same specification can also be made in Name-Value form.

```matlab
[pV, pA] = bothcs(A, T=2.0);
```

## 6. Specify Other Options

In addition to the finite time horizon specified in the previous section, other options can also be specified in Name-Value form.

- Main specifications on the Gramian side: `Method`, `Steps`, `UseScaling`
- Main specifications on the solver side: `MaxIter`, `Tol`, `Verbose`, `StoreTrace`

For example, the following shows an example in which options are specified together.

```matlab
T = 2.0;

[pV, pA, infoV, infoA] = bothcs( ...
    A, T, ...
    Method="integral", ...
    Steps=80, ...
    UseScaling=false, ...
    MaxIter=2000, ...
    Tol=1e-9, ...
    Verbose=true, ...
    StoreTrace=true);
```

For details of the options, see the "4.1 Top-Level Functions (vcs.m, aecs.m, bothcs.m)" section of [README_eng.md][repo-readme].

Also, `UseScaling` is an option that makes computation possible even when the $A$ matrix is unstable. On the other hand, because it computes the Jordan normal form, note that an error may occur when eigenvalues are repeated.


## 7. Run Sample Scripts

If you want to run organized examples, use the following scripts. Each section of the README can also be used as a guide when reading these scripts.

| File | Contents |
| --- | --- |
| [`ex01_minimal_bothcs.m`][ex01] | Basics of `vcs`, `aecs`, and `bothcs`, and checking solver information |
| [`ex02_finite_horizon.m`][ex02] | Score comparison using multiple finite time horizons `T` |
| [`ex03_edge_weight_sweep.m`][ex03] | Score changes when changing the weight of a single edge |
| [`ex04_visualize_scores.m`][ex04] | Compute VCS and AECS from an adjacency matrix created with the GUI |
| [`ex05_minimal_graph_bothcs.m`][ex05] | Display an adjacency matrix as a directed graph and compute VCS and AECS from the same matrix |


[repo-readme]: ../README.md
[ex01]: ./ex01_minimal_bothcs.m
[ex02]: ./ex02_finite_horizon.m
[ex03]: ./ex03_edge_weight_sweep.m
[ex04]: ./ex04_visualize_scores.m
[ex05]: ./ex05_minimal_graph_bothcs.m
