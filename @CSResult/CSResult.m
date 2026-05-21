classdef CSResult
    % CSRESULT Result of a controllability scoring computation.
    %   info = CSRESULT() creates an empty result object with default values.
    %
    %   info = CSRESULT(Name,Value,...) creates a result object and sets
    %   one or more properties using name-value arguments. Name is a
    %   character vector or string scalar and Value is the corresponding
    %   value. Name-value arguments can appear in any order.
    %
    %   CSResult properties (scalar, unless noted otherwise):
    %
    %       ObjectiveValue - Final objective value f(p)
    %       Gradient       - Gradient at the final iterate p (vector)
    %       GradNorm       - Norm of the final gradient
    %       StepNorm       - Norm of the last update step
    %       Iterations     - Number of iterations performed
    %       FuncCount      - Number of objective evaluations
    %       Converged      - Logical flag indicating successful convergence
    %       ExitFlag       - Numeric code describing the termination reason
    %       ExitMessage    - Text message describing the termination reason
    %       Algorithm      - Name of the algorithm used
    %       SolverOptions  - Options used by the solver (PGSolverOptions)
    %       ProblemInfo    - Struct with problem-specific information
    %       Trace          - Optional iteration history (struct array or [])
    %
    %   Notes:
    %       * StepNorm is typically the norm of the last accepted update,
    %         e.g., norm(p_{k+1} - p_k), and is used in the stopping test.
    %       * GradNorm is provided for diagnostic purposes and is not
    %         necessarily used directly in the convergence criterion.
    %
    %   Example:
    %       info = CSResult('ObjectiveValue',fval, ...
    %                       'GradNorm',gradnorm, ...
    %                       'StepNorm',stepnorm, ...
    %                       'Iterations',k, ...
    %                       'Converged',true, ...
    %                       'ExitFlag',1, ...
    %                       'ExitMessage',"Step size below tolerance");
    %
    %   Typically, CSResult objects are created and returned by solver
    %   functions such as solveVcs, solveAecs, or ProjectedGradientSolver.

    properties
        % ObjectiveValue Final objective value f(p) at the last iterate.
        ObjectiveValue (1, 1) double = NaN

        % Gradient Gradient at the final iterate p.
        %   Gradient is usually a column vector of the same length as p.
        Gradient double = []

        % GradNorm Euclidean norm of the final gradient.
        %   Provided for diagnostic purposes.
        GradNorm (1, 1) double = NaN

        % StepNorm Euclidean norm of the last update step.
        %   Typically StepNorm = norm(p_{k+1} - p_k) at termination and
        %   is used in the stopping criterion.
        StepNorm (1, 1) double = NaN

        % Iterations Number of iterations performed by the solver.
        Iterations (1, 1) double {mustBeNonnegative} = 0

        % FuncCount Number of objective function evaluations.
        FuncCount (1, 1) double {mustBeNonnegative} = 0

        % Converged Logical flag indicating successful convergence.
        Converged (1, 1) logical = false

        % ExitFlag Numeric code describing the termination reason.
        %   A positive value typically indicates successful termination.
        %   Zero or negative values indicate various failure modes.
        ExitFlag (1, 1) double = 0

        % ExitMessage Text message describing the termination reason.
        ExitMessage (1, 1) string = ""

        % Algorithm Name of the algorithm used by the solver.
        %   For example: "Projected gradient with Armijo line search".
        Algorithm (1, 1) string = ""

        % SolverOptions Options used by the solver.
        %   This is typically a PGSolverOptions object.
        SolverOptions = []

        % ProblemInfo Struct with problem-specific information.
        %   Example fields:
        %       Dimension         - Dimension of p
        %       StableDimension   - Dimension of stable subspaces of A
        %       ZeroDimension     - Dimension of zero eigespaces of A
        %       UnstableDimension - Dimension of unstable subspaces of A
        %       T                 - Time horizon
        %       UseScaling        - Logical flag indicating applying scaling
        ProblemInfo struct = struct()

        % Trace Optional iteration history.
        %   When StoreTrace is true in SolverOptions, Trace may be a
        %   struct array with fields such as:
        %       Iter
        %       Objective
        %       GradNorm
        %       StepNorm
        %       StepSize
        %   Otherwise, Trace is typically [].
        Trace = []
    end

    methods

        function obj = CSResult(varargin)
            % CSRESULT Construct a CSResult object.
            %   info = CSRESULT() creates an object with default values.
            %
            %   info = CSRESULT(Name,Value,...) sets one or more properties
            %   using name-value arguments.

            if nargin == 0
                return
            end

            % Name-value parsing
            parser = inputParser;
            parser.FunctionName = 'CSResult';

            addParameter(parser, 'ObjectiveValue', obj.ObjectiveValue, ...
                         @(v) validateattributes(v, {'double'}, {'scalar', 'real'}, ...
                                                 parser.FunctionName, 'ObjectiveValue'));

            addParameter(parser, 'Gradient', obj.Gradient, ...
                         @(v) validateattributes(v, {'double'}, {'2d', 'real'}, ...
                                                 parser.FunctionName, 'Gradient'));

            addParameter(parser, 'GradNorm', obj.GradNorm, ...
                         @(v) validateattributes(v, {'double'}, {'scalar', 'real', 'nonnegative'}, ...
                                                 parser.FunctionName, 'GradNorm'));

            addParameter(parser, 'StepNorm', obj.StepNorm, ...
                         @(v) validateattributes(v, {'double'}, {'scalar', 'real', 'nonnegative'}, ...
                                                 parser.FunctionName, 'StepNorm'));

            addParameter(parser, 'Iterations', obj.Iterations, ...
                         @(v) validateattributes(v, {'double'}, ...
                                                 {'scalar', 'real', 'nonnegative'}, ...
                                                 parser.FunctionName, 'Iterations'));

            addParameter(parser, 'FuncCount', obj.FuncCount, ...
                         @(v) validateattributes(v, {'double'}, ...
                                                 {'scalar', 'real', 'nonnegative'}, ...
                                                 parser.FunctionName, 'FuncCount'));

            addParameter(parser, 'Converged', obj.Converged, ...
                         @(v) islogical(v) && isscalar(v));

            addParameter(parser, 'ExitFlag', obj.ExitFlag, ...
                         @(v) validateattributes(v, {'double'}, {'scalar', 'real'}, ...
                                                 parser.FunctionName, 'ExitFlag'));

            addParameter(parser, 'ExitMessage', char(obj.ExitMessage), ...
                         @(v) (ischar(v) || isstring(v)));

            addParameter(parser, 'Algorithm', char(obj.Algorithm), ...
                         @(v) (ischar(v) || isstring(v)));

            addParameter(parser, 'SolverOptions', obj.SolverOptions, ...
                         @(v) true);  % allow empty or any object; detailed check optional

            addParameter(parser, 'ProblemInfo', obj.ProblemInfo, ...
                         @(v) isstruct(v));

            addParameter(parser, 'Trace', obj.Trace, ...
                         @(v) true);  % allow [] or struct array

            parse(parser, varargin{:});
            r = parser.Results;

            obj.ObjectiveValue = r.ObjectiveValue;
            obj.Gradient       = r.Gradient;
            obj.GradNorm       = r.GradNorm;
            obj.StepNorm       = r.StepNorm;
            obj.Iterations     = r.Iterations;
            obj.FuncCount      = r.FuncCount;
            obj.Converged      = r.Converged;
            obj.ExitFlag       = r.ExitFlag;
            obj.ExitMessage    = string(r.ExitMessage);
            obj.Algorithm      = string(r.Algorithm);
            obj.SolverOptions  = r.SolverOptions;
            obj.ProblemInfo    = r.ProblemInfo;
            obj.Trace          = r.Trace;
        end

    end
end
