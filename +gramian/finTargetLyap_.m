function wlist = finTargetLyap_(A, T, targetNodes, wopts)
    n = size(A, 1);
    m = numel(targetNodes);

    W = cell(m, 1);
    I = eye(n, 'like', A);

    for i = 1:m
        idx = targetNodes(i);

        bi = I(:, idx);
        Xi = gramian.finiteGramianVanLoan_(A, T, bi);

        W{i} = {Xi(targetNodes, targetNodes)};
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
