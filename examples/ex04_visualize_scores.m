% ex04_visualize_scores.m
% GUI で作成した隣接行列から VCS と AECS を計算

clear;
clc;
close all;

N = 5;
edgeLowerBound = 0.2;
edgeUpperBound = 1.0;
selfLoopWeight = -1.0;
T = 2.0;

adjacency = create_adjacency_gui(struct( ...
                                        'N', N, ...
                                        'lower_bound', edgeLowerBound, ...
                                        'upper_bound', edgeUpperBound));

A = adjacency + selfLoopWeight * eye(N);

[pV, pA] = bothcs(A, T, UseScaling = false);

[pVSorted, idxV] = sort(pV, "descend");
[pASorted, idxA] = sort(pA, "descend");

disp("Adjacency matrix:");
disp(adjacency);

disp("System matrix A = adjacency + selfLoopWeight * eye(N):");
disp(A);

disp("Scores:");
scores = table((1:N).', pV, pA, ...
               'VariableNames', ["Node", "VCS", "AECS"]);
disp(scores);

disp("VCS ranking:");
disp(table(idxV, pVSorted, 'VariableNames', ["Node", "Weight"]));

disp("AECS ranking:");
disp(table(idxA, pASorted, 'VariableNames', ["Node", "Weight"]));

figure('Name', 'Controllability Scores', 'Color', 'w');
tiledlayout(1, 2);

nexttile;
bar(pV);
title("VCS weights");
xlabel("node");
ylabel("weight");
ylim([0, max([pV; pA]) * 1.1]);

nexttile;
bar(pA);
title("AECS weights");
xlabel("node");
ylabel("weight");
ylim([0, max([pV; pA]) * 1.1]);

function matrix = create_adjacency_gui(options)
    % CREATE_ADJACENCY_GUI Create an adjacency matrix through a simple GUI.

    if nargin ~= 1
        error('examples:create_adjacency_gui:InvalidInputCount', ...
              'Exactly one options argument must be provided.');
    end

    oldTextInterpreter = get(groot, 'defaultTextInterpreter');
    oldAxesTickLabelInterpreter = get(groot, 'defaultAxesTickLabelInterpreter');
    oldLegendInterpreter = get(groot, 'defaultLegendInterpreter');
    cleanupInterpreter = onCleanup(@() restoreInterpreters( ...
                                                           oldTextInterpreter, oldAxesTickLabelInterpreter, oldLegendInterpreter));
    set(groot, 'defaultTextInterpreter', 'none');
    set(groot, 'defaultAxesTickLabelInterpreter', 'none');
    set(groot, 'defaultLegendInterpreter', 'none');

    if isstruct(options)
        s = options;
    else
        s = struct();
        props = properties(options);
        for k = 1:numel(props)
            s.(props{k}) = options.(props{k});
        end
    end

    if ~isfield(s, 'N') || ~isscalar(s.N) || s.N <= 0 || floor(s.N) ~= s.N
        error('examples:create_adjacency_gui:InvalidNodeCount', ...
              'options.N must be a positive integer.');
    end
    N = s.N;

    if isfield(s, 'lower_bound') && ~isempty(s.lower_bound) && ...
            isscalar(s.lower_bound) && isnumeric(s.lower_bound) && isfinite(s.lower_bound)
        lower_bound = s.lower_bound;
    else
        lower_bound = 1;
    end

    if isfield(s, 'upper_bound') && ~isempty(s.upper_bound) && ...
            isscalar(s.upper_bound) && isnumeric(s.upper_bound) && isfinite(s.upper_bound)
        upper_bound = s.upper_bound;
    else
        upper_bound = 1;
    end

    if lower_bound > upper_bound
        error('examples:create_adjacency_gui:InvalidBounds', ...
              'lower_bound must be less than or equal to upper_bound.');
    end

    if isfield(s, 'matrix')
        if ~isempty(s.matrix) && isequal(size(s.matrix), [N, N]) && isnumeric(s.matrix)
            matrix = s.matrix;
        else
            error('examples:create_adjacency_gui:InvalidMatrix', ...
                  'options.matrix must be a numeric matrix of size N x N.');
        end
    else
        matrix = zeros(N, N);
    end

    initial_matrix = matrix;
    selected_source = [];

    fig = figure( ...
                 'Name', sprintf('Adjacency Matrix Editor (%d nodes)', N), ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Color', 'w', ...
                 'Position', [100, 100, 900, 700], ...
                 'CloseRequestFcn', @handle_close);

    ax = axes('Parent', fig, 'Position', [0.05, 0.18, 0.9, 0.77]);
    hold(ax, 'on');

    status_text = uicontrol( ...
                            'Parent', fig, ...
                            'Style', 'text', ...
                            'Units', 'normalized', ...
                            'Position', [0.05, 0.08, 0.6, 0.05], ...
                            'BackgroundColor', 'w', ...
                            'HorizontalAlignment', 'left', ...
                            'FontSize', 11, ...
                            'String', initial_status_message());

    uicontrol( ...
              'Parent', fig, ...
              'Style', 'pushbutton', ...
              'Units', 'normalized', ...
              'Position', [0.68, 0.08, 0.1, 0.06], ...
              'String', 'Undo', ...
              'Callback', @undo_last_edge);

    uicontrol( ...
              'Parent', fig, ...
              'Style', 'pushbutton', ...
              'Units', 'normalized', ...
              'Position', [0.79, 0.08, 0.1, 0.06], ...
              'String', 'Reset', ...
              'Callback', @reset_graph);

    uicontrol( ...
              'Parent', fig, ...
              'Style', 'pushbutton', ...
              'Units', 'normalized', ...
              'Position', [0.68, 0.01, 0.1, 0.06], ...
              'String', 'Cancel', ...
              'Callback', @cancel_editing);

    uicontrol( ...
              'Parent', fig, ...
              'Style', 'pushbutton', ...
              'Units', 'normalized', ...
              'Position', [0.79, 0.01, 0.1, 0.06], ...
              'String', 'Finish', ...
              'FontWeight', 'bold', ...
              'Callback', @finish_editing);

    theta = linspace(0, 2 * pi, N + 1);
    theta(end) = [];
    node_x = cos(theta + pi / 2);
    node_y = sin(theta + pi / 2);
    history = zeros(0, 2);

    draw_graph();
    uiwait(fig);

    if isgraphics(fig)
        delete(fig);
    end

    clear cleanupInterpreter;

    function message = initial_status_message()
        if all(matrix(:) == 0)
            message = 'グラフを編集してください。始点ノードをクリックしてください。';
        else
            message = 'グラフが初期化されました。始点ノードをクリックしてください。';
        end
    end

    function restoreInterpreters(textInterpreter, axesTickLabelInterpreter, legendInterpreter)
        set(groot, 'defaultTextInterpreter', textInterpreter);
        set(groot, 'defaultAxesTickLabelInterpreter', axesTickLabelInterpreter);
        set(groot, 'defaultLegendInterpreter', legendInterpreter);
    end

    function draw_graph()
        cla(ax);
        axis(ax, [-1.3, 1.3, -1.3, 1.3]);
        axis(ax, 'equal');
        axis(ax, 'off');
        hold(ax, 'on');

        for src = 1:N
            for dst = 1:N
                if matrix(src, dst) ~= 0
                    draw_arrow(src, dst);
                end
            end
        end

        for idx = 1:N
            face_color = [1, 1, 1];
            line_width = 1.5;
            if isequal(selected_source, idx)
                face_color = [1.0, 0.9, 0.3];
                line_width = 2.5;
            end

            plot(ax, node_x(idx), node_y(idx), 'o', ...
                 'MarkerSize', 18, ...
                 'MarkerFaceColor', face_color, ...
                 'MarkerEdgeColor', 'k', ...
                 'LineWidth', line_width, ...
                 'ButtonDownFcn', {@select_node, idx});
            text(ax, node_x(idx), node_y(idx), sprintf('    %d', idx), ...
                 'FontSize', 11, ...
                 'FontWeight', 'bold', ...
                 'Interpreter', 'none', ...
                 'VerticalAlignment', 'middle', ...
                 'ButtonDownFcn', {@select_node, idx});
        end
    end

    function draw_arrow(src, dst)
        start_pos = [node_x(src), node_y(src)];
        end_pos = [node_x(dst), node_y(dst)];
        weight_label = sprintf('%.3g', matrix(src, dst));

        if src == dst
            radius = 0.12;
            center = start_pos + [0.12, 0.12];
            t = linspace(pi * 0.2, pi * 1.8, 80);
            x_loop = center(1) + radius * cos(t);
            y_loop = center(2) + radius * sin(t);
            plot(ax, x_loop, y_loop, 'Color', [0.2, 0.4, 0.8], 'LineWidth', 1.5);
            quiver(ax, x_loop(end - 1), y_loop(end - 1), ...
                   x_loop(end) - x_loop(end - 1), y_loop(end) - y_loop(end - 1), ...
                   0, 'Color', [0.2, 0.4, 0.8], 'LineWidth', 1.5, ...
                   'MaxHeadSize', 4, 'AutoScale', 'off');
            text(ax, center(1), center(2) + radius + 0.05, weight_label, ...
                 'FontSize', 10, ...
                 'HorizontalAlignment', 'center', ...
                 'Interpreter', 'none', ...
                 'VerticalAlignment', 'middle', ...
                 'BackgroundColor', 'w', ...
                 'Margin', 1, ...
                 'ButtonDownFcn', {@edit_edge_weight, src, dst});
            return
        end

        direction = end_pos - start_pos;
        norm_direction = norm(direction);
        if norm_direction == 0
            return
        end

        unit_direction = direction / norm_direction;
        offset = 0.12;
        arrow_start = start_pos + offset * unit_direction;
        arrow_end = end_pos - offset * unit_direction;
        arrow_delta = arrow_end - arrow_start;

        quiver(ax, arrow_start(1), arrow_start(2), arrow_delta(1), arrow_delta(2), ...
               0, 'Color', [0.2, 0.4, 0.8], 'LineWidth', 1.5, ...
               'MaxHeadSize', 0.35, 'AutoScale', 'off');
        label_pos = (arrow_start + arrow_end) / 2;
        text(ax, label_pos(1), label_pos(2), weight_label, ...
             'FontSize', 10, ...
             'HorizontalAlignment', 'center', ...
             'Interpreter', 'none', ...
             'VerticalAlignment', 'middle', ...
             'BackgroundColor', 'w', ...
             'Margin', 1, ...
             'ButtonDownFcn', {@edit_edge_weight, src, dst});
    end

    function select_node(~, ~, node_idx)
        if isempty(selected_source)
            selected_source = node_idx;
            status_text.String = sprintf('始点: %d を選択中です。終点ノードをクリックしてください。', node_idx);
        else
            edge_weight = lower_bound + (upper_bound - lower_bound) * rand();
            matrix(selected_source, node_idx) = edge_weight;
            history(end + 1, :) = [selected_source, node_idx];
            status_text.String = sprintf('辺 %d -> %d を追加しました (重み: %.4g)。次の始点ノードをクリックしてください。', ...
                                         selected_source, node_idx, edge_weight);
            selected_source = [];
        end
        draw_graph();
    end

    function undo_last_edge(~, ~)
        if isempty(history)
            status_text.String = '取り消す辺がありません。';
            return
        end

        last_edge = history(end, :);
        history(end, :) = [];
        matrix(last_edge(1), last_edge(2)) = 0;
        selected_source = [];
        status_text.String = sprintf('辺 %d -> %d を取り消しました。', last_edge(1), last_edge(2));
        draw_graph();
    end

    function reset_graph(~, ~)
        matrix = zeros(N, N);
        history = zeros(0, 2);
        selected_source = [];
        status_text.String = 'すべての辺を削除しました。始点ノードをクリックしてください。';
        draw_graph();
    end

    function edit_edge_weight(~, ~, src, dst)
        current_weight = matrix(src, dst);
        answer = inputdlg( ...
                          sprintf('辺 %d -> %d の重みを入力してください。', src, dst), ...
                          'Edit Edge Weight', ...
                          [1 50], ...
                          {sprintf('%.16g', current_weight)});

        if isempty(answer)
            status_text.String = sprintf('辺 %d -> %d の重み編集をキャンセルしました。', src, dst);
            return
        end

        new_weight = str2double(answer{1});
        if ~isscalar(new_weight) || ~isfinite(new_weight)
            status_text.String = sprintf('辺 %d -> %d の重みは有限の数値を入力してください。', src, dst);
            return
        end

        matrix(src, dst) = new_weight;
        selected_source = [];
        status_text.String = sprintf('辺 %d -> %d の重みを %.4g に更新しました。', src, dst, new_weight);
        draw_graph();
    end

    function finish_editing(~, ~)
        selected_source = [];
        uiresume(fig);
    end

    function cancel_editing(~, ~)
        selected_source = [];
        matrix = initial_matrix;
        uiresume(fig);
    end

    function handle_close(~, ~)
        if isgraphics(fig) && strcmp(get(fig, 'WaitStatus'), 'waiting')
            uiresume(fig);
        end
        if isgraphics(fig)
            delete(fig);
        end
    end

end
