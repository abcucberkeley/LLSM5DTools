function mccMaster_matlab(functionName, varargin)
% compile command

%#function setup

switch functionName
    case 'XR_microscopeAutomaticProcessing'
        XR_microscopeAutomaticProcessing_parser(varargin{1}, varargin{2:end});
    case 'XR_decon_data_wrapper'
        XR_decon_data_wrapper_parser(varargin{1}, varargin{2:end});
    case 'XR_crop_dataset'
        XR_crop_dataset_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'XR_fftSpectrumComputingWrapper'
        XR_fftSpectrumComputingWrapper_parser(varargin{1}, varargin{2:end});
    case 'XR_FSC_analysis_wrapper'
        XR_FSC_analysis_wrapper_parser(varargin{1},varargin{2:end});
    case 'XR_MIP_wrapper'
        XR_MIP_wrapper_parser(varargin{1}, varargin{2:end});
    case 'XR_parallel_rsync_wrapper'
        XR_parallel_rsync_wrapper_parser(varargin{1}, varargin{2}, varargin{3:end});
    case 'simReconAutomaticProcessing'
        simReconAutomaticProcessing_parser(varargin{1}, varargin{2:end});        
    case 'XR_matlab_stitching_wrapper'
        XR_matlab_stitching_wrapper_parser(varargin{1}, varargin{2}, varargin{3:end});
    case 'XR_stitching_frame_zarr_dev_v1'
        XR_stitching_frame_zarr_dev_v1_parser(varargin{1}, varargin{2}, varargin{3:end});
    case 'tiffToZarr'
        tiffToZarr_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});        
    case 'cross_correlation_registration_2d'
        cross_correlation_registration_2d_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7}, varargin{8}, varargin{9:end});
    case 'cross_correlation_registration_3d'
        cross_correlation_registration_3d_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7}, varargin{8}, varargin{9:end});
    case 'compute_tile_bwdist'
        compute_tile_bwdist_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7}, varargin{8});
    case 'processStitchBlock'
        processStitchBlock_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7},  varargin{8:end});
    case 'XR_deskewRotateFrame'
        XR_deskewRotateFrame_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'XR_RLdeconFrame3D'
        XR_RLdeconFrame3D_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'XR_RotateFrame3D'
        XR_RotateFrame3D_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'RLdecon_for_zarr_block'
        RLdecon_for_zarr_block_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7}, varargin{8}, varargin{9}, varargin{10:end});
    case 'XR_deskewRotateZarr'
        XR_deskewRotateZarr_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'XR_deskewRotateBlock'
        XR_deskewRotateBlock_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7}, varargin{8}, varargin{9}, varargin{10:end});
    case 'XR_resampleFrame'
        XR_resampleFrame_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'XR_resampleSingleZarr'
        XR_resampleSingleZarr_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'resampleZarrBlock'
        resampleZarrBlock_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6:end});
    case 'XR_crop_frame'
        XR_crop_frame_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4:end});
    case 'XR_crop_block'
        XR_crop_block_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7:end});
    case 'XR_MIP_zarr'
        XR_MIP_zarr_parser(varargin{1}, varargin{2:end});
    case 'saveMIP_zarr'
        saveMIP_zarr_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4});
    case 'MIP_block'
        MIP_block_parser(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7:end});
    case 'saveMIP_tiff'
        saveMIP_tiff_parser(varargin{1}, varargin{2}, varargin{3:end});
    case 'XR_one_image_FSC_analysis_frame'
        XR_one_image_FSC_analysis_frame_parser(varargin{1}, varargin{2}, varargin{3:end});
    case 'XR_fftSpectrumComputingFrame'
        XR_fftSpectrumComputingFrame_parser(varargin{1}, varargin{2}, varargin{3:end});
    case 'simReconFrame'
        simReconFrame_parser(varargin{1}, varargin{2}, varargin{3:end});        
end
