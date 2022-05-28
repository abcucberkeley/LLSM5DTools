function writezarr(data, filepath, varargin)
% wrapper for zarr writer 
% 
% Author: Xiongtao Ruan (01/25/2022)
% 
% xruan (05/23/2022): add support for bounding box write; also add
% parallelWriteZarr as default method


ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('data', @(x) isnumeric(x));
ip.addRequired('filepath', @(x) ischar(x));
ip.addParameter('blockSize', [500, 500, 500], @isnumeric);
ip.addParameter('expand2dDim', true, @islogical); % expand the z dimension for 2d data
ip.addParameter('groupWrite', true, @islogical);
ip.addParameter('bbox', [], @isnumeric);
ip.parse(data, filepath, varargin{:});

pr = ip.Results;
expand2dDim = pr.expand2dDim;
blockSize = pr.blockSize;
groupWrite = pr.groupWrite;
bbox = pr.bbox;

dtype = class(data);
sz = size(data);
init_val = zeros(1, dtype);
if ismatrix(data) 
    if expand2dDim
        sz(3) = 1;
        blockSize(3) = 1;
    else
        blockSize = blockSize(1 : 2);
    end
end
blockSize = min(sz, blockSize);
% overwrite the zarr file
if exist(filepath, 'dir') && isempty(bbox)
    rmdir(filepath, 's');
end

try 
    if ismatrix(data)
        error('No support for 2d data for now!')
    end
    if isempty(bbox)
        parallelWriteZarr(filepath, data, 1, blockSize);
    else
        parallelWriteZarr(filepath, data, 1, bbox);
    end
catch ME
    disp(ME);
    bim = blockedImage(filepath, sz, blockSize, init_val, "Adapter", ZarrAdapter, 'Mode', 'w');
    % for data greater than 2GB, use multiprocessing
    if ~ispc && prod(sz) * 2 / 1024^3 > 2 && ~ismatrix(data) 
        bim.Adapter.setData(data);
    else
        bim.Adapter.setRegion(ones(1, numel(bim.Size)), bim.Size, data)
    end
    bim.Adapter.close();
end

if groupWrite
    try
        fileattrib(filepath, '+w', 'g');
    catch
        warning('Unable to change file attribe for group write!');
    end
end

end
