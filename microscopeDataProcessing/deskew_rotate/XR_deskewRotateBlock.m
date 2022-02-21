function [done_flag] = XR_deskewRotateBlock(batchInds, zarrFullpath, dsrFullpath, flagFullname, ...
    BatchBBoxes, RegionBBoxes, borderSize, xyPixelSize, dz, varargin)
% Deskew and/or rotate data for given blocks


ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('blockInds', @isnumeric);
ip.addRequired('zarrFullpath', @(x) ischar(x));
ip.addRequired('dsrFullpath', @(x) ischar(x));
ip.addRequired('flagFullname', @(x) ischar(x));
% ip.addParameter('ResultDir', 'matlab_stitch', @ischar);
ip.addRequired('BatchBBoxes', @isnumeric);
ip.addRequired('RegionBBoxes', @isnumeric);
ip.addRequired('borderSize', @isnumeric);
ip.addRequired('pixelSize', @isnumeric); %in um
ip.addRequired('dz', @isnumeric); %in um
% ip.addParameter('BlockSize', [], @isnumeric);
ip.addParameter('Overwrite', false, @islogical);
ip.addParameter('SkewAngle', 32.45 , @isnumeric);
ip.addParameter('Reverse', true, @islogical); 
ip.addParameter('flipZstack', false, @islogical); 
ip.addParameter('Interp', 'linear', @(x) any(strcmpi(x, {'cubic', 'linear'})));
ip.addParameter('uuid', '', @ischar);
ip.addParameter('debug', false, @islogical);

ip.parse(batchInds, zarrFullpath, dsrFullpath, flagFullname, ...
    BatchBBoxes, RegionBBoxes, borderSize, xyPixelSize, dz, varargin{:});

pr = ip.Results;
Overwrite = pr.Overwrite;
SkewAngle = pr.SkewAngle;
Reverse = pr.Reverse;
flipZstack = pr.flipZstack;
Interp = pr.Interp;
uuid = pr.uuid;

% we assume the path exists, otherwise return error (in case of completion 
% of processing for all blocks).
flagPath = fileparts(flagFullname);
if ~exist(flagPath, 'dir')
    error('The block directory %s does not exist, skip the processing!', flagPath);
end

if exist(flagFullname, 'file')
    if Overwrite
        delete(flagFullname);
    else
        fprintf('The batch files (%d - %d) already exist, skip them!\n', batchInds(1), batchInds(end));
        return;
    end
end

if ~exist(zarrFullpath, 'dir')
    error('The input zarr file %s doesnot exist!', zarrFullpath);
end

bim = blockedImage(zarrFullpath, 'Adapter', ZarrAdapter);

if ~exist(dsrFullpath, 'dir')
    error('The output zarr file %s doesnot exist!', dsrFullpath);
end
nv_bim = blockedImage(dsrFullpath, 'Adapter', ZarrAdapter);

done_flag = false(numel(batchInds), 1);
for i = 1 : numel(batchInds)
    bi = batchInds(i);
    fprintf('Process Batch %d ... ', bi);
    tic;
    
    ibStart = BatchBBoxes(i, 1 : 3);
    ibEnd = BatchBBoxes(i, 4 : 6);
    
    % load the region in input 
    % in_batch = bim.getRegion(ibStart, ibEnd);
    in_batch = bim.Adapter.getIORegion(ibStart, ibEnd);
    
    % deskew and rotate    
    ObjectiveScan = false;
    resample = [];
    
    out_batch = deskewRotateFrame3D(in_batch, SkewAngle, dz, xyPixelSize, ...
                'reverse', Reverse, 'Crop', true, 'ObjectiveScan', ObjectiveScan, ...
                'resample', resample, 'Interp', Interp);
    
    if ~isempty(borderSize)
        out_batch = out_batch(borderSize(1) + 1 : end - borderSize(4), borderSize(2) + 1 : end - borderSize(5), ...
            borderSize(3) + 1 : end - borderSize(6)); 
    end
            
    obStart = RegionBBoxes(i, 1 : 3);
    obEnd = RegionBBoxes(i, 4 : 6);

    % out_batch = out_batch(baStart(1) : baEnd(1), baStart(2) : baEnd(2), baStart(3) : baEnd(3));
    
    % write out_batch (in the future, directly write the whole region)
    nv_bim.Adapter.setRegion(obStart, obEnd, out_batch)

    done_flag(i) = true;

    toc;
end

if all(done_flag)
    fclose(fopen(flagFullname, 'w'));
end



end

