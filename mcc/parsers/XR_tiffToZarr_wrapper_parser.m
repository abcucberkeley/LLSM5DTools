function [] = XR_tiffToZarr_wrapper_parser(tiffFullpaths, varargin)


%#function tiffToZarr

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('tiffFullpaths', @(x) iscell(x) || ischar(x));
ip.addParameter('zarrPathstr', 'zarr', @ischar);
ip.addParameter('locIds', [], @(x) isnumeric(x) || ischar(x)); % location ids for the tiles
ip.addParameter('blockSize', [500, 500, 250], @(x) isnumeric(x) || ischar(x));
ip.addParameter('shardSize', [], @(x) isnumeric(x) || ischar(x));
ip.addParameter('flippedTile', [], @(x) isempty(x) || islogical(x) || ischar(x));
ip.addParameter('resample', [], @(x) isempty(x) || isnumeric(x) || ischar(x));
ip.addParameter('partialFile', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ChannelPatterns', {'tif'}, @(x) iscell(x) || ischar(x));
ip.addParameter('InputBbox', [], @(x) isnumeric(x) || ischar(x)); % crop input tile before processing
ip.addParameter('tileOutBbox', [], @(x) isnumeric(x) || ischar(x)); % crop output tile after processing
ip.addParameter('processFunPath', '', @(x) isempty(x) || isa(x,'function_handle') || ischar(x) || isstring(x) || iscell(x));
ip.addParameter('parseCluster', true, @(x) islogical(x) || ischar(x));
ip.addParameter('bigData', true, @(x) islogical(x) || ischar(x));
ip.addParameter('masterCompute', true, @(x) islogical(x) || ischar(x)); % master node participate in the task computing. 
ip.addParameter('jobLogDir', '../job_logs', @ischar);
ip.addParameter('cpusPerTask', 1, @(x) isnumeric(x) || ischar(x));
ip.addParameter('uuid', '', @ischar);
ip.addParameter('maxTrialNum', 3, @(x) isnumeric(x) || ischar(x));
ip.addParameter('unitWaitTime', 30, @(x) isnumeric(x) || ischar(x));
ip.addParameter('mccMode', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ConfigFile', '', @ischar);

ip.parse(tiffFullpaths, varargin{:});

pr = ip.Results;
zarrPathstr = pr.zarrPathstr;
locIds = pr.locIds;
blockSize = pr.blockSize;
shardSize = pr.shardSize;
flippedTile = pr.flippedTile;
resample = pr.resample;
partialFile = pr.partialFile;
ChannelPatterns = pr.ChannelPatterns;
InputBbox = pr.InputBbox;
tileOutBbox = pr.tileOutBbox;
processFunPath = pr.processFunPath;
parseCluster = pr.parseCluster;
bigData = pr.bigData;
masterCompute = pr.masterCompute;
jobLogDir = pr.jobLogDir;
cpusPerTask = pr.cpusPerTask;
uuid = pr.uuid;
maxTrialNum = pr.maxTrialNum;
unitWaitTime = pr.unitWaitTime;
mccMode = pr.mccMode;
ConfigFile = pr.ConfigFile;

if ischar(tiffFullpaths) && ~isempty(tiffFullpaths) && strcmp(tiffFullpaths(1), '{')
    tiffFullpaths = eval(tiffFullpaths);
end
if ischar(locIds)
    locIds = str2num(locIds);
end
if ischar(blockSize)
    blockSize = str2num(blockSize);
end
if ischar(shardSize)
    shardSize = str2num(shardSize);
end
if ischar(flippedTile)
    flippedTile = str2num(flippedTile);
end
if ischar(resample)
    resample = str2num(resample);
end
if ischar(partialFile)
    partialFile = str2num(partialFile);
end
if ischar(ChannelPatterns) && ~isempty(ChannelPatterns) && strcmp(ChannelPatterns(1), '{')
    ChannelPatterns = eval(ChannelPatterns);
end
if ischar(InputBbox)
    InputBbox = str2num(InputBbox);
end
if ischar(tileOutBbox)
    tileOutBbox = str2num(tileOutBbox);
end
if ischar(processFunPath) && ~isempty(processFunPath) && (strcmp(processFunPath(1), '{') || strcmp(processFunPath(1), '[') || strcmp(processFunPath(1), '@'))
    processFunPath = eval(processFunPath);
end
if ischar(parseCluster)
    parseCluster = str2num(parseCluster);
end
if ischar(bigData)
    bigData = str2num(bigData);
end
if ischar(masterCompute)
    masterCompute = str2num(masterCompute);
end
if ischar(cpusPerTask)
    cpusPerTask = str2num(cpusPerTask);
end
if ischar(maxTrialNum)
    maxTrialNum = str2num(maxTrialNum);
end
if ischar(unitWaitTime)
    unitWaitTime = str2num(unitWaitTime);
end
if ischar(mccMode)
    mccMode = str2num(mccMode);
end

XR_tiffToZarr_wrapper(tiffFullpaths, zarrPathstr=zarrPathstr, locIds=locIds, ...
    blockSize=blockSize, shardSize=shardSize, flippedTile=flippedTile, resample=resample, ...
    partialFile=partialFile, ChannelPatterns=ChannelPatterns, InputBbox=InputBbox, ...
    tileOutBbox=tileOutBbox, processFunPath=processFunPath, parseCluster=parseCluster, ...
    bigData=bigData, masterCompute=masterCompute, jobLogDir=jobLogDir, cpusPerTask=cpusPerTask, ...
    uuid=uuid, maxTrialNum=maxTrialNum, unitWaitTime=unitWaitTime, mccMode=mccMode, ...
    ConfigFile=ConfigFile);

end

