% +cscore/+gramian/finIntegralNoscale_.m
function wlist = finIntegralNoscale_(A, T, wopts)
    n = size(A, 1);

    if mod(wopts.Steps, 2) == 0
        steps = wopts.Steps;
    else
        steps = wopts.Steps + 1;
    end
    dt = T / steps;

    W = cell(n, 1);

    eAt = expm(T * A);
    for i = 1 : n
        W{i} = {zeros(n, n)};
        W{i}{1}(i, i) = 1 / 3 * dt;
        W{i}{1} = W{i}{1} + 1 / 3 * dt * eAt(:, i) * eAt(:, i).';
    end

    for k = 1 : steps - 1
        t = k * dt;
        eAt = expm(t * A);

        if mod(k, 2) == 0
            for i = 1 : n
                W{i}{1} = W{i}{1} + 2 / 3 * dt * eAt(:, i) * eAt(:, i).';
            end
        else
            for i = 1 : n
                W{i}{1} = W{i}{1} + 4 / 3 * dt * eAt(:, i) * eAt(:, i).';
            end
        end
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end