function [binnedData,summary,params]=runSpatioTemporalEventPipeline(filepath, filenames,params, data,sex_icon)

extrusions_transformed= data.extrusions_transformed;
divisions_transformed= data.divisions_transformed; 
landmarks_transformed=data.landmarks_transformed;
masks_transformed=data.masks_transformed;
masks_relativeTime = data.masks_relativeTime;
features_transformed=data.features_transformed;

%% Processing (Spatio Temporal discretisation)

binnedData = processAllMovies( ...
    extrusions_transformed, ...
    divisions_transformed, ... 
    masks_transformed, ...
    masks_relativeTime, ...
    features_transformed, ...
    spatialGrid, ...
    params);

%% Summary

summary = aggregateBinnedData(binnedData);

save(fullfile(filepath,'dataframes', ...
    strcat('STdata_',alignMethod,'_',num2str(params.timeStep),'h_timeStep.mat')), ...
    'summary','binnedData','spatialGrid','params');

%% Valid Bin Mask

nMovies = size(binnedData,1);
nTimeBins = size(binnedData,2);

validBinsMovie = false(params.nBins, params.nBins, nTimeBins, nMovies);

for m = 1:nMovies
    for t = 1:nTimeBins

        d = binnedData{m,t};

        if isstruct(d) && isfield(d,'tissue') && ...
                isfield(d.tissue,'validBinMask') && ...
                ~isempty(d.tissue.validBinMask)

            validBinsMovie(:,:,t,m) = d.tissue.validBinMask;
        end

    end
end

end