close all
%% init
filepath = 'D:\Antonio\extrusion systematic characterisation\';
% filepath = 'D:\Antonio\caspase dynamics\alignment';
params.nBins = 30;
params.timeStep = 1;
params.frameRate = 5;

timeDataframe = readtable(fullfile(filepath,'dataframes','timeAlignment.xlsx'));

%% Alignment choice
[selectedColumn, selectedLandmarks] = askAlignmentMethod();
timeTable = buildTimeTable(timeDataframe, selectedColumn);

%% load data
[nf_extrusions,nf_divisions, nf_masks,nf_piv, nf_features] = loadFileLists(filepath);
nf_landmarks = dir(fullfile(filepath,'input',selectedLandmarks,'*landmarks.zip'));

filenames = {nf_extrusions.name};
matFile = fullfile(filepath,'dataframes', ...
    sprintf('data_%sAlignment_transformed.mat', selectedLandmarks));

%% Procruste transformation
if ~exist(matFile,'file')
    [data,Rglobal] = runPreprocessing(filepath, nf_extrusions,nf_divisions, nf_masks,nf_piv, nf_features, nf_landmarks, timeTable, params.frameRate, selectedLandmarks);
    save(matFile, 'data','Rglobal', '-v7.3');
else
    load(matFile);
end

%% spatio-temporal discretisation
dataFile = fullfile(filepath, 'dataframes', ...
    sprintf('SpatioTempData_%s_%gh_timeStep.mat', selectedLandmarks, params.timeStep));

if ~exist(dataFile,'file')
    [allData,summary,spatialGrids]=getHeatmapData(filenames,data,Rglobal,params);
    save(dataFile, 'summary','allData','params','spatialGrids','-v7.3');
else
    load(dataFile);
end

%% Regional analysis
% getSumAverageCVHeatmap(filepath,selectedLandmarks,extrusions_transformed,data,params);

% extrusions
getRegionalHeatmap(filepath,filenames,selectedLandmarks,data.extrusions_transformed,allData,Rglobal,summary,params,'extrusions');

%divisions
getRegionalHeatmap(filepath,filenames,selectedLandmarks,data.divisions_transformed,allData,Rglobal,summary,params,'divisions');
