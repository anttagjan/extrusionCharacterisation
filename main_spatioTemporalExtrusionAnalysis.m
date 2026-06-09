close all
%% load data
filepath = 'D:\Antonio\extrusion systematic characterisation\test';
frameRate = 5;

timeDataframe = readtable(fullfile(filepath,'dataframes','timeAlignment.xlsx'));

%% Alignment choice
[selectedColumn, selectedLandmarks] = askAlignmentMethod();

timeTable = buildTimeTable(timeDataframe, selectedColumn);

[nf_extrusions,nf_divisions, nf_masks,nf_piv, nf_features] = loadFileLists(filepath);
nf_landmarks = dir(fullfile(filepath,'input',selectedLandmarks,'*landmarks.zip'));

filenames = {nf_extrusions.name};
matFile = fullfile(filepath,'dataframes', ...
    sprintf('data_%sAlignment_transformed.mat', selectedLandmarks));

if ~exist(matFile,'file')
    data = runPreprocessing(filepath, nf_extrusions,nf_divisions, nf_masks,nf_piv, nf_features, nf_landmarks, timeTable, frameRate, selectedLandmarks);
    save(matFile, 'data', '-v7.3');
else
    load(matFile);
end

getHeatmapData(filepath, filenames,selectedLandmarks, data);

getSumAverageCVHeatmap(filepath,selectedLandmarks,extrusions_transformed,allValidN_full,timeStep,nBins);
getRegionalHeatmap(filepath,filenames,selectedLandmarks,procruste_transformed,allValidN_full,heatmapSum,nBins,timeStep);

