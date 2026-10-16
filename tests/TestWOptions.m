classdef TestWOptions < matlab.unittest.TestCase
    methods (Test)

        function defaultMethodIsDirect(testCase)
            wopts = WOptions();

            testCase.verifyEqual(wopts.Method, "direct");
            testCase.verifyEqual(wopts.Steps, 0);
        end

        function directMethodDoesNotWarn(testCase)
            testCase.verifyWarningFree(@() WOptions('Method', "direct"));
        end

        function deprecatedLyapConstructorAlias(testCase)
            testCase.verifyWarning(@() testCase.verifyDeprecatedConstructorResult(), ...
                                   "WOptions:DeprecatedLyapMethod");
        end

        function deprecatedLyapSetterAlias(testCase)
            testCase.verifyWarning(@() testCase.verifyDeprecatedSetterResult(), ...
                                   "WOptions:DeprecatedLyapMethod");
        end

        function integralMethodKeepsStepsActive(testCase)
            wopts = WOptions('Method', "integral", 'Steps', 12);

            testCase.verifyEqual(wopts.Method, "integral");
            testCase.verifyEqual(wopts.Steps, 12);
        end

        function directMethodSupportsInfiniteHorizon(testCase)
            A = -eye(2);
            wopts = WOptions('Method', "direct", 'UseScaling', false);

            wlist = gramian.computeGramian(A, Inf, wopts);

            testCase.verifyEqual(wlist.W{1}{1}, diag([0.5, 0]), 'AbsTol', 1e-12);
            testCase.verifyEqual(wlist.W{2}{1}, diag([0, 0.5]), 'AbsTol', 1e-12);
        end

        function integralMethodUsesQuadrature(testCase)
            A = zeros(2);
            wopts = WOptions('Method', "integral", 'Steps', 2, 'UseScaling', false);

            wlist = gramian.computeGramian(A, 1, wopts);

            testCase.verifyEqual(wlist.W{1}{1}, diag([1, 0]), 'AbsTol', 1e-12);
            testCase.verifyEqual(wlist.W{2}{1}, diag([0, 1]), 'AbsTol', 1e-12);
        end

    end

    methods (Access = private)

        function verifyDeprecatedConstructorResult(testCase)
            wopts = WOptions('Method', "lyap");

            testCase.verifyEqual(wopts.Method, "direct");
        end

        function verifyDeprecatedSetterResult(testCase)
            wopts = WOptions();
            wopts.Method = "lyap";

            testCase.verifyEqual(wopts.Method, "direct");
        end

    end
end
