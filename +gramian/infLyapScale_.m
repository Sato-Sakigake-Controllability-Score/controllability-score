% +cscore/+gramian/infLyapScale_.m
function wlist = infLyapScale_(A, wopts)
    n = size(A, 1);
    [blocks, blockSizes, ~, Q, Qinv] = gramian.blockDiagonalization_(A, wopts);

    idxS = 1 : blockSizes(1);
    idxI = blockSizes(1) + 1 : blockSizes(1) + blockSizes(2);
    idxU = blockSizes(1) + blockSizes(2) + 1 : n;

    W = cell(n, 1);

    for i = 1 : n
        Qinvi = Qinv(:, i);

        % --- left half plane ---
        if ~isempty(idxS)
            QinviS = Qinvi(idxS);
            W{i}{end + 1} = lyap(blocks{1}, QinviS * QinviS.');
        end

        % --- imaginary axis ---
        if ~isempty(idxI)
            QinviI = Qinvi(idxI);
            %W{i}{end + 1} = QinviI * QinviI.';
            W{i}{end + 1} = lyap(blocks{2} - 1e-8 * eye(size(blocks{2})), QinviI * QinviI.');
        end

        % --- right half plane ---
        if ~isempty(idxU)
            QinviU = Qinvi(idxU);
            W{i}{end + 1} = lyap(-blocks{3}, QinviU * QinviU.');
        end
    end

    Sa = cell(size(W{1}));
    vcsBlocks = 1 : size(W{1}, 2);
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end