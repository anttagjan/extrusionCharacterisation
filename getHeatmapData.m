function [allData,summary,spatialGrid]=getHeatmapData(filenames, data,Rglobal,params)

extrusions_transformed= data.extrusions_transformed;
divisions_transformed= data.divisions_transformed; %RAJOUT
landmarks_transformed=data.landmarks_transformed;
masks_transformed=data.masks_transformed;
masks_relativeTime = data.masks_relativeTime;
features_transformed=data.features_transformed;



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
    divisions_transformed, ... %AJOUT
    masks_transformed, ...
    masks_relativeTime, ...
    features_transformed, ...
    spatialGrid, ...
    params);

%% Summary
summary = aggregateHeatmaps(allData);

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


<<<<<<< Updated upstream
%% PLOTS pour DIVISIONS aussi

%plotExtrusionsQualityControl(allData,filenames,landmarks_transformed,spatialGrid, 'extrusions')
%plotExtrusions(filenames,extrusions_transformed,landmarks_transformed);

%plotExtrusionsQualityControl(allData,filenames,landmarks_transformed,spatialGrid, 'divisions')

plotExtrusionsQualityControl( ...
    allData, ...
    filenames, ...
    landmarks_transformed, ...
    spatialGrid, ...
    'extrusions')


plotExtrusions( ...
    filenames, ...
    extrusions_transformed, ...
    landmarks_transformed);

%POur division
plotExtrusionsQualityControl( ...
    allData, ...
    filenames, ...
    landmarks_transformed, ...
    spatialGrid, ...
    'divisions')

plotHeatmaps(summary)
=======
%% PLOTS
plotExtrusionsQualityControl(allData,filenames,landmarks_transformed,spatialGrid)
plotExtrusions(filenames,extrusions_transformed,landmarks_transformed);
plotHeatmaps(summary);
>>>>>>> Stashed changes

end