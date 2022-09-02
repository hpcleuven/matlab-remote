# Matlab Parallel Server

## About
Matlab Parallel Server allows you to launch jobs on the cluster from within a Matlab session, both when using Matlab in the command line or or from the GUI. For now, 
this is only possible when launchin a Matlab instance on the cluster, but in the future it will also be possible to submit jobs from your Matlab desktop client.

Matlab Parallel Server is available from Matlab R2022a+. 

> **_NOTE:_**  We can only grant access to Matlab for academic users. Please request access by requesting access to the lli_matlab group on your VSC account page

## Configuration

Before being able to use Matlab Parallel Server, you have to go through some configuration steps. 

### On the cluster
First of all, you need to start Matlab on the cluster. You should always request an interactive job before starting Matlab, to avoid cluttering on the login node. Be 
aware that if you launch a Matlab session on the login node anyway and you use too many resources, your session will be terminated automatically!

```
#Request an interactive job on Genius
qsub -I -l nodes=1:ppn=1 -A <account_name> -l walltime=01:00:00
```

Now, you can load the Matlab module

```
module purge
module use /apps/leuven/skylake/2021a/modules/all
module load MATLAB/R2022a
```

You can start a Matlab GUI by just typing `matlab`. For this set-up it might be easier and quicker to just launch Matlab in the terminal window. You can do this by
executing `matlab -nodisplay`.

Now you should have a Matlab session open. The scripts to configure the Matlab Parallel Server are stored in the Matlab toolbox. Execute following commands:

``` 
rehash toolboxcache
cd /apps/leuven/skylake/2021a/software/MATLAB/R2022a/toolbox/parallel/config_cluster
configCluster
```

FOLLOWING PROCEDURE HAS NOT BEEN FINALIZED YET!!!!!
You will be asked to provide a location where to store your job output files. You are free to choose where, but we recommend a location in your $VSC_DATA folder, e.g. 
/data/leuven/123/vsc12345/software/genius/matlab/config/. Be sure to create the folder beforehand. 

Now you have properly set up Matlab to submit jobs to the cluster. Your cluster profile has not been finalized yet though. The following steps will guide you through that. 

```
% required variables
c = parcluster;
c.AdditionalProperties.AccountName = 'account-name';
c.AdditionalProperties.WallTime = '05:00:00';

% optional variables
c.AdditionalProperties.EmailAddress = 'user-id@kuleuven.be';
c.AdditionalProperties.GpusPerNode = 1;
c.AdditionalProperties.GpuCard = 'gpu-card';
c.AdditionalProperties.MemUsage = '6gb';

% save the profile
c.saveProfile
```

You can always modify these parameters later on. emptying them is possible 

WIP!!!





