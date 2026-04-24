function Wk = assembleWBlock(obj, p, k)
    p = p(:);
    if numel(p) ~= obj.n
        error('WList:InvalidPSize', ...
            'p must have length equal to Dimension (%d).', obj.n);
    end

    if k < 1 || k > numel(obj.blockSizes)
        error('WList:InvalidBlockIndex', ...
            'Block index k out of range.');
    end

    nk = obj.blockSizes(k);
    Wk = zeros(nk, nk);

    for i = 1 : obj.n
        if p(i) ~= 0
            Wk = Wk + p(i) * obj.W{i}{k};
        end
    end

    Wk = 0.5 * (Wk + Wk.');
end