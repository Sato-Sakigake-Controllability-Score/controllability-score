% ex05_minimal_graph_bothcs.m
% 隣接行列を有向グラフとして表示し，同じ行列から VCS と AECS を計算する最小例

clear;
clc;
close all;

adjacency = [ ...
             0.0, 0.8, 0.3, 0.0; ...
             0.0, 0.3, 0.5, 0.0; ...
             0.0, 0.0, 0.0, 0.6; ...
             0.3, 0.0, 0.0, 0.0];

n = size(adjacency, 1);

figure('Name', 'Adjacency Graph', 'Color', 'w');
G = digraph(adjacency);
plot(G, ...
     'NodeLabel', compose("%d", 1:n), ...
     'EdgeLabel', G.Edges.Weight);
axis equal off;
title("Directed adjacency graph");

[pV, pA] = bothcs(adjacency);

disp("Adjacency matrix:");
disp(adjacency);

disp("VCS weights:");
disp(pV);

disp("AECS weights:");
disp(pA);
