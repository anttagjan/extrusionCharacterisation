function [allData,summary,params]=getHeatmapData(filepath, filenames, alignMethod, data,Rglobal)

params.nBins = 30;
params.timeStep = 1;
extrusions_transformed= data.extrusions_transformed;
landmarks_transformed=data.landmarks_transformed;
masks_transformed=data.masks_transformed;
masks_relativeTime = data.masks_relativeTime;
features_transformed=data.features_transformed;

%% Preparing heatmap grid
allX = extrusions_transformed(:,1);
allY = extrusions_transformed(:,2);

spatialGrid.nBins = params.nBins;

spatialGrid.xEdges = linspace( ...
    1, ...
    Rglobal.ImageSize(2), ...
    params.nBins+1);

spatialGrid.yEdges = linspace( ...
    1, ...
    Rglobal.ImageSize(1), ...
    params.nBins+1);

%% Processing (Spatio Temporal discretisation)

[allData,timeBins] = processAllMovies( ...
    extrusions_transformed, ...
    masks_transformed, ...
    masks_relativeTime, ...
    features_transformed, ...
    spatialGrid, ...
    params);

%% Summary

summary = aggregateHeatmaps(allData);

save(fullfile(filepath,'dataframes', ...
    strcat('STdata_',alignMethod,'_',num2str(params.timeStep),'h_timeStep.mat')), ...
    'summary','allData','spatialGrid','params');

%% Valid Bin Mask

nMovies = size(allData,1);
nTimeBins = size(allData,2);

validBinsMovie = false(params.nBins, params.nBins, nTimeBins, nMovies);

for m = 1:nMovies
    for t = 1:nTimeBins

        d = allData{m,t};

        if isstruct(d) && isfield(d,'tissue') && ...
                isfield(d.tissue,'validBinMask') && ...
                ~isempty(d.tissue.validBinMask)

            validBinsMovie(:,:,t,m) = d.tissue.validBinMask;
        end

    end
end


%% PLOTS

plotExtrusionsQualityControl(allData,filenames,landmarks_transformed,spatialGrid)
plotExtrusions(filenames,extrusions_transformed,landmarks_transformed);
plotHeatmaps(summary);

end