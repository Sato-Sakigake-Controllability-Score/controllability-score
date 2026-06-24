function varargout = solveAecs(obj, varargin)
    % SOLVEVCS Solve the AECS problem for this CSProblem instance.
    %
    %   p = prob.solveAecs()
    %       Solves the AECS problem using default solver options.
    %
    %   p = prob.solveAecs(solopts)
    %       Solves the AECS problem using the specified PGSolverOptions object.
    %
    %   [p,info] = prob.solveAecs(...)
    %       Also returns solver diagnostic information.
    %
    %   Input
    %   -----
    %   solopts : PGSolverOptions (optional)
    %       Options controlling the projected gradient solver.
    %       If omitted, default options are used.
    %
    %   Output
    %   ------
    %   p    : optimal weight vector
    %   info : CSResult object containing solver diagnostics

    allowed = [0 1 2];
    if ~ismember(nargout, allowed)
        error("CSProblem:solveAecs:InvalidNargout", ...
              "solveAecs supports %s outputs.", mat2str(allowed));
    end

    narginchk(1, 2);
    if nargin < 2 || isempty(varargin{1})
        solopts = PGSolverOptions;
    else
        solopts = varargin{1};
    end
    if ~isa(solopts, 'PGSolverOptions') || ~isscalar(solopts)
        error('CSProblem:solveAecs:InvalidOptions', ...
              'options must be a scalar PGSolverOptions object.');
    end

    solver = ProjectedGradientSolver(solopts);
    [p, info] = solver.solve(@(x)obj.fAecs(x), obj.InitialGuess);

    if isprop(info, "ProblemInfo")
        info.ProblemInfo = struct( ...
                                  "Objective", "AECS", ...
                                  "Dimension", obj.Dimension, ...
                                  "TargetNodes", obj.TargetNodes);
    end

    switch nargout
        case 0
            varargout = {p};
        case 1
            varargout = {p};
        case 2
            varargout = {p, info};
    end
end
