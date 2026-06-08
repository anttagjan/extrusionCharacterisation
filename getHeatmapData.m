function getHeatmapData(filepath, filename, peaks, data)

params.nBins = 30;
params.timeStep = 1;
extrusions_transformed= data.extrusions_transformed;
masks_transformed=data.masks_transformed;
features_transformed=data.features_transformed;

grid = buildSpatialGrid(extrusions_transformed, params.nBins);

allData = processAllMovies( ...
    extrusions_transformed, ...
    masks_transformed, ...
    features_transformed, ...
    grid, ...
    params);

summary = aggregateHeatmaps(allData);

save(fullfile(filepath,'dataframes', ...
    strcat('heatmap_',filename,'_',num2str(timeStep),'h_timeStep.mat')), ...
    'summary','allData','grid','params');

nMovies = size(allData,1);

validBinsMovie = [];

for m = 1:nMovies
    validBinsMovie(:,:,m) = allData{m}.tissue.validBinMask;
end

plotExtrusions(filenames,extrusions_transformed,landmarks_transformed,validBinsMovie);
plotHeatmaps(summary);

end