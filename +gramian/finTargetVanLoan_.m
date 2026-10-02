function wlist = finTargetVanLoan_(A, T, targetNodes, wopts)
    n = size(A, 1);
    m = numel(targetNodes);

    W = cell(m, 1);

    for i = 1:m
        idx = targetNodes(i);

        bi = zeros(n, 1, 'like', A);
        bi(idx) = 1;
        Xi = gramian.finiteGramianVanLoan_(A, T, bi);

        W{i} = {Xi(targetNodes, targetNodes)};
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
