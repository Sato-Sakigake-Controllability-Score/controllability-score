classdef WOptions
%WOPTIONS Options for computing the Gramians W_i.
%   wopts = WOptions() creates an object with default settings.
%
%   wopts = WOptions(Name,Value,...) specifies options using one or more
%   name-value arguments. Name is a character vector or string scalar and
%   Value is the corresponding value. Name-value arguments can appear in
%   any order.
%
%   WOptions properties:
%       Method     - "lyap" or "integral" (default: "lyap")
%       Steps      - Nonnegative integer (default: 50)
%                      Effective only when Method="integral".
%                      When Method="lyap", accessing Steps returns 0.
%                      (Always stored internally.)
%                      If Method changes back to "integral", the previously
%                      stored value is used.
%       UseScaling - Logical flag (default: true)
%       EigTol     - Nonnegative scalar (default: 1e-12)
%                      Effective only when UseScaling=true.
%                      When UseScaling=false, accessing EigTol returns 0.
%                      (Always stored internally.)
%                      If UseScaling becomes true again, the previously
%                      stored value is used.
%
%   Notes:
%     - Some properties become inactive depending on other settings
%       (Steps when Method="lyap", EigTol when UseScaling=false).
%     - Options are persistent: values are not discarded when temporarily
%       inactive.
%     - The returned property values reflect the active configuration.

    %% Properties (Dependent)
    properties (Dependent)
        % Method Integration/solution method for W computation.
        % Allowed: "lyap" or "integral"
        Method

        % Steps Number of subintervals for quadrature-based methods.
        Steps

        % UseScaling Logical flag for applying scaling / coordinate transform.
        UseScaling

        % EigTol Tolerance for separation of eigenvalues when applying
        % coordinate transform.
        EigTol
    end

    %% Private properties
    properties (Access = private)
        MethodInternal (1,1) string = "lyap"
        StepsInternal  (1,1) double = 50
        UseScalingInternal (1,1) logical = true
        EigTolInternal (1,1) double = 1e-12
    end

    %% Constructor
    methods
        function obj = WOptions(varargin)
        %WOPTIONS Construct a WOptions object.
        %   See the class help for a full description.

            % ---- Parse Name-Value pairs ----
            parser = inputParser;
            parser.FunctionName = 'WOptions';

            addParameter(parser,'Method',obj.MethodInternal, ...
                @(v) (ischar(v) && isrow(v)) || (isstring(v) && isscalar(v)));
            addParameter(parser,'Steps',obj.StepsInternal, ...
                @(v) isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && (v>=0) && (mod(v,1)==0));
            addParameter(parser,'UseScaling',obj.UseScalingInternal, ...
                @(v) (islogical(v) && isscalar(v)) || (isnumeric(v) && isscalar(v) && isfinite(v) && any(v==[0 1])));
            addParameter(parser,'EigTol',obj.EigTolInternal, ...
                @(v) (isa(v,'double') && isscalar(v) && isreal(v) && isfinite(v) && (v>=0)));
       
            parse(parser, varargin{:});
            r = parser.Results;

            obj.Method = r.Method;
            obj.Steps = r.Steps;
            obj.UseScaling = r.UseScaling;
            obj.EigTol = r.EigTol;
        end
    end

    %% Getter and setter
    methods
        function m = get.Method(obj)
            m = obj.MethodInternal;
        end

        function obj = set.Method(obj, value)
            value = string(value);
            value = validatestring(value, ["lyap","integral"], ...
                'WOptions', 'Method');
            value = string(value);

            obj.MethodInternal = value;
        end

        function s = get.Steps(obj)
            if obj.MethodInternal == "integral"
                s = obj.StepsInternal;
            else
                s = 0;
            end
        end

        function obj = set.Steps(obj, value)
            validateattributes(value, {'numeric'}, {'scalar','real','nonnegative','integer','finite'}, ...
                'WOptions', 'Steps');

            obj.StepsInternal = double(value);
        end

        function u = get.UseScaling(obj)
            u = obj.UseScalingInternal;
        end

        function obj = set.UseScaling(obj, value)
            validateattributes(value, {'logical','numeric'}, {'scalar'}, 'WOptions', 'UseScaling');
            if isnumeric(value) && ~any(value==[0,1])
                error("WOptions:InvalidUseScaling", ...
                    "UseScaling must be logical or numeric scalar 0/1.")
            end

            obj.UseScalingInternal = logical(value);
        end

        function e = get.EigTol(obj)
            if obj.UseScaling
                e = obj.EigTolInternal;
            else
                e = 0;
            end
        end

        function obj = set.EigTol(obj, value)
            validateattributes(value, {'double'}, {'scalar','real','nonnegative','finite'}, ...
                'WOptions', 'EigTol');

            obj.EigTolInternal = value;
        end
    end

    %% Validator
    methods
        function validateWOptions_(obj)
            % ---- Method ----
            m = obj.Method;
            if ~any(m == ["lyap","integral"])
                error("WOptions:InvalidMethod", ...
                    'Method must be one of "lyap","integral".');
            end

            % ---- Steps: active only for integral ----
            if m == "integral"
                s = obj.Steps;
                validateattributes(s, {'numeric'}, {'scalar','real','nonnegative','integer','finite'}, ...
                    'validateWOptions_', 'Steps');
                if s < 1
                    error("WOptions:InvalidStepsForIntegral", ...
                        "Steps must be >= 1 when Method is ""integral"".");
                end
            end

            % ---- UseScaling ----
            u = obj.UseScaling;
            validateattributes(u, {'logical'}, {'scalar'}, 'validateWOptions_', 'UseScaling');

            % ----EigTol: active only for UseScaling=true ----
            if u
                e = obj.EigTol;
                validateattributes(e, {'double'}, {'scalar','real','nonnegative','finite'}, ...
                    'validateWOptions_', 'EigTol');
                if e <= 0
                    error("WOptions:InvalidEigTolWhenScaling", ...
                        "EigTol must be > 0 when UseScaling is true.");
                end
            end
        end
    end
end
