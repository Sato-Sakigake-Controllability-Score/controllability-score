% +cscore/+gramian/computeGramian.m
function wlist = computeGramian(A, T, wopts)
    % COMPUTEGRAMIAN  Build WList from (A,T,WOptions)
    %
    % wlist = computeGramian(A, T, wopts)
    %

    wopts.validateWOptions_;

    if isinf(T)
        switch wopts.Method
            case "lyap"
                if wopts.UseScaling
                    wlist = gramian.infLyapScale_(A, wopts);
                    return
                else
                    wlist = gramian.infLyapNoscale_(A, wopts);
                    return
                end

            case "integral"
                error("T=inf does not allow WOptions.Method=""%s"".", ...
                      wopts.Method);

            otherwise
                error("Unknown Method ""%s"".", wopts.Method);
        end
    else
        switch wopts.Method
            case "lyap"
                if wopts.UseScaling
                    wlist = gramian.finLyapScale_(A, T, wopts);
                    return
                else
                    wlist = gramian.finLyapNoscale_(A, T, wopts);
                    return
                end

            case "integral"
                if wopts.UseScaling
                    wlist = gramian.finIntegralScale_(A, T, wopts);
                    return
                else
                    wlist = gramian.finIntegralNoscale_(A, T, wopts);
                    return
                end

            otherwise
                error("Unknown Method ""%s"".", wopts.Method);
        end
    end
end
