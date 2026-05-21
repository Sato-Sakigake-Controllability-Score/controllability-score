function varargout = solveVcs(obj, varargin)
    % SOLVEVCS Solve the VCS problem for this CSProblem instance.
    %
    %   p = prob.solveVcs()
    %       Solves the VCS problem using default solver options.
    %
    %   p = prob.solveVcs(solopts)
    %       Solves the VCS problem using the specified PGSolverOptions object.
    %
    %   [p,info] = prob.solveVcs(...)
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
        error("CSProblem:solveVcs:InvalidNargout", ...
              "solveVcs supports %s outputs.", mat2str(allowed));
    end

    narginchk(1, 2);
    if nargin < 2 || isempty(varargin{1})
        solopts = PGSolverOptions;
    else
        solopts = varargin{1};
    end
    if ~isa(solopts, 'PGSolverOptions') || ~isscalar(solopts)
        error('CSProblem:solveVcs:InvalidOptions', ...
              'options must be a scalar PGSolverOptions object.');
    end

    solver = ProjectedGradientSolver(solopts);
    [p, info] = solver.solve(@(x)obj.fVcs(x), obj.InitialGuess);

    if isprop(info, "ProblemInfo")
        info.ProblemInfo = struct("Objective", "VCS", "Dimension", obj.Dimension);
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
