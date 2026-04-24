% +cscore/@WList/validateWList_.m
function validateWList_(obj)
%validateWList  Validate consistency of WList.
%
% Enforced conventions:
%   - n := sum(blockSizes) is BOTH:
%       (i)  dimension of each Wi (n-by-n), and
%       (ii) number of Wi (|{Wi}| = n).
%
% Representation enforced:
%   - W is a cell array of length n.
%   - W{i} is a cell array of length nb (= numel(blockSizes)).
%   - W{i}{b} is a square matrix of size blockSizes(b)-by-blockSizes(b).
%
% Block selections enforced:
%   - vcsBlocks and aecsBlocks are integer indices in 1..nb, no duplicates.
%
% AECS constant enforced:
%   - Sa is a cell array of length nb (= numel(blockSizes)).
%   - Sa{b} is a square matrix of size blockSizes(b)-by-blockSizes(b).
%

    % ----------------------------
    % WList: length
    % ----------------------------
    if numel(obj.W) ~= obj.n
        error('WList:WiCountMismatch', ...
            'Number of Wi must equal n=sum(blockSizes)=%d. Got numel(W)=%d.', ...
            obj.n, numel(obj.W));
    end
    
    % ----------------------------
    % block selections: validate
    % ----------------------------
    validateBlocks_(obj.vcsBlocks, obj.nb, "vcsBlocks");
    validateBlocks_(obj.aecsBlocks, obj.nb, "aecsBlocks");
    
    % ----------------------------
    % each Wi: block cell of length nb, each block square of correct size
    % ----------------------------
    for i = 1 : obj.n
        Wi = obj.W{i};
    
        if ~iscell(Wi) || numel(Wi) ~= obj.nb
            error('WList:WiNotBlockCell', ...
                'W{%d} must be a cell array with nb=%d blocks.', i, obj.nb);
        end
    
        for b = 1 : obj.nb
            if isempty(Wi{b})
                error('WList:MissingMatrix', '%s must be provided (nonempty).', ...
                    sprintf('W{%d}{%d}', i, b));
            end
            sb = obj.blockSizes(b);
            checkSquareN_(Wi{b}, sb, sprintf('W{%d}{%d}', i, b));
        end
    end
    
    % ----------------------------
    % Sa: block cell of length nb, each block square of correct size
    % ----------------------------
    if ~iscell(obj.Sa) || numel(obj.Sa) ~= obj.nb
        error('WList:SaNotBlockCell', ...
                'Sa must be a cell array with nb=%d blocks.', obj.nb);
    end

    for b = 1 : obj.nb
        sb = obj.blockSizes(b);
        checkSquareN_(obj.Sa{b}, sb, sprintf('Sa{%d}', b));
    end
end
    

% ===== local helpers =====
    
function validateBlocks_(blocks, nb, name)
    if isempty(blocks) || ~isvector(blocks)
        error('WList:BadBlocks', '%s must be a nonempty vector.', name);
    end
    if any(~isfinite(blocks)) || any(mod(blocks,1) ~= 0)
        error('WList:BadBlocks', '%s must contain finite integers.', name);
    end
    if any(blocks < 1) || any(blocks > nb)
        error('WList:BadBlocks', '%s must be integer indices within 1..%d.', name, nb);
    end
    if numel(unique(blocks)) ~= numel(blocks)
        error('WList:DuplicateBlocks', '%s contains duplicate block indices.', name);
    end
end
    
function checkSquareN_(X, n, name)
    %checkSquareN_  Require X to be empty or n-by-n numeric real matrix.
    if isempty(X)
        return
    end
    if ~ismatrix(X) || ~isequal(size(X), [n n])
        error('WList:BadSize', '%s must be %d-by-%d.', name, n, n);
    end
    if ~isnumeric(X) || ~isreal(X)
        error('WList:BadType', '%s must be a real numeric matrix.', name);
    end
end
