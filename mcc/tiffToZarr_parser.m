function [] = tiffToZarr_parser(tifFilename, zarrFilename, frame, varargin)

ip = inputParser;
ip.CaseSensitive = false;

%#function tiffToZarr
%#function processFFCorrectionFrame
%#function erodeVolumeBy2DProjection

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('tifFilename', @(x) ischar(x) || iscell(x));
ip.addRequired('zarrFilename', @ischar);
ip.addOptional('frame', [], @(x) isnumeric(x) || ischar(x));
ip.addParameter('Overwrite', false, @(x) islogical(x) || ischar(x));
ip.addParameter('blockSize', [500, 500, 250], @(x) isnumeric(x) || ischar(x));
ip.addParameter('expand2dDim', true, @(x) islogical(x) || ischar(x)); % expand the z dimension for 2d data
ip.addParameter('flipZstack', false, @(x) islogical(x) || ischar(x));
ip.addParameter('resample', [], @(x) isempty(x) || isnumeric(x) || ischar(x));
ip.addParameter('InputBbox', [], @(x) isnumeric(x) || ischar(x));
ip.addParameter('tileOutBbox', [], @(x) isempty(x) || isnumeric(x) || ischar(x));
ip.addParameter('readWholeTiff', true, @(x) islogical(x) || ischar(x));
ip.addParameter('compressor', 'lz4', @ischar);
ip.addParameter('usrFcn', '', @(x) isempty(x) || isa(x,'function_handle') || ischar(x));
ip.addParameter('uuid', '', @ischar);

ip.parse(tifFilename, zarrFilename, frame, varargin{:});

pr = ip.Results;
Overwrite = pr.Overwrite;
blockSize = pr.blockSize;
expand2dDim = pr.expand2dDim;
flipZstack = pr.flipZstack;
resample = pr.resample;
InputBbox = pr.InputBbox;
tileOutBbox = pr.tileOutBbox;
readWholeTiff = pr.readWholeTiff;
compressor = pr.compressor;
usrFcn = pr.usrFcn;
uuid = pr.uuid;

if ischar(tifFilename) && strcmp(tifFilename(1), '{')
    tifFilename = eval(tifFilename);
end
if ischar(frame)
    frame = str2num(frame);
end
if ischar(Overwrite)
    Overwrite = strcmp(Overwrite, 'true');
end
if ischar(blockSize)
    blockSize = str2num(blockSize);
end
if ischar(expand2dDim)
    expand2dDim = strcmp(expand2dDim, 'true');
end
if ischar(flipZstack)
    flipZstack = strcmp(flipZstack, 'true');
end
if ischar(resample)
    resample = str2num(resample);
end
if ischar(InputBbox)
    InputBbox = str2num(InputBbox);
end
if ischar(tileOutBbox)
    tileOutBbox = str2num(tileOutBbox);
end
if ischar(readWholeTiff)
    readWholeTiff = strcmp(readWholeTiff,'true');
end

tiffToZarr(tifFilename, zarrFilename, frame, 'Overwrite', Overwrite, 'blockSize', blockSize, ...
    'expand2dDim', expand2dDim, 'flipZstack', flipZstack, 'resample', resample, ...
    'InputBbox', InputBbox, 'tileOutBbox', tileOutBbox, 'readWholeTiff', readWholeTiff, ...
    'compressor', compressor, 'usrFcn', usrFcn, 'uuid', uuid);

end

