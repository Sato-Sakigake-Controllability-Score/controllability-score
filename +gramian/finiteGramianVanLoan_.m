function W = finiteGramianVanLoan_(A, T, b)
% FINITEGRAMIANVANLOAN_
% Compute the finite-horizon controllability Gramian
%
%   W = integral_0^T exp(A*t) * (b*b.') * exp(A.'*t) dt
%
% using the Van Loan block matrix exponential.

n = size(A, 1);
b = b(:);

if numel(b) ~= n
    error("gramian:InvalidInputVector", ...
        "b must have the same number of rows as A.");
end

Z = zeros(n, n, 'like', A);

M = [
    -A,          b * b.'
    Z,           A.'
];

EM = expm(T * M);

% EM has the block form
%
% [ exp(-A*T), F         ]
% [ 0,         exp(A.'*T)]
%
% and W = exp(A*T) * F.

F = EM(1:n, n + 1:2 * n);
eAT = EM(n + 1:2 * n, n + 1:2 * n).';

W = eAT * F;

% Remove numerical asymmetry caused by roundoff.
W = 0.5 * (W + W.');

% Do not silently pass overflow or NaN to the optimizer.
if any(~isfinite(W), "all")
    error("gramian:FiniteHorizonOverflow", ...
        ["The finite-horizon Gramian contains Inf or NaN. " ...
         "The matrix exponential may have overflowed."]);
end

end