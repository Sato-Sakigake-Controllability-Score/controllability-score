% ex02_finite_horizon.m
% Compare VCS and AECS for several finite time horizons T.

clear;
clc;

A = [ ...
     -0.6,  0.2,  0.0,  0.0; ...
     0.0, -0.9,  0.3,  0.0; ...
     0.1,  0.0,  0.2,  0.4; ...
     0.0,  0.0,  0.1,  0.7];

horizons = [0.5, 2.0, 5.0];
pVAll = zeros(size(A, 1), numel(horizons));
pAAll = zeros(size(A, 1), numel(horizons));

for k = 1:numel(horizons)
    T = horizons(k);
    [pVAll(:, k), pAAll(:, k)] = bothcs(A, T);
end

disp("Finite-horizon VCS weights:");
disp(array2table(pVAll, 'VariableNames', compose("T_%.1f", horizons)));

disp("Finite-horizon AECS weights:");
disp(array2table(pAAll, 'VariableNames', compose("T_%.1f", horizons)));

figure;
tiledlayout(1, 2);

nexttile;
bar(pVAll);
title("Finite-horizon VCS");
xlabel("node");
ylabel("weight");
legend(compose("T = %.1f", horizons), 'Location', 'best');

nexttile;
bar(pAAll);
title("Finite-horizon AECS");
xlabel("node");
ylabel("weight");
legend(compose("T = %.1f", horizons), 'Location', 'best');
