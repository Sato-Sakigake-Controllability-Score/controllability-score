function [f, g] = evalVcs(obj, p)
%EVALVCS Evaluate VCS objective and optionally its gradient.
%   f = evalVcs(obj,p) computes the VCS objective value only.
%   [f,g] = evalVcs(obj,p) computes the objective and its gradient.
%
%   VCS (blockwise):
%     f(p) = - sum_{k in vcsBlocks} logdet(W_k(p)),
%     W_k(p) = sum_{i=1}^n p_i * W_{i,k}.
%
%   Notes:
%     - Simplex feasibility of p is handled by the projection operator in
%       the solver; this method only checks dimension consistency.

    validateattributes(p, {'double'}, {'vector','real'}, 'WList', 'p');
    p = p(:);
    n = obj.n;
    if numel(p) ~= n
        error('WList:InvalidPSize', ...
            'p must have length equal to Dimension (%d). Got %d.', n, numel(p));
    end

    wantGrad = (nargout >= 2);
    if wantGrad
        g = zeros(n,1);
    else
        g = [];
    end

    f = 0.0;

    for k = obj.vcsBlocks
        Wk = obj.assembleWBlock(p, k);

        [tf, d] = csutil.isposdef(Wk);
        if ~tf
            f = Inf;
            if wantGrad
                g(:) = NaN;
            end
            return
        end

        % f += -logdet(Wk)
        f = f - sum(log(d));

        if wantGrad
            Winvk = inv(Wk);

            % g_i += -trace(Winvk * W_{i,k})
            for i = 1 : n
                Wik = obj.W{i}{k};
                g(i) = g(i) - sum(Winvk .* Wik.', "all"); % trace(Winvk*Wik)
            end
        end
    end

    if ~isfinite(f)
        f = Inf;
    end
    if wantGrad && any(~isfinite(g))
        g(:) = NaN;
    end
end