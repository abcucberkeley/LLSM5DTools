function [] = combinePhases(dataFile, varargin)

%fn = '/clusterfs/fiona/Data/20210923_latticeSIM/phasePSF/isolated/DS/RAW_488_slow_CamA_ch0_CAM1_stack0000_488nm_0000000msec_0013199486msecAbs_000x_000y_000z_0000t.tif';
%fn = '/clusterfs/fiona/Data/20210923_latticeSIM/data06_100perc/DS/RAW_exp08_CamA_ch0_CAM1_stack0000_488nm_0000000msec_0006674367msecAbs_000x_000y_000z_0000t.tif';
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('dataFile');
ip.addParameter('nphases', 5, @isnumeric);

ip.parse(dataFile, varargin{:});

pr = ip.Results;
nphases = pr.nphases;

% get first phase to check size
cPhase = readtiff([dataFile(1:end-4) '_phase' num2str(1) '.tif']);
outSize = size(cPhase);

out = zeros(outSize(1),outSize(2),outSize(3)*nphases);
for p=1:nphases
    if(p > 1)
        cPhase = readtiff([dataFile(1:end-4) '_phase' num2str(p) '.tif']);
    end
    out(:,:,p:nphases:end) = cPhase;
end

writetiff(single(out),dataFile);

end