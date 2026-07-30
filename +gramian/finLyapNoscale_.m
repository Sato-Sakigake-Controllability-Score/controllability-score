% +cscore/+gramian/finLyapNoscale_.m
function wlist = finLyapNoscale_(A, T, wopts)
    n = size(A, 1);

    W = cell(n, 1);
    for i = 1:n
        if issparse(A)
            bi = sparse(n, 1);
        else
            bi = zeros(n, 1, 'like', A);
        end
        bi(i) = 1;
        W{i} = {gramian.finiteGramianVanLoan_(A, T, bi)};
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
