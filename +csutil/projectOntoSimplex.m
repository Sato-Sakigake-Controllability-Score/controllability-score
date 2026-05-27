function pProj = projectOntoSimplex(p)
    % PROJECTONTOSIMPLEX Project a vector onto the probability simplex.
    %   pProj = projectOntoSimplex(p) returns the Euclidean projection of p onto
    %       { x : x >= 0, sum(x) = 1 }.
    %
    %   The output is a column vector with the same number of elements as p.

    validateattributes(p, {'double'}, {'vector', 'real', 'finite'}, ...
                       'projectOntoSimplex', 'p');

    p = p(:);
    n = numel(p);

    if n == 0
        error('csutil:projectOntoSimplex:EmptyInput', ...
              'Input must be a nonempty vector.');
    end

    % Sort in descending order
    u = sort(p, 'descend');

    % Find rho = max { j : u_j - (1/j)(sum_{i=1}^j u_i - 1) > 0 }
    cssv = cumsum(u);
    j = (1:n).';
    t = (cssv - 1) ./ j;
    rho = find(u - t > 0, 1, 'last');

    if isempty(rho)
        % Should not happen for finite input, but keep it safe.
        pProj = ones(n, 1) / n;
        return
    end

    theta = t(rho);

    % Projection
    pProj = max(p - theta, 0);

    % Numerical guard: enforce exact sum=1 if close
    s = sum(pProj);
    if s ~= 0
        pProj = pProj / s;
    else
        pProj = ones(n, 1) / n;
    end
end
