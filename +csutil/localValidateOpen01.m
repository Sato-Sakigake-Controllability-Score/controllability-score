function localValidateOpen01(v, funcName, varName)
    validateattributes(v, {'double'}, {'scalar', 'real', 'finite'}, funcName, varName);

    if ~(v > 0 && v < 1)
        id  = sprintf('%s:Invalid%s', funcName, varName);
        msg = sprintf('%s must be in the open interval (0,1).', varName);
        error(id, msg);
    end
end
