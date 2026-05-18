% ex01_minimal_bothcs.m
% Basic use of bothcs, plus comparison with vcs/aecs and solver info.

clear; clc;

A = diag([-1.0, -2.0, 0.5, 1.2]);

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

disp("Solver summary:");
summary = table( ...
    ["VCS"; "AECS"], ...
    [infoV.ObjectiveValue; infoA.ObjectiveValue], ...
    [infoV.Iterations; infoA.Iterations], ...
    [infoV.Converged; infoA.Converged], ...
    [infoV.ExitFlag; infoA.ExitFlag], ...
    'VariableNames', ["Objective", "ObjectiveValue", "Iterations", "Converged", "ExitFlag"]);
disp(summary);
