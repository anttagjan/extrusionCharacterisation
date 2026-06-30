function [binnedData,summary,params]=runSpatioTemporalEventPipeline(params, rawData,spatialGrid)

extrusions_transformed= rawData.extrusions_transformed;
divisions_transformed= rawData.divisions_transformed; 
masks_transformed=rawData.masks_transformed;
masks_relativeTime = rawData.masks_relativeTime;
features_transformed=rawData.features_transformed;

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

summary = aggregateSpatialData(binnedData);

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