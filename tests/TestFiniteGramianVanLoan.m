classdef TestFiniteGramianVanLoan < matlab.unittest.TestCase
    methods (Test)

        function resonantEigenvaluePair(testCase)
            A = [0, 1; 1, 0];
            T = 0.7;
            b = [1; 0];

            expected = TestFiniteGramianVanLoan.resonantExpected(T);
            actual = gramian.finiteGramianVanLoan_(A, T, b);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-12);
        end

        function computeGramianUsesVanLoanWithoutScaling(testCase)
            A = [0, 1; 1, 0];
            T = 0.7;
            wopts = WOptions('Method', "lyap", 'UseScaling', false);

            wlist = gramian.computeGramian(A, T, wopts);

            expected = TestFiniteGramianVanLoan.resonantExpected(T);
            testCase.verifyEqual(wlist.W{1}{1}, expected, 'AbsTol', 1e-12);
        end

        function targetNodesUseVanLoan(testCase)
            A = sparse([0, 1; 1, 0]);
            T = 0.7;
            targetNodes = [1, 2];
            wopts = WOptions('Method', "lyap", 'UseScaling', false);

            wlist = gramian.computeGramian(A, T, wopts, targetNodes);

            expected = TestFiniteGramianVanLoan.resonantExpected(T);
            testCase.verifyEqual(wlist.W{1}{1}, expected, 'AbsTol', 1e-12);
        end

        function agreesWithLyapunovFormulaWhenSolutionIsUnique(testCase)
            A = [-1, 0.2; 0, -2];
            T = 0.7;
            b = [0.3; 1];
            Q = b * b.';
            eAT = expm(T * A);

            expected = lyap(A, Q - eAT * Q * eAT.');
            actual = gramian.finiteGramianVanLoan_(A, T, b);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-12);
        end

    end

    methods (Static, Access = private)

        function W = resonantExpected(T)
            diagonalTerm = sinh(2 * T) / 4;
            offDiagonalTerm = sinh(T)^2 / 2;
            W = [
                 T / 2 + diagonalTerm, offDiagonalTerm
                 offDiagonalTerm, -T / 2 + diagonalTerm
                ];
        end

    end
end
