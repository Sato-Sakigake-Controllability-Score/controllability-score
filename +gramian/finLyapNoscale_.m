% +cscore/+gramian/finLyapNoscale_.m
function wlist = finLyapNoscale_(A, T, wopts)
    n = size(A, 1);
    eAT = expm(T * A);

    W = cell(n, 1);

    switch wopts.Method
        case "lyap"
            for i = 1:n
                eATi = eAT(:, i);
                rhs = -eATi * eATi.';
                rhs(i, i) = rhs(i, i) + 1;
                W{i}{1} = lyap(A, rhs);
            end

        case "adi"
            error("implement later.");

        otherwise
            error("Unknown Method ""%s"".", wopts.Method);
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
