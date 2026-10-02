% +cscore/+gramian/finVanLoanNoscale_.m
function wlist = finVanLoanNoscale_(A, T, wopts)
    n = size(A, 1);

    W = cell(n, 1);

    for i = 1:n
        bi = zeros(n, 1, 'like', A);
        bi(i) = 1;
        W{i} = {gramian.finiteGramianVanLoan_(A, T, bi)};
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
