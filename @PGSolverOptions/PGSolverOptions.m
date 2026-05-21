classdef PGSolverOptions
    % PGSOLVEROPTIONS Options for the projected gradient solver.
    %   solopts = PGSOLVEROPTIONS() creates an object with default settings.
    %
    %   solopts = PGSOLVEROPTIONS(Name,Value,...) specifies options using
    %   one or more name-value arguments. Name is a character vector or
    %   string scalar and Value is the corresponding value. Name-value
    %   arguments can appear in any order.
    %
    %   PGSolverOptions properties:
    %       StepSize    - Initial step size for the projected gradient step
    %       StepSizeInf - Minimum step size for the Armijo line search
    %       MaxIter     - Maximum number of iterations
    %       Tol         - Termination tolerance on the step size
    %       Rho         - Backtracking factor in Armijo line search
    %       Sigma       - Sufficient decrease parameter in Armijo condition
    %       Verbose     - Display iteration diagnostics
    %       StoreTrace  - Store iteration history
    %
    %   Armijo line search:
    %       The solver uses a backtracking Armijo rule of the form
    %           q_k := (projection of ( p_k - alpha * grad f(p_k) ) onto simplex)
    %           f(q_k) <= f(p_k) + Sigma * <grad f(p_k), q_k - p_k>
    %       where the step size alpha is initialized from StepSize and
    %       successively reduced by the factor Rho during backtracking. If no
    %       acceptable step size is found before the trial step size falls
    %       below StepSizeInf, the algorithm terminates with a corresponding
    %       exit flag.
    %
    %   Stopping criterion:
    %       The solver terminates when any of the following conditions is met:
    %           1. Step size tolerance
    %               The norm of the update satisfies
    %                   ||p_{k+1} - p_k|| <= Tol
    %               indicating that successive iterates are sufficiently close.
    %           2. Minimum step size in Armijo line search
    %               During backtracking, the trial step size becomes smaller
    %               than StepSizeInf.
    %               In this case, no further progress can be made and the
    %               solver stops.
    %           3. Maximum number of iterations
    %               The number of iterations exceeds MaxIter.
    %
    %   Example:
    %       opts = PGSolverOptions('StepSize',0.1,'StepSizeInf',1e-12,'Rho',0.5,...
    %                               'Sigma',1e-4,'MaxIter',1000);
    %

    properties
        % StepSize Initial step size for the projected gradient step.
        %   StepSize is a positive scalar. The solver uses StepSize as
        %   the initial trial step length in the Armijo backtracking
        %   line search. The default is 0.1.
        StepSize (1, 1) double {mustBePositive} = 0.1

        % StepSizeInf Minimum step size for the Armijo line search.
        %   If the trial step size falls below StepSizeInf, the solver
        %   stops and reports that the step size is too small to make
        %   further progress. The default is 1e-12
        StepSizeInf (1, 1) double {mustBePositive} = 1e-12

        % MaxIter Maximum number of iterations.
        %   MaxIter is a positive integer. The default is 1000.
        MaxIter  (1, 1) double {mustBeInteger, mustBePositive} = 1000

        % Tol Termination tolerance on the step size.
        %   The solver terminates when the norm of the step between
        %   successive iterates becomes sufficiently small. The criterion
        %   is
        %       ||p_{k+1} - p_k|| <= Tol.
        %   Tol is a positive scalar. The default is 1e-8.
        Tol      (1, 1) double {mustBePositive} = 1e-8

        % Rho Backtracking factor in Armijo line search.
        %   Rho is a scalar in the open interval (0,1) that controls how
        %   aggressively the step size is reduced during backtracking.
        %   Smaller values lead to faster reduction of the step size.
        %   The default is 0.5.
        Rho      (1, 1) double {csutil.mustBeOpen01} = 0.5

        % Sigma Sufficient decrease parameter in Armijo condition.
        %   Sigma is a scalar in the open interval (0,1) that controls
        %   the required decrease in the objective value. The default is 1e-4.
        Sigma    (1, 1) double {csutil.mustBeOpen01} = 1e-4

        % Verbose Display iteration diagnostics.
        %   Verbose is a logical flag. When true, the solver prints basic
        %   progress information to the command window. The default is false.
        Verbose  (1, 1) logical = false

        % StoreTrace Store iteration history.
        %   StoreTrace is a logical flag. When true, the solver records
        %   iteration history that can be returned in the result object.
        %   The default is false.
        StoreTrace (1, 1) logical = false
    end

    methods

        function obj = PGSolverOptions(varargin)
            % PGSOLVEROPTIONS Construct a PGSolverOptions object.
            %   See the class help for a full description.

            % Parse name-value arguments
            parser = inputParser;
            parser.FunctionName = 'PGSolverOptions';

            addParameter(parser, 'StepSize', obj.StepSize, ...
                         @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0));
            addParameter(parser, 'StepSizeInf', obj.StepSizeInf, ...
                         @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0));
            addParameter(parser, 'MaxIter', obj.MaxIter, ...
                         @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0) && (mod(v, 1) == 0));
            addParameter(parser, 'Tol', obj.Tol, ...
                         @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0));
            addParameter(parser, 'Rho', obj.Rho, ...
                         @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (0 < v) && (v < 1));
            addParameter(parser, 'Sigma', obj.Sigma, ...
                         @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (0 < v) && (v < 1));
            addParameter(parser, 'Verbose', obj.Verbose, ...
                         @(v) (islogical(v) && isscalar(v)) || (isnumeric(v) && isscalar(v) && any(v == [0 1])));
            addParameter(parser, 'StoreTrace', obj.StoreTrace, ...
                         @(v) (islogical(v) && isscalar(v)) || (isnumeric(v) && isscalar(v) && any(v == [0 1])));

            parse(parser, varargin{:});
            r = parser.Results;

            obj.StepSize    = r.StepSize;
            obj.StepSizeInf = r.StepSizeInf;
            obj.MaxIter     = r.MaxIter;
            obj.Tol         = r.Tol;
            obj.Rho         = r.Rho;
            obj.Sigma       = r.Sigma;
            obj.Verbose     = logical(r.Verbose);
            obj.StoreTrace  = logical(r.StoreTrace);
        end

    end
end
