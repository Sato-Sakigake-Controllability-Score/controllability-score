classdef CSOptions
%CSOPTIONS Options for controllability scoring problems.
%   csopts = CSOptions() creates an object with default settings.
%   The defaults include WOptions and PGSolverOptions.
%
%   csopts = CSOptions(Name,Value,...) specifies options using one or more
%   name-value arguments. Name is a character vector or string scalar and
%   Value is the corresponding value. Name-value arguments can appear in
%   any order.
%
%   CSOptions properties:
%       WOptions      - Options for computing the Gramians W_i
%       SolverOptions - Options for the projected gradient solver
%

    %% Propeties
    properties
        %WOptions Options for computing the matrices W_i.
        %   WOptions is a WOptions object that controls how the list of
        %   matrices W_i and the optional scaling/preprocessing are
        %   constructed.
        WOptions (1,1) WOptions = WOptions()

        %SolverOptions Options for the projected gradient solver.
        %   SolverOptions is a PGSolverOptions object that controls the
        %   behaviour of the projected gradient solver used to compute
        %   the optimal weight vector p.
        SolverOptions (1,1) PGSolverOptions = PGSolverOptions()
    end

    %% Properties (Dependent)
    properties (Dependent)
        % --- WOptions properties ---
        Method
        Steps
        UseScaling
        EigTol

        % --- SolverOptions properties ---
        Tol
        MaxIter
        Rho
        Sigma
        StepSize
        StepSizeInf
        Verbose
        StoreTrace
    end

    %% Constructor
    methods
        function obj = CSOptions(varargin)
        %CSOPTIONS Construct a CSOptions object.
        %   See the class help for a full description.

            % ---- Parse Name-Value pairs ----
            parser = inputParser;
            parser.FunctionName = 'CSOptions';

            % Core objects
            addParameter(parser,'WOptions',obj.WOptions, ...
                @(v) isa(v,'WOptions') && isscalar(v));
            addParameter(parser,'SolverOptions',obj.SolverOptions, ...
                @(v) isa(v,'PGSolverOptions') && isscalar(v));
            
            % WOptions properties
            addParameter(parser,'Method',[], ...
                @(v) (ischar(v) && isrow(v)) || (isstring(v) && isscalar(v)));
            addParameter(parser,'Steps',[], ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v>=0) && (mod(v,1)==0));
            addParameter(parser,'UseScaling',[], ...
                @(v) (islogical(v) && isscalar(v)) || (isnumeric(v) && isscalar(v) && isfinite(v) && any(v==[0 1])));
            addParameter(parser,'EigTol',[], ...
                @(v) (isa(v,'double') && isscalar(v) && isreal(v) && isfinite(v) && (v>=0)));
       
            % SolverOptions propeties
            addParameter(parser,'StepSize',[], ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0));
            addParameter(parser,'StepSizeInf',[], ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0));
            addParameter(parser,'MaxIter',[], ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0) && (mod(v,1)==0));
            addParameter(parser,'Tol',[], ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v > 0));
            addParameter(parser,'Rho',[], ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (0 < v) && (v < 1));
            addParameter(parser,'Sigma',[], ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (0 < v) && (v < 1));
            addParameter(parser,'Verbose',[], ...
                @(v) (islogical(v) && isscalar(v)) || (isnumeric(v) && isscalar(v) && any(v==[0 1])));
            addParameter(parser,'StoreTrace',[], ...
                @(v) (islogical(v) && isscalar(v)) || (isnumeric(v) && isscalar(v) && any(v==[0 1])));
            
            parse(parser, varargin{:});
            r = parser.Results;
            
            % ---- Assign whole objects first ----
            obj.WOptions = r.WOptions;
            obj.SolverOptions = r.SolverOptions;

            % ---- Override propetes ----
            % WOptions
            if ~isempty(r.Method);     obj.Method = r.Method; end
            if ~isempty(r.Steps);      obj.Steps = r.Steps; end
            if ~isempty(r.UseScaling); obj.UseScaling = logical(r.UseScaling); end
            if ~isempty(r.EigTol);     obj.EigTol = r.EigTol; end

            % SolverOptions
            if ~isempty(r.StepSize);    obj.StepSize = r.StepSize; end
            if ~isempty(r.StepSizeInf); obj.StepSizeInf = r.StepSizeInf; end
            if ~isempty(r.MaxIter);     obj.MaxIter = r.MaxIter; end
            if ~isempty(r.Tol);         obj.Tol = r.Tol; end
            if ~isempty(r.Rho);         obj.Rho = r.Rho; end
            if ~isempty(r.Sigma);       obj.Sigma = r.Sigma; end
            if ~isempty(r.Verbose);     obj.Verbose = logical(r.Verbose); end
            if ~isempty(r.StoreTrace);  obj.StoreTrace = logical(r.StoreTrace); end
        end
    end

    %% Getter and setter
    methods
        % ---- WOptions properties ----
        function v = get.Method(obj)
            v = obj.WOptions.Method;
        end
        function obj = set.Method(obj,v)
            w = obj.WOptions;
            w.Method = v;
            obj.WOptions = w;
        end
    
        function v = get.Steps(obj)
            v = obj.WOptions.Steps;
        end
        function obj = set.Steps(obj,v)
            w = obj.WOptions;
            w.Steps = v;
            obj.WOptions = w;
        end
    
        function v = get.UseScaling(obj)
            v = obj.WOptions.UseScaling;
        end
        function obj = set.UseScaling(obj,v)
            w = obj.WOptions;
            w.UseScaling = logical(v);
            obj.WOptions = w;
        end

        function v = get.EigTol(obj)
            v = obj.WOptions.EigTol;
        end
        function obj = set.EigTol(obj,v)
            w = obj.WOptions;
            w.EigTol = v;
            obj.WOptions = w;
        end

        % ---- SolverOptions properties ----
        function v = get.Tol(obj)
            v = obj.SolverOptions.Tol;
        end
        function obj = set.Tol(obj,v)
            s = obj.SolverOptions;
            s.Tol = v;
            obj.SolverOptions = s;
        end
    
        function v = get.MaxIter(obj)
            v = obj.SolverOptions.MaxIter;
        end
        function obj = set.MaxIter(obj,v)
            s = obj.SolverOptions;
            s.MaxIter = v;
            obj.SolverOptions = s;
        end
    
        function v = get.Rho(obj)
            v = obj.SolverOptions.Rho;
        end
        function obj = set.Rho(obj,v)
            s = obj.SolverOptions;
            s.Rho = v;
            obj.SolverOptions = s;
        end


        function v = get.Sigma(obj)
            v = obj.SolverOptions.Sigma;
        end
        function obj = set.Sigma(obj,v)
            s = obj.SolverOptions;
            s.Sigma = v;
            obj.SolverOptions = s;
        end
    
        function v = get.StepSize(obj)
            v = obj.SolverOptions.StepSize;
        end
        function obj = set.StepSize(obj,v)
            s = obj.SolverOptions;
            s.StepSize = v;
            obj.SolverOptions = s;
        end
    
        function v = get.StepSizeInf(obj)
            v = obj.SolverOptions.StepSizeInf;
        end
        function obj = set.StepSizeInf(obj,v)
            s = obj.SolverOptions;
            s.StepSizeInf = v;
            obj.SolverOptions = s;
        end

        function v = get.Verbose(obj)
            v = obj.SolverOptions.Verbose;
        end
        function obj = set.Verbose(obj,v)
            s = obj.SolverOptions;
            s.Verbose = logical(v);
            obj.SolverOptions = s;
        end
    
        function v = get.StoreTrace(obj)
            v = obj.SolverOptions.StoreTrace;
        end
        function obj = set.StoreTrace(obj,v)
            s = obj.SolverOptions;
            s.StoreTrace = logical(v);
            obj.SolverOptions = s;
        end
    end
end
