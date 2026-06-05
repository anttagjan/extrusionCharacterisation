close all
%% load data
filepath = 'D:\Antonio\extrusion systematic characterisation\test';
frameRate = 5;

timeDataframe = readtable(fullfile(filepath,'dataframes','timeAlignment.xlsx'));

[nf_extrusion, nf_masks, nf_features] = loadFileLists(filepath);

%% Alignment choice
[selectedColumn, selectedLandmarks] = askAlignmentMethod();

timeTable = buildTimeTable(timeDataframe, selectedColumn);

nf_landmarks = dir(fullfile(filepath,'input',selectedLandmarks,'*landmarks.zip'));

matFile = fullfile(filepath,'dataframes', ...
    sprintf('data_%s_transformed.mat', selectedLandmarks));

if ~exist(matFile,'file')
    data = runPreprocessing(filepath, nf_extrusion, nf_masks, nf_features, nf_landmarks, timeTable, frameRate);
    save(matFile, '-struct', 'data', '-v7.3');
else
    load(matFile);
end

getHeatmapData(filepath, selectedLandmarks, timeTable, procruste_transformed, masks_transformed, features_transformed);

getSumAverageCVHeatmap(filepath,selectedLandmarks,procruste_transformed,allValidN_full,timeStep,nBins);
getRegionalHeatmap(filepath,filenames,selectedLandmarks,procruste_transformed,allValidN_full,heatmapSum,nBins,timeStep);

