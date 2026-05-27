function varargout = isposdef(A)
    % ISPOSDEF Test numerical symmetric positive definiteness of a matrix.
    %
    %   tf = isposdef(A)
    %   [tf,d] = isposdef(A)
    %
    %   Criterion:
    %       tol = length(d) * eps(max(abs(d)))
    %       eigenvalues within tol of zero are treated as zero

    % --- Check square matrix ---
    validateattributes(A, {'double'}, {'2d', 'real', 'square'}, 'isposdef', 'A', 1);

    if ~issymmetric(A)
        tf = false;
        d = [];
    else
        d = eig(A);
        tol = numel(d) * eps(max(abs(d)));
        tf = all(d > tol);
        d(abs(d) <= tol) = 0;
    end

    switch nargout
        case {0, 1}
            varargout = {tf};
        otherwise
            varargout = {tf, d};
    end
end
