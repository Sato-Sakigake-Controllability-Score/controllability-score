function wlist = finTargetLyap_(A, T, targetNodes, wopts)
    eAT = expm(T * A);
    m = numel(targetNodes);

    W = cell(m, 1);

    for i = 1 : m
        idx = targetNodes(i);
        rhs = -eAT(:, idx) * eAT(:, idx).';
        rhs(idx, idx) = rhs(idx, idx) + 1;

        Xi = lyap(A, rhs);
        W{i} = {Xi(targetNodes, targetNodes)};
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
