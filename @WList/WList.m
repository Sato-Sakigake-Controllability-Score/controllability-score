% +cscore/@WList/WList.m
classdef WList < handle
%WList  Stores Wi and compute values related to W(p) for VCS/AECS.
%
% Data convention:
%   - n denotes BOTH:
%       (i)  dimension of each Wi (n-by-n), and
%       (ii) number of Wi (|{Wi}| = n).
%
% Block representation:
%   - blockSizes: 1-by-nb positive integers with sum(blockSizes) = n.
%   - W: cell array of length n.
%       W{i} is a cell array of length nb (= numel(blockSizes)).
%       W{i}{b} is a block matrix of size blockSizes(b)-by-blockSizes(b).
%   - "No block structure" is represented as a single block:
%       - blockSizes = n;   nb=1;
%       - W{i} = {Wi}.
%
% Block selection:
%   - vcsBlocks: blocks used in VCS objective (typically 1:nb)
%   - aecsBlocks: blocks used in AECS objective (typically 1)
%
% Inputs:
%   W            cell (1 x n): W{i}{b} blocks
%   Q            transformation matrix (can be [] if no transform)
%   Sa           cell (1 x nb): constant block marix for AECS (can be [])
%   wopts        options used for computation
%   vcsBlocks    blocks used for VCS (typically 1:nb)
%   aecsBlocks   blocks used for AECS (typically 1)
%
% Notes on Q:
%   Q is a matrix to transform A into block-diagonal form:
%        J = Q^{-1} A Q
%

    %% Properties
    properties (SetAccess = private)
        W               % cell length n; each WList{i}{b} is a block
        Q
        Sa

        vcsBlocks
        aecsBlocks
        blockSizes      % 1-by-nb vector
        n               % total dimension AND number of Wi
        nb              % number of blocks

        WOptions        % options used for computation
    end

    %% Constructor
    methods
        function obj = WList(W, Q, Sa, wopts, vcsBlocks, aecsBlocks)
            %WLIST Construct a WList.
            %
            % Inputs:
            %   W            cell (length n): W{i}{b} blocks
            %   Q,Sa         constants (can be [])
            %   vcsBlocks    blocks for VCS (typically all)
            %   aecsBlocks   blocks for AECS (typically 1)
            %   blockSizes   vector of block sizes (sum = n)
            %   wopts        options used for computation

            if nargin < 3
                error("WList:NotEnoughInputs", ...
                    "Expected at least 3 inputs: W,Q,Sa.");
            end

            if nargin < 4, wopts = []; end
            if nargin < 5 || isempty(vcsBlocks),  vcsBlocks = [];  end
            if nargin < 6 || isempty(aecsBlocks), aecsBlocks = []; end

            if ~iscell(W) || isempty(W) || ~all(cellfun(@iscell, W))
                error("W must be a cell array whose elements are cell arrays of matrices.");
            end
            W = W(:).';
            for i = 1 : numel(W)
                W{i} = W{i}(:).';
            end
            blockSizes = cellfun(@(A) size(A, 1), W{1});

            if iscell(Sa)
                Sa = Sa(:).';
            end

            obj.W = W;
            obj.Q = Q;
            obj.Sa = Sa;
            obj.blockSizes = blockSizes;
            obj.n = sum(obj.blockSizes);
            obj.nb = numel(obj.blockSizes);

            if isempty(vcsBlocks)
                obj.vcsBlocks = 1 : obj.nb;
            else
                obj.vcsBlocks = unique(sort(vcsBlocks(:).'));
            end
            if isempty(aecsBlocks)
                obj.aecsBlocks = 1;
            else
                obj.aecsBlocks = unique(sort(aecsBlocks(:).'));
            end

            obj.WOptions = wopts;

            % Validate assumptions: numel(W)=n and each block matches blockSizes
            validateWList_(obj);
        end
    end

    %% Public methods
    methods
        Wk = assembleWBlock(obj, p, k)
        [f, g] = evalVcs(obj, p)
        [f, g] = evalAecs(obj, p)
    end

    %% Private methods
    methods (Access = private)
        validateWList_(obj)
    end
end
