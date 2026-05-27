function [blocks, blockSizes, eigA, Q, Qinv] = blockDiagonalization_(A, wopts)
    % BLOCKDIAGONALIZATION_  Block diagonalize A

    validateattributes(A, {'double'}, {'2d', 'real', 'square'}, mfilename, 'A');
    tol = wopts.EigTol;
    validateattributes(tol, {'double'}, {'scalar', 'real', 'positive'}, mfilename, 'tol');

    n = size(A, 1);

    % --- Schur of A.' and eigenvalues ---
    [U, L] = schur(A.', 'real');
    eigA_ = ordeig(L);

    isS = real(eigA_) < -tol;
    isU = real(eigA_) > tol;
    isI = ~(isS | isU);

    nS = nnz(isS);
    nI = nnz(isI);
    nU = nnz(isU);

    if nS + nI + nU ~= n
        error('%s:SchurFails', mfilename);
    end

    % --- if A is stable, no transform is applied ---
    if nS == n
        blocks = {A, [], []};
        blockSizes = [nS, 0, 0];
        eigA = eigA_;
        Q = [];
        Qinv = [];
        return
    end

    % --- reorder L into [stable | imag | unstable] ---
    clusters = 3 * double(isS) + 2 * double(isI) + 1 * double(isU);
    [U, L] = ordschur(U, L, clusters);
    eigA = ordeig(L);

    % --- make L into quasi-lower triangular form ---
    L = L.';

    % --- indices (empty ranges allowed) ---
    idxS = 1:nS;
    idxI = nS + 1:nS + nI;
    idxU = nS + nI + 1:n;

    % --- extract diagonal blocks (0x0 if empty) ---
    Ls = L(idxS, idxS);
    Li = L(idxI, idxI);
    Lu = L(idxU, idxU);

    % --- extract sub-diagonal coupling blocks (empty-compatible) ---
    Lis = L(idxI, idxS);
    Lus = L(idxU, idxS);
    Lui = L(idxU, idxI);

    % --- solve Sylvester equations only when dimensions are nonzero ---
    Sis = zeros(nI, nS);
    Sui = zeros(nU, nI);
    Sus = zeros(nU, nS);

    if nI > 0 && nS > 0
        % Li*Sis - Sis*Ls = -Lis
        Sis = sylvester(Li, -Ls, -Lis);
    end

    if nU > 0 && nI > 0
        % Lu*Sui - Sui*Li = -Lui
        Sui = sylvester(Lu, -Li, -Lui);
    end

    if nU > 0 && nS > 0
        % Lu*Sus - Sus*Ls = -(Lus + Lui*Sis)
        rhs = -Lus;
        if nI > 0
            rhs = -(Lus + Lui * Sis);
        end
        Sus = sylvester(Lu, -Ls, rhs);
    end

    % --- build S ---
    S = eye(n);
    if nI > 0 && nS > 0
        S(idxI, idxS) = Sis;
    end
    if nU > 0 && nS > 0
        S(idxU, idxS) = Sus;
    end
    if nU > 0 && nI > 0
        S(idxU, idxI) = Sui;
    end

    Sinv = S \ eye(n);

    % --- return ---
    blocks = {Ls, Li, Lu};
    blockSizes = [nS, nI, nU];
    Q = U * S;
    Qinv = Sinv * U.';
end
