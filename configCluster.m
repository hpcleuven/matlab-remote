function configCluster
% Configure MATLAB to submit to the cluster.

% Copyright 2013-2022 The MathWorks, Inc.

% The version of MATLAB being supported
release = ['R' version('-release')];

% Import cluster definitions
def = clusterDefinition();

% Cluster list
cluster_dir = fullfile(fileparts(mfilename('fullpath')),'IntegrationScripts');
% Listing of setting file(s).  Derive the specific one to use.
cluster_list = dir(cluster_dir);
% Ignore . and .. directories
cluster_list = cluster_list(arrayfun(@(x) x.name(1), cluster_list) ~= '.');
len = length(cluster_list);
if len==0
    error('No cluster directory exists.')
elseif len==1
    cluster = cluster_list.name;
else
    cluster = lExtractPfile(cluster_list);
end

% Determine the name of the cluster profile
profile = [cluster ' ' release];

% Delete the profile (if it exists)
% In order to delete the profile, check first if an existing profile.  If
% so, check if it's the default profile.  If so, set the default profile to
% "local" (otherwise, MATLAB will throw the following warning)
%
%  Warning: The value of DefaultProfile is 'name-of-profile-we-want-to-delete' which is not the name of an existing profile.  Setting the DefaultProfile to 'local' at the user level.  Valid profile names are:
%  	  'local' 'profile1' 'profile2' ...
%
% This way, we bypass the warning message.  Then remove the old incarnation
% of the profile (that we're going to eventually create.)
if verLessThan('matlab','9.13')
    % R2022a and older
    % Handle to function returning list of cluster profiles
    cp_fh = @parallel.clusterProfiles;
    % Handle to function returning default cluster profile
    dp_fh = @parallel.defaultClusterProfile;
else
    % R2022b and newer
    % Handle to function returning list of cluster profiles
    cp_fh = @parallel.listProfiles;
    % Handle to function returning default cluster profile
    dp_fh = @parallel.defaultProfile;
end
if any(strcmp(profile,feval(cp_fh))) %#ok<*FVAL>
    % The profile exists.  Check if it's the default profile.
    if strcmp(profile,feval(dp_fh))
        % The profile is the default profile.  Change the default profile
        % to the default profile (local or Processes) to avoid the
        % afformentioned warning.

        % Get the list of factory profile names
        %
        %  Before R2022b: local
        %  After  R2022a: Processes, Threads
        %
        % In either case, pick the first one
        fpn = parallel.internal.settings.getFactoryProfileNames;
        dp_fh(fpn{1});
    end
    % The profile is not the default profile, safely remove it.
    parallel.internal.ui.MatlabProfileManager.removeProfile(profile)
end

% User's local machine's hostname
if strcmp(def.Type, 'shared')
    hostname = '';
else
    [~, hostname] = system('hostname');
    hostname = strtrim(hostname);
end

% Skip this for shared
if ~strcmp(def.Type,'shared')
    % If multiple releases were specified in the mdcs.rc
    % select the correct one to use.
    releaseBreakDown = strsplit(def.ClusterMatlabRoot,',');
    matchingRelease = (~cellfun(@isempty,regexp(releaseBreakDown,release,'once')));
    if ~matchingRelease
        emsg = sprintf(['\n\t The version of MATLAB you are running is not installed on the cluster.\n', ...
                        '\t Contact your cluster administrator for further assistance. \n']);
        error(emsg)
    end
    releaseToUse = releaseBreakDown{matchingRelease};
    releaseToUse = strsplit(releaseToUse,':');
    def.ClusterMatlabRoot = releaseToUse{2};
end

% Create the user's local Job Storage Location folder
loc = '';
if strcmp(def.Type, 'shared')
    if isempty(def.LocalJobStorageLocation)
        rootd = lGetLocalRoot();
    else
        user = lGetLocalUsername();
        rootd = [def.LocalJobStorageLocation user];
        loc = '.matlab';
    end
elseif strcmp(def.Type, 'nonshared')
    if isempty(def.LocalJobStorageLocation)
        rootd = lGetLocalRoot();
    else
        user = lGetLocalUsername();
        rootd = [def.LocalJobStorageLocation user];
        if ispc
            loc = 'MATLAB';
        else
            loc = '.matlab';
        end
    end
elseif strcmp(def.Type, 'remote')
    user = getenv('USER');
    rootd = [def.LocalJobStorageLocation user];
    loc = '.matlab';
end
jsl = fullfile(rootd,loc,'3p_cluster_jobs',cluster,release,def.Type);

if exist(jsl,'dir')==false
    [status,err,eid] = mkdir(jsl);
    if status==false
        error(eid,'Can''t make directory %s: %s',jsl,err)
    end
end

% Configure the user's remote storage location and assemble the cluster profile.
if strcmp(def.Type, 'shared')
    rjsl = '';
    user = '';
    def.ClusterHost = '';
    def.ClusterMatlabRoot = '';
elseif strcmp(def.Type, 'nonshared')
    user = lGetRemoteUsername(cluster);
    rootd = [def.RemoteJobStorageLocation user];
    rjsl = [rootd '/' '.matlab' '/' '3p_cluster_jobs' '/' cluster '/' hostname '/' release '/' def.Type];
    hd = lGetHomeDirPath(cluster);
    rootd = [def.RemoteJobStorageLocation '/' ];
elseif strcmp(def.Type, 'remote')
    if ispc
        rootd = [def.RemoteJobStorageLocation user];
        rjsl = [rootd '/' '.matlab' '/' '3p_cluster_jobs' '/' cluster '/' hostname '/' release '/' def.Type];
    else
        rjsl = '';
    end
end
assembleClusterProfile(jsl, rjsl, cluster, user, profile, def);

lNotifyUserOfCluster(profile)

% % Validate if you want to
% ps.Profiles(pnidx).validate

end


function cluster_name = lExtractPfile(cl)
% Display profile listing to user to select from

len = length(cl);
for pidx = 1:len
    name = cl(pidx).name;
    names{pidx,1} = name; %#ok<AGROW>
end

selected = false;
while selected==false
    for pidx = 1:len
        fprintf('\t[%d] %s\n',pidx,names{pidx});
    end
    idx = input(sprintf('Select a cluster [1-%d]: ',len));
    selected = idx>=1 && idx<=len;
end
cluster_name = cl(idx).name;

end


function r = lGetLocalRoot()

r = fileparts(prefdir);

end


function un = lGetRemoteUsername(cluster)

un = input(['Username on ' upper(cluster) ' (e.g. jdoe): '],'s');
if isempty(un)
    error(['Failed to configure cluster: ' cluster])
end

end


function user = lGetLocalUsername()

user = char(java.lang.System.getProperty('user.name'));

end


function assembleClusterProfile(jsl, rjsl, cluster, user, profile, def)

% Create generic cluster profile
c = parallel.cluster.Generic;

% Required mutual fields
% Location of the Integration Scripts
c.IntegrationScriptsLocation = fullfile(fileparts(mfilename('fullpath')),'IntegrationScripts', cluster);
c.NumWorkers = str2num(def.NumWorkers); %#ok<ST2NM>
c.OperatingSystem = 'unix';

% Depending on the submission type, populate cluster profile fields
if strcmp(def.Type, 'shared')
    c.HasSharedFilesystem = true;
else
    % Set common properties for nonshared and remote
    c.AdditionalProperties.Username = user;
    c.AdditionalProperties.ClusterHost = def.ClusterHost;
    c.ClusterMatlabRoot = def.ClusterMatlabRoot;
    if strcmp(def.Type, 'nonshared')
        c.AdditionalProperties.RemoteJobStorageLocation = rjsl;
        c.HasSharedFilesystem = false;
    elseif strcmp(def.Type,'remote')
        if ispc
            jsl = struct('windows',jsl,'unix',rjsl);
        end
        c.HasSharedFilesystem = true;
    end
end
c.JobStorageLocation = jsl;

% AdditionalProperties for the cluster:
% username, queue, walltime, e-mail, etc.
c.AdditionalProperties.AccountName = '';
c.AdditionalProperties.AdditionalSubmitArgs = '';
c.AdditionalProperties.AuthenticationMode = 'IdentityFile';
c.AdditionalProperties.IdentityFile = '~/.ssh/id_rsa';
c.AdditionalProperties.IdentityFileHasPassphrase = false;
c.AdditionalProperties.Constraint = '';
c.AdditionalProperties.EmailAddress = '';
c.AdditionalProperties.EnableDebug = false;
c.AdditionalProperties.GpuCard = '';
c.AdditionalProperties.GpusPerNode = 0;
c.AdditionalProperties.MemUsage = '4gb';
c.AdditionalProperties.Nodes = 0;
c.AdditionalProperties.ProcsPerNode = 0;
c.AdditionalProperties.QueueName = '';
c.AdditionalProperties.RequireExclusiveNode = false;
c.AdditionalProperties.Reservation = '';
c.AdditionalProperties.WallTime = '';

% MPI Configuration
if verLessThan('matlab','9.6')
    % Set to true in versions older than R2019a
    % Use the default smpd process manager
    c.AdditionalProperties.UseSmpd = true;
else
    % and false in R2019a or newer
    % Use the new hydra process manager shipped with MATLAB
    c.AdditionalProperties.UseSmpd = false;
end

% Save Profile
c.saveAsProfile(profile);
c.saveProfile('Description', profile)

% Set as default profile
parallel.defaultClusterProfile(profile);

end


function lNotifyUserOfCluster(profile)

%{
cluster = split(profile);
cluster = cluster{1};
fprintf(['\n\tMust set QueueName before submitting jobs to %s.  E.g.\n\n', ...
         '\t>> c = parcluster;\n', ...
         '\t>> c.AdditionalProperties.QueueName = ''queue-name'';\n', ...
         '\t>> c.saveProfile\n\n'], upper(cluster))
%}

% configCluster completed
fprintf('Complete.  Default cluster profile set to "%s".\n', profile)

end
