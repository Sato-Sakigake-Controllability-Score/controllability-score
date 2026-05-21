classdef ProjectedGradientSolver
    % PROJECTEDGRADIENTSOLVER Projected gradient method with Armijo backtracking.
    %
    %   This solver minimizes a differentiable objective over the standard
    %   simplex.
    %
    %   Required function signature:
    %       [f,g] = fun(p)
    %   where:
    %       f is a scalar objective value (Inf allowed),
    %       g is a gradient vector (NaN entries allowed to signal invalidity).
    %
    %   Exit flags:
    %       1 Converged: step norm <= Tol
    %       0 Maximum number of iterations reached
    %      -1 Armijo backtracking failed (alpha < StepSizeInf)
    %      -2 Initial point evaluation failed
    %      -3 Accepted point evaluation failed during iteration
    %
    %   Algorithm (projection arc):
    %     - Trial point:   pTilde = csutil.projectOntoSimplex(p - alpha*g)
    %     - Armijo test:   f(pTilde) <= f(p) + Sigma * g'*(pTilde - p)
    %     - Backtracking:  alpha <- Rho*alpha
    %     - See Sato and Terasaki (2024)
    %
    %   Stopping:
    %     - StepNorm = norm(pNew - p,2) <= Tol
    %     - Backtracking fails if alpha < StepSizeInf
    %
    %   Usage:
    %     solver = ProjectedGradientSolver(opts);
    %     [p, info] = solver.solve(@(x)prob.fAecs(x), p0);

    properties (SetAccess = private)
        StepSize      (1, 1) double = 0.1
        MaxIter       (1, 1) double = 1000
        Tol           (1, 1) double = 1.0e-8

        % Armijo parameters:
        %   Rho   : backtracking shrinkage factor in (0,1)
        %   Sigma : sufficient decrease constant in (0,1)
        Rho           (1, 1) double = 0.5
        Sigma         (1, 1) double = 1.0e-4

        % Minimum acceptable trial step size; stop if alpha < StepSizeInf.
        StepSizeInf   (1, 1) double = 1.0e-12

        Verbose       (1, 1) logical = false
        StoreTrace    (1, 1) logical = false
    end

    methods

        function obj = ProjectedGradientSolver(options)
            % options: PGSolverOptions or struct with the same field names.
            if nargin == 0 || isempty(options)
                obj = obj.validateOptions_();
                return
            end

            if isstruct(options)
                s = options;
            else
                s = struct();
                props = properties(options);
                for k = 1:numel(props)
                    s.(props{k}) = options.(props{k});
                end
            end

            if isfield(s, 'StepSize')    && ~isempty(s.StepSize)
                obj.StepSize = s.StepSize;
            end
            if isfield(s, 'MaxIter')     && ~isempty(s.MaxIter)
                obj.MaxIter = s.MaxIter;
            end
            if isfield(s, 'Tol')         && ~isempty(s.Tol)
                obj.Tol = s.Tol;
            end
            if isfield(s, 'Rho')         && ~isempty(s.Rho)
                obj.Rho = s.Rho;
            end
            if isfield(s, 'Sigma')       && ~isempty(s.Sigma)
                obj.Sigma = s.Sigma;
            end
            if isfield(s, 'StepSizeInf') && ~isempty(s.StepSizeInf)
                obj.StepSizeInf = s.StepSizeInf;
            end
            if isfield(s, 'Verbose')     && ~isempty(s.Verbose)
                obj.Verbose = logical(s.Verbose);
            end
            if isfield(s, 'StoreTrace')  && ~isempty(s.StoreTrace)
                obj.StoreTrace = logical(s.StoreTrace);
            end

            obj = obj.validateOptions_();
        end

        function [p, info] = solve(obj, fun, p0)
            % SOLVE Run projected gradient method with Armijo backtracking.

            validateattributes(p0, {'double'}, {'vector', 'real', 'finite'}, 'solve', 'p0');

            % Initial projection
            p = csutil.projectOntoSimplex(p0(:));
            p = p(:);
            funcCount = 0;

            % Evaluate at initial point
            [fp, gp, funcCount] = obj.evalFG_(fun, p, funcCount);
            gp = gp(:);
            if numel(gp) ~= numel(p)
                [p, info] = obj.makeResult_(p, fp, gp, 0, funcCount, false, ...
                                            -2, 'Initial point gradient has incompatible size.', NaN, []);
                return
            end
            if ~isfinite(fp) || any(isnan(gp))
                [p, info] = obj.makeResult_(p, fp, gp, 0, funcCount, false, ...
                                            -2, 'Initial point evaluation failed.', NaN, []);
                return
            end

            if obj.StoreTrace
                trace = obj.initTrace_();
            else
                trace = [];
            end

            converged = false;
            exitFlag = 0;
            exitMessage = '';
            stepNorm = Inf;

            alpha0 = obj.StepSize; % initial trial step size each iteration

            for iter = 1:obj.MaxIter
                alpha = alpha0;
                accepted = false;

                while alpha >= obj.StepSizeInf
                    % Projection arc trial point
                    pTilde = csutil.projectOntoSimplex(p - alpha * gp);
                    pTilde = pTilde(:);

                    [fTilde, funcCount] = obj.evalF_(fun, pTilde, funcCount);

                    % Reject invalid trial point
                    if ~isfinite(fTilde)
                        alpha = obj.Rho * alpha;
                        continue
                    end

                    % Armijo condition
                    rhs = fp + obj.Sigma * (gp.' * (pTilde - p));

                    if fTilde <= rhs
                        accepted = true;
                        break
                    end

                    alpha = obj.Rho * alpha;
                end

                if ~accepted
                    exitFlag = -1;
                    exitMessage = 'Armijo backtracking failed (alpha < StepSizeInf).';
                    break
                end

                % Accept
                pPrev = p;
                p = pTilde;
                [fp, gp, funcCount] = obj.evalFG_(fun, p, funcCount);
                gp = gp(:);

                if numel(gp) ~= numel(p)
                    exitFlag = -3;
                    exitMessage = 'Accepted point gradient has incompatible size.';
                    break
                end
                if ~isfinite(fp) || any(isnan(gp))
                    exitFlag = -3;
                    exitMessage = 'Accepted point evaluation failed.';
                    break
                end

                stepNorm = norm(p - pPrev, 2);

                if obj.StoreTrace
                    trace = obj.appendTrace_(trace, iter, fp, stepNorm, alpha, funcCount);
                end

                if obj.Verbose
                    fprintf('Iter %4d  f=% .6e  step=% .3e  alpha=% .3e\n', ...
                            iter, fp, stepNorm, alpha);
                end

                % Stop by update size
                if stepNorm <= obj.Tol
                    converged = true;
                    exitFlag = 1;
                    exitMessage = 'Step norm below Tol.';
                    break
                end
            end

            if iter >= obj.MaxIter && ~converged && exitFlag == 0
                exitFlag = 0;
                exitMessage = 'Maximum iterations reached.';
            end

            [p, info] = obj.makeResult_(p, fp, gp, iter, funcCount, converged, ...
                                        exitFlag, exitMessage, stepNorm, trace);
        end

    end

    methods (Access = private)

        function obj = validateOptions_(obj)
            validateattributes(obj.StepSize, {'double'}, {'scalar', 'real', 'finite', 'positive'}, ...
                               'ProjectedGradientSolver', 'StepSize');
            validateattributes(obj.MaxIter, {'double'}, {'scalar', 'real', 'finite', 'integer', 'positive'}, ...
                               'ProjectedGradientSolver', 'MaxIter');
            validateattributes(obj.Tol, {'double'}, {'scalar', 'real', 'finite', 'nonnegative'}, ...
                               'ProjectedGradientSolver', 'Tol');
            validateattributes(obj.Rho, {'double'}, {'scalar', 'real', 'finite', '>', 0, '<', 1}, ...
                               'ProjectedGradientSolver', 'Rho');
            validateattributes(obj.Sigma, {'double'}, {'scalar', 'real', 'finite', '>', 0, '<', 1}, ...
                               'ProjectedGradientSolver', 'Sigma');
            validateattributes(obj.StepSizeInf, {'double'}, {'scalar', 'real', 'finite', 'positive'}, ...
                               'ProjectedGradientSolver', 'StepSizeInf');
        end

        function [f, funcCount] = evalF_(~, fun, p, funcCount)
            try
                f = fun(p);
            catch ME
                error('ProjectedGradientSolver:InvalidObjectiveHandle', ...
                      'fun must support one output: f = fun(p). (%s)', ME.message);
            end
            funcCount = funcCount + 1;
        end

        function [f, g, funcCount] = evalFG_(~, fun, p, funcCount)
            try
                [f, g] = fun(p);
            catch ME
                error('ProjectedGradientSolver:InvalidObjectiveHandle', ...
                      'fun must support two outputs: [f,g] = fun(p). (%s)', ME.message);
            end
            funcCount = funcCount + 1;
        end

        function trace = initTrace_(~)
            trace = struct();
            trace.Iteration  = zeros(0, 1);
            trace.Fval       = zeros(0, 1);
            trace.StepNorm   = zeros(0, 1);
            trace.Alpha      = zeros(0, 1);
            trace.FuncCount  = zeros(0, 1);
        end

        function trace = appendTrace_(~, trace, iter, fval, stepNorm, alpha, funcCount)
            trace.Iteration(end + 1, 1) = iter;
            trace.Fval(end + 1, 1)      = fval;
            trace.StepNorm(end + 1, 1)  = stepNorm;
            trace.Alpha(end + 1, 1)     = alpha;
            trace.FuncCount(end + 1, 1) = funcCount;
        end

        function [p, info] = makeResult_(obj, p, fval, grad, iters, funcCount, converged, ...
                                         exitFlag, exitMessage, stepNorm, trace)
            % Construct CSResult (assumes CSResult class exists).
            info = CSResult();
            info.ObjectiveValue = fval;
            info.Gradient       = grad;
            info.Iterations     = iters;
            info.FuncCount      = funcCount;
            info.Converged      = converged;
            info.ExitFlag       = exitFlag;
            info.ExitMessage    = exitMessage;
            info.Algorithm      = "ProjectedGradient (Armijo, projection arc)";
            info.SolverOptions  = obj;
            info.StepNorm       = stepNorm;
            info.Trace          = trace;

            if isprop(info, 'GradNorm')
                if isempty(grad) || any(isnan(grad))
                    info.GradNorm = NaN;
                else
                    info.GradNorm = norm(grad(:), 2);
                end
            end
        end

    end
end
