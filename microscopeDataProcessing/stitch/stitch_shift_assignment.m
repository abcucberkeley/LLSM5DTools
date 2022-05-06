function [xyz_shift, d_shift] = stitch_shift_assignment(zarrFullpaths, xcorrDir, imSizes, xyz, ...
    px, xyz_factors, overlap_matrix, overlap_regions, MaxOffset, xcorrDownsample, tileIdx, assign_method, parseCluster)
% main function for stitch shift assignment 
% The main code is taken from XR_stitching_frame_zarr_dev_v1.m (to simplify
% the function).
%
% First compute xcorr between overlapping tiles, and then perform
% assignment of shifts either by local or global assignment method
% local assignment: MST and DFS 
% global assignment: weighted constrained linear least square
% 
% author: Xiongtao Ruan (11/05/2021)
% xruan (02/06/2022): for 'test' assignment method, not compute xcorr for tiles overlap from corners.


fprintf('Compute cross-correlation based registration between overlap tiles...\n');

xcorr_thresh = 0.25;
% test thrshold for global assignment (in some cases the xcorr between
% tiles are pretty weak, especially for low snr images)
xcorr_thresh = 0.10;
xcorr_thresh = 0.05;

if ~exist(xcorrDir, 'dir')
    mkdir_recursive(xcorrDir, true);
end

xf = xyz_factors(1);
yf = xyz_factors(2);
zf = xyz_factors(3);

nF = numel(zarrFullpaths);
absolute_shift_mat = zeros(nF * (nF - 1) / 2, 3); % order: x, y, z
max_xcorr_mat = zeros(nF * (nF - 1) / 2, 3);

% refactor the code with slurm generic framework
overlap_matrix_orig = overlap_matrix;
[ti, tj] = ind2sub(size(overlap_matrix), find(overlap_matrix));
switch assign_method
    case {'grid', 'test'}
        grid_overlap_inds = sum(abs(tileIdx(ti, :) - tileIdx(tj, :)), 2) == 1;

        % remove non-grid overlaps (corner overlaps)
        ti = ti(grid_overlap_inds);
        tj = tj(grid_overlap_inds);
        overlap_matrix = 0 * overlap_matrix;
        overlap_matrix(sub2ind(size(overlap_matrix), ti, tj)) = 1;    
end

inputFullpaths = zarrFullpaths(ti);
outputFullpaths = arrayfun(@(x) sprintf('%s/xcorr_tile_%d_tile_%d.mat', xcorrDir, ti(x), tj(x)), 1 : numel(ti), 'unif', 0);

cuboid_mat = [xyz, xyz + (imSizes(:, [2, 1, 3]) - 1) .* [xf, yf, zf] * px];

pinds = (ti - 1) * nF - ti .* (ti + 1) / 2 + tj;
cuboid_overlap_ij_mat = overlap_regions(pinds, :);

% funcStrs = arrayfun(@(x) sprintf(['multires_cross_correlation_registration_imblock(''%s'',''%s'',''%s'',', ...
%                             '[%s],[%s],[%s],%0.20d,[%s],''downSample'',[%s],''xyMaxOffset'',%0.20d,''zMaxOffset'',%0.20d);toc;'], ...
%                             zarrFullpaths{ti(x)}, zarrFullpaths{tj(x)}, outputFullpaths{x}, strrep(mat2str(cuboid_mat(ti(x), :)), ' ', ','), ...
%                             strrep(mat2str(cuboid_mat(tj(x), :)), ' ', ','), strrep(mat2str(cuboid_overlap_ij_mat(x, :)), ' ', ','), ...
%                             px, sprintf('%.20d;%.20d;%.20d', xf, yf, zf), strrep(num2str(xcorrDownsample, '%.20d,'), ' ', ''), ...
%                             xyMaxOffset, zMaxOffset), 1 : numel(ti), 'unif', 0);

funcStrs = arrayfun(@(x) sprintf(['multires_cross_correlation_registration_imblock_test(''%s'',''%s'',''%s'',', ...
                            '[%s],[%s],[%s],%0.20d,[%s],''downSample'',[%s],''MaxOffset'',%s);toc;'], ...
                            zarrFullpaths{ti(x)}, zarrFullpaths{tj(x)}, outputFullpaths{x}, strrep(mat2str(cuboid_mat(ti(x), :)), ' ', ','), ...
                            strrep(mat2str(cuboid_mat(tj(x), :)), ' ', ','), strrep(mat2str(cuboid_overlap_ij_mat(x, :)), ' ', ','), ...
                            px, sprintf('%.20d;%.20d;%.20d', xf, yf, zf), strrep(num2str(xcorrDownsample, '%.20d,'), ' ', ''), ...
                            strrep(mat2str(MaxOffset), ' ', ',')), 1 : numel(ti), 'unif', 0);
                        
rawImageSizes = prod((cuboid_overlap_ij_mat(:, 4 : 6) - cuboid_overlap_ij_mat(:, 1 : 3))' ./ (px * [xf; yf; zf])) * 8 / 1024^3;
cpusPerTask_xcorr = prctile(min(24, ceil(rawImageSizes * 15 / 20)), 90);

maxTrialNum_xcorr = 2;
is_done_flag = slurm_cluster_generic_computing_wrapper(inputFullpaths, outputFullpaths, funcStrs, ...
    'cpusPerTask', cpusPerTask_xcorr, 'maxTrialNum', maxTrialNum_xcorr, 'parseCluster', parseCluster);    

maxTrialNum_xcorr = 1;    
if ~all(is_done_flag)
    is_done_flag = slurm_cluster_generic_computing_wrapper(inputFullpaths, outputFullpaths, funcStrs, ...
        'cpusPerTask', cpusPerTask_xcorr * 2, 'maxTrialNum', maxTrialNum_xcorr, 'parseCluster', parseCluster);
end

maxTrialNum_xcorr = 1;
if ~all(is_done_flag)
    is_done_flag = slurm_cluster_generic_computing_wrapper(inputFullpaths, outputFullpaths, funcStrs, ...
        'cpusPerTask', cpusPerTask_xcorr * 4, 'maxTrialNum', maxTrialNum_xcorr, 'parseCluster', parseCluster);
end

% collect results
if all(is_done_flag)
    d_w = zeros(numel(outputFullpaths), 6);
    for f = 1 : numel(outputFullpaths)
        xcorrFullpath = outputFullpaths{f};
        ind = pinds(f);
        i = ti(f);
        j = tj(f);

        if exist(xcorrFullpath, 'file')
            order_flag = (0.5 - (xyz(i, :) > xyz(j, :))) * 2;
            a = load(xcorrFullpath);
            absolute_shift_mat(ind, :) = a.relative_shift .* order_flag;
            max_xcorr_mat(ind, :) = [i, j, a.max_xcorr];
            d_w(f, :) = [i, j, a.max_xcorr, absolute_shift_mat(ind, :)];
        end
    end
    max_xcorr_mat(max_xcorr_mat(:, 1) == 0 | max_xcorr_mat(:, 2) == 0, :) = [];
else
    error('Some xcorr files are missing!')
end

% perform assignment
switch assign_method
    case 'local'
        [d_shift] = stitch_local_assignment(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, xcorr_thresh);
    case 'global'
        neq = size(max_xcorr_mat, 1);
        max_shift_l = -ones(neq, 1) .* MaxOffset;
        max_shift_u = (cuboid_overlap_ij_mat(:, 4 : 6) - cuboid_overlap_ij_mat(:, 1 : 3)) ./ (px .* [xf, yf, zf]);
        max_shift_u = min(max_shift_u - 1, MaxOffset);
        
        max_allow_shift = [max_shift_l, max_shift_u];
        
        [d_shift] = stitch_global_assignment(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, max_allow_shift, xcorr_thresh);
    case 'grid'
        neq = size(max_xcorr_mat, 1);
        max_shift_l = -ones(neq, 1) .* MaxOffset;
        max_shift_u = (cuboid_overlap_ij_mat(:, 4 : 6) - cuboid_overlap_ij_mat(:, 1 : 3)) ./ (px .* [xf, yf, zf]);
        max_shift_u = min(max_shift_u - 1, MaxOffset);
        
        max_allow_shift = [max_shift_l, max_shift_u];
        
        [d_shift] = stitch_global_grid_assignment(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, max_allow_shift, xcorr_thresh, tileIdx);
    case 'test'
        neq = size(max_xcorr_mat, 1);
        max_shift_l = -ones(neq, 1) .* MaxOffset;
        max_shift_u = (cuboid_overlap_ij_mat(:, 4 : 6) - cuboid_overlap_ij_mat(:, 1 : 3)) ./ (px .* [xf, yf, zf]);
        max_shift_u = min(max_shift_u - 1, MaxOffset);
        
        max_allow_shift = [max_shift_l, max_shift_u];
        
        [d_shift] = stitch_global_grid_assignment_test(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, max_allow_shift, xcorr_thresh, tileIdx);
        
end

% for debug d_shift
if ~false
    absolute_shift_mat_1 = zeros(nF * (nF - 1) / 2, 3);
    for f = 1 : numel(ti)
        ind = pinds(f);
        i = ti(f);
        j = tj(f);
        absolute_shift_mat_1(ind, :) = d_shift(j, :) - d_shift(i, :);
    end
end

xyz_shift = xyz + d_shift .* [xf, yf, zf] .* px;

end


% unify input and output for different assignment methods

function [d_shift] = stitch_local_assignment(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, xcorr_thresh)
% use max xcorr as weights to construct a graph, and use MST to trim the
% graph, and use DFS to assign the absolute shift based on a tile's
% predecessor. 


d_shift = zeros(nF, 3);
% also remove the pair with very small max corr, i.e., <0.5 
max_xcorr_mat(max_xcorr_mat(:, 3) < xcorr_thresh, 3) = 0.001;        
G = graph(max_xcorr_mat(:, 1), max_xcorr_mat(:, 2), -max_xcorr_mat(:, 3));
T = minspantree(G, 'type', 'forest');
aj = full(adjacency(T));
if any(size(aj) ~= nF)
    aj = padarray(aj, nF - size(aj), 0, 'post');
end
% overlap_matrix = overlap_matrix .* aj;
[inds_i, inds_j] = find(overlap_matrix .* aj);
absolute_shift_mat_orig = absolute_shift_mat;
absolute_shift_mat = absolute_shift_mat * 0;        
if numel(inds_i) > 0
    tinds = (inds_i - 1) * nF - inds_i .* (inds_i + 1) / 2 + inds_j;
    absolute_shift_mat(tinds, :) = absolute_shift_mat_orig(tinds, :);
end

% calculate absolute shifts of tiles
% xyz_shift = xyz;
% for i = 1 : nF - 1
%     for j = i + 1 : nF
%         if ~overlap_matrix(i, j)
%             continue;
%         end
%         % ind = 0.5 * i * (2 * j - i - 1);
%         ind = (i - 1) * nF - i * (i + 1) / 2 + j;
%         if all(absolute_shift_mat(ind, :) == 0) 
%             continue;
%         end
%         % order_flag = (0.5 - (xyz(i, :) > xyz(j, :))) * 2;
%         % xyz_shift(j, :) = (xyz_shift(i, :) - xyz(i, :)) + (xyz_shift(j, :) + order_flag .* relative_shift_mat(ind, :) .* [xf, yf, zf] * px);
%         xyz_shift(j, :) = (xyz_shift(i, :) - xyz(i, :)) + (xyz_shift(j, :) + absolute_shift_mat(ind, :) .* [xf, yf, zf] * px);
%     end
% end
% xruan (11/05/2021) change to use DFS search to just shift to the tile's precessor
% search from node 1
v = dfsearch(T, 1);
visit_flag = false(numel(v), 1);
for i = 1 : numel(v)
    n_i = v(i);
    if i == 1
        visit_flag(n_i) = true;
        continue;
    end

    n_nbs = neighbors(T, n_i);
    n_pr = n_nbs(visit_flag(n_nbs));
    if n_i > n_pr
        s = n_pr;
        t = n_i;
        st_sign = 1;
    else
        s = n_i;
        t = n_pr;
        st_sign = -1;
    end
    ind = (s - 1) * nF - s * (s + 1) / 2 + t;

    d_shift(n_i, :) = d_shift(n_pr, :) + st_sign .* absolute_shift_mat(ind, :);
    visit_flag(n_i) = true;
end

end


function [d_shift] = stitch_global_assignment(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, max_allow_shift, xcorr_thresh)
% solve weighted constrained linear least square problem for the assignment
% the weight is the function of max shift (currently just y=x). 
% max allowed shift is based on the maxShift parameter and the number of
% overlap between tiles.
% 02/03/2022: add threshold for objective to remove the samples with small xcorr

neq = sum(overlap_matrix(:));

R = zeros(neq, nF);

[n_i, n_j] = find(overlap_matrix);

inds_i = sub2ind(size(R), 1 : neq, n_i');
inds_j = sub2ind(size(R), 1 : neq, n_j');

R(inds_i) = -1; 
R(inds_j) = 1;

max_xcorr_mat_filt = max_xcorr_mat;
max_xcorr_mat_filt(max_xcorr_mat_filt(:, 3) < xcorr_thresh, :) = [];
w = max_xcorr_mat_filt(:, 3);

nP = size(max_xcorr_mat_filt, 1);
R_w = zeros(nP, nF);

np_i = max_xcorr_mat_filt(:, 1);
np_j = max_xcorr_mat_filt(:, 2);
inds_i = sub2ind(size(R_w), 1 : nP, np_i');
inds_j = sub2ind(size(R_w), 1 : nP, np_j');
R_w(inds_i) = -1; 
R_w(inds_j) = 1;

W = diag(w);
R_w = W.^0.5 * R_w;
% R_w = R;

c_inds = (np_i - 1) * nF - np_i .* (np_i + 1) / 2 + np_j;
d_w = absolute_shift_mat(c_inds, :);
d_w = W.^0.5 * d_w;

d_shift = zeros(nF, 3);
for i = 1 : 3
    C = R_w;
    d = d_w(:, i);
    A = [R; -R];

    l = max_allow_shift(:, i);
    u = max_allow_shift(:, 3 + i);
    b = [u; -l];

    [x,resnorm,residual,exitflag,output,lambda] = lsqlin(C,d,A,b);
    d_shift(:, i) = x;
end

% round to integers and normalize for the first tile.
d_shift = round(d_shift);
d_shift = d_shift - d_shift(1, :);

end


function [d_shift] = stitch_global_grid_assignment(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, max_allow_shift, xcorr_thresh, tileIdx)
% solve weighted constrained linear least square problem for the assignment
% the weight is the function of max shift (currently just y=x). 
% max allowed shift is based on the maxShift parameter and the number of
% overlap between tiles.
% 02/03/2022: add threshold for objective to remove the samples with small xcorr

neq = sum(overlap_matrix(:));

R = zeros(neq, nF);

[n_i, n_j] = find(overlap_matrix);

inds_i = sub2ind(size(R), 1 : neq, n_i');
inds_j = sub2ind(size(R), 1 : neq, n_j');

R(inds_i) = -1; 
R(inds_j) = 1;

max_xcorr_mat_filt = max_xcorr_mat;
max_xcorr_mat_filt(max_xcorr_mat_filt(:, 3) < xcorr_thresh, :) = [];
% w = max_xcorr_mat_filt(:, 3);
nP = size(max_xcorr_mat_filt, 1);
w = ones(nP, 1) * 0.00;
for i = 1 : nP
    s = max_xcorr_mat_filt(i, 1);
    t = max_xcorr_mat_filt(i, 2);
    
    % check if two tiles are neighboring tiles
    if sum(abs(tileIdx(s, :) - tileIdx(t, :))) == 1
        aind = find(abs(tileIdx(s, :) - tileIdx(t, :)));
        switch aind
            case 1
                w(i) = 0.1;
            case 2
                w(i) = 1;
            case 3
                w(i) = 10;
        end
    end    
end

R_w = zeros(nP, nF);

np_i = max_xcorr_mat_filt(:, 1);
np_j = max_xcorr_mat_filt(:, 2);
inds_i = sub2ind(size(R_w), 1 : nP, np_i');
inds_j = sub2ind(size(R_w), 1 : nP, np_j');
R_w(inds_i) = -1; 
R_w(inds_j) = 1;

W = diag(w);
R_w = W.^0.5 * R_w;
% R_w = R;

c_inds = (np_i - 1) * nF - np_i .* (np_i + 1) / 2 + np_j;
d_w = absolute_shift_mat(c_inds, :);
d_w = W.^0.5 * d_w;

d_shift = zeros(nF, 3);
for i = 1 : 3
    C = R_w;
    d = d_w(:, i);
    A = [R; -R];

    l = max_allow_shift(:, i);
    u = max_allow_shift(:, 3 + i);
    b = [u; -l];

    [x,resnorm,residual,exitflag,output,lambda] = lsqlin(C,d,A,b);
    d_shift(:, i) = x;
end

% round to integers and normalize for the first tile.
d_shift = round(d_shift);
d_shift = d_shift - d_shift(1, :);

end


function [d_shift] = stitch_global_grid_assignment_test(nF, max_xcorr_mat, absolute_shift_mat, overlap_matrix, max_allow_shift, xcorr_thresh, tileIdx)
% solve weighted constrained linear least square problem for the assignment
% the weight is the function of max shift (currently just y=x). 
% max allowed shift is based on the maxShift parameter and the number of
% overlap between tiles.
% 02/03/2022: add threshold for objective to remove the samples with small xcorr

neq = sum(overlap_matrix(:));

R = zeros(neq, nF);

[n_i, n_j] = find(overlap_matrix);

inds_i = sub2ind(size(R), 1 : neq, n_i');
inds_j = sub2ind(size(R), 1 : neq, n_j');

R(inds_i) = -1; 
R(inds_j) = 1;

max_xcorr_mat_filt = max_xcorr_mat;
max_xcorr_mat_filt(max_xcorr_mat_filt(:, 3) < xcorr_thresh, :) = [];
% w = max_xcorr_mat_filt(:, 3);
nP = size(max_xcorr_mat_filt, 1);
w = ones(nP, 1) * 0.00;
for i = 1 : nP
    s = max_xcorr_mat_filt(i, 1);
    t = max_xcorr_mat_filt(i, 2);
    
    % check if two tiles are neighboring tiles
    if sum(abs(tileIdx(s, :) - tileIdx(t, :))) == 1
        aind = find(abs(tileIdx(s, :) - tileIdx(t, :)));
        switch aind
            case 1
                w(i) = 1;
            case 2
                w(i) = 10;
            case 3
                w(i) = 0.1;
        end
    end    
end

R_w = zeros(nP, nF);

np_i = max_xcorr_mat_filt(:, 1);
np_j = max_xcorr_mat_filt(:, 2);
inds_i = sub2ind(size(R_w), 1 : nP, np_i');
inds_j = sub2ind(size(R_w), 1 : nP, np_j');
R_w(inds_i) = -1; 
R_w(inds_j) = 1;

W = diag(w);
R_w = W.^0.5 * R_w;
% R_w = R;

c_inds = (np_i - 1) * nF - np_i .* (np_i + 1) / 2 + np_j;
d_w = absolute_shift_mat(c_inds, :);
d_w = W.^0.5 * d_w;

d_shift = zeros(nF, 3);
for i = 1 : 3
    C = R_w;
    d = d_w(:, i);
    A = [R; -R];

    l = max_allow_shift(:, i);
    u = max_allow_shift(:, 3 + i);
    b = [u; -l];

    [x,resnorm,residual,exitflag,output,lambda] = lsqlin(C,d,A,b);
    d_shift(:, i) = x;
end

% round to integers and normalize for the first tile.
d_shift = round(d_shift);
d_shift = d_shift - d_shift(1, :);

end

