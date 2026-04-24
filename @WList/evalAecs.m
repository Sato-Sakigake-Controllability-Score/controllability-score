function [f, g] = evalAecs(obj, p)
%EVALAECS Evaluate AECS objective and optionally its gradient.
%   f = evalAecs(obj,p) computes the AECS objective value only.
%   [f,g] = evalAecs(obj,p) computes the objective and its gradient.
%
%   AECS (blockwise):
%     f(p) = sum_{k in aecsBlocks} trace( inv(W_k(p)) * Sa_k ),
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
    Sa = obj.Sa;

    for k = obj.aecsBlocks
        Wk = obj.assembleWBlock(p, k);

        [tf, d] = csutil.isposdef(Wk);
        if ~tf
            f = Inf;
            if wantGrad
                g(:) = NaN;
            end
            return
        end

        Sak = Sa{k};

        if isempty(Sak)
            % f += trace(Winvk)
            f = f + sum(1 ./ d);

            if wantGrad
                Winvk = inv(Wk);
                % g_i += -trace( (Winvk * Winvk) * W_{i,k} )
                Gk = Winvk * Winvk;

                for i = 1 : n
                    Wik = obj.W{i}{k};
                    g(i) = g(i) - sum(Gk .* Wik.', "all");
                end
            end
        else
            % f += trace(Winvk*Sak) = sum(sum(Winvk .* Sak.'))
            Winvk = inv(Wk);
            f = f + sum(Winvk .* Sak.', "all");

            if wantGrad
                % g_i += -trace( (Winvk * Sak * Winvk) * W_{i,k} )
                Gk = Winvk * Sak * Winvk;
    
                for i = 1 : n
                    Wik = obj.W{i}{k};
                    g(i) = g(i) - sum(Gk .* Wik.', "all");
                end
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