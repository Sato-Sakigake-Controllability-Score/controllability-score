classdef CSProblem
%CSPROBLEM Controllability scoring problem definition.
%   prob = CSProblem(A) constructs a problem for system matrix A with
%   time horizon T = Inf. WOptions defaults to WOptions(A,Inf).
%
%   prob = CSProblem(A,T) uses the specified time horizon T (scalar > 0 or Inf).
%
%   prob = CSProblem(A,T,Name,Value,...) supports:
%       'WOptions'      - WOptions object (default: WOptions(A,T))
%       'InitialGuess'  - initial guess p (default: uniform vector of length n)
%

    %% Public properties (read-only)
    properties (SetAccess = private)
        % controllability Gramians
        WList

        % Dimensions
        Dimension          % n = size(A,1)

        % Target node indices for target controllability score problems.
        % Empty means the original full-state controllability score.
        TargetNodes
    end

    %% Initial guess (user-settable but dimension-consistent)
    properties (Dependent)
        InitialGuess
    end

    properties (Access = private)
        InitialGuessInternal double = []
    end

    %% Constructor
    methods
        function obj = CSProblem(A, varargin)
        %CSPROBLEM Construct a CSProblem instance.
        %   prob = CSProblem(A)
        %   prob = CSProblem(A,T)
        %   prob = CSProblem(A,T,Name,Value,...)
        %   prob = CSProblem(A,Name,Value,...)   (T defaults to Inf)

            %----- A: required -----
            if nargin < 1
                error('CSProblem:NotEnoughInputs', ...
                    'At least the system matrix A must be provided.');
            end
            validateattributes(A, {'double'}, {'2d','real','square'}, ...
                'CSProblem', 'A', 1);
            n = size(A,1);

            %----- Optional positional T -----
            T = Inf;
            nvStart = 1;
            if nargin >= 2
                firstOpt = varargin{1};
                if isnumeric(firstOpt) && isscalar(firstOpt)
                    T = firstOpt;
                    nvStart = 2;
                end
            end
            validateattributes(T, {'double'}, {'scalar','real'}, ...
                'CSProblem', 'T', 2);

            if T <= 0
                error('CSProblem:InvalidT', ...
                    'T must be positive. Got %.2f.', ...
                    T);
            end

            %----- Name-Value parsing -----
            parser = inputParser;
            parser.FunctionName = 'CSProblem';

            addParameter(parser, 'WOptions', WOptions, ...
                @(v) isempty(v) || isa(v,'WOptions'));

            addParameter(parser, 'InitialGuess', [], ...
                @(v) isempty(v) || (isnumeric(v) && isvector(v)));
            addParameter(parser, 'TargetNodes', [], ...
                @(v) isempty(v) || (isnumeric(v) && isvector(v)));

            parse(parser, varargin{nvStart:end});
            r = parser.Results;

            wopts = r.WOptions;

            targetNodes = [];
            if ~isempty(r.TargetNodes)
                targetNodes = unique(r.TargetNodes(:), "stable");
                validateattributes(targetNodes, {'double'}, ...
                    {'integer','positive','<=',n}, 'CSProblem', 'TargetNodes');
                targetNodes = double(targetNodes(:));
            end

            %----- Compute W list (block-diagonal representation) -----
            if isempty(targetNodes)
                WList = gramian.computeGramian(A, T, wopts);
                obj.Dimension = n;
            else
                WList = gramian.computeGramian(A, T, wopts, targetNodes);
                obj.Dimension = numel(targetNodes);
            end

            %----- Assign core properties -----
            obj.WList           = WList;
            obj.TargetNodes     = targetNodes;

            %----- InitialGuess -----
            if isempty(r.InitialGuess)
                obj.InitialGuess = ones(obj.Dimension,1) / obj.Dimension;
            else
                obj.InitialGuess = r.InitialGuess;
            end
        end
    end

    %% Dependent property accessors for InitialGuess
    methods
        function value = get.InitialGuess(obj)
            value = obj.InitialGuessInternal;
        end

        function obj = set.InitialGuess(obj, value)
            validateattributes(value, {'double'}, {'vector','real'}, ...
                'CSProblem', 'InitialGuess');
            value = value(:);
            if ~isempty(obj.Dimension) && numel(value) ~= obj.Dimension
                error('CSProblem:InvalidInitialGuessSize', ...
                    'InitialGuess must have length equal to Dimension (%d). Got %d.', ...
                    obj.Dimension, numel(value));
            end
            obj.InitialGuessInternal = value;
        end
    end

    %% Public methods
    methods
        function [f, g] = fVcs(obj, p)
            [f, g] = obj.WList.evalVcs(p);
        end

        function g = gradVcs(obj, p)
            [~, g] = obj.WList.evalVcs(p);
        end

        function [f, g] = fAecs(obj, p)
            [f, g] = obj.WList.evalAecs(p);
        end

        function g = gradAecs(obj, p)
            [~, g] = obj.WList.evalAecs(p);
        end
        
        [p, info] = solveVcs(obj, varargin)
        [p, info] = solveAecs(obj, varargin)
    end
end
