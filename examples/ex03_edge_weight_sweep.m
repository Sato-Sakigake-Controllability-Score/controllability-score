% ex03_edge_weight_sweep.m
% 1 本のエッジ重みを変えたときのスコア変化

clear; clc; close all;

n = 5;
A0 = [ ...
    -0.8,  0.0,  0.1,  0.0,  0.0; ...
     0.2, -0.7,  0.0,  0.0,  0.0; ...
     0.0,  0.3, -0.5,  0.2,  0.0; ...
     0.0,  0.0,  0.0, -0.4,  0.3; ...
     0.1,  0.0,  0.0,  0.0, -0.6];

edge = [3, 5];   % A(row, column)
weights = linspace(0, 1.5, 40);
T = 2.0;

pVHistory = zeros(n, numel(weights));
pAHistory = zeros(n, numel(weights));

for k = 1:numel(weights)
    A = A0;
    A(edge(1), edge(2)) = weights(k);

    [pVHistory(:, k), pAHistory(:, k)] = bothcs(A, T, UseScaling=false);
end

figure;
tiledlayout(1, 2);

nexttile;
plot(weights, pVHistory.', 'LineWidth', 1.5);
title("VCS under edge-weight sweep");
xlabel(sprintf("A(%d,%d)", edge(1), edge(2)));
ylabel("weight");
legend(compose("node %d", 1:n), 'Location', 'best');

nexttile;
plot(weights, pAHistory.', 'LineWidth', 1.5);
title("AECS under edge-weight sweep");
xlabel(sprintf("A(%d,%d)", edge(1), edge(2)));
ylabel("weight");
legend(compose("node %d", 1:n), 'Location', 'best');
