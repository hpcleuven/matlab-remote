function displayPoolError(cluster, job)
% This function is called when an interactive job type (parpool) is not supported with the cluster.
% It will inform the user how to alternatively submit a batch job to the cluster.

% Copyright 2010-2021 The MathWorks, Inc.

CR = 10;
TAB = 9;

v = ver('matlab');
labs = num2str(numel(job.Tasks));
if str2double(v.Version)<8.2
    poolOpt = 'matlabpool';
    poolCmd = ['>> matlabpool open ' cluster.Profile ' ' labs ')'];
else
    poolOpt = 'pool';
    poolCmd = ['>> parpool(''' cluster.Profile ''',' labs ')'];
end

labs = num2str(str2double(labs)+1);
emsg = [CR CR '****************************************************' ...
        ...
        CR cluster.Profile ' does not support calling' ...
        CR CR TAB poolCmd ...
        CR CR 'Instead, use batch()' ...
        CR CR TAB '>> job = batch(...,''' poolOpt ''',' labs ');' ...
        CR CR 'Call' ...
        CR CR TAB '>> doc batch' ...
        CR CR 'for more help on using batch.' ...
           CR '****************************************************' ...
        ...
        ];
error(emsg)