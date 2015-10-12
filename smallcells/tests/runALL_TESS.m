import matlab.unittest.TestSuite;

try
    suite = TestSuite.fromPackage('testcases','IncludingSubpackages',true);
    results = run(suite);
    display(results);
catch e
    disp(getReport(e,'extended'));
    exit(1);
end
% Report Error
exit(any([results.Failed]));