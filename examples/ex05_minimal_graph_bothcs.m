% ex05_minimal_graph_bothcs.m
% Minimal example that displays an adjacency matrix as a directed graph
% and computes VCS and AECS from the same matrix.

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
