function [relative_shift, max_xcorr, relative_shift_mat, max_xcorr_mat] = cross_correlation_registration_3d_mip_slabs(imgFullpath_1, imgFullpath_2, xcorrFullpath, cuboid_1, cuboid_2, cuboid_overlap_12, px, xyz_factors, varargin)
% compute shift between a pair of tiles in stitching based on cross-correlation 
% for large zarr files using the MIP slabs. 
% 
% relative_shift: negative for move toward; postive for move away, xyz
% 
% copied from cross_correlation_registration_3d.m
% 
% Author: Xiongtao Ruan (05/01/2023)
% 
% xruan (06/13/2023): change to use cluster for the xcorr computing


ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('imgFullpath_1', @ischar);
ip.addRequired('imgFullpath_2', @ischar);
ip.addRequired('xcorrFullpath', @ischar);
ip.addRequired('cuboid_1', @isnumeric);
ip.addRequired('cuboid_2', @isnumeric);
ip.addRequired('cuboid_overlap_12', @isnumeric);
ip.addRequired('px', @isnumeric);
ip.addRequired('xyz_factors', @isnumeric);
ip.addParameter('downSample', [1, 1, 1], @isnumeric);
ip.addParameter('MaxOffset', [300, 300, 50], @isnumeric);
ip.addParameter('mipDirStr', '', @ischar);
ip.addParameter('poolSize', [], @isnumeric);
ip.addParameter('dimNumThrsh', 10000, @isnumeric);
ip.addParameter('blankNumTrsh', 200, @isnumeric); % skip blank regions beyond this length when cropping template
ip.addParameter('parseCluster', true, @islogical);
ip.addParameter('mccMode', false, @islogical);
ip.addParameter('ConfigFile', '', @ischar);

ip.parse(imgFullpath_1, imgFullpath_2, xcorrFullpath, cuboid_1, cuboid_2, cuboid_overlap_12, px, xyz_factors, varargin{:});

pr = ip.Results;
downSample = pr.downSample;
MaxOffset = pr.MaxOffset;
mipDirStr = pr.mipDirStr;
poolSize = pr.poolSize;
dimNumThrsh = pr.dimNumThrsh;
blankNumTrsh = pr.blankNumTrsh;
parseCluster = pr.parseCluster;
mccMode = pr.mccMode;
ConfigFile = pr.ConfigFile;

saveResult = ~isempty(xcorrFullpath);
if saveResult && exist(xcorrFullpath, 'file')
    fprintf('The xcorr result %s already exists!\n', xcorrFullpath);
    load(xcorrFullpath, 'relative_shift', 'max_xcorr', 'relative_shift_mat', 'max_xcorr_mat');
    return;
end

poolSize_1 = [1, 1, 1];
if numel(poolSize) == 6
    poolSize_1 = poolSize(4 : 6);
    poolSize = poolSize(1 : 3);
end

fprintf('Compute xcorr shifts for tiles with MIP slab method:\n    %s\n    %s\n', imgFullpath_1, imgFullpath_2);
mipFullpaths = cell(3, 2);
axis_strs = {'y', 'x', 'z'};
xyz_inds = [2, 1, 3];

inputFullpaths = cell(3, 1);
outputFullpaths = cell(3, 1);
funcStrs = cell(3, 1);
overlap_sizes = zeros(3, 3);
for i = 1 : 3
    for f = 1 : 2
        if f == 1
            imgFullpath_f = imgFullpath_1;
        else
            imgFullpath_f = imgFullpath_2;
        end
        [dataPath, fsn] = fileparts(imgFullpath_f);
        mipFullpaths{i, f} = sprintf('%s/%s/%s_%s.zarr', dataPath, mipDirStr, fsn, axis_strs{i});
    end

    % call cross_correlation_registration_3d.m for each axis
    imgFullpath_i1 = mipFullpaths{i, 1};
    imgFullpath_i2 = mipFullpaths{i, 2};

    xyz_factors_i = xyz_factors .* poolSize_1([2, 1, 3]);
    xyz_factors_i(xyz_inds(i)) = xyz_factors(xyz_inds(i)) * poolSize(i);
    MaxOffset_i = ceil(MaxOffset ./ poolSize_1);
    MaxOffset_i(i) = ceil(MaxOffset(i) / poolSize(i));
    downSample_i = round(downSample ./ poolSize_1);
    downSample_i(i) = 2;
        
    sz_i1 = getImageSize(imgFullpath_i1);
    sz_i2 = getImageSize(imgFullpath_i2);
    cuboid_1i = cuboid_1;
    cuboid_1i(4 : 6) = cuboid_1i(1 : 3) + (sz_i1([2, 1, 3]) - 2) * px .* xyz_factors_i;
    cuboid_2i = cuboid_2;
    cuboid_2i(4 : 6) = cuboid_2i(1 : 3) + (sz_i2([2, 1, 3]) - 2) * px .* xyz_factors_i;

    stitch2D = false;
    [is_overlap, cuboid_overlap_12i] = check_cuboids_overlaps(cuboid_1i, cuboid_2i, stitch2D);

    if ~is_overlap
        cuboid_1i = cuboid_1;
        cuboid_2i = cuboid_2;
        cuboid_overlap_12i = cuboid_overlap_12;
    end

    overlap_sizes(i, :) = ceil((cuboid_overlap_12i(4 : 6) - cuboid_overlap_12i(1 : 3)) ./ px ./ xyz_factors_i) + MaxOffset_i;
    
    imgFullpath_i2_str = sprintf('{''%s''}', imgFullpath_i2);
    largeZarr = false;    
    mipDirStr_i = '';
    poolSize_i = [];
    pair_indices = [i, i + 1];

    inputFullpaths{i} = imgFullpath_i1;
    outputFullpaths{i} = sprintf('%s_%s.mat', xcorrFullpath(1 : end - 4), axis_strs{i});
    funcStrs{i} = sprintf(['cross_correlation_registration_wrapper(''%s'',%s,''%s'',', ...
        '[%s],[%s],[%s],[%s],%0.20d,[%s],''Stitch2D'',%s,''downSample'',[%s],', ...
        '''MaxOffset'',%s,''largeZarr'',%s,''mipDirStr'',''%s'',''poolSize'',%s)'], ...
        imgFullpath_i1, imgFullpath_i2_str, outputFullpaths{i}, strrep(mat2str(pair_indices), ' ', ','), ...
        strrep(mat2str(cuboid_1i), ' ', ','), strrep(mat2str(cuboid_2i), ' ', ','), ...
        strrep(mat2str(cuboid_overlap_12i), ' ', ','), px, strrep(mat2str(xyz_factors_i), ' ', ','), ...
        string(stitch2D), strrep(num2str(downSample_i, '%.20d,'), ' ', ''), ...
        strrep(mat2str(MaxOffset_i), ' ', ','), string(largeZarr), mipDirStr_i, ...
        strrep(mat2str(poolSize_i), ' ', ','));

%     tic
%     [relative_shift_i, max_xcorr_i] = cross_correlation_registration_3d(imgFullpath_i1, ...
%         imgFullpath_i2, '', cuboid_1i, cuboid_2i, cuboid_overlap_12i, px, xyz_factors_i, ...
%         downSample=downSample_i, MaxOffset=MaxOffset_i, dimNumThrsh=dimNumThrsh, ...
%         blankNumTrsh=blankNumTrsh);
%     toc
%     relative_shift_mat(i, :) = relative_shift_i;
%     max_xcorr_mat(i) = max_xcorr_i;
end

memAllocate = max(prod(overlap_sizes, 2)) * 4 / 2^30 * 50;
for i = 1 : 3
    is_done_flag = generic_computing_frameworks_wrapper(inputFullpaths, outputFullpaths, ...
        funcStrs, 'cpusPerTask', 2, 'maxTrialNum', 2, 'parseCluster', parseCluster, ...
        'memAllocate', memAllocate * 2^(i - 1), 'mccMode', mccMode, 'ConfigFile', ConfigFile);
    if all(is_done_flag)
        break;
    end
end

if ~all(is_done_flag)
    error('Some pairs of xcorr results are missing!');
end

% collect results
relative_shift_mat = zeros(3, 3);
max_xcorr_mat = zeros(3, 1);
for i = 1 : 3
    a = load(outputFullpaths{i});
    relative_shift_mat(i, :) = a.relative_shift_mat;
    max_xcorr_mat(i) = a.max_xcorr_mat;
end

% use weighted average to estimate the final shift
relative_shift = zeros(1, 3);
for i = 1 : 3
    diff_inds = setdiff(1 : 3, xyz_inds(i));
    weight_i = max_xcorr_mat(diff_inds) .^ 2;
    relative_shift_mat(diff_inds, i) = relative_shift_mat(diff_inds, i) * poolSize_1(xyz_inds(i));

    relative_shift(i) = sum(relative_shift_mat(diff_inds, i) .* weight_i) ./ sum(weight_i);
end
relative_shift = round(relative_shift);
max_xcorr = sum(max_xcorr_mat.^3) ./ sum(max_xcorr_mat .^ 2);

if saveResult
    fprintf('Save results ...\n');
    
    uuid = get_uuid();
    xcorrTmppath = sprintf('%s_%s.mat', xcorrFullpath(1 : end - 4), uuid);
    save('-v7.3', xcorrTmppath, 'relative_shift', 'max_xcorr', 'relative_shift_mat', 'max_xcorr_mat');
    fileattrib(xcorrTmppath, '+w', 'g');
    movefile(xcorrTmppath, xcorrFullpath);
    fprintf('Done!\n');    
end

end


