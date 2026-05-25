% +cscore/+gramian/finIntegralScale_.m
function wlist = finIntegralScale_(A, T, wopts)
    n = size(A, 1);
    [blocks, blockSizes, ~, Q, Qinv] = gramian.blockDiagonalization_(A, wopts);

    if isempty(Q)
        wlist = gramian.finIntegralNoscale_(A, T, wopts);
        return
    end

    nS = blockSizes(1);
    nI = blockSizes(2);
    nU = blockSizes(3);
    idxS = 1 : nS;
    idxI = nS + 1 : nS + nI;
    idxU = nS + nI + 1 : n;

    if mod(wopts.Steps, 2) == 0
        steps = wopts.Steps;
    else
        steps = wopts.Steps + 1;
    end
    dt = T / steps;

   
    W = cell(n, 1);
    for i = 1 : n
        W{i} = {zeros(n, n)};
    end

    for k = 0 : steps
        t = k * dt;
        if k == 0 || k == steps
            weight = 1 / 3 * dt;
        elseif mod(k, 2) == 0
            weight = 2 / 3 * dt;
        else
            weight = 4 / 3 * dt;
        end

        if ~isempty(idxS)
            eASt = expm(t * blocks{1});
        end
        if ~isempty(idxI)
            eAIt = 1/sqrt(T) * expm(t * blocks{2});
        end
        if ~isempty(idxU)
            emAUt = expm(-(T-t) * blocks{3});
        end


        for i = 1 : n
            % --- left half plane ---
            if ~isempty(idxS)
                QinviS = Qinv(idxS, i);
                eAStQinviS = eASt * QinviS;
                W{i}{1}(idxS, idxS) = W{i}{1}(idxS, idxS) + weight * (eAStQinviS * eAStQinviS.');
            end
    
            % --- imaginary axis ---
            if ~isempty(idxI)
                QinviI = Qinv(idxI, i);
                eAItQinviI = eAIt * QinviI;
                W{i}{1}(idxI, idxI) = W{i}{1}(idxI, idxI) + weight * (eAItQinviI * eAItQinviI.');
            end
    
            % --- right half plane ---
            if ~isempty(idxU)
                QinviU = Qinv(idxU, i);
                emAUtQinviU = emAUt * QinviU;
                W{i}{1}(idxU, idxU) = W{i}{1}(idxU, idxU) + weight * (emAUtQinviU * emAUtQinviU.');
            end

            % --- cross terms ---
            % --- left half plane and imaginary axis ---
            if ~isempty(idxS) && ~isempty(idxI)
                W{i}{1}(idxS, idxI) = W{i}{1}(idxS, idxI) + weight * (eAStQinviS * eAItQinviI.');
            end

            % --- imaginary axis and right half plane ---
            if ~isempty(idxI) && ~isempty(idxU)
                W{i}{1}(idxI, idxU) = W{i}{1}(idxI, idxU) + weight * (eAItQinviI * emAUtQinviU.');
            end

            % --- left half plan and right half plane ---
            if ~isempty(idxS) && ~isempty(idxU)
                W{i}{1}(idxS, idxU) = W{i}{1}(idxS, idxU) + weight * (eAStQinviS * emAUtQinviU.');
            end
        end
    end


    for i = 1 : n
        % --- cross terms ---
        % --- left half plane and imaginary axis ---
        if ~isempty(idxS) && ~isempty(idxI)
            W{i}{1}(idxI, idxS) = W{i}{1}(idxS, idxI).';
        end
    
        % --- imaginary axis and right half plane ---
        if ~isempty(idxI) && ~isempty(idxU)
            W{i}{1}(idxU, idxI) = W{i}{1}(idxI, idxU).';
        end
    
        % --- left half plan and right half plane ---
        if ~isempty(idxS) && ~isempty(idxU)
            W{i}{1}(idxU, idxS) = W{i}{1}(idxS, idxU).';
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