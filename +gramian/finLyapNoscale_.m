% +cscore/+gramian/finLyapNoscale_.m
function wlist = finLyapNoscale_(A, T, wopts)
    n = size(A, 1);

    W = cell(n, 1);
    I = eye(n, 'like', A);

    for i = 1:n
        bi = I(:, i);
        W{i} = {gramian.finiteGramianVanLoan_(A, T, bi)};
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
