% +cscore/+gramian/computeGramian.m
function wlist = computeGramian(A, T, varargin)
    % COMPUTEGRAMIAN Build WList from (A,T,WOptions[,targetNodes])
    %
    % wlist = computeGramian(A, T, wopts)
    % wlist = computeGramian(A, T, wopts, targetNodes)
    %

    narginchk(3, 4);

    wopts = varargin{1};
    targetNodes = [];
    if nargin >= 4
        targetNodes = varargin{2};
    end

    wopts.validateWOptions_;

    if ~isempty(targetNodes)
        if isinf(T)
            switch wopts.Method
                case "lyap"
                    wlist = gramian.infTargetLyap_(A, targetNodes, wopts);
                case "integral"
                    error("T=inf does not allow WOptions.Method=""%s"".", ...
                          wopts.Method);
                otherwise
                    error("Unknown Method ""%s"".", wopts.Method);
            end
            return
        end

        switch wopts.Method
            case "lyap"
                wlist = gramian.finTargetLyap_(A, T, targetNodes, wopts);
            case "integral"
                wlist = gramian.finTargetIntegral_(A, T, targetNodes, wopts);
            otherwise
                error("Unknown Method ""%s"".", wopts.Method);
        end
        return
    end

    if isinf(T)
        switch wopts.Method
            case "lyap"
                if wopts.UseScaling
                    wlist = gramian.infLyapScale_(A, wopts);
                else
                    wlist = gramian.infLyapNoscale_(A, wopts);
                end

            case "integral"
                error("T=inf does not allow WOptions.Method=""%s"".", ...
                      wopts.Method);

            otherwise
                error("Unknown Method ""%s"".", wopts.Method);
        end
        return
    end

    switch wopts.Method
        case "lyap"
            if wopts.UseScaling
                wlist = gramian.finLyapScale_(A, T, wopts);
            else
                wlist = gramian.finLyapNoscale_(A, T, wopts);
            end

        case "integral"
            if wopts.UseScaling
                wlist = gramian.finIntegralScale_(A, T, wopts);
            else
                wlist = gramian.finIntegralNoscale_(A, T, wopts);
            end

        otherwise
            error("Unknown Method ""%s"".", wopts.Method);
    end
end
