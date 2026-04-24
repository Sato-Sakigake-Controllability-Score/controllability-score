function varargout = aecs(A, varargin)
%AECS Solve the AECS problem from A and T.
%
%   p = aecs(A)
%   [p,info] = aecs(A,T,...)
%   [p,info,WList] = aecs(A,T,...)
%
%   Supported names:
%       T, TargetNodes, CSOptions, WOptions, PGSolverOptions
%       plus WOptions properties: Method, Steps, UseScaling, EigTol
%       plus PGSolverOptions properties: StepSize, StepSizeInf, MaxIter,
%       Tol, Rho, Sigma, Verbose, StorTrace
%

    narginchk(1, inf)

    % ---- nargout validation ----
    allowed = [0 1 2 3];
    if ~ismember(nargout, allowed)
        error("aecs:InvalidNargout", "aecs supports %s outputs.", mat2str(allowed));
    end

    % ---- Parse T (optional) ----
    T = inf;
    nvStart = 1;

    if nargin >= 2
        maybeT = varargin{1};
        if isnumeric(maybeT) && isscalar(maybeT)
            T = maybeT;
            nvStart = 2;
        else
            % No positional T; treat varargin{1} as Name-Value start.
            T = inf;
            nvStart = 1;
        end
    end

    % ---- Parse Name-Value pairs ----
    parser = inputParser;
    parser.FunctionName = 'aecs';

    % Core objects
    addParameter(parser,'T',[], @(v) isempty(v) || (isnumeric(v)&&isscalar(v)));
    addParameter(parser,'TargetNodes',[], @(v) isempty(v) || (isnumeric(v)&&isvector(v)));
    addParameter(parser,'CSOptions',CSOptions, @(v) isa(v,'CSOptions') && isscalar(v));
    addParameter(parser,'WOptions',[], @(v) isempty(v) || (isa(v,'WOptions') && isscalar(v)));
    addParameter(parser,'SolverOptions',[], @(v) isempty(v) || (isa(v,'PGSolverOptions') && isscalar(v)));

    % WOptions properties
    addParameter(parser,'Method',[], @(v) isempty(v) || ischar(v) || isstring(v));
    addParameter(parser,'Steps',[], @(v) isempty(v) || (isnumeric(v) && isscalar(v)));
    addParameter(parser,'UseScaling',[], @(v) isempty(v) || (islogical(v)&&isscalar(v)) || (isnumeric(v)&&isscalar(v)&&any(v==[0 1])));
    addParameter(parser,'EigTol',[], @(v) isempty(v) || (isnumeric(v) && isscalar(v)));

    % SolverOptions propeties
    addParameter(parser,'StepSize',[], @(v) isempty(v) || (isnumeric(v)&&isscalar(v)));
    addParameter(parser,'StepSizeInf',[], @(v) isempty(v) || (isnumeric(v)&&isscalar(v)));
    addParameter(parser,'MaxIter',[], @(v) isempty(v) || (isnumeric(v)&&isscalar(v)));
    addParameter(parser,'Tol',[], @(v) isempty(v) || (isnumeric(v)&&isscalar(v)));
    addParameter(parser,'Rho',[], @(v) isempty(v) || (isnumeric(v)&&isscalar(v)));
    addParameter(parser,'Sigma',[], @(v) isempty(v) || (isnumeric(v)&&isscalar(v)));
    addParameter(parser,'Verbose',[], @(v) isempty(v) || (islogical(v)&&isscalar(v)) || (isnumeric(v)&&isscalar(v)&&any(v==[0 1])));
    addParameter(parser,'StoreTrace',[], @(v) isempty(v) || (islogical(v)&&isscalar(v)) || (isnumeric(v)&&isscalar(v)&&any(v==[0 1])));

    parse(parser, varargin{nvStart:end});
    r = parser.Results;

    validateattributes(A, {'double'}, {'2d','real','square'}, 'aecs', 'A', 1);

    % ---- Set T if provided ----
    if ~isempty(r.T)
        T = r.T;
    end

    % ---- Set CSOptions ----
    csopts = r.CSOptions;

    % ---- Set WOptions and PGSolverOptions if provided ----
    if ~isempty(r.WOptions)
        csopts.WOptions = r.WOptions;
    end
    if ~isempty(r.SolverOptions)
        csopts.SolverOptions = r.SolverOptions;
    end

    % ---- Override properties ----
    % WOptions
    if ~isempty(r.Method);     csopts.Method = r.Method; end
    if ~isempty(r.Steps);      csopts.Steps = r.Steps; end
    if ~isempty(r.UseScaling); csopts.UseScaling = logical(r.UseScaling); end
    if ~isempty(r.EigTol);     csopts.EigTol = r.EigTol; end

    % SolverOptions
    if ~isempty(r.StepSize);    csopts.StepSize = r.StepSize; end
    if ~isempty(r.StepSizeInf); csopts.StepSizeInf = r.StepSizeInf; end
    if ~isempty(r.MaxIter);     csopts.MaxIter = r.MaxIter; end
    if ~isempty(r.Tol);         csopts.Tol = r.Tol; end
    if ~isempty(r.Rho);         csopts.Rho = r.Rho; end
    if ~isempty(r.Sigma);       csopts.Sigma = r.Sigma; end
    if ~isempty(r.Verbose);     csopts.Verbose = logical(r.Verbose); end
    if ~isempty(r.StoreTrace);  csopts.StoreTrace = logical(r.StoreTrace); end


    % ---- Build problem using WOptions only ----
    prob = CSProblem(A, T, "WOptions", csopts.WOptions, "TargetNodes", r.TargetNodes);

    % ---- Solve ----
    [p, info] = prob.solveAecs(csopts.SolverOptions);

    switch nargout
        case 0
            varargout = {p};
        case 1
            varargout = {p};
        case 2
            varargout = {p, info};
        case 3
            varargout = {p, info, prob.WList};
    end
end
