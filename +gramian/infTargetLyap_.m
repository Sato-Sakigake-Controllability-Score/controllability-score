function wlist = infTargetLyap_(A, targetNodes, wopts)
    eigA = eig(A);
    if any(real(eigA) > -wopts.EigTol)
        error("computeTargetGramian:A is unstable." + ...
            " T=inf requires A to be stable in target mode.")
    end

    m = numel(targetNodes);
    n = size(A, 1);
    W = cell(m, 1);

    for i = 1 : m
        idx = targetNodes(i);
        Ei = zeros(n, n);
        Ei(idx, idx) = 1;

        Xi = lyap(A, Ei);
        W{i} = {Xi(targetNodes, targetNodes)};
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
