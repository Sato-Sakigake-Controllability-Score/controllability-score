% +cscore/+gramian/finLyapScale_.m
function wlist = finLyapScale_(A, T, wopts)
    n = size(A, 1);
    [blocks, blockSizes, ~, Q, Qinv] = gramian.blockDiagonalization_(A, wopts);

    if isempty(Q)
        wlist = gramian.finLyapNoscale_(A, T, wopts);
        return
    end

    nS = blockSizes(1);
    nI = blockSizes(2);
    nU = blockSizes(3);
    idxS = 1:nS;
    idxI = nS + 1:nS + nI;
    idxU = nS + nI + 1:n;

    W = cell(n, 1);

    if ~isempty(idxS)
        eAST = expm(T * blocks{1});
    end
    if ~isempty(idxU)
        emAUT = expm(-T * blocks{3});
    end

    for i = 1:n
        W{i} = cell(1, 1);
        W{i}{1} = zeros(n, n);

        Qinvi = Qinv(:, i);

        % --- left half plane ---
        if ~isempty(idxS)
            QinviS = Qinvi(idxS);
            eASTQinviS = eAST * QinviS;
            W{i}{1}(idxS, idxS) = lyap(blocks{1}, QinviS * QinviS.' - eASTQinviS * eASTQinviS.');
        end

        % --- imaginary axis ---
        if ~isempty(idxI)
            QinviI = Qinvi(idxI);
            CII = [-blocks{2}, QinviI * QinviI.'
                   zeros(nI, nI), blocks{2}.'];
            eCIIT = expm(T * CII);
            eAIT = eCIIT(nI + 1:2 * nI, nI + 1:2 * nI).';
            W{i}{1}(idxI, idxI) = eAIT * eCIIT(1:nI, nI + 1:2 * nI) / T;
        end

        % --- right half plane ---
        if ~isempty(idxU)
            QinviU = Qinvi(idxU);
            emAUTQinviU = emAUT * QinviU;
            W{i}{1}(idxU, idxU) = lyap(-blocks{3}, QinviU * QinviU.' - emAUTQinviU * emAUTQinviU.');
        end

        % ---- cross terms ----
        % --- left half plane and imaginary axis ---
        if ~isempty(idxS) && ~isempty(idxI)
            CIS = [-blocks{2}, QinviI * QinviS.'
                   zeros(nS, nI), blocks{1}.'];
            eCIST = expm(T * CIS);
            W{i}{1}(idxI, idxS) = eAIT * eCIST(1:nI, nI + 1:nI + nS) / sqrt(T);
            W{i}{1}(idxS, idxI) = W{i}{1}(idxI, idxS).';
        end

        % --- left half plane and right half plane ---
        if ~isempty(idxS) && ~isempty(idxU)
            CUS = [-blocks{3}, QinviU * QinviS.'
                   zeros(nS, nU), blocks{1}.'];
            eCUST = expm(T * CUS);
            W{i}{1}(idxU, idxS) = eCUST(1:nU, nU + 1:nU + nS);
            W{i}{1}(idxS, idxU) = W{i}{1}(idxU, idxS).';
        end

        % --- imaginary axis and right half plane ---
        if ~isempty(idxI) && ~isempty(idxU)
            CUI = [-blocks{3}, QinviU * QinviI.'
                   zeros(nI, nU), blocks{2}.'];
            eCUIT = expm(T * CUI);
            W{i}{1}(idxU, idxI) = eCUIT(1:nU, nU + 1:nU + nI) / sqrt(T);
            W{i}{1}(idxI, idxU) = W{i}{1}(idxU, idxI).';
        end
    end

    if isempty(idxU)
        emAUT = speye(0);
    end

    DinvFull = blkdiag(speye(nS, nS), speye(nI, nI) / sqrt(T), emAUT);
    Sa = {DinvFull * (Qinv * Qinv.') * DinvFull.'};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
