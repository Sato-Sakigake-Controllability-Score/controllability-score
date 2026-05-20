% ex01_minimal_bothcs.m
% vcs, aecsを計算するための基本的な例
% 両方の重みを同時に計算するbothcs関数を使用し、個別の呼び出しと比較
% また, ソルバーの出力を表示

clear; clc;

% 4x4の対角行列を定義
A = diag([-1.0, -2.0, 0.5, 1.2]);

% bothcs関数を使用してVCSとAECSの重みを同時に計算
[pV, pA, infoV, infoA] = bothcs(A);

pVSeparate = vcs(A);
pASeparate = aecs(A);

disp("VCS weights from bothcs:");
disp(pV);

disp("AECS weights from bothcs:");
disp(pA);

disp("Difference from separate calls:");
fprintf("  ||pV - vcs(A)||  = %.3e\n", norm(pV - pVSeparate));
fprintf("  ||pA - aecs(A)|| = %.3e\n", norm(pA - pASeparate));

% ソルバーの出力を表示
disp("Solver summary:");
summary = table( ...
    ["VCS"; "AECS"], ...
    [infoV.ObjectiveValue; infoA.ObjectiveValue], ...
    [infoV.Iterations; infoA.Iterations], ...
    [infoV.Converged; infoA.Converged], ...
    [infoV.ExitFlag; infoA.ExitFlag], ...
    'VariableNames', ["Objective", "ObjectiveValue", "Iterations", "Converged", "ExitFlag"]);
disp(summary);
