function wlist = finTargetIntegral_(A, T, targetNodes, wopts)
    m = numel(targetNodes);

    if mod(wopts.Steps, 2) == 0
        steps = wopts.Steps;
    else
        steps = wopts.Steps + 1;
    end
    dt = T / steps;

    W = cell(m, 1);
    for i = 1 : m
        W{i} = {zeros(m, m)};
    end

    for k = 0 : steps
        t = k * dt;
        eAt = expm(t * A);
        V = eAt(targetNodes, targetNodes);

        if k == 0 || k == steps
            weight = dt / 3;
        elseif mod(k, 2) == 0
            weight = 2 * dt / 3;
        else
            weight = 4 * dt / 3;
        end

        for i = 1 : m
            vi = V(:, i);
            W{i}{1} = W{i}{1} + weight * (vi * vi.');
        end
    end

    Q = [];
    Sa = {[]};
    vcsBlocks = 1;
    aecsBlocks = 1;

    wlist = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks);
end
