function commonSubmitArgs = getCommonSubmitArgs(cluster)
% Get any additional submit arguments for the PBS qsub command
% that are common to both independent and communicating jobs.

% Copyright 2016-2022 The MathWorks, Inc.

% wiki: 

commonSubmitArgs = '';
ap = cluster.AdditionalProperties;

%% REQUIRED

% Physical Memory used by a single core
mu = validatedPropValue(ap, 'MemUsage', 'char', '');
if isempty(mu)
    emsg = sprintf(['\n\t>> %% Must set MemUsage.  E.g.\n\n', ...
                    '\t>> c = parcluster;\n', ...
                    '\t>> c.AdditionalProperties.MemUsage = ''4gb'';\n', ...
                    '\t>> c.saveProfile\n\n']);
    error(emsg)
else
    commonSubmitArgs = sprintf('%s -l pmem=%s', commonSubmitArgs, mu);
end

% Account name
an = validatedPropValue(ap, 'AccountName', 'char');
if isempty(an)
        emsg = sprintf(['\n\t>> %% Must set AccountName.  E.g.\n\n', ...
                     '\t>> c = parcluster;\n', ...
                     '\t>> c.AdditionalProperties.AccountName = ''account-name'';\n', ...
                     '\t>> c.saveProfile\n\n']);
     error(emsg)
else
     commonSubmitArgs = sprintf('%s -A %s', commonSubmitArgs, an);
end

% Walltime
wt = validatedPropValue(ap, 'WallTime', 'char');
if isempty(wt)
     emsg = sprintf(['\n\t>> %% Must set WallTime.  E.g.\n\n', ...
                     '\t>> c = parcluster;\n', ...
                     '\t>> c.AdditionalProperties.WallTime = ''00:30:00'';\n', ...
                     '\t>> c.saveProfile\n\n']);
     error(emsg)
else
     commonSubmitArgs = sprintf('%s -l walltime=%s', commonSubmitArgs, wt);
end


%% OPTIONAL

% Queue name
qn = validatedPropValue(ap, 'QueueName', 'char', '');
if ~isempty(qn)
    commonSubmitArgs = sprintf('%s -q %s', commonSubmitArgs, qn);
end

% GPU Selection
ngpus = validatedPropValue(ap, 'GpusPerNode', 'double', 0);
if ngpus>0 
    commonSubmitArgs = sprintf('%s -l gpus=%d', commonSubmitArgs, ngpus);
end

% Job placement
jp = validatedPropValue(ap, 'JobPlacement', 'char', '');
ren = validatedPropValue(ap, 'RequireExclusiveNode', 'bool', false);
if ~isempty(jp) || ren
    if ren
        jp = [jp ':excl'];
        if strncmp(jp,':',1)
            % If we only want exclusive and didn't request JP, then remove the leading ':'.
            jp(1) = '';
        end
    end
    commonSubmitArgs = [commonSubmitArgs ' -l place=' jp];
end

% Email notification
ea = validatedPropValue(ap, 'EmailAddress', 'char', '');
if ~isempty(ea)
    commonSubmitArgs = sprintf('%s -M %s -m abe', commonSubmitArgs, ea);
end

% Catch-all
asa = validatedPropValue(ap, 'AdditionalSubmitArgs', 'char', '');
if ~isempty(asa)
    commonSubmitArgs = sprintf('%s %s', commonSubmitArgs, asa);
end

commonSubmitArgs = strtrim(commonSubmitArgs);

end
