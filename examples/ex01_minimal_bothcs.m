% ex01_minimal_bothcs.m
% Basic example for computing VCS and AECS.
% Use bothcs to compute both weights at once, and compare with separate calls.
% Also display solver output.

clear;
clc;

% Define a 4-by-4 diagonal matrix.
A = diag([-1.0, -2.0, 0.5, 1.2]);

% Use bothcs to compute VCS and AECS weights at the same time.
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

% Display solver output.
disp("Solver summary:");
summary = table( ...
                ["VCS"; "AECS"], ...
                [infoV.ObjectiveValue; infoA.ObjectiveValue], ...
                [infoV.Iterations; infoA.Iterations], ...
                [infoV.Converged; infoA.Converged], ...
                [infoV.ExitFlag; infoA.ExitFlag], ...
                'VariableNames', ["Objective", "ObjectiveValue", "Iterations", "Converged", "ExitFlag"]);
disp(summary);
