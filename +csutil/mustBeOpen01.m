function mustBeOpen01(x)
    if ~(isscalar(x) && isreal(x) && isfinite(x) && x > 0 && x < 1)
        eid = 'PGSolverOptions:ValueNotInOpen01';
        error(eid, 'Value must be a real finite scalar in the open interval (0,1).');
    end
end