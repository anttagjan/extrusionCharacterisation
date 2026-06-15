function getHeatmapData(filepath, filenames, alignMethod, data)

params.nBins = 30;
params.timeStep = 1;
extrusions_transformed= data.extrusions_transformed;
landmarks_transformed=data.landmarks_transformed;
masks_transformed=data.masks_transformed;
features_transformed=data.features_transformed;

%% Preparing heatmap grid
allX = extrusions_transformed(:,1);
allY = extrusions_transformed(:,2);

spatialGrid.nBins = params.nBins;

spatialGrid.xEdges = linspace(min(allX), max(allX), params.nBins+1);
spatialGrid.yEdges = linspace(min(allY), max(allY), params.nBins+1);

%% Processing (Spatio Temporal discretisation)

[allData,timeBins] = processAllMovies( ...
    extrusions_transformed, ...
    masks_transformed, ...
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