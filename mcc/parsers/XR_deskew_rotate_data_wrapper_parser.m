function XR_deskew_rotate_data_wrapper_parser(dataPaths, varargin)


ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('dataPaths', @(x) ischar(x) || iscell(x));
ip.addParameter('DSDirStr', 'DS/', @ischar);
ip.addParameter('DSRDirStr', 'DSR/', @ischar);
ip.addParameter('Deskew', true, @(x) islogical(x) || ischar(x));
ip.addParameter('Rotate', true, @(x) islogical(x) || ischar(x));
ip.addParameter('Overwrite', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ChannelPatterns', {'CamA_ch0', 'CamA_ch1', 'CamB_ch0', 'CamB_ch1'}, @(x) iscell(x) || ischar(x));
ip.addParameter('dz', 0.5, @(x) isscalar(x) || ischar(x));
ip.addParameter('xyPixelSize', 0.108, @(x) isscalar(x) || ischar(x));
ip.addParameter('SkewAngle', 32.45, @(x) isscalar(x) || ischar(x));
ip.addParameter('ObjectiveScan', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ZstageScan', false, @(x) islogical(x) || ischar(x));
ip.addParameter('Reverse', false, @(x) islogical(x) || ischar(x));
ip.addParameter('flipZstack', false, @(x) islogical(x) || ischar(x));
ip.addParameter('parseSettingFile', false, @(x) islogical(x) || ischar(x)); % use setting file to decide whether filp Z stack or not, it is  poirier over flipZstack
ip.addParameter('Crop', false, @(x) islogical(x) || ischar(x));
ip.addParameter('DSRCombined', true, @(x) islogical(x) || ischar(x)); % combined processing 
ip.addParameter('LLFFCorrection', false, @(x) islogical(x) || ischar(x));
ip.addParameter('BKRemoval', false, @(x) islogical(x) || ischar(x));
ip.addParameter('LowerLimit', 0.4, @(x) isnumeric(x) || ischar(x)); % this value is the lowest
ip.addParameter('constOffset', [], @(x) isnumeric(x) || ischar(x)); % If it is set, use constant background, instead of background from the camera.
ip.addParameter('LSImagePaths', {'','',''}, @(x) iscell(x) || ischar(x));
ip.addParameter('BackgroundPaths', {'','',''}, @(x) iscell(x) || ischar(x));
ip.addParameter('Save16bit', false , @(x) islogical(x) || ischar(x)); % saves deskewed data as 16 bit -- not for quantification
ip.addParameter('save3DStack', true , @(x) islogical(x) || ischar(x)); % option to save 3D stack or not
ip.addParameter('SaveMIP', true , @(x) islogical(x) || ischar(x)); % save MIP-z for ds and dsr. 
ip.addParameter('largeFile', false, @(x) islogical(x) || ischar(x));
ip.addParameter('zarrFile', false, @(x) islogical(x) || ischar(x)); % use zarr file as input
ip.addParameter('saveZarr', false , @(x) islogical(x) || ischar(x)); % save as zarr
ip.addParameter('BatchSize', [1024, 1024, 1024] , @(x) isvector(x) || ischar(x)); % in y, x, z
ip.addParameter('BlockSize', [256, 256, 256], @(x) isvector(x) || ischar(x)); % in y, x, z
ip.addParameter('zarrSubSize', [20, 20, 20], @(x) isnumeric(x) || ischar(x)); % zarr subfolder size
ip.addParameter('inputBbox', [], @(x) isempty(x) || isvector(x) || ischar(x));
ip.addParameter('taskSize', [], @(x) isnumeric(x) || ischar(x));
ip.addParameter('resample', [], @(x) isempty(x) || isnumeric(x) || ischar(x)); % resampling after rotation 
ip.addParameter('Interp', 'linear', @(x) any(strcmpi(x, {'cubic', 'linear'})) || ischar(x));
ip.addParameter('maskFns', {}, @(x) iscell(x) || ischar(x)); % 2d masks to filter regions to deskew and rotate, in xy, xz, yz order
ip.addParameter('suffix', '', @ischar); % suffix for the folder
ip.addParameter('parseCluster', true, @(x) islogical(x) || ischar(x));
ip.addParameter('parseParfor', false, @(x) islogical(x) || ischar(x));
ip.addParameter('masterCompute', true, @(x) islogical(x) || ischar(x)); % master node participate in the task computing. 
ip.addParameter('jobLogDir', '../job_logs', @ischar);
ip.addParameter('cpusPerTask', 1, @(x) isnumeric(x) || ischar(x));
ip.addParameter('uuid', '', @ischar);
ip.addParameter('debug', false, @(x) islogical(x) || ischar(x));
ip.addParameter('mccMode', false, @(x) islogical(x) || ischar(x));
ip.addParameter('ConfigFile', '', @ischar);

ip.parse(dataPaths, varargin{:});

pr = ip.Results;
DSDirStr = pr.DSDirStr;
DSRDirStr = pr.DSRDirStr;
Deskew = pr.Deskew;
Rotate = pr.Rotate;
Overwrite = pr.Overwrite;
ChannelPatterns = pr.ChannelPatterns;
dz = pr.dz;
xyPixelSize = pr.xyPixelSize;
SkewAngle = pr.SkewAngle;
ObjectiveScan = pr.ObjectiveScan;
ZstageScan = pr.ZstageScan;
Reverse = pr.Reverse;
flipZstack = pr.flipZstack;
parseSettingFile = pr.parseSettingFile;
Crop = pr.Crop;
DSRCombined = pr.DSRCombined;
LLFFCorrection = pr.LLFFCorrection;
BKRemoval = pr.BKRemoval;
LowerLimit = pr.LowerLimit;
constOffset = pr.constOffset;
LSImagePaths = pr.LSImagePaths;
BackgroundPaths = pr.BackgroundPaths;
Save16bit = pr.Save16bit;
save3DStack = pr.save3DStack;
SaveMIP = pr.SaveMIP;
largeFile = pr.largeFile;
zarrFile = pr.zarrFile;
saveZarr = pr.saveZarr;
BatchSize = pr.BatchSize;
BlockSize = pr.BlockSize;
zarrSubSize = pr.zarrSubSize;
inputBbox = pr.inputBbox;
taskSize = pr.taskSize;
resample = pr.resample;
Interp = pr.Interp;
maskFns = pr.maskFns;
suffix = pr.suffix;
parseCluster = pr.parseCluster;
parseParfor = pr.parseParfor;
masterCompute = pr.masterCompute;
jobLogDir = pr.jobLogDir;
cpusPerTask = pr.cpusPerTask;
uuid = pr.uuid;
debug = pr.debug;
mccMode = pr.mccMode;
ConfigFile = pr.ConfigFile;

if ischar(dataPaths) && ~isempty(dataPaths) && strcmp(dataPaths(1), '{')
    dataPaths = eval(dataPaths);
end
if ischar(Deskew)
    Deskew = str2num(Deskew);
end
if ischar(Rotate)
    Rotate = str2num(Rotate);
end
if ischar(Overwrite)
    Overwrite = str2num(Overwrite);
end
if ischar(ChannelPatterns) && ~isempty(ChannelPatterns) && strcmp(ChannelPatterns(1), '{')
    ChannelPatterns = eval(ChannelPatterns);
end
if ischar(dz)
    dz = str2num(dz);
end
if ischar(xyPixelSize)
    xyPixelSize = str2num(xyPixelSize);
end
if ischar(SkewAngle)
    SkewAngle = str2num(SkewAngle);
end
if ischar(ObjectiveScan)
    ObjectiveScan = str2num(ObjectiveScan);
end
if ischar(ZstageScan)
    ZstageScan = str2num(ZstageScan);
end
if ischar(Reverse)
    Reverse = str2num(Reverse);
end
if ischar(flipZstack)
    flipZstack = str2num(flipZstack);
end
if ischar(parseSettingFile)
    parseSettingFile = str2num(parseSettingFile);
end
if ischar(Crop)
    Crop = str2num(Crop);
end
if ischar(DSRCombined)
    DSRCombined = str2num(DSRCombined);
end
if ischar(LLFFCorrection)
    LLFFCorrection = str2num(LLFFCorrection);
end
if ischar(BKRemoval)
    BKRemoval = str2num(BKRemoval);
end
if ischar(LowerLimit)
    LowerLimit = str2num(LowerLimit);
end
if ischar(constOffset)
    constOffset = str2num(constOffset);
end
if ischar(LSImagePaths) && ~isempty(LSImagePaths) && strcmp(LSImagePaths(1), '{')
    LSImagePaths = eval(LSImagePaths);
end
if ischar(BackgroundPaths) && ~isempty(BackgroundPaths) && strcmp(BackgroundPaths(1), '{')
    BackgroundPaths = eval(BackgroundPaths);
end
if ischar(Save16bit)
    Save16bit = str2num(Save16bit);
end
if ischar(save3DStack)
    save3DStack = str2num(save3DStack);
end
if ischar(SaveMIP)
    SaveMIP = str2num(SaveMIP);
end
if ischar(largeFile)
    largeFile = str2num(largeFile);
end
if ischar(zarrFile)
    zarrFile = str2num(zarrFile);
end
if ischar(saveZarr)
    saveZarr = str2num(saveZarr);
end
if ischar(BatchSize)
    BatchSize = str2num(BatchSize);
end
if ischar(BlockSize)
    BlockSize = str2num(BlockSize);
end
if ischar(zarrSubSize)
    zarrSubSize = str2num(zarrSubSize);
end
if ischar(inputBbox)
    inputBbox = str2num(inputBbox);
end
if ischar(taskSize)
    taskSize = str2num(taskSize);
end
if ischar(resample)
    resample = str2num(resample);
end
if ischar(maskFns) && ~isempty(maskFns) && strcmp(maskFns(1), '{')
    maskFns = eval(maskFns);
end
if ischar(parseCluster)
    parseCluster = str2num(parseCluster);
end
if ischar(parseParfor)
    parseParfor = str2num(parseParfor);
end
if ischar(masterCompute)
    masterCompute = str2num(masterCompute);
end
if ischar(cpusPerTask)
    cpusPerTask = str2num(cpusPerTask);
end
if ischar(debug)
    debug = str2num(debug);
end
if ischar(mccMode)
    mccMode = str2num(mccMode);
end

XR_deskew_rotate_data_wrapper(dataPaths, DSDirStr=DSDirStr, DSRDirStr=DSRDirStr, ...
    Deskew=Deskew, Rotate=Rotate, Overwrite=Overwrite, ChannelPatterns=ChannelPatterns, ...
    dz=dz, xyPixelSize=xyPixelSize, SkewAngle=SkewAngle, ObjectiveScan=ObjectiveScan, ...
    ZstageScan=ZstageScan, Reverse=Reverse, flipZstack=flipZstack, parseSettingFile=parseSettingFile, ...
    Crop=Crop, DSRCombined=DSRCombined, LLFFCorrection=LLFFCorrection, BKRemoval=BKRemoval, ...
    LowerLimit=LowerLimit, constOffset=constOffset, LSImagePaths=LSImagePaths, ...
    BackgroundPaths=BackgroundPaths, Save16bit=Save16bit, save3DStack=save3DStack, ...
    SaveMIP=SaveMIP, largeFile=largeFile, zarrFile=zarrFile, saveZarr=saveZarr, ...
    BatchSize=BatchSize, BlockSize=BlockSize, zarrSubSize=zarrSubSize, inputBbox=inputBbox, ...
    taskSize=taskSize, resample=resample, Interp=Interp, maskFns=maskFns, suffix=suffix, ...
    parseCluster=parseCluster, parseParfor=parseParfor, masterCompute=masterCompute, ...
    jobLogDir=jobLogDir, cpusPerTask=cpusPerTask, uuid=uuid, debug=debug, mccMode=mccMode, ...
    ConfigFile=ConfigFile);

end
