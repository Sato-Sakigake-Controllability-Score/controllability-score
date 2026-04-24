% +cscore/+gramian/infLyapNoscale_.m
function wlist = infLyapNoscale_(A, wopts)
    n = size(A, 1);
    eigA = eig(A);
    if any(real(eigA) > -wopts.EigTol)
        error("computeGramian:A is unstable." + ...
            "T=inf without scaling requires A is stable.")
    end

    W = cell(n, 1);

    switch wopts.Method
        case "lyap"
            for i = 1 : n
                Ei = zeros(n, n);
                Ei(i, i) = 1;
                W{i}{1} = lyap(A, Ei);
            end

        case "adi"
            error("implement later.")

        otherwise
            error("Unknown Method ""%s"".", wopts.Method)
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end