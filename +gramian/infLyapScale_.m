% +cscore/+gramian/infLyapScale_.m
function wlist = infLyapScale_(A, wopts)
    n = size(A, 1);
    [blocks, blockSizes, ~, Q, Qinv] = gramian.blockDiagonalization_(A, wopts);

    if isempty(Q)
        wlist = gramian.infLyapNoscale_(A, wopts);
        return
    end

    nS = blockSizes(1);
    nI = blockSizes(2);
    nU = blockSizes(3);
    idxS = 1 : nS;
    idxI = nS + 1 : nS + nI;
    idxU = nS + nI + 1 : n;

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
    j = 1;
    if ~isempty(idxS)
        QinvS = Qinv(idxS, :);
        Sa{j} = QinvS * QinvS.';
        j = j + 1;
    end
    if ~isempty(idxI)
        Sa{j} = sparse(nI, nI);
        j = j + 1;
    end
    if ~isempty(idxU)
        Sa{j} = sparse(nU, nU);
    end
    vcsBlocks = 1 : size(W{1}, 2);
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end